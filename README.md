<center>
<img src='doc/logo.png' style='max-height: 15vh; max-width: 100vw'>
</center>

---

# openIPE: An Extensible Memory Isolation Framework for Microcontrollers

[![Build Status](https://github.com/martonbognar/openipe/actions/workflows/ci.yaml/badge.svg)](https://github.com/martonbognar/openipe/actions/workflows/ci.yaml)
 [![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
![Docker pulls](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fghcr-badge.elias.eu.org%2Fapi%2Fmartonbognar%2Fopenipe%2Fopenipe&query=downloadCount&label=Docker+pulls&logo=github)

This repository contains [openIPE](https://mici.hu/papers/bognar25openipe.pdf), a microcontroller design based on [openMSP430](https://github.com/olgirard/openmsp430), implementing Texas Instruments' [Intellectual Property Encapsulation (IPE)](https://www.ti.com/lit/an/slaa685/slaa685.pdf#page=9) memory isolation feature and featuring a firmware layer that can be used to implement various security-critical features.
Aside from the source code of the microcontroller and applications, the repository contains a unit test suite and uses a symbolic execution tool to validate properties of either IPE application or firmware code.

If you extend or improve upon our work, please consider submitting a pull request and cite openIPE as the following:

```bibtex
@inproceedings{bognar25openipe,
  title     = {{openIPE}: An Extensible Memory Isolation Framework for Microcontrollers},
  author    = {Bognar, Marton and Van Bulck, Jo},
  year      = 2025,
  booktitle = {10th {IEEE} European Symposium on Security and Privacy (EuroS{\&}P)},
}
```

For a complete introduction to this work, we also strongly encourage reading our [EuroS&P'25 paper](https://mici.hu/papers/bognar25openipe.pdf).

## Installation

### Docker setup

We recommend using [Docker Compose](https://docs.docker.com/compose/) for the development environment.
You can launch a development container with the following command:

```shell
docker compose run --remove-orphans openipe
```

Check (and if desired, modify) the list of mounted directories in [`docker-compose.yaml`](./docker-compose.yaml), which will allow you to synchronize files between the container and your local file system.

You can also build the image locally if you'd like to modify the [`Dockerfile`](./Dockerfile):

```shell
docker compose run --build --remove-orphans openipe_local
```

### Manual setup

Alternatively, you can follow the steps in the [Dockerfile](Dockerfile) to set up the dependencies on your own machine.

## Basic functionality

To enable easy reproduction of the most important results and to provide an easy way of getting started with the codebase, we provide top-level scripts in the `scripts` directory.
These scripts can be used as a starting point for running more advanced examples and are detailed in the following sections.

### Unit test suite

#### Regression tests

Run `./scripts/regression_tests.sh` to execute the original regression tests of openMSP430.
This test will finish with an overview table and a report of the number of successful and unsuccessful tests.

#### Isolation test suite

Run `./scripts/isolation_tests.sh` to execute the unit tests we added to validate the security guarantees added by our extensions and the interrupt case study.
This script performs two steps:
First, it runs the tests as expected, where it is validated that no leakage occurs.
Then, it runs some tests without the hardware fixes proposed in IPE Exposure to validate that this re-enables some vulnerabilities.

During the execution of the case study tests (#24-26), overhead measurements for the interrupt latencies are also provided.


```shell
$ ./scripts/isolation_tests.sh
...
#===================================================================#
#                            SUMMARY REPORT                         #
#===================================================================#

         +-----------------------------------
         | Number of PASSED  tests : 26
         | Number of SKIPPED tests : 0
         | Number of FAILED  tests : 0
         | Number of ABORTED tests : 0
         |----------------------------------
         | Number of tests         : 26
         +----------------------------------

...
```

### Attestation case study

The script `./scripts/framework_attestation.sh` runs the framework on the attestation code adapted from VRASED and runs it on openIPE, reporting on the total number of cycles elapsed.

### Symbolic validation

The following scripts run the [Pandora](https://github.com/pandora-tee/pandora) symbolic execution tool on openIPE binaries.
These scripts operate on the `pmem.elf` and `bmem.elf` binaries located in the `core/sim/rtl_sim/run` directory, i.e., they will analyze the last program that was run on the simulator.
For example, you can run `./scripts/framework_hello.sh` first to generate the simple hello world IPE application binary.

The script `./scripts/symbolic_ipe.sh` performs the security validation if the binary contains a valid IPE region, while `./scripts/symbolic_firmware.sh` will validate the firmware code.

The Pandora reports will be stored in the `logs/symbolic_ipe/` and `logs/symbolic_firmware/` directories, respectively. If you use docker compose or manually map the volumes, you will be able to access these logs on your host machine and open them in a browser.

## Software development framework

The [`framework/`](core/sim/rtl_sim/src-c/framework) directory provides a **source-to-source C compilation toolchain** that automates the boilerplate required to safely call in and out of the IPE-protected region. `compiler.py` and `linker.py` act as drop-in replacements for `msp430-elf-gcc` and are wired in via `Makefile.include`:

```makefile
CC = $(OPENIPE)/compiler.py
LD = $(OPENIPE)/linker.py
```

### Annotations

Annotate C code with macros from `libipe/ipe_support.h`:

| Macro       | Purpose                                                   |
|-------------|-----------------------------------------------------------|
| `IPE_ENTRY` | Entry point callable from untrusted code (ecall)          |
| `IPE_FUNC`  | Internal IPE function (not directly callable from outside)|
| `IPE_VAR`   | Protected variable (placed in `.ipe_vars`)                |
| `IPE_CONST` | Protected constant (placed in `.ipe_const`)               |

One compilation unit must also include `DECLARE_IPE_STRUCT;` to emit the hardware initialization structure.

### Toolchain flow

```
  annotated C sources    libraries (libgcc.a, ...)
         │                       │
         ▼                       │
     compiler.py                 │
 (src→src AST transform)         │
         │                       │
         ▼                       │
    .o files                     │
         │                       │
         └──────────┬────────────┘
                    ▼
                linker.py
          (generate stubs + link)
                    │
                    ▼
             final ELF binary
        ┌────────────────────────┐
        │   IPE-protected region │  ← hardware boundary
        ├────────────────────────┤
        │   untrusted code/data  │
        └────────────────────────┘
```

### Toolchain components

**compiler.py** performs a source-to-source AST transformation (via pycparser) on each annotated file:
- `IPE_ENTRY fn()` is split: the body moves to `fn_internal()` inside the IPE region; `fn()` becomes a generated ecall stub.
- Calls from IPE code to untrusted functions are rewritten to `fn_stub()` (ocall trampolines).
- Calls to compiler helper routines (`libgcc.a`) are intercepted at assembly level and rewritten to secure, intra-IPE variants.
- Argument register usage (r12–r15) is encoded as a bitmap and embedded as weak ELF symbols (`__ipe_ecall_*`, `__ipe_ocall_*`) for the linker.

**linker.py** reads those symbols across all object files, instantiates assembly templates to produce the entry-dispatch table and ocall stubs, and links everything with a custom linker script. Different versions of IPE entry stubs (e.g., with or without secure interrupt support) can be specified via a JSON config file.

### Ecall/ocall flow

The runtime stubs implement the ecall/ocall entry points in assembly, with register clearing to prevent leakage across the IPE boundary.

```
   main   untrusted stub             IPE "enclave"
     |          |          ╔══════════════════════════════╗
     │          │          ║  IPE stub         IPE app    ║
     ├─ fn ────>│          ║     │                │       ║
     │          ├─ ipe_entry ──>─┤                │       ║
     │          │          ║     ├─ fn_internal ─>│       ║
     │          │          ║     │                │ ...   ║
     │          │          ║     │<─ ocall_cb_fn ─┤       ║
     │          │<─ ocall_stub ──┤                │       ║
     │<─ cb_fn ─┤          ║     │                │       ║
 ... │          │          ║     │                │       ║
     ├── ret ──>│          ║     │                │       ║
     │          ├─ ipe_entry ──>─┤                │       ║
     │          │          ║     ├─ ocall ret ───>│       ║
     │          │          ║     │                │ ...   ║
     │          │          ║     │<─── ecall ret ─┤       ║
     │          │<─ ecall ret ───┤                │       ║
     │<─ ret ───┤          ║                              ║
     │          │          ╚══════════════════════════════╝
```

**Ecalls (untrusted->IPE)** route through the single hardware entry point `ipe_entry`, which initializes secure registers and stack, before dispatching to `fn_internal()`.

**Ocalls (IPE->untrusted)** use a generated trampoline `ocall_cb_fn()` that lives _inside_ the IPE region: it saves and clears secret registers, calls the untrusted `cb_fn()`, and the untrusted return re-enters IPE via `ipe_entry` to restore trusted registers before resuming.

## Extending the codebase

The following is a non-exhaustive list of the most important directories and files that are relevant for the memory isolation implementation and the security evaluation.

- [`core/rtl/verilog`](core/rtl/verilog): contains the source files for the HDL implementation. Newly introduced files or files with notable changes are `periph/ipe_periph.v`, `omsp_frontend.v`, `omsp_mem_backbone.v`, `openMSP430.v`.
- [`core/sim/rtl_sim/bin/ipe_linker.x`](core/sim/rtl_sim/bin/ipe_linker.x): linker script used for IPE support.
- [`core/sim/rtl_sim/bin/ipe_macros.asm`](core/sim/rtl_sim/bin/ipe_macros.asm): utility scripts for the software development framework.
- [`core/sim/rtl_sim/run/run_ipe`](core/sim/rtl_sim/run/run_ipe): script to run IPE unit tests.
- [`core/sim/rtl_sim/src-c/framework`](core/sim/rtl_sim/src-c/framework): our software framework adapted from IPE Exposure.
- [`core/sim/rtl_sim/src-c/ipe-hello`](core/sim/rtl_sim/src-c/ipe-hello): IPE hello world project in C.
- [`core/sim/rtl_sim/src-c/ipe-hmac`](core/sim/rtl_sim/src-c/ipe-hmac): software attestation case study.


### Making firmware modifications

One of the most important features of openIPE is the extensible firmware.
You can find the firmware implementing the IPE bootcode in [`core/sim/rtl_sim/src/ipe/bootcode.s43`](core/sim/rtl_sim/src/ipe/bootcode.s43), and the version extended to implement the FW-IRQ secure interrupt scheme in [`core/sim/rtl_sim/src/ipe/bootcode-fw-irq.s43`](core/sim/rtl_sim/src/ipe/bootcode-fw-irq.s43).
In the [IPE unit test file](core/sim/rtl_sim/run/run_ipe) we added additional options to switch between different firmware implementations.
Finally, the [openIPE linker script](core/sim/rtl_sim/bin/ipe_linker.x) and the [assembly macros](core/sim/rtl_sim/bin/ipe_macros.asm) contain useful options for firmware modifications.

## Support

In case of suggestions or questions, please open a pull request or an issue!

## License

openIPE is based on the excellent [openMSP430](https://github.com/olgirard/openmsp430) core and is released under a BSD-3-Clause license.

#!/usr/bin/python3
import sys
import os
import re
import subprocess
from elftools.elf.elffile import ELFFile

CFLAGS = '-Wall -std=gnu99 -g -mcpu=430 -mmpy=none -D__MSP430F149__'

def patch_relocs(fn):
    elf_relocations = []

    with open(fn, 'rb') as f:
        elf_file = ELFFile(f)

        for section in elf_file.iter_sections():
            if not re.match(r'.rela.ipe_(func|entry)', section.name):
                continue
            print(f'.. processing section <{section.name}>')

            symtab = elf_file.get_section(section['sh_link'])
            for n in range(section.num_relocations()):
                rel = section.get_relocation(n)
                sym = symtab.get_symbol(rel['r_info_sym'])

                # Intercept unprotected arithmetic function calls
                # inserted by the compiler back-end; see also:
                # https://gcc.gnu.org/onlinedocs/gccint/Integer-library-routines.html
                if re.match(r'(memset|__(u|)(ashl|ashr|lshr|mul|div|mod)(q|h|s|d|t)i.*)', sym.name):
                    print(f'\tL__ intercepting relocation {sym.name}')
                    rel_offset = section['sh_offset'] + n * section['sh_entsize']
                    elf_relocations.append((rel_offset, sym.name))

    print(f".. applying relocation patches to '{fn}'")
    with open(fn, 'r+b') as f:
        elf_file = ELFFile(f)
        symtab = elf_file.get_section_by_name('.symtab')
        for (rel_offset, sym_name) in elf_relocations:
            ipe_sym_name = '__ipe_' + sym_name

            # get symbol table index of added symbol
            for sym_idx in range(symtab.num_symbols()):
                if symtab.get_symbol(sym_idx).name == ipe_sym_name:
                    break
            if (symtab.get_symbol(sym_idx).name != ipe_sym_name):
                print(f"\tL__ WARNING: '{ipe_sym_name:22}' not defined; skipping..")
                continue

            # overwrite symbol table index in targeted relocation
            # skip r_offset and patch r_info 3 bytes (litte endian; lower byte
            # stores relocation type)
            # https://wiki.osdev.org/ELF_Tutorial#Relocation_Sections
            print(f"\tL__ patching relocation  for symbol '{sym_name:22}'@{rel_offset} -> '{ipe_sym_name:27}'@{sym_idx}")
            f.seek(rel_offset+5)
            f.write(sym_idx.to_bytes(3, byteorder='little'))

def process_filename(filename):
    print(f'processing relocations in: {filename}')
    patch_relocs(filename)

def run_cmd(cmdline):
    cmdline = " ".join(cmdline)
    print(f'running: {cmdline}')
    c = subprocess.run("pwd; " + cmdline, shell=True, capture_output=True, text=True)
    print(c.stdout, end='')
    print(c.stderr, end='')
    return c.returncode

def main():
    # Extract non-option arguments (filenames) and call our custom relocation patcher
    filenames = [arg for arg in sys.argv[1:] if arg.endswith('.o') and not arg.startswith('-')]
    for filename in filenames:
        process_filename(filename)

    # Find all C/asm files in libipe
    libipe = os.path.dirname(sys.argv[0]) + '/libipe'
    libipe_files = []
    for root, _, files in os.walk(libipe):
        for filename in files:
            if any(filename.endswith(ext) for ext in ['.s', '.asm', '.c']) and not root.endswith("templates") and not "irq" in filename:
                libipe_files.append(os.path.join(root, filename))

    # Compile libipe objects and add them to the linker cmdline
    cc = 'msp430-gcc'
    linker_args = [cc] + sys.argv[1:]
    compiler_args = [cc] + CFLAGS.split(' ')
    #compiler_args = [a for a in compiler_args if not any(re.match(r, a) for r in ld_only_opts)]
    for f in libipe_files:
        rv = run_cmd(compiler_args + ['-c', f])
        if rv != 0:
            print(f'fatal: compiler returned non-zero return value: {rv}')
            sys.exit(rv)
        # insert after the last obj file in the linker cmdline
        objfile = os.path.splitext(os.path.basename(f))[0] + '.o'
        last_obj_idx = max(idx for idx, val in enumerate(linker_args) if val.endswith('.o'))
        linker_args.insert(last_obj_idx + 1, objfile)

    # Finally link everything together with the default MSP430 linker
    sys.exit(run_cmd(linker_args))

if __name__ == '__main__':
    main()

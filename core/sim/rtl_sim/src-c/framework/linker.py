#!/usr/bin/env python3
import sys
from pathlib import Path
import re
import json
import string
import tempfile
import atexit
from itertools import chain

from elftools.elf.elffile import ELFFile
from elftools.elf.sections import SymbolTableSection

from jinja2 import Template
from common import *

CC = "msp430-elf-gcc"
FLAGS = ['-mmcu=msp430f149', '-mhwmult=none']

# Default memory sizes (bytes) — must match openMSP430_defines.v
PMEM_SIZE_DEFAULT = 41984
DMEM_SIZE_DEFAULT = 10240
BMEM_SIZE_DEFAULT = 1024
PER_SIZE_DEFAULT  = 4096


def _parse_size(s):
    s = s.strip()
    if s.upper().endswith('K'):
        return int(s[:-1]) * 1024
    return int(s, 0)


def _make_linker_script(template_path, pmem_size, dmem_size, bmem_size, per_size):
    pmem_base            = 0x10000 - pmem_size
    bmem_base            = per_size + dmem_size
    bmem_ivt_base        = bmem_base + bmem_size - 0x24
    bmem_trampoline_base = bmem_base + bmem_size - 0x4
    with open(template_path) as f:
        tmpl = string.Template(f.read())
    content = tmpl.safe_substitute(
        per_size=per_size,
        dmem_size=dmem_size,
        pmem_base=pmem_base,
        pmem_size=pmem_size,
        bmem_base=bmem_base,
        bmem_total_size=bmem_size,
        bmem_ivt_base=bmem_ivt_base,
        bmem_trampoline_base=bmem_trampoline_base,
    )
    tmp = tempfile.NamedTemporaryFile(mode='w', suffix='.x', delete=False,
                                      prefix='ipe_linker_')
    tmp.write(content)
    tmp.close()
    atexit.register(lambda p: Path(p).unlink(missing_ok=True), tmp.name)
    return tmp.name


def get_libipe_path(subpath):
    return Path(sys.argv[0]).resolve().parent / 'libipe' / subpath


def retrieve_stubs_entries(files):
    dic_stubs_entries = {
        'entries': [],
        'stubs': [],

        'entries_names': [],
        'stubs_names': []
    }   

    for filename in files: 
        with open(filename, 'rb') as f:
            elf_file = ELFFile(f)
            for section in elf_file.iter_sections():
                if isinstance(section, SymbolTableSection):
                    for symbol in section.iter_symbols():
                        if symbol.name.startswith("__ipe_ocall_"):
                            funcName = symbol.name.removeprefix("__ipe_ocall_")
                            value = int(symbol.entry['st_value'])
                            if funcName not in dic_stubs_entries['stubs_names']:
                                dic_stubs_entries['stubs_names'].append(funcName)
                                dic_stubs_entries['stubs'].append({
                                    'function': funcName,
                                    'name': funcName + "_stub",
                                    'bitmap': f'{value:08b}',
                                })
                                info(f"ocall found: {dic_stubs_entries['stubs'][-1]}")

                        elif symbol.name.startswith("__ipe_ecall_"):
                            entry_name = symbol.name.removeprefix("__ipe_ecall_")
                            if entry_name not in dic_stubs_entries['entries_names']:
                                dic_stubs_entries['entries_names'].append(entry_name)
                                dic_stubs_entries['entries'].append({
                                    'internal_name': entry_name + '_internal',
                                    'external_name': entry_name,
                                    'index': len(dic_stubs_entries['entries']),
                                    'bitmap': hex(symbol.entry['st_value']),
                                })
                                info(f"ecall found: {dic_stubs_entries['entries'][-1]}")
    return dic_stubs_entries

def main():
    # Strip --pmem/dmem/bmem/per-size args before passing anything to gcc
    pmem_size = PMEM_SIZE_DEFAULT
    dmem_size = DMEM_SIZE_DEFAULT
    bmem_size = BMEM_SIZE_DEFAULT
    per_size  = PER_SIZE_DEFAULT
    raw_args  = sys.argv[1:]
    filtered  = []
    i = 0
    while i < len(raw_args):
        if raw_args[i] == '--pmem-size':
            pmem_size = _parse_size(raw_args[i + 1]); i += 2
        elif raw_args[i] == '--dmem-size':
            dmem_size = _parse_size(raw_args[i + 1]); i += 2
        elif raw_args[i] == '--bmem-size':
            bmem_size = _parse_size(raw_args[i + 1]); i += 2
        elif raw_args[i] == '--per-size':
            per_size  = _parse_size(raw_args[i + 1]); i += 2
        else:
            filtered.append(raw_args[i]); i += 1

    # If -T points to a template (contains $pmem_base placeholder), process it
    for j, arg in enumerate(filtered):
        if arg == '-T' and j + 1 < len(filtered):
            try:
                with open(filtered[j + 1]) as f:
                    content = f.read()
                if '$pmem_base' in content:
                    filtered[j + 1] = _make_linker_script(
                        filtered[j + 1], pmem_size, dmem_size, bmem_size, per_size)
            except OSError:
                pass
            break

    # Extract non-option arguments (filenames)
    filenames = [arg for arg in filtered if arg.endswith('.o') and not arg.startswith('-')]

    default_config = {
        'entry_stub': 'ipe-protected.s'
    }
    try:
        with open("config.json") as config_json:
            config = json.load(config_json)
            for k in config:
                default_config[k] = config[k]
    except FileNotFoundError:
        pass
    info(f'Config used: {default_config}')

    files_to_compile = [get_libipe_path('stubs/' + default_config['entry_stub'])]
    files_to_compile.append(get_libipe_path('stubs/ipe-libc.c'))


    # write generated table file
    dic_stubs_entries = retrieve_stubs_entries(filenames)
    files_to_compile.append(Path(get_tmp(suffix='.s', prefix='generated_table_')))
    with open(get_libipe_path('templates/generated_table.s')) as file:
        table_template = Template(file.read())
        table_obj = {
            'max_entry_index': len(dic_stubs_entries['entries']) - 1,
            'entry_functions': dic_stubs_entries['entries'],
        }
        with open(files_to_compile[-1], "w") as target_file:
            target_file.write(table_template.render(table_obj))


    # write generated stubs
    files_to_compile.append(Path(get_tmp(suffix='.s', prefix='generated_stubs_')))
    with open(get_libipe_path('templates/generated_stubs.s')) as file:
        stubs_template = Template(file.read())
        stubs_obj = {
            'stubs_to_unprotected': dic_stubs_entries['stubs'],
            'stubs_to_protected': dic_stubs_entries['entries'],
        }
        with open(files_to_compile[-1], "w") as target_file:
            target_file.write(stubs_template.render(stubs_obj))


    additional_files_to_link = []
    for file in files_to_compile:
        out = get_tmp(suffix='.o',prefix=file.stem)
        additional_files_to_link.append(out)
        call_prog(CC, FLAGS + ['-c', str(file), '-o', additional_files_to_link[-1]])


    linker_args = filtered
    for object_name in additional_files_to_link:
        last_obj_idx = max(idx for idx, val in enumerate(linker_args) if val.endswith('.o'))
        linker_args.insert(last_obj_idx + 1, object_name)

    call_prog(CC, linker_args)


if __name__ == '__main__':
    main()

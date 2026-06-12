#!/usr/bin/env python3
import argparse
from pathlib import Path
import re
import json

from elftools.elf.elffile import ELFFile
from elftools.elf.sections import SymbolTableSection

from jinja2 import Template
from common import *

CC = "msp430-elf-gcc"
FLAGS = ['-mmcu=msp430f149', '-mhwmult=none']

# Valid memory sizes — must match openMSP430_defines.v
PMEM_SIZES = ['1K', '2K', '4K', '8K', '12K', '16K', '24K', '32K',
              '41K', '48K', '51K', '54K', '55K']
DMEM_SIZES = ['128', '256', '512', '1K', '2K', '4K', '5K',
              '8K', '10K', '16K', '24K', '32K']

# Fixed hardware constants — not configurable
BMEM_SIZE = 1024
PER_SIZE  = 4096

def _parse_size(s):
    s = s.strip()
    if s.upper().endswith('K'):
        return int(s[:-1]) * 1024
    try:
        return int(s, 0)
    except ValueError:
        raise argparse.ArgumentTypeError(f'invalid size: {s!r}')


def _write_linker_script(pmem_size, dmem_size):
    pmem_base            = 0x10000 - pmem_size
    bmem_base            = PER_SIZE + dmem_size
    bmem_ivt_base        = bmem_base + BMEM_SIZE - 0x24
    bmem_trampoline_base = bmem_base + BMEM_SIZE - 0x4
    preamble = (
        f"PMEM_BASE = {pmem_base};\n"
        f"PMEM_SIZE = {pmem_size};\n"
        f"DMEM_SIZE = {dmem_size};\n"
        f"PER_SIZE = {PER_SIZE};\n"
        f"BMEM_BASE = {bmem_base};\n"
        f"BMEM_TOTAL_SIZE = {BMEM_SIZE};\n"
        f"BMEM_IVT_BASE = {bmem_ivt_base};\n"
        f"BMEM_TRAMPOLINE_BASE = {bmem_trampoline_base};\n"
    )
    linker_x = get_libipe_path('../../../bin/ipe_linker.x')
    path = get_tmp(suffix='.x', prefix='pmem_')
    with open(path, 'w') as f:
        f.write(preamble + linker_x.read_text())
    return path


def get_libipe_path(subpath):
    return Path(__file__).resolve().parent / 'libipe' / subpath


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
    parser = argparse.ArgumentParser(description='openIPE linker')
    parser.add_argument('--pmem-size', choices=PMEM_SIZES, default='41K',
                        metavar='SIZE', help='Program memory size (default: %(default)s)')
    parser.add_argument('--dmem-size', choices=DMEM_SIZES, default='10K',
                        metavar='SIZE', help='Data memory size (default: %(default)s)')
    parser.add_argument('--config', type=Path, default=None,
                        metavar='FILE', help='Config JSON file (default: config.json if present)')

    args, cli_ld_args = parser.parse_known_args()

    pmem_x = _write_linker_script(_parse_size(args.pmem_size), _parse_size(args.dmem_size))
    cli_ld_args = [pmem_x if a == 'pmem.x' else a for a in cli_ld_args]

    filenames = [arg for arg in cli_ld_args if arg.endswith('.o') and not arg.startswith('-')]

    config_path = args.config if args.config is not None else Path('config.json')
    if args.config is not None and not config_path.exists():
        parser.error(f'config file not found: {config_path}')

    default_config = {'entry_stub': 'ipe-protected.s'}
    if config_path.exists():
        default_config.update(json.loads(config_path.read_text()))
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
        out = get_tmp(suffix='.o', prefix=file.stem)
        additional_files_to_link.append(out)
        call_prog(CC, FLAGS + ['-c', str(file), '-o', additional_files_to_link[-1]])

    linker_args = cli_ld_args
    for object_name in additional_files_to_link:
        last_obj_idx = max(idx for idx, val in enumerate(linker_args) if val.endswith('.o'))
        linker_args.insert(last_obj_idx + 1, object_name)

    call_prog(CC, linker_args)


if __name__ == '__main__':
    main()

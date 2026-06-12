#!/usr/bin/env python3
import sys
from pathlib import Path
import re
import json
from itertools import chain

from elftools.elf.elffile import ELFFile
from elftools.elf.sections import SymbolTableSection

from jinja2 import Template
from common import *

CC = "msp430-elf-gcc"
FLAGS = ['-mmcu=msp430f149', '-mhwmult=none']


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
    # Extract non-option arguments (filenames)
    filenames = [arg for arg in sys.argv[1:] if arg.endswith('.o') and not arg.startswith('-')]
    
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


    linker_args = sys.argv[1:]
    for object_name  in additional_files_to_link:
        last_obj_idx = max(idx for idx, val in enumerate(linker_args) if val.endswith('.o'))
        linker_args.insert(last_obj_idx + 1, object_name)


    call_prog(CC, linker_args)


if __name__ == '__main__':
    main()

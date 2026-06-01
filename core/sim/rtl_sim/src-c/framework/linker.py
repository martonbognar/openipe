#!/usr/bin/python3
import sys
import os
import re
import subprocess
import json

from elftools.elf.elffile import ELFFile
from elftools.elf.sections import SymbolTableSection


from jinja2 import Template
from common import *


CFLAGS = '-Wall -std=gnu99 -g -mcpu=430 -mmpy=none -D__MSP430F149__'


def add_sym(file, sym_map):
    args = []

    for sym, sect in sym_map.items():
        args += ['--add-symbol', f'{sym}={sect}:0,weak']

    args += [file, file]
    call_prog('msp430-elf-objcopy', args)
    return file


def is_section_in_file(fn, section_name):
    with open(fn, 'rb') as f:
        elf_file = ELFFile(f)
        return elf_file.get_section_by_name(section_name)
    

def create_empty_section(fn, section_name):
    nf = get_tmp(suffix='.bin')
    call_prog('msp430-elf-objcopy', ['--add-section', f'{section_name}={nf}', fn, fn])



def get_elf_relocations(fn):
    elf_relocations = []

    with open(fn, 'rb') as f:
        elf_file = ELFFile(f)

        for section in elf_file.iter_sections():
            if not re.match(r'.rela.ipe_(func|entry)', section.name):
                continue
            info(f'.. processing section <{section.name}>')

            symtab = elf_file.get_section(section['sh_link'])
            for n in range(section.num_relocations()):
                rel = section.get_relocation(n)
                sym = symtab.get_symbol(rel['r_info_sym'])

                # Intercept unprotected arithmetic function calls
                # inserted by the compiler back-end; see also:
                # https://gcc.gnu.org/onlinedocs/gccint/Integer-library-routines.html
                if re.match(r'(memset|__(u|)(ashl|ashr|lshr|mul|div|mod)(q|h|s|d|t)i.*)', sym.name):
                    info(f'\tL__ intercepting relocation {sym.name}')
                    rel_offset = section['sh_offset'] + n * section['sh_entsize']
                    elf_relocations.append((rel_offset, sym.name))

    return elf_relocations

def get_arith_subs():
    stubs_file = os.path.abspath(os.path.dirname(sys.argv[0]) + '/libipe/arithmetic_stubs/')
    return [os.path.join(root, file) for root, _, files in os.walk(stubs_file) for file in files if file.endswith('.s')]


def patch_relocs(fn):
    elf_relocations = get_elf_relocations(fn)
    sym_map = {'__ipe_' + sym_name : '.ipe_func' for (_, sym_name) in elf_relocations}
    
    if not is_section_in_file(fn, '.ipe_func'):
        info("Section .ipe_func can't be found. Going to create an empty!")
        create_empty_section(fn, '.ipe_func')

    add_sym(fn, sym_map)

    # add_sym modified offsets
    elf_relocations = get_elf_relocations(fn)

    info(f".. applying relocation patches to '{fn}'")
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
                info(f"\tL__ WARNING: '{ipe_sym_name:22}' not defined; skipping..")
                continue

            # overwrite symbol table index in targeted relocation
            # skip r_offset and patch r_info 3 bytes (litte endian; lower byte
            # stores relocation type)
            # https://wiki.osdev.org/ELF_Tutorial#Relocation_Sections
            info(f"\tL__ patching relocation  for symbol '{sym_name:22}'@{rel_offset} -> '{ipe_sym_name:27}'@{sym_idx}")
            f.seek(rel_offset+5)
            f.write(sym_idx.to_bytes(3, byteorder='little'))

    return len(elf_relocations)


def process_filename(filename):
    info(f'processing relocations in: {filename}')
    return patch_relocs(filename)


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
                                dic_stubs_entries['stubs_names'].append(entry_name)
                                dic_stubs_entries['entries'].append({
                                    'internal_name': entry_name + '_internal',
                                    'external_name': entry_name,
                                    'index': len(dic_stubs_entries['entries']),
                                    'bitmap': hex(symbol.entry['st_value']),
                                })
                                info(f"ecall found: {dic_stubs_entries['entries'][-1]}")
    return dic_stubs_entries


def main():
    # Extract non-option arguments (filenames) and call our custom relocation patcher
    filenames = [arg for arg in sys.argv[1:] if arg.endswith('.o') and not arg.startswith('-')]
    
    additional_files_to_link = []
    files_to_compile = get_arith_subs() if sum([process_filename(filename) for filename in filenames]) > 0 else []
    print(files_to_compile)

    dic_stubs_entries = retrieve_stubs_entries(filenames)


    # write generated table file
    files_to_compile.append(get_tmp(suffix='.s'))
    with open(os.path.abspath(os.path.dirname(sys.argv[0]) + '/libipe/templates/generated_table.s')) as file:
        table_template = Template(file.read())
        table_obj = {
            'max_entry_index': len(dic_stubs_entries['entries']) - 1,
            'entry_functions': dic_stubs_entries['entries'],
        }
        with open(files_to_compile[-1], "w") as target_file:
            target_file.write(table_template.render(table_obj))


    # write generated stubs
    files_to_compile.append(get_tmp(suffix='.s'))
    with open(os.path.abspath(os.path.dirname(sys.argv[0]) + '/libipe/templates/generated_stubs.s')) as file:
        stubs_template = Template(file.read())
        stubs_obj = {
            'stubs_to_unprotected': dic_stubs_entries['stubs'],
            'stubs_to_protected': dic_stubs_entries['entries'],
        }
        with open(files_to_compile[-1], "w") as target_file:
            target_file.write(stubs_template.render(stubs_obj))

    
    for file in files_to_compile:
        file_name = file.removesuffix('.s')
        additional_files_to_link.append(f'{file_name}.o')

        call_prog("msp430-gcc", ['-c', file, '-o', additional_files_to_link[-1]])


    default_config = {
        'entry_stub': 'ipe-protected.s'
    }
    try:
        with open("config.json") as config_json:
            config = json.load(config_json)
            for k in config:
                default_config[k] = config[k]
    except FileNotFoundError:
        info("Config found cannot be found!")

    info(f'Config used: {default_config}')

    additional_files_to_link.append(get_tmp(suffix='.o'))
    entry_stub_file = os.path.abspath(os.path.join(os.path.dirname(sys.argv[0]) + '/libipe/stubs/', default_config['entry_stub']))
    call_prog("msp430-gcc", ['-c', entry_stub_file, '-o', additional_files_to_link[-1]])


    linker_args = sys.argv[1:]
    for object_name  in additional_files_to_link:
        last_obj_idx = max(idx for idx, val in enumerate(linker_args) if val.endswith('.o'))
        linker_args.insert(last_obj_idx + 1, object_name)


    call_prog("msp430-gcc", linker_args)


if __name__ == '__main__':
    main()
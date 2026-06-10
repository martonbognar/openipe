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


# objcopy only allows adding symbols with a defined value; thus manually
# patch up the newly added symbol in the symbol table to make it an
# undefined (external) symbol, such that the linker throws an error if
# it is not found in the std libraries later
def add_sym(file, sym_map):
    args = []

    for sym, sect in sym_map.items():
        args += ['--add-symbol', f'{sym}={sect}:0,global']

    args += [file, file]
    call_prog('msp430-elf-objcopy', args)

    with open(file, 'r+b') as f:
        elf_file = ELFFile(f)
        symtab = elf_file.get_section_by_name('.symtab')

        for idx in range(symtab.num_symbols()):
            sym = symtab.get_symbol(idx)
            if sym.name in sym_map.keys():
                entry_off = symtab['sh_offset'] + idx * symtab['sh_entsize']
                assert symtab['sh_entsize'] == 16
                f.seek(entry_off + 14)
                f.write((0).to_bytes(2, byteorder='little')) # SHN_UNDEF


def is_section_in_file(fn, section_name):
    with open(fn, 'rb') as f:
        elf_file = ELFFile(f)
        return elf_file.get_section_by_name(section_name)
    

def create_empty_section(fn, section_name):
    info(f"creating empty section '{section_name}'...")
    nf = get_tmp(suffix='.bin', prefix='empty_')
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
                # inserted by the compiler back-end
                if re.match(r'memset|__mspabi_.*',sym.name):
                    rel_offset = n * section['sh_entsize']
                    elf_relocations.append((rel_offset, sym.name, section.name))

    return elf_relocations

def patch_relocs(fn):
    elf_relocations = get_elf_relocations(fn)
    sym_map = {'__ipe' + sym_name : '.ipe_func' for (_, sym_name, _) in elf_relocations}
    
    if not is_section_in_file(fn, '.ipe_func') and len(elf_relocations) > 0:
        create_empty_section(fn, '.ipe_func')

    add_sym(fn, sym_map)
    
    info(f".. applying relocation patches to '{fn}'")
    with open(fn, 'r+b') as f:
        elf_file = ELFFile(f)
        symtab = elf_file.get_section_by_name('.symtab')
        for (rela_offset, sym_name, rela_sect_name) in elf_relocations:
            ipe_sym_name = '__ipe' + sym_name

            # get symbol table index of added symbol
            for sym_idx in range(symtab.num_symbols()):
                if symtab.get_symbol(sym_idx).name == ipe_sym_name:
                    break
            if (symtab.get_symbol(sym_idx).name != ipe_sym_name):
                warning(f"\tL__ '{ipe_sym_name:22}' not defined; skipping..")
                continue

            # re-calculate relocation offset (file has changed after add_sym)
            rela_sect = elf_file.get_section_by_name(rela_sect_name)
            offset = rela_sect['sh_offset'] + rela_offset

            # overwrite symbol table index in targeted relocation
            # skip r_offset and patch r_info 3 bytes (litte endian; lower byte
            # stores relocation type)
            # https://wiki.osdev.org/ELF_Tutorial#Relocation_Sections
            info(f"\tL__ patching relocation  for symbol '{sym_name:22}'@{offset} -> '{ipe_sym_name:27}'@{sym_idx}")
            f.seek(offset+5)
            f.write(sym_idx.to_bytes(3, byteorder='little'))


def process_filename(filename):
    info(f'processing relocations in: {filename}')
    patch_relocs(filename)


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
    # Extract non-option arguments (filenames) and call our custom relocation patcher
    filenames = [arg for arg in sys.argv[1:] if arg.endswith('.o') and not arg.startswith('-')]
    for f in filenames:
        process_filename(f)
    
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

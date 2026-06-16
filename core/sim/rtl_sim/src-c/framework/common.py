import subprocess
import tempfile
import os
import sys
import shutil
import atexit

import colorama

import logging
from logging import debug, info, warning, error
logging.basicConfig(format=f'%(levelname)s: %(message)s',level=logging.INFO)

from elftools.elf.elffile import ELFFile


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


def rm(*files):
    for f in files:
        try:
            if os.path.isdir(f):
                shutil.rmtree(f)
            else:
                os.remove(f)
        except:
            pass

tmp_files = []


def get_tmp(suffix='', prefix=''):
    tmp = tempfile.mkstemp(suffix, prefix)[1]
    tmp_files.append(tmp)
    return tmp


def get_tmp_dir():
    tmp = tempfile.mkdtemp()
    tmp_files.append(tmp)
    return tmp


@atexit.register
def cleanup():
    if tmp_files:
        info('Cleaning up temporary files: ' + ', '.join(tmp_files))
        rm(*tmp_files)
        del tmp_files[:]

def call_prog(prog, arguments=[], get_output=False):
    cmd = [prog] + arguments
    info(' '.join(cmd))

    try:
        if get_output:
            return subprocess.check_output(cmd)
        else:
            subprocess.check_call(cmd)
    except OSError as e:
        if e.errno == os.errno.ENOENT:
            fatal_error('{} is not in your PATH'.format(prog))
        else:
            fatal_error('Error running {}: {}'.format(prog, e))
    except subprocess.CalledProcessError:
        fatal_error(f'Command {prog} failed')

def fatal_error(msg):
    error(colorama.Style.BRIGHT + colorama.Fore.RED + msg + colorama.Style.RESET_ALL)
    info(f'leaving temporary files: {tmp_files}')
    atexit.unregister(cleanup)
    sys.exit(1)

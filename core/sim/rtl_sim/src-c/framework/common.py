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


def get_tmp(suffix=''):
    tmp = tempfile.mkstemp(suffix)[1]
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

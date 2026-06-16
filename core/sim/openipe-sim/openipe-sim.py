#!/usr/bin/env python3

import argparse
import os
import errno
import subprocess
import colorama
import sys
import json

from logging import debug, info, warning, error, fatal
from pathlib import Path


def check_compatibility(firmware, stub):
    existing_firmwares = {
        'bootcode': 0, 
        'bootcode-fw-irq': 1, 
        'bootcode-clean-irq': 2,
    }
    existing_stubs = {
        'ipe-protected': 0,
        'ipe-protected-sw-irq': 1,
        'ipe-protected-irq': 2,
        'ipe-protected-fw-irq': 3,
        'ipe-protected-clean-irq': 4,
    }

    # Use compatibility[stub][bootcode]
    compatibility = [
        [True, False, False],
        [False, False, False], # No appropriate bootcode
        [False, True, True],
        [False, True, False],
        [False, False, True]
    ]
    return compatibility[existing_stubs[stub]][existing_firmwares[firmware]]


def call_prog(prog, arguments=[], get_output=False):
    cmd = [prog] + arguments
    info(' '.join(cmd))

    try:
        if get_output:
            return subprocess.check_output(cmd)
        else:
            subprocess.check_call(cmd)
    except OSError as e:
        if e.errno == errno.ENOENT:
            fatal_error('{} is not in your PATH'.format(prog))
        else:
            fatal_error('Error running {}: {}'.format(prog, e))
    except subprocess.CalledProcessError:
        fatal_error(f'Command {prog} failed')


def fatal_error(msg):
    error(colorama.Style.BRIGHT + colorama.Fore.RED + msg + colorama.Style.RESET_ALL)
    sys.exit(1)


def get_parser():
    parser = argparse.ArgumentParser(description='openIPE simulation manager')
    parser.add_argument(
        '--firmware',
        '-f',
        dest='firmware',
        default='bootcode',
        help='Select bootcode to choose',
    )
    parser.add_argument(
        '--entry-stub',
        '-e',
        dest='entry_stub',
        default='ipe-protected.s',
        help='Select which entrycode to use',
    )
    parser.add_argument(
        '--config-file',
        '-c',
        dest='config_file',
        default='config.json',
        help='Select a configuration file to use',
    )
    parser.add_argument(
        '--only-build',
        '-o',
        dest='only_build',
        type=bool,
        default=False,
        help='Put true if you only want the binary without running it'
    )
    parser.add_argument(
        '--name',
        '-n',
        dest='project_name',
        help='Project name (default will be folder name)'
    )
    parser.add_argument(
        '--omit-ipe-fixes',
        dest='omit_ipe_fixes',
        type=int,
        default=0,
    )
    parser.add_argument(
        '--ipe-irq-sw',
        dest='ipe_irq_sw',
        type=int,
        default=0,
    )
    parser.add_argument(
        '--ipe-irq-fw',
        dest='ipe_irq_fw',
        type=int,
        default=0,
    )
    parser.add_argument(
        '--omit-sp-switching',
        dest='omit_sp_switching',
        type=int,
        default=0,
    )

    parser.add_argument(
        'project_folder',
    )

    return parser



if __name__ == '__main__':
    parser = get_parser()
    args, _ = parser.parse_known_args()
    args = vars(args)

    c_runner_path = Path(os.path.dirname(__file__) + '/../rtl_sim/run')
    if not c_runner_path.exists():
        fatal_error(f"Could not find openIPE run_c at {c_runner_path}")
    project_path = Path(args['project_folder']).absolute()
    if not project_path.exists():
        fatal_error(f"Project path {project_path} does not exists")

    found_config = False
    try:
        with open(f'{project_path.absolute()}/{args['config_file']}', 'r') as config_json:
            info("Config file found!")
            warning("Config file may override parameters values")
            found_config = True
            config = json.load(config_json)
            for k in config:
                args[k] = config[k]
    except FileNotFoundError:
        pass

    if int(args['omit_ipe_fixes']) == 1:
        os.environ['__OMIT_IPE_FIXES'] = "1"
    if int(args['omit_sp_switching']) == 1:
        os.environ['__OMIT_SP_SWITCHING'] = "1"
    if int(args['ipe_irq_sw']) == 1:
        os.environ['__IPE_IRQ_SW'] = "1"
    if int(args['ipe_irq_fw']) == 1:
        os.environ['__IPE_IRQ_FW'] = "1"

    dic_config = {
        'firmware': args['firmware'],
        'entry_stub': args['entry_stub'],
        'simulation': "0" if args['only_build'] else "1",
    }

    if not check_compatibility(dic_config['firmware'], dic_config['entry_stub'].removesuffix('.s')):
        fatal_error(f'Firmware {dic_config['firmware']} and entry stub {dic_config['entry_stub']} cannot be used together')

    if not found_config:
        with open(f'{project_path.absolute()}/{args['config_file']}', "w") as config:
            config.write(json.dumps(dic_config))

    # The project should have the same name as the folder he's inside of
    project_name = os.path.basename(project_path.absolute()) if not args['project_name'] else args['project_name']

    info("Going to run the builder")
    os.chdir(f'{c_runner_path}')
    call_prog(f'{c_runner_path}/run_c', [f'{project_path}', f'{project_name}'])

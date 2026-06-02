#!/usr/bin/python3

from common import *
import copy
import os
import sys
import argparse

from pycparser import c_ast
from pycparserext import ext_c_parser
from pycparserext.ext_c_generator import GnuCGenerator

from jinja2 import Template

# converts number into bitmap
def make_bitmap(registers_used):
    if registers_used == 0:
        return "00000000"
    if registers_used == 1:
        return "00001000"
    if registers_used == 2:
        return "00001100"
    if registers_used == 3:
        return "00001110"
    else:
        return "00001111"

# throw an exception if function uses stack passing
def break_if_stack_passing(funcDefExt, reg_used):
    funcName = funcDefExt.type.declname
    return_type = funcDefExt.type.type
    if isinstance(return_type, c_ast.Struct):  # 1 argument register used as pointer to struct
        if reg_used > 3:
            raise NotImplementedError("Stack passing in " + funcName)
    else:
        if reg_used > 4:
            raise NotImplementedError("Stack passing in " + funcName)

def make_declaration(funcDecl, suffix):
    decl_copy = copy.deepcopy(funcDecl)
    decl_copy.name += suffix
    decl_copy.type.type.declname += suffix
    # delete function attributes
    decl_copy.funcspec = []
    return decl_copy

def insert_ast_func_decl(ast, orig_decl, suffix=""):
    # include stub declaration in AST following original declaration
    # (to ensure any typedef dependencies are satisfied)
    for i, n in enumerate(ast.ext):
        if hasattr(n, 'decl'):
            n = n.decl
        if isinstance(n.type, ext_c_parser.FuncDeclExt):
            if n == orig_decl:
                stub = make_declaration(n, suffix=suffix)
                ast.ext.insert(i + 1, stub)
                return
    error(f"insert_ast_func_decl: declaration '{orig_decl.name}' not found in AST")

# return the number of registers used as argument to a function
class ArgumentRegCounter(c_ast.NodeVisitor):
    def __init__(self):
        self.reg_used = 0

    # returns the number of registers used as argument for the provided types of arguments
    @staticmethod
    def nb_reg_used(argTypes):
        nb_reg = 0
        # data sizes in MSPCompilerGuide p82 (for restricted data model) (enums not supported)
        for argType in argTypes:
            if argType in ["long long", "signed long long", "unsigned long long", "double", "long double"]:  # 64 bit == 4 reg
                nb_reg += 4
            elif argType in ["long", "signed long", "unsigned long", "float"]:  # 32 bit == 2 reg
                nb_reg += 2
            elif argType in ["void"]:
                nb_reg += 0
            else:
                nb_reg += 1
        return nb_reg

    def visit_Decl(self, node):
        arg_type = node.type
        if isinstance(arg_type, c_ast.PtrDecl):
            self.reg_used += 2  # for restricted data model
        else:
            self.reg_used += self.nb_reg_used(arg_type.type.names)

# for all entry functions in IPE:
#   change name of function
#   add to entry function table
#   write a unprotected stub with old name
class IPECollector(c_ast.NodeVisitor):
    def __init__(self, ast):
        self.index = 0
        self.ipe_functions = {}
        self.inline_functions = {}
        self.entry_functions = []
        self.entry_functions_names = []
        self.ast = ast

    def _check_attributes(self, decl, node=None):
        # check attributes for IPE annotations (see ipe.support.h), if IPE function then register function name
        function_name = decl.name
        for attributes_group in decl.funcspec:
            if attributes_group == "inline" or attributes_group == "__inline__":
                # if inlined function, we ignore it
                self.inline_functions[function_name] = node
                continue
            for attribute in attributes_group.exprlist.exprs:
                # attribute is a section attribute
                if isinstance(attribute, c_ast.FuncCall):
                    sectionName = attribute.args.exprs[0].value[1:-1]
                    if sectionName == ".ipe_entry":
                        self.ipe_functions[function_name] = node
                        internal_name = function_name + "_internal"
                        if (decl.type.args):
                            v = ArgumentRegCounter()
                            v.visit(decl.type.args)
                            break_if_stack_passing(decl.type, v.reg_used)
                        return_regs = ArgumentRegCounter.nb_reg_used(decl.type.type.type.names)
                        self.entry_functions.append({
                            'internal_name': internal_name,
                            'external_name': function_name,
                            'index': self.index,
                            'bitmap': hex(int(make_bitmap(return_regs), 2)),
                        })
                        self.entry_functions_names.append(function_name)
                        self.index += 1

                        # change declaration name not ecalls, because this way ecall from other file possible
                        insert_ast_func_decl(self.ast, decl, suffix="")
                        decl.type.type.declname = internal_name

                    if sectionName == ".ipe_func":
                        self.ipe_functions[function_name] = node
    
    def visit_Decl(self, node):
        if isinstance(node.type, ext_c_parser.FuncDeclExt):
            self._check_attributes(node)

    def visit_FuncDef(self, node):
        self._check_attributes(node.decl, node)

# register all ocalls in IPE function + redirect ocall to new stub
class OcallCollector(c_ast.NodeVisitor):
    def __init__(self, ipe_functions, inline_functions, ipe_entries_names):
        self.ipe_functions = ipe_functions
        self.inline_functions = inline_functions
        self.ipe_entries_names = ipe_entries_names
        self.ocall_functions = {}
        self.ocall_detected = False

    def visit_FuncCall(self, node):
        if (not hasattr(node.name, 'name')):
            return
        funcName = node.name.name
        # works because function declaration must proceed function call
        if funcName not in self.ipe_functions and funcName not in self.inline_functions and "__" not in funcName:
            self.ocall_detected = True
            self.ocall_functions[funcName] = node
            # change ocalls not declaration, because unprotected --> unprotected calls should not go through stub
            node.name.name += "_stub"
        if funcName in self.ipe_functions and funcName in self.ipe_entries_names:
            node.name.name += "_internal"

# for all ocalls in IPE:
#   write a protected stub
#   include declaration of new stub following existing declaration
class OcallStubCreator(c_ast.NodeVisitor):
    def __init__(self, ocall_functions, ast):
        self.ocall_functions = ocall_functions
        self.ast = ast
        self.stubs = []

    def visit_Decl(self, node):
        if isinstance(node.type, ext_c_parser.FuncDeclExt):
            if not isinstance(node.type.type, c_ast.TypeDecl):
                return
            funcName = node.type.type.declname
            if funcName in self.ocall_functions:
                if (node.type.args):
                    v = ArgumentRegCounter()
                    v.visit(node.type.args)
                    break_if_stack_passing(node.type, v.reg_used)
                    self.stubs.append({
                        'function': funcName,
                        'name': funcName + "_stub",
                        'bitmap': make_bitmap(v.reg_used),
                    })
                else:
                    self.stubs.append({
                        'function': funcName,
                        'name': funcName + "_stub",
                        'bitmap': make_bitmap(0),
                    })
                insert_ast_func_decl(self.ast, node, suffix="_stub")

###################################################################
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='openIPE compiler')
    parser.add_argument(
        '-o',
        dest='out_file',
        help='Place the output into file',
        metavar='file'
    )
    parser.add_argument('-c',
        dest='compile_only',
        help='Compile and assemble, but do not link',
        action='store_true'
    )

    args, _ = parser.parse_known_args()
    if not args.compile_only:
        fatal_error("Only supports modular compilation with -c")   
    elif not args.out_file:
        fatal_error("You need to provide an output file with -o")

    debug(f"openipe-cc {sys.argv[1:]}")

    # Run the input C file through the preprocessor
    file_name = next(
        os.path.splitext(os.path.basename(x))[0]
        for x in sys.argv
        if x.endswith(".o")
    )
    pp_file = get_tmp(suffix='.pp')
    
    pp_argv = [
        "-E" if x == "-c"
        else pp_file if x.endswith(".o")
        else x
        for x in sys.argv[1:]
    ]
    call_prog("msp430-gcc", pp_argv)

    # Now extract the AST from the preprocessed C file
    parser = ext_c_parser.GnuCParser()
    with open(pp_file, "r") as pf:
        src = pf.read()
    original_ast = parser.parse(src)

    # Redirect all untrusted->IPE calls (ecalls) through stub
    ipe_collector = IPECollector(original_ast)
    ipe_collector.visit(original_ast)
    info(f"Found ecalls: {[e['external_name'] for e in ipe_collector.entry_functions]}")

    # Redirect all IPE->untrusted calls (ocalls) through stub
    ocall_collector = OcallCollector(ipe_collector.ipe_functions, ipe_collector.inline_functions, ipe_collector.entry_functions_names)
    for ipe_fn in ipe_collector.ipe_functions.values():
        if ipe_fn:
            ocall_collector.ocall_detected = False
            ocall_collector.visit(ipe_fn)
    
    info(f"Found ocalls: {list(ocall_collector.ocall_functions.keys())}")
    ocall_stub_creator = OcallStubCreator(ocall_collector.ocall_functions, original_ast)
    ocall_stub_creator.visit(original_ast)

    # compile converted AST in new C file
    out_c = get_tmp(suffix='.c')
    with open(out_c, 'w') as newFile:
        for line in GnuCGenerator().visit(original_ast).splitlines():
            if "asm" in line:
                newFile.write(line + ";\n")
            else:
                newFile.write(line + "\n")

    new_args = sys.argv[1:].copy()
    new_args[new_args.index('-c') + 1] = out_c
    new_args[new_args.index('-o') + 1] = f'{file_name}.o'

    call_prog("msp430-gcc", new_args)

    # Store name + bitmap in .o file for later processing by linker
    # NOTE: the `--add-symbol` option is only available for GNU binutils > msp430-gcc;
    # thus rely on msp430-elf-objcopy from the TI GCC port.
    for ecall in ipe_collector.entry_functions:
        call_prog('msp430-elf-objcopy', ['--add-symbol',
                 f'__ipe_ecall_{ecall["external_name"]}={ecall["bitmap"]},weak', f'{file_name}.o'])
    for ocall in ocall_stub_creator.stubs:
        call_prog('msp430-elf-objcopy', ['--add-symbol',
                 f'__ipe_ocall_{ocall["function"]}={hex(int(ocall["bitmap"],2))},weak', f'{file_name}.o'])
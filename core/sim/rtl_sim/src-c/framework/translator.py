#!/usr/bin/env python3

import argparse
import copy
import os
import sys

from pycparser import c_ast
from pycparserext import ext_c_parser
from pycparserext.ext_c_generator import GnuCGenerator

from jinja2 import Template

# required by parser library
sys.path.extend(['.', '..'])

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

# include declaration of function at top of translated file
def include_declaration(funcDecl, includeAst, suffix):
    decl_copy = copy.deepcopy(funcDecl)
    decl_copy.name += suffix
    decl_copy.type.type.declname += suffix
    # delete function attributes
    decl_copy.funcspec = []
    includeAst.ext.append(decl_copy)

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

# register all ocalls in IPE function + redirect ocall to new stub
class OcallCollector(c_ast.NodeVisitor):
    def __init__(self, ipe_functions, inline_functions):
        self.ipe_functions = ipe_functions
        self.inline_functions = inline_functions
        self.ocall_functions = {}
        self.ocall_detected = False

    def visit_FuncCall(self, node):
        funcName = node.name.name
        # works because function declaration must proceed function call
        if funcName not in self.ipe_functions and funcName not in self.inline_functions and "__" not in funcName:
            self.ocall_detected = True
            self.ocall_functions[funcName] = node
            # change ocalls not declaration, because unprotected --> unprotected calls should not go through stub
            node.name.name += "_stub"

# for all entry functions in IPE:
#   change name of function
#   add to entry function table
#   write a unprotected stub with old name
#   include declaration of stub at top of translated file
class IPECollector(c_ast.NodeVisitor):
    def __init__(self, generated_header, replacement_functions):
        self.index = 0
        self.generated_header = generated_header
        self.replacement_functions = replacement_functions
        self.ipe_functions = {}
        self.inline_functions = {}
        self.entry_functions = []

    def visit_FuncDef(self, node):
        function_name = node.decl.name
        # check attributes for IPE annotations (see ipe.support.h), if IPE function then register function name
        for attributes_group in node.decl.funcspec:
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
                        if (node.decl.type.args):
                            v = ArgumentRegCounter()
                            v.visit(node.decl.type.args)
                            break_if_stack_passing(node.decl.type, v.reg_used)
                        return_regs = ArgumentRegCounter.nb_reg_used(node.decl.type.type.type.names)
                        self.entry_functions.append({
                            'internal_name': internal_name,
                            'external_name': function_name,
                            'index': self.index,
                            'bitmap': hex(int(make_bitmap(return_regs), 2)),
                        })
                        self.index += 1
                        include_declaration(node.decl, self.generated_header, "")
                        # change declaration name not ecalls, because this way ecall from other file possible
                        node.decl.type.type.declname = internal_name
                        # append function with new name to ext ast
                        self.replacement_functions.ext.append(node)
                    if sectionName == ".ipe_func":
                        self.ipe_functions[function_name] = node


# for all ocalls in IPE:
#   write a protected stub
#   include declaration of new stub at top of translated file
class OcallStubCreator(c_ast.NodeVisitor):
    def __init__(self, generated_header, ocall_functions):
        self.generated_header = generated_header
        self.ocall_functions = ocall_functions
        self.stubs = []

    def visit_Decl(self, node):
        arg_type = node.type
        if isinstance(arg_type, ext_c_parser.FuncDeclExt):
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
                include_declaration(node, self.generated_header, "_stub")

def base_name(filename):
    local_name = filename.split('/')[-1]
    return '.'.join(local_name.split('.')[:-1])

def preprocessed_name(filename):
    base = base_name(filename)
    return base + '.pp'

def ast_from_source(parser, filename):
    pp_file_name = preprocessed_name(filename)
    libipe = os.path.abspath(os.path.dirname(sys.argv[0]) + '/libipe')
    os.system(f'msp430-gcc -std=c99 -I{os.path.abspath(os.path.dirname(__file__))}/fake_libc_include -I{libipe} -I{os.path.abspath(os.path.dirname(__file__))} -g --preprocess {filename} -o {pp_file_name}')

    pp_file = open(pp_file_name, "r")
    src = pp_file.read()
    return parser.parse(src, filename=pp_file_name)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Source-to-source translator for IPE security")
    parser.add_argument('source_file')
    parser.add_argument('-output', help="Path to the output file directory (default: ./output/).", default="output")
    args = parser.parse_args()

    try:
        os.mkdir(args.output)
    except FileExistsError as e:
        pass

    parser = ext_c_parser.GnuCParser()
    original_ast = ast_from_source(parser, args.source_file)

    pp_file_name = preprocessed_name(args.source_file)

    replacement_functions = parser.parse("", filename='<none>')
    generated_header = parser.parse("", filename='<none>')

    ipe_collector = IPECollector(generated_header, replacement_functions)
    ipe_collector.visit(original_ast)

    ocall_collector = OcallCollector(ipe_collector.ipe_functions, ipe_collector.inline_functions)

    for ipe_fn in ipe_collector.ipe_functions.values():
        ocall_collector.ocall_detected = False
        ocall_collector.visit(ipe_fn)
        if ocall_collector.ocall_detected and ipe_fn not in replacement_functions.ext:
            replacement_functions.ext.append(ipe_fn)

    ocall_stub_creator = OcallStubCreator(generated_header, ocall_collector.ocall_functions)
    ocall_stub_creator.visit(original_ast)

    # write generated table file
    with open(os.path.abspath(os.path.dirname(sys.argv[0]) + '/libipe/templates/generated_table.s')) as file:
        table_template = Template(file.read())
        table_obj = {
            'max_entry_index': ipe_collector.index - 1,
            'entry_functions': ipe_collector.entry_functions,
        }
        with open(os.path.join(args.output, "generated_table.s"), "w") as target_file:
            target_file.write(table_template.render(table_obj))

    # write generated stubs
    with open(os.path.abspath(os.path.dirname(sys.argv[0]) + '/libipe/templates/generated_stubs.s')) as file:
        stubs_template = Template(file.read())
        stubs_obj = {
            'stubs_to_unprotected': ocall_stub_creator.stubs,
            'stubs_to_protected': ipe_collector.entry_functions,
        }
        with open(os.path.join(args.output, "generated_stubs.s"), "w") as target_file:
            target_file.write(stubs_template.render(stubs_obj))

    # write C translation result to new file
    with open(os.path.join(args.output, 'generated_ipe_header.h'), "w") as newFile:
        newFile.write(GnuCGenerator().visit(generated_header))

    newFile = open(os.path.join(args.output, base_name(args.source_file) + '.c'), "w")
    for line in GnuCGenerator().visit(replacement_functions).splitlines():
        if "asm" in line:
            newFile.write(line + ";\n")
        else:
            newFile.write(line + "\n")

    # clean up
    os.remove("./lextab.py")
    os.remove("./yacctab.py")
    os.remove(pp_file_name)

#!/bin/bash
#------------------------------------------------------------------------------
# Copyright (C) 2001 Authors
#
# This source file may be used and distributed without restriction provided
# that this copyright statement is not removed from the file and that any
# derivative work contains the original copyright notice and the associated
# disclaimer.
#
# This source file is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation; either version 2.1 of the License, or
# (at your option) any later version.1
#
# This source is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
# License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this source; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
#------------------------------------------------------------------------------
#
# File Name: asm2ihex.sh
#
# Author(s):
#             - Olivier Girard,    olgirard@gmail.com
#
#------------------------------------------------------------------------------
# $Rev$
# $LastChangedBy$
# $LastChangedDate$
#------------------------------------------------------------------------------

###############################################################################
#                            Parameter Check                                  #
###############################################################################
EXPECTED_ARGS=8
if [ $# -ne $EXPECTED_ARGS ]; then
  echo "ERROR    : wrong number of arguments"
  echo "USAGE    : asm2ihex.sh <test name> <test assembler file> <linker script> <assembler define>  <prog mem size> <data mem size> <peripheral addr space size> <bootcode mem size>"
  echo "Example  : asm2ihex.sh c-jump_jge  ../src/c-jump_jge.s43 ../bin/template.x ../bin/pmem.h 2048            128             512"
  exit 1
fi

# MSPGCC version prefix
if [ -z "$MSPGCC_PFX" ]; then
    if command -v msp430-gcc >/dev/null; then
	MSPGCC_PFX=msp430
    else
	MSPGCC_PFX=msp430-elf
    fi
fi

###############################################################################
#               Check if definition & assembler files exist                   #
###############################################################################

if [ ! -e $2 ]; then
    echo "Assembler file doesn't exist: $2"
    exit 1
fi
if [ ! -e $3 ]; then
    echo "Linker definition file template doesn't exist: $3"
    exit 1
fi
if [ ! -e $4 ]; then
    echo "Assembler definition file template doesn't exist: $4"
    exit 1
fi


../bin/gen_linker_def.sh $3 $4 $5 $6 $7 $8

###############################################################################
#                  Compile, link & generate IHEX file                         #
###############################################################################

echo ""
echo "\$ $MSPGCC_PFX-as      -alsm $2 -o $1.o > $1.l43"
$MSPGCC_PFX-as      -alsm    -I../../../../sdk/libipe/stubs     $2     -o $1.o     > $1.l43
echo "\$ $MSPGCC_PFX-objdump -xdsStr $1.o >> $1.l43"
$MSPGCC_PFX-objdump -xdsStr       $1.o              >> $1.l43
echo "\$ $MSPGCC_PFX-ld      -T ./pmem.x $1.o -o $1.elf"
$MSPGCC_PFX-ld      -T ./pmem.x   $1.o    -o $1.elf
echo "\$ $MSPGCC_PFX-objcopy -O ihex $1.elf $1.ihex"
$MSPGCC_PFX-objcopy -O ihex       $1.elf    $1.ihex
echo ""

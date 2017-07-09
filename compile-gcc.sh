#!/bin/sh
PROJNAME=$1
ZPUCHAIN=$2
ZBC=$3
SINOS=`pwd`

# -DNUM_PROCS 8 -DNUM_PPP 8 \

cd $ZBC

lua zbc.lua core.lex -- core.par -- pass.zpu-char -- pass.consteval -I -C -B \
 -DWORD_CHARS 4 -DWORD_VALS 4 \
 -DNUM_PROCS 64 -DNUM_PPP 64 \
 -DSYSCALL_BUDGET 64 \
 -DSTACK_SIZE_VALS 8192 -DVM_STACK_TOP 1879048192 \
 -- pass.optswitch -- pass.mkextern __asm__ __asmnv__ < $SINOS/out/$PROJNAME.b > $SINOS/out/$PROJNAME.ast
lua zbc.lua output.zpu < $SINOS/out/$PROJNAME.ast > $SINOS/out/$PROJNAME.S

cd $SINOS
$ZPUCHAIN/zpu-elf-gcc -Os base.S out/$PROJNAME.S -N -nostdlib -o out/$PROJNAME.elf
$ZPUCHAIN/zpu-elf-objcopy -O binary out/$PROJNAME.elf out/$PROJNAME.bin

#!/bin/sh
PROJNAME=$1
ZPUCHAIN=$2
ZBC=$3
SINOS=`pwd`

# -DNUM_PROCS 8 -DNUM_PPP 8 \

cd $ZBC

echo .scope lib base > $SINOS/out/$PROJNAME.S

cat $SINOS/base.S >> $SINOS/out/$PROJNAME.S
lua zbc.lua core.lex -- core.par -- pass.zpu-char -- pass.consteval -I -C -B \
 -DWORD_CHARS 4 -DWORD_VALS 4 \
 -DNUM_PROCS 64 -DNUM_PPP 64 \
 -DSYSCALL_BUDGET 64 \
 -DSTACK_SIZE_VALS 8192 -DVM_STACK_TOP 1879048192 \
 -- pass.optswitch -- pass.mkextern __asm__ __asmnv__ < $SINOS/out/$PROJNAME.b > $SINOS/out/$PROJNAME.ast

echo .scope project $PROJNAME >> $SINOS/out/$PROJNAME.S

lua zbc.lua output.zpu < $SINOS/out/$PROJNAME.ast >> $SINOS/out/$PROJNAME.S

lua zbc.lua asm.zpu < $SINOS/out/$PROJNAME.S >> $SINOS/out/$PROJNAME.bin

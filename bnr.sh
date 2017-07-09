#!/bin/sh
# yes, vifino thought up the name "sinkrn".
# 'sinos' refers to the project in general.

# GCC ZPU Toolchain. Kernel only uses this for the assembler/objdump.
# In practice? vifino would like the servers to be written in C, with good reason (sanity).
# Still, kernel is simpler and maybe more portable this way.
# ... in other news, ZPUCHAIN is not required unless using compile-gcc.sh.
ZPUCHAIN=~/Documents/ATOMINST/zpugcc/bin
ZBC=../../Lua/ZBC/
# lua-cpuemus + SINMMU.
VIFINO_LCE=../../Lua/lua-cpuemus
SINOS=`pwd`

rm out/*

# build the 'hello server' (the kernel testbed application, written in B to be consistent)
cat pututil.b mmucall.b prog/hello.b > out/hello.b

# this controls the toolchain used

# ./compile.sh hello $ZBC
./compile-gcc.sh hello $ZPUCHAIN $ZBC

# embed the SIStem: Sinkrn Initialization Stem
cat out/hello.bin | ./kembed.lua > out/kembed.b

# build sinkrn.
cat kernel/main_zpu.b kernel/db.b kernel/sched.b kernel/syscall.b kernel/pipe.b kernel/hal.b pututil.b mmucall.b malloc.b out/kembed.b malloc_heap_end.b > out/kernel.b
./compile.sh kernel $ZPUCHAIN $ZBC

# execute sinkrn
cd $VIFINO_LCE
luajit ./emu_zpu_sinmmu.lua $SINOS/out/kernel.bin

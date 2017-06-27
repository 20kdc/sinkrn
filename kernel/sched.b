/* This file is released into the public domain.
   No warranty is provided, implied or otherwise. */

/* Kernel Process Table */

sched_process 0;

/* Syscall interface registers. On ZPU/SINMMU there's dedicated logic holding these. */
sched_process_res 0;
sched_process_p1 0;
sched_process_p2 0;
sched_process_p3 0;
sched_process_p4 0;

/* Basic universal properties */
sched_process_exists 0;
sched_process_ip 0;
sched_process_sp 0;

/* malloc'd buffer holding the current stack.
   Mapped at 1879048192 - STACK_SIZE_VALS. */
sched_process_stack_addr 0;
/* Process data buffer. Pointer to a structure:
   [0]    : Refcount.
   [1]    : Size in words
   [2]    : Actual malloc'd data */
sched_process_databuf 0;

sched_create_arrays() {
 extrn sched_process_exists, sched_process_res, sched_process_ip, sched_process_sp;
 extrn sched_process_p1, sched_process_p2, sched_process_p3, sched_process_p4;
 extrn sched_process_stack_addr, sched_process_databuf;
 sched_process_res = sched_malloc_procarray();
 sched_process_p1 = sched_malloc_procarray();
 sched_process_p2 = sched_malloc_procarray();
 sched_process_p3 = sched_malloc_procarray();
 sched_process_p4 = sched_malloc_procarray();

 sched_process_exists = sched_malloc_procarray();
 sched_process_ip = sched_malloc_procarray();
 sched_process_sp = sched_malloc_procarray();

 sched_process_stack_addr = sched_malloc_procarray();
 sched_process_databuf = sched_malloc_procarray();
}

sched_malloc_procarray() {
 if (!NUM_PROCS) {
  return 0; /* Doesn't matter */
 } else {
  auto m;
  m = malloc(NUM_PROCS);
  if (!m) {
   puts("FATAL: Unable to malloc critical sched-array. Recompile with lower NUM_PROCS [");
   puti(NUM_PROCS);
   puts(" at current]*n");
   platform_die();
  }
  return m;
 }
}

/* It is assumed databuf is one of the data buffers described above.
   The buffer gains a reference now, and that is lost is freed on error or on process death. */
sched_create_process(databuf, nip, r, da, db, dc, dd) {
 extrn sched_process_exists, sched_process_res, sched_process_ip, sched_process_sp;
 extrn sched_process_p1, sched_process_p2, sched_process_p3, sched_process_p4;
 extrn sched_process_stack_addr, sched_process_databuf;
 auto target;
 target = 0;
 if (!(++databuf[0])) {
  puts("WARN: Was unable to create a process (reference overflow).*n");
  databuf[0]--;
 }
 while (target < NUM_PROCS) {
  if (!sched_process_exists[target]) {
   auto buf;
   sched_process_res[target] = r;
   sched_process_p1[target] = da;
   sched_process_p2[target] = db;
   sched_process_p3[target] = dc;
   sched_process_p4[target] = dd;

   sched_process_ip[target] = nip;
   sched_process_sp[target] = VM_STACK_TOP;
   buf = malloc(STACK_SIZE_VALS / WORD_VALS);
   if (!buf) {
    puts("WARN: Was unable to create a process (out of memory for stack).*n");
    db_decrc(databuf);
    return -1;
   }
   sched_process_stack_addr[target] = buf;
   sched_process_databuf[target] = databuf;
   sched_process_exists[target] = 1;
   platform_initproc(target);
   return target;
  }
  target++;
 }
 db_decrc(databuf);
 puts("WARN: Was unable to create a process (out of slots).*n");
 return -1;
}

sched_mmu_readback(res, ip, sp, p1, p2, p3, p4) {
 extrn sched_process, sched_process_res, sched_process_ip, sched_process_sp;
 extrn sched_process_p1, sched_process_p2, sched_process_p3, sched_process_p4;
 sched_process_res[sched_process] = res;
 sched_process_ip[sched_process] = ip;
 sched_process_sp[sched_process] = sp;
 sched_process_p1[sched_process] = p1;
 sched_process_p2[sched_process] = p2;
 sched_process_p3[sched_process] = p3;
 sched_process_p4[sched_process] = p4;
}

sched_copyreg(src, dst) {
 extrn sched_process, sched_process_res, sched_process_ip, sched_process_sp;
 extrn sched_process_p1, sched_process_p2, sched_process_p3, sched_process_p4;
 sched_process_res[dst] = sched_process_res[src];
 sched_process_ip[dst] = sched_process_ip[src];
 sched_process_sp[dst] = sched_process_sp[src];
 sched_process_p1[dst] = sched_process_p1[src];
 sched_process_p2[dst] = sched_process_p2[src];
 sched_process_p3[dst] = sched_process_p3[src];
 sched_process_p4[dst] = sched_process_p4[src];
 platform_copyprocreg(src, dst);
}

sched_switch() {
 extrn sched_process, sched_process_exists;
 auto target, loops;
 target = sched_process + 1;
 loops = 0;
 while (loops < 2) {
  while (target < NUM_PROCS) {
   if (sched_process_exists[target]) {
    sched_process = target;
    return;
   }
   target++;
  }
  target = 0;
  loops++;
 }
 puts("FATAL: All processes are dead. Thank you for using SINKRN.*n");
 platform_die();
}

sched_killcurrent() {
 extrn sched_process, sched_process_exists;
 extrn sched_process_stack_addr, sched_process_databuf;
 sched_process_exists[sched_process] = 0;
 pipe_proc_cleanup(sched_process, -1);
 free(sched_process_stack_addr[sched_process]);
 db_decrc(sched_process_databuf[sched_process]);
}

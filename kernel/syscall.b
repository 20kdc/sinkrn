/* This file is released into the public domain.
   No warranty is provided, implied or otherwise. */

/* Just the syscalls.
 * Returns -1 to switch to the next process via round-robin, otherwise returns a specific process.
 * Budget is only regained when using round-robin, hopefully ensuring relatively fair distribution.
 */
syscall_handler(sc, a, b, c, d) {
 extrn sched_process, sched_process_res, pipe_pfun_proc_forwarder, sched_process_databuf;
 auto v, dbs, dbd;
 switch (sc) {
  case 0:
   sched_killcurrent();
   return -1;
  case 1:
   /* Abandon timeslice */
   return -1;
  case 2:
   /* Recall this returns -1 on error, and the next process number otherwise. */
   v = pipe_proc_send(sched_process, a, b, c, d);
   if (v == -1) {
    sched_process_res[sched_process] = 1;
    break;
   }
   sched_process_res[sched_process] = 0;
   return v;
  case 3:
   sched_process_res[sched_process] = pipe_proc_addinp(sched_process);
   break;
  case 4:
   if (a < 0)
    break;
   if (a >= NUM_PPP)
    break;
   pipe_proc_cleanup(sched_process, a);
   break;
  case 5:
   /* Fork... */
   sched_process_res[sched_process] = syscall_fork();
   return -1;
  case 6:
   sched_process_res[sched_process] = -1;
   dbs = sched_process_databuf[sched_process];
   if (a < 0)
    break;
   if (b < 1)
    break;
   if (a != 0)
    break;
   if (a + b < 0)
    break;
   if (a + b > dbs[1])
    break;
   if (((a + b) * WORD_VALS) < 0)
    break;
   v = syscall_spawn(a, b);
   if (v != -1) {
    sched_process_res[sched_process] = 0;
    dbd = sched_process_databuf[v];
    if (c >= 0)
     if (c < NUM_PPP) {
      dbd[3] = dbs[3 + (c * 2)];
      dbd[4] = dbs[4 + (c * 2)];
     }
   }
   return -1;
  case 7:
   sched_process_res[sched_process] = -1;
   if (a < 1)
    break;
   if ((a * WORD_VALS) < WORD_VALS)
    break;
   dbs = sched_process_databuf[sched_process];
   dbd = syscall_spawn_db(0, dbs[1], a);
   if (dbd) {
    sched_process_res[sched_process] = 0;
    syscall_copypipes(dbs, dbd);
    v = 0;
    while (v < NUM_PROCS) {
     if (sched_process_databuf[v] == dbs) {
      sched_process_databuf[v] = dbd;
      dbd[0]++;
      db_decrc(dbs);
     }
     v++;
    }
    return -1;
   }
   break;
  case 8:
   sched_process_res[sched_process] = -1;
   dbs = sched_process_databuf[sched_process];
   if (a < 0)
    break;
   if (a >= dbs[1])
    break;
   sched_process_res[sched_process] = dbs[2][a];
   dbs[2][a] = b;
   break;
  default:
   break;
 }
 return sched_process;
}

syscall_fork() {
 extrn sched_process, sched_process_databuf, sched_process_res, sched_process_stack_addr, sched_process_sp;
 auto proc, i, stack1, stack2;
 proc = syscall_spawn(0, sched_process_databuf[sched_process][1]);
 if (proc == -1)
  return -1;
 sched_copyreg(sched_process, proc);
 sched_process_res[proc] = 1;
 /* Copy stack. Note that the full stack is copied because the data has to be cleared out anyway for security reasons. */
 stack1 = sched_process_stack_addr[sched_process];
 stack2 = sched_process_stack_addr[proc];
 i = 0;
 while (i < (STACK_SIZE_VALS / WORD_VALS)) {
  stack2[i] = stack1[i];
  i++;
 }
 syscall_copypipes(sched_process_databuf[sched_process], sched_process_databuf[proc]);
 return 0;
}

syscall_copypipes(dbs, dbd) {
 auto i;
 i = 3;
 while (i < (3 + (NUM_PPP * 2))) {
  dbd[i] = dbs[i];
  i++;
 }
}

/* Used by fork to handle most of initialization, too.
   Returns the procid. */
syscall_spawn(dBase, dLen) {
 /* Luckily this takes care of dbd cleanup */
 auto dbd;
 dbd = syscall_spawn_db(dBase, dLen, dLen);
 if (dbd)
  return platform_create_standard_process(dbd);
 return -1;
}

syscall_spawn_db(dBase, dLen, rLen) {
 extrn sched_process, sched_process_databuf;
 auto bt, dbcs, dbd, i;
 dbcs = sched_process_databuf[sched_process][2];
 bt = malloc(rLen);
 if (!bt)
  return 0;
 dbd = db_new(bt, rLen);
 if (!dbd) {
  free(bt);
  return 0;
 }
 i = 0;
 while (i < rLen) {
  if (i < dLen) {
   bt[i] = dbcs[i];
  } else {
   bt[i] = 0;
  }
  i++;
 }
 return dbd;
}


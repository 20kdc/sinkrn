/* This file is released into the public domain.
   No warranty is provided, implied or otherwise. */

/* Pipes module */

/* pipe_pfun_*(userdata, data1, data2, spf, spud) :
 * userdata: Userdata
 * data1/data2: the actual message being sent
 * spf: 0, or the forwarded function pointer
 * spud: forwarded UD
 * The return value should be an existing process ID, or -1 on error.
 */

/* userdata: pipe ID in the global pipes table */
pipe_pfun_proc_forwarder(userdata, data1, data2, spf, spud) {
 extrn sched_process_databuf;
 auto proc, pp, nproc, db, targpipeid;
 proc = userdata / NUM_PPP;
 pp = userdata - (proc * NUM_PPP);

 db = sched_process_databuf[proc];
 targpipeid = -1;
 if (spf) {
  targpipeid = db_pipe_install(db, spf, spud);
  if (targpipeid == -1)
   return -1;
 }
 nproc = platform_create_pip_process(db, pp, data1, data2, targpipeid, 0);
 if (nproc < 0)
  return -1;
 return nproc;
}

pipe_pfun_hal(userdata, data1, data2, spf, spud) {
 extrn sched_process;
 if (spf != 0)
  return spf(spud, hal_comm_read(data1, data2), 0, 0, 0);
 hal_comm_write(data1, data2);
 return sched_process;
}

pipe_proc_addinp(proc) {
 extrn sched_process_databuf;
 return db_pipe_install(sched_process_databuf[proc], 0, proc);
}

/* Removes all references to a specific input or all inputs on the process. */
pipe_proc_cleanup(proc, inp) {
 extrn sched_process_exists, sched_process_databuf;
 extrn pipe_pfun_proc_forwarder;
 auto i, j, base, top, db;
 i = 0;
 top = (base = proc * NUM_PPP) + NUM_PPP;
 if (inp >= 0) {
  base =+ inp;
  top = base;
 }
 while (i < NUM_PROCS) {
  if (sched_process_exists[i]) {
   db = sched_process_databuf[i];
   j = 3;
   while (j < (3 + (NUM_PPP * 2))) {
    /* It doesn't matter if there wasn't ever a process here and thus it's nonsense memory, this just zeroes stuff */
    if (db[j] == pipe_pfun_proc_forwarder)
     if (db[j + 1] >= base)
      if (db[j + 1] < top)
       db[j] = 0;
    if (i == proc)
     if (j == (3 + (inp * 2)))
      db[j] = 0;
    j =+ 2;
   }
  }
  i++;
 }
}

/* Handles untrustworthy indexes (proc is trustworthy though), be careful here. */
pipe_proc_send(proc, pipe, data1, data2, attach) {
 extrn sched_process_databuf;
 auto procdb, targ_func, targ_data, attach_func, attach_data;
 if (pipe < 0)
  return -1;
 if (pipe >= NUM_PPP)
  return -1;
 procdb = sched_process_databuf[proc];

 targ_func = procdb[3 + (pipe * 2)];
 targ_data = procdb[4 + (pipe * 2)];

 if (attach >= NUM_PPP)
  return -1;

 attach_func = 0;
 attach_data = 0;

 if (attach >= 0) {
  attach_func = procdb[3 + (attach * 2)];
  attach_data = procdb[4 + (attach * 2)];
  if (!attach_func)
   return -1;
 }

 if (targ_func)
  return targ_func(targ_data, data1, data2, attach_func, attach_data);
 return -1;
}

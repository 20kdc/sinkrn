/* This file is released into the public domain.
   No warranty is provided, implied or otherwise. */

/* Databuf:
 * [0]: refcount
 * [1]: buffer size in words
 * [2]: buffer address
 * [3..]: Pipes, alternating function and userdata (3 to (3 + (NUM_PPP * 2)) - 1)
 */

db_new(malbuf, mallen) {
 auto db, i;
 db = malloc(3 + (NUM_PPP * 2));
 if (db) {
  db[0] = 0;
  db[1] = mallen;
  db[2] = malbuf;
  i = 3;
  while (i < ((NUM_PPP * 2) + 3))
   db[i++] = 0;
 }
 return db;
}

db_decrc(databuf) {
 if (databuf[0]--)
  return;
 free(databuf[2]);
 free(databuf);
}

/* Note that if a == 0, then a new input is created, assuming 'b' is the process ID. */
db_pipe_install(db, a, b) {
 extrn pipe_pfun_proc_forwarder;
 auto i, idx;
 i = 3;
 while (i < (3 + (NUM_PPP * 2))) {
  if (!db[i]) {
   idx = (i - 3) / 2;
   if (!a) {
    db[i] = pipe_pfun_proc_forwarder;
    db[i + 1] = (b * NUM_PPP) + idx;
   } else {
    db[i] = a;
    db[i + 1] = b;
   }
   return idx;
  }
  i =+ 2;
 }
 return -1;
}

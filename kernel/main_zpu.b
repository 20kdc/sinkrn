/* This file is released into the public domain.
   No warranty is provided, implied or otherwise. */

/* All the code in the kernel that's specific to the ZPU platform.
   This'll have some porting documentation:

   The port of the kernel has an extremely high amount of control,
    due to this being a necessity for proper portability.
   The following functions have to be implemented:

   platform_die(): Do whatever the system can to shutdown.
   platform_create_standard_process(db): Should just forward to sched_create_process with the correct IP.
   platform_create_pip_process(db, st, a, b, c, d): Should just forward to sched_create_process with the correct IP.
   platform_initproc(pid): Clears fields of any platform-specific process information (registers)
                           (Only used if using the default sched.b)
   platform_copyprocreg(source, dest): Copies platform-specific process information (for use in fork)
   hal_tty_count(): H.A.L function
   hal_tty_type(tty): H.A.L function. Returns the following:
    0: Byte Console (TTY0 should be this)
       Get: Size 1, Register 1: Returns -1 if nothing is there yet, otherwise pops a byte from the buffer
       Put: Writes the byte to the console
    1: Networking Port (Communicates with another system.)
       Get: Size 1, Register 1: Returns -1 if nothing is there yet, otherwise pops a word from the buffer
       Put: Writes the word onto the port
    <NTD: Specify more kinds of HAL devices.>
   hal_tty_put(tty, ch): H.A.L function.
   hal_tty_get(tty, reg): H.A.L function, returns word. Special registers:
   -2: Type
   -1: 'Get' Register Bank Size

   The following functions should be called:
   sched_switch() : Do this whenever the current process number is invalid, should be changed for any reason...
                     Here, it's wrapped with kernsched_switch(); because of the syscall budget stuff.
   malloc_init(top): Malloc is more or less expected as part of the sched module. Definitely do this, or alternatively, make a replacement sched.b.
   sched_create_arrays(): So that these don't count against kernel size, basically
   syscall_handler(sci, a, b, c, d): The actual system call handler
   <goodness knows what else>
*/

_start(memsz) {
 extrn kernel_init_block, pipe_pfun_hal;
 auto db, proc;
 /* Get the SP at startup, which is memory size */
 malloc_init(((&memsz) - WORD_VALS) - STACK_SIZE_VALS);
 sched_create_arrays();
 /* Perform platform sched_malloc_procarray here... */
 db = db_new(kernel_init_block + (WORD_VALS * 2), (kernel_init_block[0] - 8) / WORD_VALS);
 proc = -1;
 if (db) {
  db[3] = pipe_pfun_hal;
  db[4] = 0;
  proc = platform_create_standard_process(db);
 }
 if (proc == -1)
  puts("Unable to create initial process.*n");
 kernsched_switch();
 kernsched_continue();
}

_interrupt() {
 kernel_intcore();
 kernsched_continue();
}

platform_die() {
 __asmnv__("BREAKPOINT");
}
platform_create_standard_process(db) {
 return sched_create_process(db, 0, 0, 0, 0, 0, 0);
}
platform_create_pip_process(db, st, a, b, c, d) {
 return sched_create_process(db, 32, st, a, b, c, d);
}

platform_initproc(target) {
 /* This doesn't have any platform-specific registers to worry about. */
}
platform_copyprocreg(source, target) {
}

kernsched_continue() {
 extrn sched_process, sched_process_res, sched_process_ip, sched_process_sp;
 extrn sched_process_p1, sched_process_p2, sched_process_p3, sched_process_p4;
 extrn sched_process_stack_addr, sched_process_databuf;
 auto db;
 db = sched_process_databuf[sched_process];
 syscall3(1, sched_process_stack_addr[sched_process], VM_STACK_TOP - STACK_SIZE_VALS, STACK_SIZE_VALS / WORD_VALS);
 syscall3(2, db[2], 0, db[1]);
 syscall4(3, sched_process_p1[sched_process], sched_process_p2[sched_process], sched_process_p3[sched_process], sched_process_p4[sched_process]);
 /* Begin running userspace code */
 syscall3(0, sched_process_res[sched_process], sched_process_ip[sched_process], sched_process_sp[sched_process]);
}

kernsched_switch() {
 extrn kernel_syscall_budget;
 kernel_syscall_budget = SYSCALL_BUDGET;
 sched_switch();
}

kernel_syscall_budget SYSCALL_BUDGET;

kernel_intcore() {
 extrn sched_process, kernel_syscall_budget;
 auto v;
 sched_mmu_readback(2147483648[5], 2147483648[6], 2147483648[7],
  2147483648[1], 2147483648[2], 2147483648[3], 2147483648[4]);
 switch (2147483648[0]) {
  case -3:
   /* puts("WARN: A process made an invalid access.*n"); */
   sched_killcurrent();
   kernel_syscall_budget = 1;
   break;
  case -2:
   /* HW Interrupt */
   break;
  case -1:
   /* Timer Interrupt, abandon timeslice */
   kernel_syscall_budget = 1;
   break;
  default:
   v = syscall_handler(2147483648[0], 2147483648[1], 2147483648[2], 2147483648[3], 2147483648[4]);
   if (v)
    kernel_syscall_budget = 1;
   break;
 }
 if (!(--kernel_syscall_budget))
  kernsched_switch();
}

hal_tty_count() {
 return 1;
}
hal_tty_put(tty, x) {
 /* tty always == 0 */
 while ((*2147483684) == 0);
 lchar(2147483684, 3, x);
}
hal_tty_get(tty, reg) {
 /* tty always == 0 */
 if (reg == -2)
  return 0; /* 0: Console */
 if (reg == -1)
  return 1; /* 1 word. */
 auto x;
 while ((x = (*2147483688)) == 0);
 return x & 255;
}

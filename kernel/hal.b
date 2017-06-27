/* This file is released into the public domain.
   No warranty is provided, implied or otherwise. */

/* Hardware Abstraction Layer-related stuff.
 * Responsible for the HAL Pipe and putchar() in-kernel.
 * "hal_tty_" functions and the like are actually platform functions, though.
 */

putchar(c) {
 hal_tty_put(0, c);
}

/* 
 * The Actual Userspace Interface To All Hardware On The System
 * Reading:
 * d1: TTY (or -1 for count - register is ignored)
 * d2: Register
 * Register 0 is 'type', 1 is 'data'.
 * Writing:
 * d1: TTY
 */
hal_comm_read(d1, d2) {
 if (d1 == -1)
  return hal_tty_count();
 if (d1 < 0)
  return -1;
 if (d1 >= hal_tty_count())
  return -1;
 return hal_tty_get(d1, d2);
}
hal_comm_write(d1, d2) {
 hal_tty_put(d1, d2);
}

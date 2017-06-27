/* This file is released into the public domain.
   No warranty is provided, implied or otherwise. */

/* Note that 5/6/7 are reserved for RES/IP/SP transfer - only up to 4 
parameters 
could be sent. */
syscall0(cmd) {
 2147483648[0] = cmd;
 return 2147483648[0];
}
syscall1(cmd, a) {
 2147483648[1] = a;
 2147483648[0] = cmd;
 return 2147483648[0];
}
syscall2(cmd, a, b) {
 2147483648[1] = a;
 2147483648[2] = b;
 2147483648[0] = cmd;
 return 2147483648[0];
}
syscall3(cmd, a, b, c) {
 2147483648[1] = a;
 2147483648[2] = b;
 2147483648[3] = c;
 2147483648[0] = cmd;
 return 2147483648[0];
}
syscall4(cmd, a, b, c, d) {
 2147483648[1] = a;
 2147483648[2] = b;
 2147483648[3] = c;
 2147483648[4] = d;
 2147483648[0] = cmd;
 return 2147483648[0];
}

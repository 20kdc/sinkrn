/* This file is released into the public domain.
   No warranty is provided, implied or otherwise. */

puti(x) {
 if (x >= 10) {
  puti(x / 10);
  x =% 10;
 } else if (x <= -10) {
  putchar('-');
  puti(x / 10);
  x =% 10;
 }
 if (x < 0) {
  putchar(':' - x);
 } else {
  putchar('0' + x);
 }
}

puts(str) {
 auto c;
 while (c = char(str, 0)) {
  putchar(c);
  str =+ 1;
 }
}

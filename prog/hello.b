/* This file is released into the public domain.
   No warranty is provided, implied or otherwise. */

/* Program to get a feel for how the API ought to work.
   Note the use of _int for the message handler rather than what it "should be".
   Pipe IDs are 0-indexed.
   Syscalls are:
   0: End Process
   1: Abandon Timeslice (no params)
    (Useful when wasting time waiting on another thread.)
    Does not return meaningful information.
   2: Send message (outPipe, data1, data2, inPipeAttach)
    Creates a new process in the same memory space as the target, running from _interrupt,
     giving it a 2-word message, and optionally a pipe. (A negative number indicates no pipe should be sent.)
    The new process has the syscall fields set to:
     [0]: The pipe ID relative to the called process.
     [1]: data1
     [2]: data2
     [3]: The attached pipe ID, or -1 if none.
    If this fails (the target's buffer is dead, or could not create the process) then -1 is returned, else 0.
   3: Create Input (no params) returns a new pipe, or -1 on error.
    The process performing this can begin receiving messages with the given pipe ID the moment this pipe ID is given to another process.
   4: Delete Input (pipeId) removes a pipe from this process's pipe table.
    Note that doing this to a pipe owned by the current process makes anything unable to send to that pipe.
   5: Fork Process ()
    Returns -1 on error, 0 on success (parent), 1 on success (child).
    The child starts with the same pipe table as the parent.
   6: Create Process (codeBase, codeLen, attachPipe) creates a new process.
    Note that codeBase must be aligned, and is actually *divided by WORD_VALS*, and codeLen is in words.
    The process, like the init process, has only one pipe, given by it's parent (attachPipe).
    Returns -1 on error, 0 on success.
   7: Resize CDS (newSize)
    Resizes the code/data segment of the process.
    newSize is, as usual, in words.
    This is how memory allocation is achieved.
   8: Get & Set (addr, word)
    This sets an address (in words, so divide by WORD_VALS) to a given word.
    As this is a syscall, it is atomic.
 */
/*
 * Plan:
 * Create ftp_pipe
 * Fork
 *  Create ptf_pipe
 *  Fork sends message to parent to confirm it's alive and sends a pipe
 * Parent
 *  Waits for above then sends back pipe and selfdestructs
 */
_start() {
 extrn keep_running, ftp_pipe, ptf_pipe, __hello_end__;
 auto v;
 ftp_pipe = -1;
 ptf_pipe = -1;
 puts("Hello world from User Mode!*n");
 ftp_pipe = syscall0(3);
 puts("Resizing memory to add one word.*n");
 if (syscall1(7, (__hello_end__ / WORD_VALS) + 1)) {
  puts("Failed to extend memory.*n");
 } else {
  __hello_end__[0] = 1234;
  syscall0(1);
  puts("The following should be '1234':");
  puti(__hello_end__[0]);
  puts(".*nAnd now '4321':");
  syscall2(8, __hello_end__ / WORD_VALS, 4321);
  puti(__hello_end__[0]);
  puts(".*nRemoving word.*n");
  if (syscall1(7, __hello_end__ / WORD_VALS))
   puts("Failed to retract memory.*n");
 }
 puts("This program will now fork.*n");
 v = syscall0(5);
 if (v > 0) {
  puts("F:Active*n");
  ptf_pipe = syscall0(3);
  if (syscall4(2, ftp_pipe, 0, 0, ptf_pipe))
   puts("F:Could not send!*n");
 } else if (v == 0) {
  puts("P:Active*n");
 } else {
  puts("The fork failed!*n");
  keep_running = 0;
 }
 while (keep_running)
  syscall0(1);
 syscall0(0);
}

keep_running 1;
ftp_pipe 0;
ptf_pipe 0; /* Fork-only, is sent to parent */

_interrupt() {
 extrn ptf_pipe, ftp_pipe, __hello_end__, keep_running;
 auto p, pipe;
 p = 2147483648[0];
 pipe = 2147483648[3];
 if (p == ftp_pipe) {
  puts("P:Got message from fork.*n");
  if (pipe >= 0) {
   puts("P:It had a pipe. Responding...*n");
   if (syscall4(2, pipe, 0, 0, -1))
    puts("P:Could not send!*n");
   puts("P:Deleting pipes and saying goodbye.*n");
   syscall1(4, 0);
   syscall1(4, pipe);
   keep_running = 0;
  } else {
   puts("P:It had no pipe?*n");
  }
 } else if (p == ptf_pipe) {
  puts("F:The fork received the message.*n");
  /* Create the next process? */
  if (syscall3(6, 0, __hello_end__ / WORD_VALS, 0))
   puts("F:Could not create process!*n");
  /* Bye */
  puts("F:Bye.*n");
  syscall1(4, 0);
  syscall1(4, ftp_pipe);
  syscall1(4, ptf_pipe);
  keep_running = 0;
 } else {
  if (pipe >= 0) {
   puts("?: Something IDK happened (WP)*n");
   syscall1(4, pipe);
  } else {
   puts("?: Something IDK happened (NP)*n");
  }
 }
 syscall0(0);
}

putchar(c) {
 syscall4(2, 0, 0, c, -1);
}

__hello_end__[0];

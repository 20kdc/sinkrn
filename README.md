# SINKRN

Microkernel for ZPU based around a simple to implement custom MMU.

## Naming

...blame vifino for this one. I do like it, though.

## Concepts

Tiny, easy to reimplement the general design (was written in less than a week).

Security by basing all IO on pipes and "if you have the object, you have access"-style security,
 and security by making things simpler.

Defending against DoS is rather impossible (once a process is "in", all is lost as far as DoS prevention is concerned),
 don't bother, in favour of simplicity to prevent worse security flaws slipping in.

## Kernel Size

About 8k, though the NUM_PROCS static array size, and the embedded process image, may affect this somewhat.

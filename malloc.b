/* This file is released into the public domain.
   No warranty is provided, implied or otherwise. */

/* Must be second to last. Initial heap state must be last.
   The idea is that programs can put stuff on heap before they even start.
   malloc_heap is thus marked at the end of this file, the initial heap state goes after,
   and the heap is finished with "malloc_heap_end.b".
   Heap block format:
   [0]: Size in bytes (must be divisible by WORD_VALS, and this includes the header)
   [1]: Status bitfield.
        1: This block is free.
        2: There is a block after this.
   (The status bitfield could be stuffed into the size field if not for portability.)
   This should work in any sufficiently ZBC-like B compiler, I think.
   Unfortunately I do not have a reliable reference to if ZBC follows standards (I did try to make it work for Ken T.'s samples though)
    and the B compiler is expected to put all data at the end, in the presented order.
  Malloc size is given in WORDs.
  Also, example definition of a used block at compile-time:
  some_block_head[2] 12 2;
  some_block_data[1] 123; */

malloc_init(ram_end) {
 extrn malloc_heap_init;
 malloc_heap_init[0] = ((ram_end - malloc_heap_init) / WORD_VALS) * WORD_VALS;
 malloc_heap_init[1] = 1;
}

malloc(sz) {
 extrn malloc_heap;
 auto ptr;
 if (sz <= 0)
  return 0;
 sz =+ 2; /* Include block header in allocation. */
 sz =* WORD_VALS;
 ptr = malloc_heap;
 while (1) {
  if (ptr[1] & 1) {
   if (ptr[1] & 2)
    malloc_merge(ptr);
   /* A second block header is created, hence the sz + 2 again. */
   if (ptr[0] >= (sz + (2 * WORD_VALS))) {
    auto nxt;
    nxt = ptr + sz;
    nxt[0] = ptr[0] - sz;
    nxt[1] = ptr[1];
    ptr[0] = sz;
    ptr[1] = 2;
    return ptr + (2 * WORD_VALS);
   }
  }
  if (!(ptr[1] & 2))
   return 0;
  ptr =+ ptr[0];
 }
}

/* Merge by block header pointer. Only call on free blocks with blocks after them (flags 3) */
malloc_merge(ptr) {
 auto nxt;
 nxt = ptr + ptr[0];
 if (nxt[1] == 3)
  malloc_merge(nxt);
 if (nxt[1] & 1) {
  ptr[0] =+ nxt[0];
  ptr[1] = nxt[1];
 }
}

free(ptr) {
 ptr =- WORD_VALS * 2; /* block header */
 ptr[1] =| 1; /* Actually mark as free */
}

 /* it has no meaning, but is a marker */
malloc_heap[0];

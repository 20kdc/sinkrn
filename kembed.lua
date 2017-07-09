#!/usr/bin/env lua

-- This file is released into the public domain.
-- No warranty is provided, implied or otherwise.

-- kernel init embedder
local array = ""
local elm = 2
while true do
 -- Big-endian system, so relatively simple (?)
 local tx = io.read(4)
 if tx == nil then
  print("kernel_init_block[] (" .. elm .. "*WORD_VALS),2" .. array .. ";")
  return
 end
 elm = elm + 1
 local v = (tx:byte(1) * 0x1000000) + (tx:byte(2) * 0x10000) + (tx:byte(3) * 0x100) + tx:byte(4)
 array = array .. "," .. v
end

# Tests

- Bootcode
  - (1) If flag is not AAAA, execute main with registers unset (*)
  - If flag is AAAA, evaluate pointer:
    - (2) Incorrect pointer leads to a mass erase
    - (3) Correct pointer leads to setting the registers with the correct values (* - TI will only set them after a reboot i think, maybe it's only set by the global init fn?)
  - (4) If pointer is already saved, do not evaluate a new struct, even with AAAA
- Configuration registers
  - (5) If lock is enabled, cannot write them
  - (6) If lock is not enabled, changing them leads to changed protection
- Protection against untrusted code
  - (7) Reading protected values returns 3fff
  - (8) Writing protected values has no effect
  - (9) Jumping to anything other than the starting address causes a reset (?)
- Protection against debugger (from HW?)
  - (10) Reading protected values returns 3fff
  - (11) Writing protected values has no effect
  - (12) Cannot set breakpoints on protected code
- Protection against DMA (from HW?)
  - (13) Reading protected values returns 3fff
  - (14) Writing protected values has no effect
- Benign behavior
  - (15) Code inside can read and write data, jump anywhere
- Known attacks explicitly
  - (16) CALL
  - (17) Interrupt handler (overwriting data with the saved reti address on the stack)  !!! THIS IS BROKEN !!!
- Attacks against the bootcode
  - (18) Overwriting the bootcode from software
  - (19) Overwriting the bootcode from the debugger
  - (20) Overwriting the bootcode from DMA
  - (21) Using the bootcode as a ROP gadget

Every test except for (*) should also be run on TI.

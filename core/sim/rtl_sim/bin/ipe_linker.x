OUTPUT_ARCH(msp430)

MEMORY {
  SFR              : ORIGIN = 0x0000, LENGTH = 0x0010 /* END=0x0010, size 16 */
  RAM              : ORIGIN = PER_SIZE, LENGTH = DMEM_SIZE /* END=0x09FF, size 2048 */
  INFOMEM          : ORIGIN = 0x1000, LENGTH = 0x0100 /* END=0x10FF, size 256 as 2 128-byte segments */
  INFOA            : ORIGIN = 0x1080, LENGTH = 0x0080 /* END=0x10FF, size 128 */
  INFOB            : ORIGIN = 0x1000, LENGTH = 0x0080 /* END=0x107F, size 128 */
  
  ROM (rx)         : ORIGIN = PMEM_BASE, LENGTH = PMEM_SIZE /* END=0xFFDF, size 61152 */

  bootcode  (rwx)   : ORIGIN = BMEM_BASE, LENGTH = BMEM_TOTAL_SIZE
  bootcode_ivt (rw) : ORIGIN = BMEM_IVT_BASE, LENGTH = 0x20
  fw_trampoline (rwx) : ORIGIN = BMEM_TRAMPOLINE_BASE, LENGTH = 0x4

  ipe_seg   (rwx)   : ORIGIN = 0x8000,    LENGTH = 0x6400
  ipe_padding (rw) :  ORIGIN = 0xe3de,    LENGTH = 0x2
  ipe_vectors (rw)  : ORIGIN = 0xe3e0,    LENGTH = 0x20
  ipe_meta  (rw)    : ORIGIN = 0xff88,    LENGTH = 0x4

  vectors   (rw)    : ORIGIN = 0xffe0,    LENGTH = 0x20

  VECT1            : ORIGIN = 0xFFE0, LENGTH = 0x0002
  VECT2            : ORIGIN = 0xFFE2, LENGTH = 0x0002
  VECT3            : ORIGIN = 0xFFE4, LENGTH = 0x0002
  VECT4            : ORIGIN = 0xFFE6, LENGTH = 0x0002
  VECT5            : ORIGIN = 0xFFE8, LENGTH = 0x0002
  VECT6            : ORIGIN = 0xFFEA, LENGTH = 0x0002
  VECT7            : ORIGIN = 0xFFEC, LENGTH = 0x0002
  VECT8            : ORIGIN = 0xFFEE, LENGTH = 0x0002
  VECT9            : ORIGIN = 0xFFF0, LENGTH = 0x0002
  VECT10           : ORIGIN = 0xFFF2, LENGTH = 0x0002
  VECT11           : ORIGIN = 0xFFF4, LENGTH = 0x0002
  VECT12           : ORIGIN = 0xFFF6, LENGTH = 0x0002
  VECT13           : ORIGIN = 0xFFF8, LENGTH = 0x0002
  VECT14           : ORIGIN = 0xFFFA, LENGTH = 0x0002
  VECT15           : ORIGIN = 0xFFFC, LENGTH = 0x0002
  RESETVEC         : ORIGIN = 0xFFFE, LENGTH = 0x0002

  irq_num (rwx)     : ORIGIN = 0xffb0,    LENGTH = 0x2
}

SECTIONS
{
  __interrupt_vector_1   : { KEEP (*(__interrupt_vector_1 )) } > VECT1
  __interrupt_vector_2   : { KEEP (*(__interrupt_vector_2 )) KEEP (*(__interrupt_vector_port2)) } > VECT2
  __interrupt_vector_3   : { KEEP (*(__interrupt_vector_3 )) KEEP (*(__interrupt_vector_usart1tx)) } > VECT3
  __interrupt_vector_4   : { KEEP (*(__interrupt_vector_4 )) KEEP (*(__interrupt_vector_usart1rx)) } > VECT4
  __interrupt_vector_5   : { KEEP (*(__interrupt_vector_5 )) KEEP (*(__interrupt_vector_port1)) } > VECT5
  __interrupt_vector_6   : { KEEP (*(__interrupt_vector_6 )) KEEP (*(__interrupt_vector_timera1)) } > VECT6
  __interrupt_vector_7   : { KEEP (*(__interrupt_vector_7 )) KEEP (*(__interrupt_vector_timera0)) } > VECT7
  __interrupt_vector_8   : { KEEP (*(__interrupt_vector_8 )) KEEP (*(__interrupt_vector_adc12)) } > VECT8
  __interrupt_vector_9   : { KEEP (*(__interrupt_vector_9 )) KEEP (*(__interrupt_vector_usart0tx)) } > VECT9
  __interrupt_vector_10  : { KEEP (*(__interrupt_vector_10)) KEEP (*(__interrupt_vector_usart0rx)) } > VECT10
  __interrupt_vector_11  : { KEEP (*(__interrupt_vector_11)) KEEP (*(__interrupt_vector_wdt)) } > VECT11
  __interrupt_vector_12  : { KEEP (*(__interrupt_vector_12)) KEEP (*(__interrupt_vector_comparatora)) } > VECT12
  __interrupt_vector_13  : { KEEP (*(__interrupt_vector_13)) KEEP (*(__interrupt_vector_timerb1)) } > VECT13
  __interrupt_vector_14  : { KEEP (*(__interrupt_vector_14)) KEEP (*(__interrupt_vector_timerb0)) } > VECT14
  __interrupt_vector_15  : { KEEP (*(__interrupt_vector_15)) KEEP (*(__interrupt_vector_nmi)) } > VECT15
  __reset_vector :
  {
    KEEP (*(__interrupt_vector_16))
    KEEP (*(__interrupt_vector_reset))
    KEEP (*(.resetvec))
  } > RESETVEC

  .vectors  :
  {
    PROVIDE (__vectors_start = .) ;
    *(.vectors*)
    _vectors_end = . ;
  }  > vectors

  .rodata :
  {
    . = ALIGN(2);
    *(.plt)
    *(.rodata .rodata.* .gnu.linkonce.r.* .const .const:*)
    *(.rodata1)
    KEEP (*(.gcc_except_table)) *(.gcc_except_table.*)
  } > ROM

  /* Note: This is a separate .rodata section for sections which are
     read only but which older linkers treat as read-write.
     This prevents older linkers from marking the entire .rodata
     section as read-write.  */
  .rodata2 :
  {
    . = ALIGN(2);
    PROVIDE (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE (__preinit_array_end = .);
    . = ALIGN(2);
    PROVIDE (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array))
    PROVIDE (__init_array_end = .);
    . = ALIGN(2);
    PROVIDE (__fini_array_start = .);
    KEEP (*(.fini_array))
    KEEP (*(SORT(.fini_array.*)))
    PROVIDE (__fini_array_end = .);
    . = ALIGN(2);
    *(.eh_frame_hdr)
    KEEP (*(.eh_frame))

    /* gcc uses crtbegin.o to find the start of the constructors, so
       we make sure it is first.  Because this is a wildcard, it
       doesn't matter if the user does not actually link against
       crtbegin.o; the linker won't look for a file to match a
       wildcard.  The wildcard also means that it doesn't matter which
       directory crtbegin.o is in.  */
    KEEP (*crtbegin*.o(.ctors))

    /* We don't want to include the .ctor section from the crtend.o
       file until after the sorted ctors.  The .ctor section from
       the crtend file contains the end of ctors marker and it must
       be last */
    KEEP (*(EXCLUDE_FILE (*crtend*.o ) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))

    KEEP (*crtbegin*.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend*.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
  } > ROM

  .text :
  {
    . = ALIGN(2);
    PROVIDE (_start = .);
    KEEP (*(SORT(.crt_*)))
    *(.lowtext .text .stub .text.* .gnu.linkonce.t.* .text:*)
    KEEP (*(.text.*personality*))
    /* .gnu.warning sections are handled specially by elf32.em.  */
    *(.gnu.warning)
    *(.interp .hash .dynsym .dynstr .gnu.version*)
    PROVIDE (__etext = .);
    PROVIDE (_etext = .);
    PROVIDE (etext = .);
    . = ALIGN(2);
    KEEP (*(.init))
    KEEP (*(.fini))
    KEEP (*(.tm_clone_table))
  } > ROM

  .data :
  {
    . = ALIGN(2);
    PROVIDE (__datastart = .);

    KEEP (*(.jcr))
    *(.data.rel.ro.local) *(.data.rel.ro*)
    *(.dynamic)

    *(.data .data.* .gnu.linkonce.d.*)
    KEEP (*(.gnu.linkonce.d.*personality*))
    SORT(CONSTRUCTORS)
    *(.data1)
    *(.got.plt) *(.got)

    /* We want the small data sections together, so single-instruction offsets
       can access them all, and initialized data all before uninitialized, so
       we can shorten the on-disk segment size.  */
    . = ALIGN(2);
    *(.sdata .sdata.* .gnu.linkonce.s.* D_2 D_1)

    . = ALIGN(2);
    _edata = .;
    PROVIDE (edata = .);
    PROVIDE (__dataend = .);
  } > RAM AT>ROM

  /* Note that crt0 assumes this is a multiple of two; all the
     start/stop symbols are also assumed word-aligned.  */
  PROVIDE(__romdatastart = LOADADDR(.data));
  PROVIDE (__romdatacopysize = SIZEOF(.data));

  .bss :
  {
    . = ALIGN(2);
    PROVIDE (__bssstart = .);
    *(.dynbss)
    *(.sbss .sbss.*)
    *(.bss .bss.* .gnu.linkonce.b.*)
    . = ALIGN(2);
    *(COMMON)
    PROVIDE (__bssend = .);
  } > RAM
  PROVIDE (__bsssize = SIZEOF(.bss));

  /* This section contains data that is not initialised during load
     or application reset.  */
  .noinit (NOLOAD) :
  {
    . = ALIGN(2);
    PROVIDE (__noinit_start = .);
    *(.noinit)
    . = ALIGN(2);
    PROVIDE (__noinit_end = .);
    end = .;
  } > RAM

  /* We create this section so that "end" will always be in the
     RAM region (matching .stack below), even if the .bss
     section is empty.  */
  .heap (NOLOAD) :
  {
    . = ALIGN(2);
    __heap_start__ = .;
    _end = __heap_start__;
    PROVIDE (end = .);
    KEEP (*(.heap))
    _end = .;
    PROVIDE (end = .);
    /* This word is here so that the section is not empty, and thus
       not discarded by the linker.  The actual value does not matter
       and is ignored.  */
    LONG(0);
    __heap_end__ = .;
    __HeapLimit = __heap_end__;
  } > RAM
  /* WARNING: Do not place anything in RAM here.
     The heap section must be the last section in RAM and the stack
     section must be placed at the very end of the RAM region.  */

  .stack (ORIGIN (RAM) + LENGTH(RAM)) :
  {
    PROVIDE (__stack = .);
    *(.stack)
  }

  .bootcode  :
  {
     PROVIDE (__bootcode_start = .) ;
    *(.bootcode)
     _bootcode_end = . ;
  }  > bootcode
  .bootcode_ivt  :
  {
     PROVIDE (__bootcode_ivt_start = .) ;
    *(.bootcode_ivt*)
     _bootcode_ivt_end = . ;
  }  > bootcode_ivt

  .fw_trampoline :
  {
    PROVIDE(__fw_trampoline = .);
    *(.fw_trampoline)
  } > fw_trampoline

  .irq_num :
  {
    PROVIDE(__irq_num = .);
    *(.irq_num)
  } > irq_num

  .ipe_seg  :
  {
    PROVIDE (__ipe_seg_start = .) ;
    PROVIDE(__ipe_struct = .);
    *(.ipestruct*)     /* IPE Data structure                */
    __ipe_rx_start = .;
    *(.ipe_hw_entry*)  /* IPE Single entry point            */
    *(.ipe_func*)      /* IPE functions                     */
    *(.ipe_entry*)     /* IPE entry functions               */
    __ipe_isr_start = .;
    *(.ipe:_isr*)      /* IPE ISRs                          */
    *(.ipe_const*)     /* IPE Protected constants           */
    __ipe_rx_end = .;
    __ipe_rw_start = .;
    *(.ipe_vars*)      /* IPE variables                     */
  }  > ipe_seg
  .ipe_stack :
  {
      . = ALIGN(2);
      PROVIDE (ipe_sp = .);
      . += 2;
      /* NOTE: ensure IPE stack is large enough(!) */
      . += 0x4000;
      PROVIDE(ipe_base_stack = .);
     . += 2;
  } > ipe_seg

  .ipe_padding :
  {
    PROVIDE(__ipe_padding = .);
    *(.ipe_padding)
  } > ipe_padding

  .ipe_vectors  :
  {
     PROVIDE (__ipe_vectors_start = .) ;
    *(.ipe_vectors*)
     _ipe_vectors_end = . ;
  }  > ipe_vectors

  __ipe_rw_end = .;
  __ipe_seg_end = . ;

  .ipe_meta  :
  {
    *(.ipe_meta*);
    __ipe_struct_shift = __ipe_struct >> 4;
  }  > ipe_meta

  /* symbol values used in struct initialization (note: no XOR, so we have to use AND, NOT and OR) */
  __ipe_start_shift = __ipe_seg_start >> 4;
  __ipe_end_shift = __ipe_seg_end >> 4;
  __ipe_checksum_pt1 = (~ 0xFFFF & 0xC0) | (0xFFFF & ~ 0xC0);
  __ipe_checksum_pt2 = (~ __ipe_checksum_pt1 & __ipe_start_shift) | (__ipe_checksum_pt1 & ~ __ipe_start_shift);
  __ipe_checksum = (~ __ipe_checksum_pt2 & __ipe_end_shift) | (__ipe_checksum_pt2 & ~ __ipe_end_shift);


  .infoA     : {} > INFOA              /* MSP430 INFO FLASH MEMORY SEGMENTS */
  .infoB     : {} > INFOB

  /* The rest are all not normally part of the runtime image.  */

  .MSP430.attributes 0 :
  {
    KEEP (*(.MSP430.attributes))
    KEEP (*(.gnu.attributes))
    KEEP (*(__TI_build_attributes))
  }

  /* Stabs debugging sections.  */
  .stab          0 : { *(.stab) }
  .stabstr       0 : { *(.stabstr) }
  .stab.excl     0 : { *(.stab.excl) }
  .stab.exclstr  0 : { *(.stab.exclstr) }
  .stab.index    0 : { *(.stab.index) }
  .stab.indexstr 0 : { *(.stab.indexstr) }
  .comment       0 : { *(.comment) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1.  */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions.  */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2.  */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2.  */
  .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line .debug_line.* .debug_line_end ) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  /* SGI/MIPS DWARF 2 extensions.  */
  .debug_weaknames 0 : { *(.debug_weaknames) }
  .debug_funcnames 0 : { *(.debug_funcnames) }
  .debug_typenames 0 : { *(.debug_typenames) }
  .debug_varnames  0 : { *(.debug_varnames) }
  /* DWARF 3 */
  .debug_pubtypes 0 : { *(.debug_pubtypes) }
  .debug_ranges   0 : { *(.debug_ranges) }
  /* DWARF Extension.  */
  .debug_macro    0 : { *(.debug_macro) }

  /DISCARD/ : { *(.note.GNU-stack) }
}


/************************************************************
* SPECIAL FUNCTION REGISTER ADDRESSES + CONTROL BITS
************************************************************/
PROVIDE(IE1                = 0x0000);
PROVIDE(IFG1               = 0x0002);
PROVIDE(ME1                = 0x0004);
PROVIDE(IE2                = 0x0001);
PROVIDE(IFG2               = 0x0003);
PROVIDE(ME2                = 0x0005);
/************************************************************
* WATCHDOG TIMER
************************************************************/
PROVIDE(WDTCTL             = 0x0120);
/************************************************************
* HARDWARE MULTIPLIER
************************************************************/
PROVIDE(MPY                = 0x0130);
PROVIDE(MPYS               = 0x0132);
PROVIDE(MAC                = 0x0134);
PROVIDE(MACS               = 0x0136);
PROVIDE(OP2                = 0x0138);
PROVIDE(RESLO              = 0x013A);
PROVIDE(RESHI              = 0x013C);
PROVIDE(SUMEXT             = 0x013E);
/************************************************************
* DIGITAL I/O Port1/2
************************************************************/
PROVIDE(P1IN               = 0x0020);
PROVIDE(P1OUT              = 0x0021);
PROVIDE(P1DIR              = 0x0022);
PROVIDE(P1IFG              = 0x0023);
PROVIDE(P1IES              = 0x0024);
PROVIDE(P1IE               = 0x0025);
PROVIDE(P1SEL              = 0x0026);
PROVIDE(P2IN               = 0x0028);
PROVIDE(P2OUT              = 0x0029);
PROVIDE(P2DIR              = 0x002A);
PROVIDE(P2IFG              = 0x002B);
PROVIDE(P2IES              = 0x002C);
PROVIDE(P2IE               = 0x002D);
PROVIDE(P2SEL              = 0x002E);
/************************************************************
* DIGITAL I/O Port3/4
************************************************************/
PROVIDE(P3IN               = 0x0018);
PROVIDE(P3OUT              = 0x0019);
PROVIDE(P3DIR              = 0x001A);
PROVIDE(P3SEL              = 0x001B);
PROVIDE(P4IN               = 0x001C);
PROVIDE(P4OUT              = 0x001D);
PROVIDE(P4DIR              = 0x001E);
PROVIDE(P4SEL              = 0x001F);
/************************************************************
* DIGITAL I/O Port5/6
************************************************************/
PROVIDE(P5IN               = 0x0030);
PROVIDE(P5OUT              = 0x0031);
PROVIDE(P5DIR              = 0x0032);
PROVIDE(P5SEL              = 0x0033);
PROVIDE(P6IN               = 0x0034);
PROVIDE(P6OUT              = 0x0035);
PROVIDE(P6DIR              = 0x0036);
PROVIDE(P6SEL              = 0x0037);
/************************************************************
* USART
************************************************************/
/************************************************************
* USART 0
************************************************************/
PROVIDE(U0CTL              = 0x0070);
PROVIDE(U0TCTL             = 0x0071);
PROVIDE(U0RCTL             = 0x0072);
PROVIDE(U0MCTL             = 0x0073);
PROVIDE(U0BR0              = 0x0074);
PROVIDE(U0BR1              = 0x0075);
PROVIDE(U0RXBUF            = 0x0076);
PROVIDE(U0TXBUF            = 0x0077);
/************************************************************
* USART 1
************************************************************/
PROVIDE(U1CTL              = 0x0078);
PROVIDE(U1TCTL             = 0x0079);
PROVIDE(U1RCTL             = 0x007A);
PROVIDE(U1MCTL             = 0x007B);
PROVIDE(U1BR0              = 0x007C);
PROVIDE(U1BR1              = 0x007D);
PROVIDE(U1RXBUF            = 0x007E);
PROVIDE(U1TXBUF            = 0x007F);
/************************************************************
* Timer A3
************************************************************/
PROVIDE(TAIV               = 0x012E);
PROVIDE(TACTL              = 0x0160);
PROVIDE(TACCTL0            = 0x0162);
PROVIDE(TACCTL1            = 0x0164);
PROVIDE(TACCTL2            = 0x0166);
PROVIDE(TAR                = 0x0170);
PROVIDE(TACCR0             = 0x0172);
PROVIDE(TACCR1             = 0x0174);
PROVIDE(TACCR2             = 0x0176);
/************************************************************
* Timer B7
************************************************************/
PROVIDE(TBIV               = 0x011E);
PROVIDE(TBCTL              = 0x0180);
PROVIDE(TBCCTL0            = 0x0182);
PROVIDE(TBCCTL1            = 0x0184);
PROVIDE(TBCCTL2            = 0x0186);
PROVIDE(TBCCTL3            = 0x0188);
PROVIDE(TBCCTL4            = 0x018A);
PROVIDE(TBCCTL5            = 0x018C);
PROVIDE(TBCCTL6            = 0x018E);
PROVIDE(TBR                = 0x0190);
PROVIDE(TBCCR0             = 0x0192);
PROVIDE(TBCCR1             = 0x0194);
PROVIDE(TBCCR2             = 0x0196);
PROVIDE(TBCCR3             = 0x0198);
PROVIDE(TBCCR4             = 0x019A);
PROVIDE(TBCCR5             = 0x019C);
PROVIDE(TBCCR6             = 0x019E);
/************************************************************
* Basic Clock Module
************************************************************/
PROVIDE(DCOCTL             = 0x0056);
PROVIDE(BCSCTL1            = 0x0057);
PROVIDE(BCSCTL2            = 0x0058);
/*************************************************************
* Flash Memory
*************************************************************/
PROVIDE(FCTL1              = 0x0128);
PROVIDE(FCTL2              = 0x012A);
PROVIDE(FCTL3              = 0x012C);
/************************************************************
* Comparator A
************************************************************/
PROVIDE(CACTL1             = 0x0059);
PROVIDE(CACTL2             = 0x005A);
PROVIDE(CAPD               = 0x005B);
/************************************************************
* ADC12
************************************************************/
PROVIDE(ADC12CTL0          = 0x01A0);
PROVIDE(ADC12CTL1          = 0x01A2);
PROVIDE(ADC12IFG           = 0x01A4);
PROVIDE(ADC12IE            = 0x01A6);
PROVIDE(ADC12IV            = 0x01A8);
PROVIDE(ADC12MEM0          = 0x0140);
PROVIDE(ADC12MEM1          = 0x0142);
PROVIDE(ADC12MEM2          = 0x0144);
PROVIDE(ADC12MEM3          = 0x0146);
PROVIDE(ADC12MEM4          = 0x0148);
PROVIDE(ADC12MEM5          = 0x014A);
PROVIDE(ADC12MEM6          = 0x014C);
PROVIDE(ADC12MEM7          = 0x014E);
PROVIDE(ADC12MEM8          = 0x0150);
PROVIDE(ADC12MEM9          = 0x0152);
PROVIDE(ADC12MEM10         = 0x0154);
PROVIDE(ADC12MEM11         = 0x0156);
PROVIDE(ADC12MEM12         = 0x0158);
PROVIDE(ADC12MEM13         = 0x015A);
PROVIDE(ADC12MEM14         = 0x015C);
PROVIDE(ADC12MEM15         = 0x015E);
PROVIDE(ADC12MCTL0         = 0x0080);
PROVIDE(ADC12MCTL1         = 0x0081);
PROVIDE(ADC12MCTL2         = 0x0082);
PROVIDE(ADC12MCTL3         = 0x0083);
PROVIDE(ADC12MCTL4         = 0x0084);
PROVIDE(ADC12MCTL5         = 0x0085);
PROVIDE(ADC12MCTL6         = 0x0086);
PROVIDE(ADC12MCTL7         = 0x0087);
PROVIDE(ADC12MCTL8         = 0x0088);
PROVIDE(ADC12MCTL9         = 0x0089);
PROVIDE(ADC12MCTL10        = 0x008A);
PROVIDE(ADC12MCTL11        = 0x008B);
PROVIDE(ADC12MCTL12        = 0x008C);
PROVIDE(ADC12MCTL13        = 0x008D);
PROVIDE(ADC12MCTL14        = 0x008E);
PROVIDE(ADC12MCTL15        = 0x008F);
/************************************************************
* Interrupt Vectors (offset from 0xFFE0)
************************************************************/


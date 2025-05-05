/* Default linker script, for IPE-enabled executables */

OUTPUT_FORMAT("elf32-msp430","elf32-msp430","elf32-msp430")
OUTPUT_ARCH("msp430")

MEMORY
{
  data      (rwx)   : ORIGIN = PER_SIZE,  LENGTH = DMEM_SIZE
  bootcode  (rwx)   : ORIGIN = BMEM_BASE, LENGTH = BMEM_TOTAL_SIZE
  bootcode_ivt (rw) : ORIGIN = BMEM_IVT_BASE, LENGTH = 0x20
  fw_trampoline (rwx) : ORIGIN = BMEM_TRAMPOLINE_BASE, LENGTH = 0x4
  text      (rx)    : ORIGIN = PMEM_BASE, LENGTH = PMEM_SIZE
  ipe_seg   (rwx)   : ORIGIN = 0x8000,    LENGTH = 0x6400
  ipe_padding (rw) :  ORIGIN = 0xe3de,    LENGTH = 0x2
  ipe_vectors (rw)  : ORIGIN = 0xe3e0,    LENGTH = 0x20
  ipe_meta  (rw)    : ORIGIN = 0xff88,    LENGTH = 0x4
  vectors64 (rw)    : ORIGIN = 0xff80,    LENGTH = 0x40
  vectors32 (rw)    : ORIGIN = 0xffc0,    LENGTH = 0x20
  vectors   (rw)    : ORIGIN = 0xffe0,    LENGTH = 0x20
  irq_num (rwx)     : ORIGIN = 0xffb0,    LENGTH = 0x2
}
SECTIONS
{
  /* Read-only sections, merged into text segment.  */
  .hash          : { *(.hash)             }
  .dynsym        : { *(.dynsym)           }
  .dynstr        : { *(.dynstr)           }
  .gnu.version   : { *(.gnu.version)      }
  .gnu.version_d   : { *(.gnu.version_d)  }
  .gnu.version_r   : { *(.gnu.version_r)  }
  .rel.init      : { *(.rel.init) }
  .rela.init     : { *(.rela.init) }
  .rel.text      :
    {
      *(.rel.text)
      *(.rel.text.*)
      *(.rel.gnu.linkonce.t*)
    }
  .rela.text     :
    {
      *(.rela.text)
      *(.rela.text.*)
      *(.rela.gnu.linkonce.t*)
    }
  .rel.fini      : { *(.rel.fini) }
  .rela.fini     : { *(.rela.fini) }
  .rel.rodata    :
    {
      *(.rel.rodata)
      *(.rel.rodata.*)
      *(.rel.gnu.linkonce.r*)
    }
  .rela.rodata   :
    {
      *(.rela.rodata)
      *(.rela.rodata.*)
      *(.rela.gnu.linkonce.r*)
    }
  .rel.data      :
    {
      *(.rel.data)
      *(.rel.data.*)
      *(.rel.gnu.linkonce.d*)
    }
  .rela.data     :
    {
      *(.rela.data)
      *(.rela.data.*)
      *(.rela.gnu.linkonce.d*)
    }
  .rel.ctors     : { *(.rel.ctors)        }
  .rela.ctors    : { *(.rela.ctors)       }
  .rel.dtors     : { *(.rel.dtors)        }
  .rela.dtors    : { *(.rela.dtors)       }
  .rel.got       : { *(.rel.got)          }
  .rela.got      : { *(.rela.got)         }
  .rel.bss       : { *(.rel.bss)          }
  .rela.bss      : { *(.rela.bss)         }
  .rel.plt       : { *(.rel.plt)          }
  .rela.plt      : { *(.rela.plt)         }
  /* Internal text space.  */
  .text :
  {
    . = ALIGN(2);
    *(.init)
    *(.init0)  /* Start here after reset.  */
    *(.init1)
    *(.init2)  /* Copy data loop  */
    *(.init3)
    *(.init4)  /* Clear bss  */
    *(.init5)
    *(.init6)  /* C++ constructors.  */
    *(.init7)
    *(.init8)
    *(.init9)  /* Call main().  */
     __ctors_start = . ;
     *(.ctors)
     __ctors_end = . ;
     __dtors_start = . ;
     *(.dtors)
     __dtors_end = . ;
    . = ALIGN(2);
    *(.text)
    . = ALIGN(2);
    *(.text.*)
    . = ALIGN(2);
    *(.fini9)  /*   */
    *(.fini8)
    *(.fini7)
    *(.fini6)  /* C++ destructors.  */
    *(.fini5)
    *(.fini4)
    *(.fini3)
    *(.fini2)
    *(.fini1)
    *(.fini0)  /* Infinite loop after program termination.  */
    *(.fini)
     _etext = . ;
  }  > text
  .data   : AT (ADDR (.text) + SIZEOF (.text))
  {
     PROVIDE (__data_start = .) ;
    . = ALIGN(2);
    *(.data)
    . = ALIGN(2);
    *(.gnu.linkonce.d*)
    . = ALIGN(2);
     _edata = . ;
  }  > data
  .bss  SIZEOF(.data) + ADDR(.data) :
  {
     PROVIDE (__bss_start = .) ;
    *(.bss)
    *(COMMON)
     PROVIDE (__bss_end = .) ;
     _end = . ;
  }  > data
  _edata = . ;  /* Past last read-write (loadable) segment */
  PROVIDE (__data_load_start = LOADADDR(.data) );
  PROVIDE (__data_size = _edata - __data_start );
  PROVIDE (__bss_size = SIZEOF(.bss) );
  .noinit  SIZEOF(.bss) + ADDR(.bss) :
  {
     PROVIDE (__noinit_start = .) ;
    *(.noinit)
    *(COMMON)
     PROVIDE (__noinit_end = .) ;
     _end = . ;
  }  > data
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

  .vectors32  :
  {
     PROVIDE (__vectors32_start = .) ;
    *(.vectors32*)
     _vectors32_end = . ;
  }  > vectors32
  .vectors64  :
  {
     PROVIDE (__vectors64_start = .) ;
    *(.vectors64*)
     _vectors64_end = . ;
  }  > vectors64
  .vectors  :
  {
     PROVIDE (__vectors_start = .) ;
    *(.vectors*)
     _vectors_end = . ;
  }  > vectors
  /* Stabs debugging sections.  */
  .stab 0 : { *(.stab) }
  .stabstr 0 : { *(.stabstr) }
  .stab.excl 0 : { *(.stab.excl) }
  .stab.exclstr 0 : { *(.stab.exclstr) }
  .stab.index 0 : { *(.stab.index) }
  .stab.indexstr 0 : { *(.stab.indexstr) }
  .comment 0 : { *(.comment) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info) *(.gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  PROVIDE (__stack = STACK_INIT) ;
  PROVIDE (__data_start_rom = _etext) ;
  PROVIDE (__data_end_rom   = _etext + SIZEOF (.data)) ;
  PROVIDE (__noinit_start_rom = _etext + SIZEOF (.data)) ;
  PROVIDE (__noinit_end_rom = _etext + SIZEOF (.data) + SIZEOF (.noinit)) ;
}

__IE1 = 0x0000;
__IFG1 = 0x0002;
__ME1 = 0x0004;
__IE2 = 0x0001;
__IFG2 = 0x0003;
__ME2 = 0x0005;
__WDTCTL = 0x0120;
__MPY = 0x0130;
__MPYS = 0x0132;
__MAC = 0x0134;
__MACS = 0x0136;
__OP2 = 0x0138;
__RESLO = 0x013A;
__RESHI = 0x013C;
__SUMEXT = 0x013E;
__P1IN = 0x0020;
__P1OUT = 0x0021;
__P1DIR = 0x0022;
__P1IFG = 0x0023;
__P1IES = 0x0024;
__P1IE = 0x0025;
__P1SEL = 0x0026;
__P2IN = 0x0028;
__P2OUT = 0x0029;
__P2DIR = 0x002A;
__P2IFG = 0x002B;
__P2IES = 0x002C;
__P2IE = 0x002D;
__P2SEL = 0x002E;
__P3IN = 0x0018;
__P3OUT = 0x0019;
__P3DIR = 0x001A;
__P3SEL = 0x001B;
__P4IN = 0x001C;
__P4OUT = 0x001D;
__P4DIR = 0x001E;
__P4SEL = 0x001F;
__P5IN = 0x0030;
__P5OUT = 0x0031;
__P5DIR = 0x0032;
__P5SEL = 0x0033;
__P6IN = 0x0034;
__P6OUT = 0x0035;
__P6DIR = 0x0036;
__P6SEL = 0x0037;
__U0CTL = 0x0070;
__U0TCTL = 0x0071;
__U0RCTL = 0x0072;
__U0MCTL = 0x0073;
__U0BR0 = 0x0074;
__U0BR1 = 0x0075;
__U0RXBUF = 0x0076;
__U0TXBUF = 0x0077;
__U1CTL = 0x0078;
__U1TCTL = 0x0079;
__U1RCTL = 0x007A;
__U1MCTL = 0x007B;
__U1BR0 = 0x007C;
__U1BR1 = 0x007D;
__U1RXBUF = 0x007E;
__U1TXBUF = 0x007F;
__TAIV = 0x012E;
__TACTL = 0x0160;
__TACCTL0 = 0x0162;
__TACCTL1 = 0x0164;
__TACCTL2 = 0x0166;
__TAR = 0x0170;
__TACCR0 = 0x0172;
__TACCR1 = 0x0174;
__TACCR2 = 0x0176;
__TBIV = 0x011E;
__TBCTL = 0x0180;
__TBCCTL0 = 0x0182;
__TBCCTL1 = 0x0184;
__TBCCTL2 = 0x0186;
__TBCCTL3 = 0x0188;
__TBCCTL4 = 0x018A;
__TBCCTL5 = 0x018C;
__TBCCTL6 = 0x018E;
__TBR = 0x0190;
__TBCCR0 = 0x0192;
__TBCCR1 = 0x0194;
__TBCCR2 = 0x0196;
__TBCCR3 = 0x0198;
__TBCCR4 = 0x019A;
__TBCCR5 = 0x019C;
__TBCCR6 = 0x019E;
__DCOCTL = 0x0056;
__BCSCTL1 = 0x0057;
__BCSCTL2 = 0x0058;
__FCTL1 = 0x0128;
__FCTL2 = 0x012A;
__FCTL3 = 0x012C;
__CACTL1 = 0x0059;
__CACTL2 = 0x005A;
__CAPD = 0x005B;
__ADC12CTL0 = 0x01A0;
__ADC12CTL1 = 0x01A2;
__ADC12IFG = 0x01A4;
__ADC12IE = 0x01A6;
__ADC12IV = 0x01A8;
__ADC12MEM0 = 0x0140;
__ADC12MEM1 = 0x0142;
__ADC12MEM2 = 0x0144;
__ADC12MEM3 = 0x0146;
__ADC12MEM4 = 0x0148;
__ADC12MEM5 = 0x014A;
__ADC12MEM6 = 0x014C;
__ADC12MEM7 = 0x014E;
__ADC12MEM8 = 0x0150;
__ADC12MEM9 = 0x0152;
__ADC12MEM10 = 0x0154;
__ADC12MEM11 = 0x0156;
__ADC12MEM12 = 0x0158;
__ADC12MEM13 = 0x015A;
__ADC12MEM14 = 0x015C;
__ADC12MEM15 = 0x015E;
__ADC12MCTL0 = 0x0080;
__ADC12MCTL1 = 0x0081;
__ADC12MCTL2 = 0x0082;
__ADC12MCTL3 = 0x0083;
__ADC12MCTL4 = 0x0084;
__ADC12MCTL5 = 0x0085;
__ADC12MCTL6 = 0x0086;
__ADC12MCTL7 = 0x0087;
__ADC12MCTL8 = 0x0088;
__ADC12MCTL9 = 0x0089;
__ADC12MCTL10 = 0x008A;
__ADC12MCTL11 = 0x008B;
__ADC12MCTL12 = 0x008C;
__ADC12MCTL13 = 0x008D;
__ADC12MCTL14 = 0x008E;
__ADC12MCTL15 = 0x008F;
__IPE_ACTIVE = 0x05A8;
__MPUIPC0 =    0x05AA;
__MPUIPSEGB2 = 0x05AC;
__MPUIPSEGB1 = 0x05AE;

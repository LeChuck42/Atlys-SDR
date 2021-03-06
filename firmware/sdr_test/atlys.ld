/* Script for -z combreloc: combine and sort reloc sections */
OUTPUT_FORMAT("elf32-or1k", "elf32-or1k",
	      "elf32-or1k")
OUTPUT_ARCH(or1k)

MEMORY
{
	FLASH  (wx) : ORIGIN = 0x00000000, LENGTH = 0x0080000
	DDR    (wx) : ORIGIN = 0x00080000, LENGTH = 0x7F80000
}

ENTRY(_start)
SEARCH_DIR("=/opt/or1k-toolchain/or1k-elf/lib"); SEARCH_DIR("=/usr/local/lib"); SEARCH_DIR("=/lib"); SEARCH_DIR("=/usr/lib");

SECTIONS
{
  /* Read-only sections, merged into text segment: */
  PROVIDE (__executable_start = SEGMENT_START("text-segment", 0x0000)); . = SEGMENT_START("text-segment", 0x0000);
  .vectors   : { KEEP (*(.vectors)) } >FLASH
  .note.gnu.build-id : { *(.note.gnu.build-id) } >FLASH
  .hash           : { *(.hash) } >FLASH
  .gnu.hash       : { *(.gnu.hash) } >FLASH
  .dynsym         : { *(.dynsym) } >FLASH
  .dynstr         : { *(.dynstr) } >FLASH
  .gnu.version    : { *(.gnu.version) } >FLASH
  .gnu.version_d  : { *(.gnu.version_d) } >FLASH
  .gnu.version_r  : { *(.gnu.version_r) } >FLASH
  .rela.dyn       :
    {
      *(.rela.init)
      *(.rela.text .rela.text.* .rela.gnu.linkonce.t.*)
      *(.rela.fini)
      *(.rela.rodata .rela.rodata.* .rela.gnu.linkonce.r.*)
      *(.rela.data .rela.data.* .rela.gnu.linkonce.d.*)
      *(.rela.tdata .rela.tdata.* .rela.gnu.linkonce.td.*)
      *(.rela.tbss .rela.tbss.* .rela.gnu.linkonce.tb.*)
      *(.rela.ctors)
      *(.rela.dtors)
      *(.rela.got)
      *(.rela.sdata .rela.sdata.* .rela.gnu.linkonce.s.*)
      *(.rela.sbss .rela.sbss.* .rela.gnu.linkonce.sb.*)
      *(.rela.sdata2 .rela.sdata2.* .rela.gnu.linkonce.s2.*)
      *(.rela.sbss2 .rela.sbss2.* .rela.gnu.linkonce.sb2.*)
      *(.rela.bss .rela.bss.* .rela.gnu.linkonce.b.*)
      PROVIDE_HIDDEN (__rel_iplt_start = .);
      PROVIDE_HIDDEN (__rel_iplt_end = .);
      PROVIDE_HIDDEN (__rela_iplt_start = .);
      *(.rela.iplt)
      PROVIDE_HIDDEN (__rela_iplt_end = .);
    } >FLASH
  .rela.plt       :
    {
      *(.rela.plt)
    } >FLASH

  .config :
  {
  	KEEP (*(.config))
  } >FLASH
  
  .init :
  {
    KEEP (*(SORT_NONE(.init)))
  } >FLASH =0x15000000
  .plt            : { *(.plt) } >FLASH
  .iplt           : { *(.iplt) } >FLASH
  .text           :
  {
    *(.text.unlikely .text.*_unlikely .text.unlikely.*)
    *(.text.exit .text.exit.*)
    *(.text.startup .text.startup.*)
    *(.text.hot .text.hot.*)
    *(.text .stub .text.* .gnu.linkonce.t.*)
    /* .gnu.warning sections are handled specially by elf32.em.  */
    *(.gnu.warning)
  } >FLASH =0x15000000
  .fini           :
  {
    KEEP (*(SORT_NONE(.fini)))
  } >FLASH =0x15000000
  PROVIDE (__etext = .);
  PROVIDE (_etext = .);
  PROVIDE (etext = .);
  .rodata         : { *(.rodata .rodata.* .gnu.linkonce.r.*) 
                       . = ALIGN(4);
                       } >FLASH
  .rodata1        : { *(.rodata1) } >FLASH
  .sdata2         :
  {
    *(.sdata2 .sdata2.* .gnu.linkonce.s2.*)
  } >FLASH
  .sbss2          : { *(.sbss2 .sbss2.* .gnu.linkonce.sb2.*) } >FLASH
  .eh_frame_hdr : { *(.eh_frame_hdr) } >FLASH
  .eh_frame       : ONLY_IF_RO { KEEP (*(.eh_frame)) } >FLASH
  .gcc_except_table   : ONLY_IF_RO { *(.gcc_except_table
  .gcc_except_table.*) } >FLASH
  /* These sections are generated by the Sun/Oracle C++ compiler.  */
  .exception_ranges   : ONLY_IF_RO { *(.exception_ranges
  .exception_ranges*) } >FLASH
  /* Adjust the address for the data segment.  We want to adjust up to
     the same address within the page on the next page up.  */

  /*. = ALIGN (CONSTANT (MAXPAGESIZE)) - ((CONSTANT (MAXPAGESIZE) - .) & (CONSTANT (MAXPAGESIZE) - 1));*/
  /*. = DATA_SEGMENT_ALIGN (CONSTANT (MAXPAGESIZE), CONSTANT (COMMONPAGESIZE));*/
  . = ALIGN(4);
  __data_load = .;
  /* Exception handling  */
  .eh_frame       : ONLY_IF_RW { __data_start = DEFINED(__data_start) ? __data_start : .; KEEP (*(.eh_frame)) } > FLASH
  .gcc_except_table   : ONLY_IF_RW { __data_start = DEFINED(__data_start) ? __data_start : .; *(.gcc_except_table .gcc_except_table.*) } > FLASH
  .exception_ranges   : ONLY_IF_RW { __data_start = DEFINED(__data_start) ? __data_start : .; *(.exception_ranges .exception_ranges*) } > FLASH
  /* Thread Local Storage sections  */
  .tdata	  : { __data_start = DEFINED(__data_start) ? __data_start : .; *(.tdata .tdata.* .gnu.linkonce.td.*) } > FLASH
  .tbss		  : { *(.tbss .tbss.* .gnu.linkonce.tb.*) *(.tcommon) } > FLASH
  .preinit_array     :
  {
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  } > FLASH
  .init_array     :
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array ))
    PROVIDE_HIDDEN (__init_array_end = .);
  } > FLASH
  .fini_array     :
  {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array ))
    PROVIDE_HIDDEN (__fini_array_end = .);
  } > FLASH
  .ctors          :
  {
    /* gcc uses crtbegin.o to find the start of
       the constructors, so we make sure it is
       first.  Because this is a wildcard, it
       doesn't matter if the user does not
       actually link against crtbegin.o; the
       linker won't look for a file to match a
       wildcard.  The wildcard also means that it
       doesn't matter which directory crtbegin.o
       is in.  */
    KEEP (*crtbegin.o(.ctors))
    KEEP (*crtbegin?.o(.ctors))
    /* We don't want to include the .ctor section from
       the crtend.o file until after the sorted ctors.
       The .ctor section from the crtend file contains the
       end of ctors marker and it must be last */
    KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))
  } > FLASH
  .dtors          :
  {
    KEEP (*crtbegin.o(.dtors))
    KEEP (*crtbegin?.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
  } > FLASH
  .jcr            : { KEEP (*(.jcr)) } > FLASH
  .data.rel.ro : { *(.data.rel.ro.local* .gnu.linkonce.d.rel.ro.local.*) *(.data.rel.ro .data.rel.ro.* .gnu.linkonce.d.rel.ro.*) } > FLASH
  .dynamic        : { *(.dynamic) } > FLASH
  /*. = DATA_SEGMENT_RELRO_END (0, .);*/
  .data           :
  {
    *(.data .data.* .gnu.linkonce.d.*)
    SORT(CONSTRUCTORS)
  } > FLASH 
  .data1          : { *(.data1) }> FLASH 
  .got            : { *(.got.plt) *(.igot.plt) *(.got) *(.igot) }> FLASH 
  /* We want the small data sections together, so single-instruction offsets
     can access them all, and initialized data all before uninitialized, so
     we can shorten the on-disk segment size.  */
  .sdata          :
  {
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  }> FLASH 
  /* programmer is executed from RAM */
  .programmer     :
  {
  	*(.programmer)
  }> FLASH
  _edata = .; PROVIDE (edata = .);
  . = ALIGN(32 / 8);
  .noinit         :
  {
  	*(.noinit)
  }> DDR
  . = ALIGN(32 / 8);
  .sbss           :
  {
  	__bss_start = .;
    *(.dynsbss)
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  }> DDR
  .bss            :
  {
   *(.dynbss)
   *(.bss .bss.* .gnu.linkonce.b.*)
   *(COMMON)
   /* Align here to ensure that the .bss section occupies space up to
      _end.  Align after .bss to ensure correct alignment even if the
      .bss section disappears because there are no input sections.
      FIXME: Why do we need it? When there is no .bss section, we don't
      pad the .data section.  */
   . = ALIGN(. != 0 ? 32 / 8 : 1);
  }>DDR
  . = ALIGN(32 / 8);
  . = SEGMENT_START("ldata-segment", .);
  . = ALIGN(32 / 8);
  _end = .; PROVIDE (end = .);
  /*. = DATA_SEGMENT_END (.);*/
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
  .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line .debug_line.* .debug_line_end ) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  /* SGI/MIPS DWARF 2 extensions */
  .debug_weaknames 0 : { *(.debug_weaknames) }
  .debug_funcnames 0 : { *(.debug_funcnames) }
  .debug_typenames 0 : { *(.debug_typenames) }
  .debug_varnames  0 : { *(.debug_varnames) }
  /* DWARF 3 */
  .debug_pubtypes 0 : { *(.debug_pubtypes) }
  .debug_ranges   0 : { *(.debug_ranges) }
  /* DWARF Extension.  */
  .debug_macro    0 : { *(.debug_macro) }
  .gnu.attributes 0 : { KEEP (*(.gnu.attributes)) }
  /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) }
}
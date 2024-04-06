;hex
;e9bb00000000000000000000000000180000000300000022fa2efe0617002e803e1700147303e991002ec606170000fb60066a0007bf1704268a050724100ac07502eb75066a0007bf4904268a05073c037602eb64b402cd1a33f62e88ac0c00462e888c0c00462e88b40c0033f633c033dbb903002e8aa70c008ac443c0ec04240f0530302e88a40300462e88840300462ec68403003a46e2db2ec5361300b90800ba4800fc066800b807bf900051ac268805474759e2f60761fbcd61cffab81c35cd21061f535ab86125cd21b81c252ec5160f00cd21fb066a0007bf170426c6051007b80331ba2000cd21
;-- section.seg_000:
  ;-- section.seg_001:
entry0(int16_t arg3);
; arg int16_t arg3 @ bx
0000:0000      jmp     0xbe        ; [01] -rwx section size 236 named seg_001
0000:0003      add     byte [bx + si], al
0000:0005      add     byte [bx + si], al
0000:0007      add     byte [bx + si], al
0000:0009      add     byte [bx + si], al
0000:000b      add     byte [bx + si], al
0000:000d      add     byte [bx + si], al
0000:000f      sbb     byte [bx + si], al
0000:0011      add     byte [bx + si], al; RELOC 16 
0000:0013      add     ax, word [bx + si]
0000:0015      add     byte [bx + si], al; RELOC 16 
0000:0017      and     bh, dl
0000:0019      inc     byte cs:[0x17]
0000:001e      cmp     byte cs:[0x17], 0x14
0000:0024      jae     0x29
0000:0026      jmp     0xba
0000:0029      mov     byte cs:[0x17], 0
0000:002f      sti
0000:0030      pushaw
0000:0031      push    es
0000:0032      push    0
0000:0034      pop     es
0000:0035      mov     di, 0x417   ; 1047
0000:0038      mov     al, byte es:[di]
0000:003b      pop     es
0000:003c      and     al, 0x10    ; 16
0000:003e      or      al, al
0000:0040      jne     0x44
0000:0042      jmp     0xb9
0000:0044      push    es
0000:0045      push    0
0000:0047      pop     es
0000:0048      mov     di, 0x449   ; 1097
0000:004b      mov     al, byte es:[di]
0000:004e      pop     es
0000:004f      cmp     al, 3       ; 3
0000:0051      jbe     0x55
0000:0053      jmp     0xb9
0000:0055      mov     ah, 2
0000:0057      int     0x1a
0000:0059      xor     si, si
0000:005b      mov     byte cs:[si + 0xc], ch
0000:0060      inc     si
0000:0061      mov     byte cs:[si + 0xc], cl
0000:0066      inc     si
0000:0067      mov     byte cs:[si + 0xc], dh
0000:006c      xor     si, si
0000:006e      xor     ax, ax
0000:0070      xor     bx, bx
0000:0072      mov     cx, 3
0000:0075      mov     ah, byte cs:[bx + 0xc]
0000:007a      mov     al, ah
0000:007c      inc     bx
0000:007d      shr     ah, 4
0000:0080      and     al, 0xf     ; 15
0000:0082      add     ax, 0x3030
0000:0085      mov     byte cs:[si + 3], ah
0000:008a      inc     si
0000:008b      mov     byte cs:[si + 3], al
0000:0090      inc     si
0000:0091      mov     byte cs:[si + 3], 0x3a ; ':' ; 58
0000:0097      inc     si
0000:0098      loop    0x75
0000:009a      lds     si, cs:[0x13]
0000:009f      mov     cx, 8
0000:00a2      mov     dx, 0x48    ; 'H' ; 72
0000:00a5      cld
0000:00a6      push    es
0000:00a7      push    0xb800
0000:00aa      pop     es
0000:00ab      mov     di, 0x90    ; 144
0000:00ae      push    cx
0000:00af      lodsb   al, byte [si]
0000:00b0      mov     byte es:[di], al
0000:00b3      inc     di
0000:00b4      inc     di
0000:00b5      pop     cx
0000:00b6      loop    0xae
0000:00b8      pop     es
0000:00b9      popaw
0000:00ba      sti
0000:00bb      int     0x61
0000:00bd      iret
0000:00be      cli
0000:00bf      mov     ax, 0x351c
0000:00c2      int     0x21
0000:00c4      push    es
0000:00c5      pop     ds
0000:00c6      push    bx          ; arg3
0000:00c7      pop     dx
0000:00c8      mov     ax, 0x2561  ; 'a%'
0000:00cb      int     0x21
0000:00cd      mov     ax, 0x251c  ; int16_t arg3
0000:00d0      lds     dx, cs:[0xf]
0000:00d5      int     0x21
0000:00d7      sti
0000:00d8      push    es
0000:00d9      push    0
0000:00db      pop     es
0000:00dc      mov     di, 0x417   ; 1047
0000:00df      mov     byte es:[di], 0x10 ; 16
0000:00e3      pop     es
0000:00e4      mov     ax, 0x3103
0000:00e7      mov     dx, 0x20    ; 32
0000:00ea      int     0x21

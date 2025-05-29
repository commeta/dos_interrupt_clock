
CLOCKOFF.COM:     формат файла binary


Дизассемблирование раздела .data:

00000000 <.data>:
   0:	b8 c2 0d             	mov    $0xdc2,%ax
   3:	cd 21                	int    $0x21
   5:	06                   	push   %es
   6:	53                   	push   %bx
   7:	b8 61 35             	mov    $0x3561,%ax
   a:	cd 21                	int    $0x21
   c:	06                   	push   %es
   d:	1f                   	pop    %ds
   e:	53                   	push   %bx
   f:	5a                   	pop    %dx
  10:	b8 1c 25             	mov    $0x251c,%ax
  13:	cd 21                	int    $0x21
  15:	06                   	push   %es
  16:	33 c0                	xor    %ax,%ax
  18:	8e c0                	mov    %ax,%es
  1a:	bf 17 04             	mov    $0x417,%di
  1d:	26 8a 05             	mov    %es:(%di),%al
  20:	24 ef                	and    $0xef,%al
  22:	26 88 05             	mov    %al,%es:(%di)
  25:	07                   	pop    %es
  26:	58                   	pop    %ax
  27:	07                   	pop    %es
  28:	83 e8 02             	sub    $0x2,%ax
  2b:	8b f8                	mov    %ax,%di
  2d:	26 8b 05             	mov    %es:(%di),%ax
  30:	48                   	dec    %ax
  31:	8e c0                	mov    %ax,%es
  33:	b4 49                	mov    $0x49,%ah
  35:	cd 21                	int    $0x21
  37:	73 08                	jae    0x41
  39:	04 30                	add    $0x30,%al
  3b:	8a d0                	mov    %al,%dl
  3d:	b4 02                	mov    $0x2,%ah
  3f:	cd 21                	int    $0x21
  41:	b8 00 4c             	mov    $0x4c00,%ax
  44:	cd 21                	int    $0x21

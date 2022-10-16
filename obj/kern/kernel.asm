
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 80 11 00       	mov    $0x118000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 03 01 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010004c:	81 c3 c0 72 01 00    	add    $0x172c0,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 60 90 11 f0    	mov    $0xf0119060,%edx
f0100058:	c7 c0 e0 96 11 f0    	mov    $0xf01196e0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 0f 3c 00 00       	call   f0103c78 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 37 05 00 00       	call   f01005a5 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 b4 cd fe ff    	lea    -0x1324c(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 f5 2f 00 00       	call   f0103077 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 9a 12 00 00       	call   f0101321 <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 1e 08 00 00       	call   f01008b2 <monitor>
f0100094:	83 c4 10             	add    $0x10,%esp
f0100097:	eb f1                	jmp    f010008a <i386_init+0x4a>

f0100099 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100099:	55                   	push   %ebp
f010009a:	89 e5                	mov    %esp,%ebp
f010009c:	56                   	push   %esi
f010009d:	53                   	push   %ebx
f010009e:	e8 ac 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f01000a3:	81 c3 69 72 01 00    	add    $0x17269,%ebx
	va_list ap;

	if (panicstr)
f01000a9:	83 bb 54 1d 00 00 00 	cmpl   $0x0,0x1d54(%ebx)
f01000b0:	74 0f                	je     f01000c1 <_panic+0x28>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000b2:	83 ec 0c             	sub    $0xc,%esp
f01000b5:	6a 00                	push   $0x0
f01000b7:	e8 f6 07 00 00       	call   f01008b2 <monitor>
f01000bc:	83 c4 10             	add    $0x10,%esp
f01000bf:	eb f1                	jmp    f01000b2 <_panic+0x19>
	panicstr = fmt;
f01000c1:	8b 45 10             	mov    0x10(%ebp),%eax
f01000c4:	89 83 54 1d 00 00    	mov    %eax,0x1d54(%ebx)
	asm volatile("cli; cld");
f01000ca:	fa                   	cli    
f01000cb:	fc                   	cld    
	va_start(ap, fmt);
f01000cc:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000cf:	83 ec 04             	sub    $0x4,%esp
f01000d2:	ff 75 0c             	push   0xc(%ebp)
f01000d5:	ff 75 08             	push   0x8(%ebp)
f01000d8:	8d 83 cf cd fe ff    	lea    -0x13231(%ebx),%eax
f01000de:	50                   	push   %eax
f01000df:	e8 93 2f 00 00       	call   f0103077 <cprintf>
	vcprintf(fmt, ap);
f01000e4:	83 c4 08             	add    $0x8,%esp
f01000e7:	56                   	push   %esi
f01000e8:	ff 75 10             	push   0x10(%ebp)
f01000eb:	e8 50 2f 00 00       	call   f0103040 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 85 d5 fe ff    	lea    -0x12a7b(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 79 2f 00 00       	call   f0103077 <cprintf>
f01000fe:	83 c4 10             	add    $0x10,%esp
f0100101:	eb af                	jmp    f01000b2 <_panic+0x19>

f0100103 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100103:	55                   	push   %ebp
f0100104:	89 e5                	mov    %esp,%ebp
f0100106:	56                   	push   %esi
f0100107:	53                   	push   %ebx
f0100108:	e8 42 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010010d:	81 c3 ff 71 01 00    	add    $0x171ff,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	push   0xc(%ebp)
f010011c:	ff 75 08             	push   0x8(%ebp)
f010011f:	8d 83 e7 cd fe ff    	lea    -0x13219(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 4c 2f 00 00       	call   f0103077 <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	push   0x10(%ebp)
f0100132:	e8 09 2f 00 00       	call   f0103040 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 85 d5 fe ff    	lea    -0x12a7b(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 32 2f 00 00       	call   f0103077 <cprintf>
	va_end(ap);
}
f0100145:	83 c4 10             	add    $0x10,%esp
f0100148:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010014b:	5b                   	pop    %ebx
f010014c:	5e                   	pop    %esi
f010014d:	5d                   	pop    %ebp
f010014e:	c3                   	ret    

f010014f <__x86.get_pc_thunk.bx>:
f010014f:	8b 1c 24             	mov    (%esp),%ebx
f0100152:	c3                   	ret    

f0100153 <serial_proc_data>:

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100153:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100158:	ec                   	in     (%dx),%al
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100159:	a8 01                	test   $0x1,%al
f010015b:	74 0a                	je     f0100167 <serial_proc_data+0x14>
f010015d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100162:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100163:	0f b6 c0             	movzbl %al,%eax
f0100166:	c3                   	ret    
		return -1;
f0100167:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f010016c:	c3                   	ret    

f010016d <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016d:	55                   	push   %ebp
f010016e:	89 e5                	mov    %esp,%ebp
f0100170:	57                   	push   %edi
f0100171:	56                   	push   %esi
f0100172:	53                   	push   %ebx
f0100173:	83 ec 1c             	sub    $0x1c,%esp
f0100176:	e8 6a 05 00 00       	call   f01006e5 <__x86.get_pc_thunk.si>
f010017b:	81 c6 91 71 01 00    	add    $0x17191,%esi
f0100181:	89 c7                	mov    %eax,%edi
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
f0100183:	8d 1d 94 1d 00 00    	lea    0x1d94,%ebx
f0100189:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f010018c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010018f:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	while ((c = (*proc)()) != -1) {
f0100192:	eb 25                	jmp    f01001b9 <cons_intr+0x4c>
		cons.buf[cons.wpos++] = c;
f0100194:	8b 8c 1e 04 02 00 00 	mov    0x204(%esi,%ebx,1),%ecx
f010019b:	8d 51 01             	lea    0x1(%ecx),%edx
f010019e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01001a1:	88 04 0f             	mov    %al,(%edi,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001a4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01001af:	0f 44 d0             	cmove  %eax,%edx
f01001b2:	89 94 1e 04 02 00 00 	mov    %edx,0x204(%esi,%ebx,1)
	while ((c = (*proc)()) != -1) {
f01001b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01001bc:	ff d0                	call   *%eax
f01001be:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001c1:	74 06                	je     f01001c9 <cons_intr+0x5c>
		if (c == 0)
f01001c3:	85 c0                	test   %eax,%eax
f01001c5:	75 cd                	jne    f0100194 <cons_intr+0x27>
f01001c7:	eb f0                	jmp    f01001b9 <cons_intr+0x4c>
	}
}
f01001c9:	83 c4 1c             	add    $0x1c,%esp
f01001cc:	5b                   	pop    %ebx
f01001cd:	5e                   	pop    %esi
f01001ce:	5f                   	pop    %edi
f01001cf:	5d                   	pop    %ebp
f01001d0:	c3                   	ret    

f01001d1 <kbd_proc_data>:
{
f01001d1:	55                   	push   %ebp
f01001d2:	89 e5                	mov    %esp,%ebp
f01001d4:	56                   	push   %esi
f01001d5:	53                   	push   %ebx
f01001d6:	e8 74 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01001db:	81 c3 31 71 01 00    	add    $0x17131,%ebx
f01001e1:	ba 64 00 00 00       	mov    $0x64,%edx
f01001e6:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001e7:	a8 01                	test   $0x1,%al
f01001e9:	0f 84 f7 00 00 00    	je     f01002e6 <kbd_proc_data+0x115>
	if (stat & KBS_TERR)
f01001ef:	a8 20                	test   $0x20,%al
f01001f1:	0f 85 f6 00 00 00    	jne    f01002ed <kbd_proc_data+0x11c>
f01001f7:	ba 60 00 00 00       	mov    $0x60,%edx
f01001fc:	ec                   	in     (%dx),%al
f01001fd:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001ff:	3c e0                	cmp    $0xe0,%al
f0100201:	74 64                	je     f0100267 <kbd_proc_data+0x96>
	} else if (data & 0x80) {
f0100203:	84 c0                	test   %al,%al
f0100205:	78 75                	js     f010027c <kbd_proc_data+0xab>
	} else if (shift & E0ESC) {
f0100207:	8b 8b 74 1d 00 00    	mov    0x1d74(%ebx),%ecx
f010020d:	f6 c1 40             	test   $0x40,%cl
f0100210:	74 0e                	je     f0100220 <kbd_proc_data+0x4f>
		data |= 0x80;
f0100212:	83 c8 80             	or     $0xffffff80,%eax
f0100215:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100217:	83 e1 bf             	and    $0xffffffbf,%ecx
f010021a:	89 8b 74 1d 00 00    	mov    %ecx,0x1d74(%ebx)
	shift |= shiftcode[data];
f0100220:	0f b6 d2             	movzbl %dl,%edx
f0100223:	0f b6 84 13 34 cf fe 	movzbl -0x130cc(%ebx,%edx,1),%eax
f010022a:	ff 
f010022b:	0b 83 74 1d 00 00    	or     0x1d74(%ebx),%eax
	shift ^= togglecode[data];
f0100231:	0f b6 8c 13 34 ce fe 	movzbl -0x131cc(%ebx,%edx,1),%ecx
f0100238:	ff 
f0100239:	31 c8                	xor    %ecx,%eax
f010023b:	89 83 74 1d 00 00    	mov    %eax,0x1d74(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100241:	89 c1                	mov    %eax,%ecx
f0100243:	83 e1 03             	and    $0x3,%ecx
f0100246:	8b 8c 8b f4 1c 00 00 	mov    0x1cf4(%ebx,%ecx,4),%ecx
f010024d:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100251:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100254:	a8 08                	test   $0x8,%al
f0100256:	74 61                	je     f01002b9 <kbd_proc_data+0xe8>
		if ('a' <= c && c <= 'z')
f0100258:	89 f2                	mov    %esi,%edx
f010025a:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f010025d:	83 f9 19             	cmp    $0x19,%ecx
f0100260:	77 4b                	ja     f01002ad <kbd_proc_data+0xdc>
			c += 'A' - 'a';
f0100262:	83 ee 20             	sub    $0x20,%esi
f0100265:	eb 0c                	jmp    f0100273 <kbd_proc_data+0xa2>
		shift |= E0ESC;
f0100267:	83 8b 74 1d 00 00 40 	orl    $0x40,0x1d74(%ebx)
		return 0;
f010026e:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100273:	89 f0                	mov    %esi,%eax
f0100275:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100278:	5b                   	pop    %ebx
f0100279:	5e                   	pop    %esi
f010027a:	5d                   	pop    %ebp
f010027b:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010027c:	8b 8b 74 1d 00 00    	mov    0x1d74(%ebx),%ecx
f0100282:	83 e0 7f             	and    $0x7f,%eax
f0100285:	f6 c1 40             	test   $0x40,%cl
f0100288:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010028b:	0f b6 d2             	movzbl %dl,%edx
f010028e:	0f b6 84 13 34 cf fe 	movzbl -0x130cc(%ebx,%edx,1),%eax
f0100295:	ff 
f0100296:	83 c8 40             	or     $0x40,%eax
f0100299:	0f b6 c0             	movzbl %al,%eax
f010029c:	f7 d0                	not    %eax
f010029e:	21 c8                	and    %ecx,%eax
f01002a0:	89 83 74 1d 00 00    	mov    %eax,0x1d74(%ebx)
		return 0;
f01002a6:	be 00 00 00 00       	mov    $0x0,%esi
f01002ab:	eb c6                	jmp    f0100273 <kbd_proc_data+0xa2>
		else if ('A' <= c && c <= 'Z')
f01002ad:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002b0:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002b3:	83 fa 1a             	cmp    $0x1a,%edx
f01002b6:	0f 42 f1             	cmovb  %ecx,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002b9:	f7 d0                	not    %eax
f01002bb:	a8 06                	test   $0x6,%al
f01002bd:	75 b4                	jne    f0100273 <kbd_proc_data+0xa2>
f01002bf:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01002c5:	75 ac                	jne    f0100273 <kbd_proc_data+0xa2>
		cprintf("Rebooting!\n");
f01002c7:	83 ec 0c             	sub    $0xc,%esp
f01002ca:	8d 83 01 ce fe ff    	lea    -0x131ff(%ebx),%eax
f01002d0:	50                   	push   %eax
f01002d1:	e8 a1 2d 00 00       	call   f0103077 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d6:	b8 03 00 00 00       	mov    $0x3,%eax
f01002db:	ba 92 00 00 00       	mov    $0x92,%edx
f01002e0:	ee                   	out    %al,(%dx)
}
f01002e1:	83 c4 10             	add    $0x10,%esp
f01002e4:	eb 8d                	jmp    f0100273 <kbd_proc_data+0xa2>
		return -1;
f01002e6:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002eb:	eb 86                	jmp    f0100273 <kbd_proc_data+0xa2>
		return -1;
f01002ed:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002f2:	e9 7c ff ff ff       	jmp    f0100273 <kbd_proc_data+0xa2>

f01002f7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002f7:	55                   	push   %ebp
f01002f8:	89 e5                	mov    %esp,%ebp
f01002fa:	57                   	push   %edi
f01002fb:	56                   	push   %esi
f01002fc:	53                   	push   %ebx
f01002fd:	83 ec 1c             	sub    $0x1c,%esp
f0100300:	e8 4a fe ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100305:	81 c3 07 70 01 00    	add    $0x17007,%ebx
f010030b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f010030e:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100313:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100318:	b9 84 00 00 00       	mov    $0x84,%ecx
f010031d:	89 fa                	mov    %edi,%edx
f010031f:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100320:	a8 20                	test   $0x20,%al
f0100322:	75 13                	jne    f0100337 <cons_putc+0x40>
f0100324:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010032a:	7f 0b                	jg     f0100337 <cons_putc+0x40>
f010032c:	89 ca                	mov    %ecx,%edx
f010032e:	ec                   	in     (%dx),%al
f010032f:	ec                   	in     (%dx),%al
f0100330:	ec                   	in     (%dx),%al
f0100331:	ec                   	in     (%dx),%al
	     i++)
f0100332:	83 c6 01             	add    $0x1,%esi
f0100335:	eb e6                	jmp    f010031d <cons_putc+0x26>
	outb(COM1 + COM_TX, c);
f0100337:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010033b:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010033e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100343:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100344:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100349:	bf 79 03 00 00       	mov    $0x379,%edi
f010034e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100353:	89 fa                	mov    %edi,%edx
f0100355:	ec                   	in     (%dx),%al
f0100356:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010035c:	7f 0f                	jg     f010036d <cons_putc+0x76>
f010035e:	84 c0                	test   %al,%al
f0100360:	78 0b                	js     f010036d <cons_putc+0x76>
f0100362:	89 ca                	mov    %ecx,%edx
f0100364:	ec                   	in     (%dx),%al
f0100365:	ec                   	in     (%dx),%al
f0100366:	ec                   	in     (%dx),%al
f0100367:	ec                   	in     (%dx),%al
f0100368:	83 c6 01             	add    $0x1,%esi
f010036b:	eb e6                	jmp    f0100353 <cons_putc+0x5c>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010036d:	ba 78 03 00 00       	mov    $0x378,%edx
f0100372:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0100376:	ee                   	out    %al,(%dx)
f0100377:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010037c:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100381:	ee                   	out    %al,(%dx)
f0100382:	b8 08 00 00 00       	mov    $0x8,%eax
f0100387:	ee                   	out    %al,(%dx)
		c |= 0x0700;
f0100388:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010038b:	89 f8                	mov    %edi,%eax
f010038d:	80 cc 07             	or     $0x7,%ah
f0100390:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100396:	0f 45 c7             	cmovne %edi,%eax
f0100399:	89 c7                	mov    %eax,%edi
f010039b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f010039e:	0f b6 c0             	movzbl %al,%eax
f01003a1:	89 f9                	mov    %edi,%ecx
f01003a3:	80 f9 0a             	cmp    $0xa,%cl
f01003a6:	0f 84 e4 00 00 00    	je     f0100490 <cons_putc+0x199>
f01003ac:	83 f8 0a             	cmp    $0xa,%eax
f01003af:	7f 46                	jg     f01003f7 <cons_putc+0x100>
f01003b1:	83 f8 08             	cmp    $0x8,%eax
f01003b4:	0f 84 a8 00 00 00    	je     f0100462 <cons_putc+0x16b>
f01003ba:	83 f8 09             	cmp    $0x9,%eax
f01003bd:	0f 85 da 00 00 00    	jne    f010049d <cons_putc+0x1a6>
		cons_putc(' ');
f01003c3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c8:	e8 2a ff ff ff       	call   f01002f7 <cons_putc>
		cons_putc(' ');
f01003cd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d2:	e8 20 ff ff ff       	call   f01002f7 <cons_putc>
		cons_putc(' ');
f01003d7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003dc:	e8 16 ff ff ff       	call   f01002f7 <cons_putc>
		cons_putc(' ');
f01003e1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e6:	e8 0c ff ff ff       	call   f01002f7 <cons_putc>
		cons_putc(' ');
f01003eb:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f0:	e8 02 ff ff ff       	call   f01002f7 <cons_putc>
		break;
f01003f5:	eb 26                	jmp    f010041d <cons_putc+0x126>
	switch (c & 0xff) {
f01003f7:	83 f8 0d             	cmp    $0xd,%eax
f01003fa:	0f 85 9d 00 00 00    	jne    f010049d <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f0100400:	0f b7 83 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%eax
f0100407:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010040d:	c1 e8 16             	shr    $0x16,%eax
f0100410:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100413:	c1 e0 04             	shl    $0x4,%eax
f0100416:	66 89 83 9c 1f 00 00 	mov    %ax,0x1f9c(%ebx)
	if (crt_pos >= CRT_SIZE) {
f010041d:	66 81 bb 9c 1f 00 00 	cmpw   $0x7cf,0x1f9c(%ebx)
f0100424:	cf 07 
f0100426:	0f 87 98 00 00 00    	ja     f01004c4 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f010042c:	8b 8b a4 1f 00 00    	mov    0x1fa4(%ebx),%ecx
f0100432:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100437:	89 ca                	mov    %ecx,%edx
f0100439:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010043a:	0f b7 9b 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%ebx
f0100441:	8d 71 01             	lea    0x1(%ecx),%esi
f0100444:	89 d8                	mov    %ebx,%eax
f0100446:	66 c1 e8 08          	shr    $0x8,%ax
f010044a:	89 f2                	mov    %esi,%edx
f010044c:	ee                   	out    %al,(%dx)
f010044d:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100452:	89 ca                	mov    %ecx,%edx
f0100454:	ee                   	out    %al,(%dx)
f0100455:	89 d8                	mov    %ebx,%eax
f0100457:	89 f2                	mov    %esi,%edx
f0100459:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010045a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010045d:	5b                   	pop    %ebx
f010045e:	5e                   	pop    %esi
f010045f:	5f                   	pop    %edi
f0100460:	5d                   	pop    %ebp
f0100461:	c3                   	ret    
		if (crt_pos > 0) {
f0100462:	0f b7 83 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%eax
f0100469:	66 85 c0             	test   %ax,%ax
f010046c:	74 be                	je     f010042c <cons_putc+0x135>
			crt_pos--;
f010046e:	83 e8 01             	sub    $0x1,%eax
f0100471:	66 89 83 9c 1f 00 00 	mov    %ax,0x1f9c(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100478:	0f b7 c0             	movzwl %ax,%eax
f010047b:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f010047f:	b2 00                	mov    $0x0,%dl
f0100481:	83 ca 20             	or     $0x20,%edx
f0100484:	8b 8b a0 1f 00 00    	mov    0x1fa0(%ebx),%ecx
f010048a:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010048e:	eb 8d                	jmp    f010041d <cons_putc+0x126>
		crt_pos += CRT_COLS;
f0100490:	66 83 83 9c 1f 00 00 	addw   $0x50,0x1f9c(%ebx)
f0100497:	50 
f0100498:	e9 63 ff ff ff       	jmp    f0100400 <cons_putc+0x109>
		crt_buf[crt_pos++] = c;		/* write the character */
f010049d:	0f b7 83 9c 1f 00 00 	movzwl 0x1f9c(%ebx),%eax
f01004a4:	8d 50 01             	lea    0x1(%eax),%edx
f01004a7:	66 89 93 9c 1f 00 00 	mov    %dx,0x1f9c(%ebx)
f01004ae:	0f b7 c0             	movzwl %ax,%eax
f01004b1:	8b 93 a0 1f 00 00    	mov    0x1fa0(%ebx),%edx
f01004b7:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004bb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
f01004bf:	e9 59 ff ff ff       	jmp    f010041d <cons_putc+0x126>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004c4:	8b 83 a0 1f 00 00    	mov    0x1fa0(%ebx),%eax
f01004ca:	83 ec 04             	sub    $0x4,%esp
f01004cd:	68 00 0f 00 00       	push   $0xf00
f01004d2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004d8:	52                   	push   %edx
f01004d9:	50                   	push   %eax
f01004da:	e8 df 37 00 00       	call   f0103cbe <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004df:	8b 93 a0 1f 00 00    	mov    0x1fa0(%ebx),%edx
f01004e5:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004eb:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004f1:	83 c4 10             	add    $0x10,%esp
f01004f4:	66 c7 00 20 07       	movw   $0x720,(%eax)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004f9:	83 c0 02             	add    $0x2,%eax
f01004fc:	39 d0                	cmp    %edx,%eax
f01004fe:	75 f4                	jne    f01004f4 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100500:	66 83 ab 9c 1f 00 00 	subw   $0x50,0x1f9c(%ebx)
f0100507:	50 
f0100508:	e9 1f ff ff ff       	jmp    f010042c <cons_putc+0x135>

f010050d <serial_intr>:
{
f010050d:	e8 cf 01 00 00       	call   f01006e1 <__x86.get_pc_thunk.ax>
f0100512:	05 fa 6d 01 00       	add    $0x16dfa,%eax
	if (serial_exists)
f0100517:	80 b8 a8 1f 00 00 00 	cmpb   $0x0,0x1fa8(%eax)
f010051e:	75 01                	jne    f0100521 <serial_intr+0x14>
f0100520:	c3                   	ret    
{
f0100521:	55                   	push   %ebp
f0100522:	89 e5                	mov    %esp,%ebp
f0100524:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100527:	8d 80 47 8e fe ff    	lea    -0x171b9(%eax),%eax
f010052d:	e8 3b fc ff ff       	call   f010016d <cons_intr>
}
f0100532:	c9                   	leave  
f0100533:	c3                   	ret    

f0100534 <kbd_intr>:
{
f0100534:	55                   	push   %ebp
f0100535:	89 e5                	mov    %esp,%ebp
f0100537:	83 ec 08             	sub    $0x8,%esp
f010053a:	e8 a2 01 00 00       	call   f01006e1 <__x86.get_pc_thunk.ax>
f010053f:	05 cd 6d 01 00       	add    $0x16dcd,%eax
	cons_intr(kbd_proc_data);
f0100544:	8d 80 c5 8e fe ff    	lea    -0x1713b(%eax),%eax
f010054a:	e8 1e fc ff ff       	call   f010016d <cons_intr>
}
f010054f:	c9                   	leave  
f0100550:	c3                   	ret    

f0100551 <cons_getc>:
{
f0100551:	55                   	push   %ebp
f0100552:	89 e5                	mov    %esp,%ebp
f0100554:	53                   	push   %ebx
f0100555:	83 ec 04             	sub    $0x4,%esp
f0100558:	e8 f2 fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010055d:	81 c3 af 6d 01 00    	add    $0x16daf,%ebx
	serial_intr();
f0100563:	e8 a5 ff ff ff       	call   f010050d <serial_intr>
	kbd_intr();
f0100568:	e8 c7 ff ff ff       	call   f0100534 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f010056d:	8b 83 94 1f 00 00    	mov    0x1f94(%ebx),%eax
	return 0;
f0100573:	ba 00 00 00 00       	mov    $0x0,%edx
	if (cons.rpos != cons.wpos) {
f0100578:	3b 83 98 1f 00 00    	cmp    0x1f98(%ebx),%eax
f010057e:	74 1e                	je     f010059e <cons_getc+0x4d>
		c = cons.buf[cons.rpos++];
f0100580:	8d 48 01             	lea    0x1(%eax),%ecx
f0100583:	0f b6 94 03 94 1d 00 	movzbl 0x1d94(%ebx,%eax,1),%edx
f010058a:	00 
			cons.rpos = 0;
f010058b:	3d ff 01 00 00       	cmp    $0x1ff,%eax
f0100590:	b8 00 00 00 00       	mov    $0x0,%eax
f0100595:	0f 45 c1             	cmovne %ecx,%eax
f0100598:	89 83 94 1f 00 00    	mov    %eax,0x1f94(%ebx)
}
f010059e:	89 d0                	mov    %edx,%eax
f01005a0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01005a3:	c9                   	leave  
f01005a4:	c3                   	ret    

f01005a5 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005a5:	55                   	push   %ebp
f01005a6:	89 e5                	mov    %esp,%ebp
f01005a8:	57                   	push   %edi
f01005a9:	56                   	push   %esi
f01005aa:	53                   	push   %ebx
f01005ab:	83 ec 1c             	sub    $0x1c,%esp
f01005ae:	e8 9c fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01005b3:	81 c3 59 6d 01 00    	add    $0x16d59,%ebx
	was = *cp;
f01005b9:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005c0:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005c7:	5a a5 
	if (*cp != 0xA55A) {
f01005c9:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005d0:	b9 b4 03 00 00       	mov    $0x3b4,%ecx
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005d5:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
	if (*cp != 0xA55A) {
f01005da:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005de:	0f 84 ac 00 00 00    	je     f0100690 <cons_init+0xeb>
		addr_6845 = MONO_BASE;
f01005e4:	89 8b a4 1f 00 00    	mov    %ecx,0x1fa4(%ebx)
f01005ea:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ef:	89 ca                	mov    %ecx,%edx
f01005f1:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005f2:	8d 71 01             	lea    0x1(%ecx),%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f5:	89 f2                	mov    %esi,%edx
f01005f7:	ec                   	in     (%dx),%al
f01005f8:	0f b6 c0             	movzbl %al,%eax
f01005fb:	c1 e0 08             	shl    $0x8,%eax
f01005fe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100601:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100606:	89 ca                	mov    %ecx,%edx
f0100608:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100609:	89 f2                	mov    %esi,%edx
f010060b:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010060c:	89 bb a0 1f 00 00    	mov    %edi,0x1fa0(%ebx)
	pos |= inb(addr_6845 + 1);
f0100612:	0f b6 c0             	movzbl %al,%eax
f0100615:	0b 45 e4             	or     -0x1c(%ebp),%eax
	crt_pos = pos;
f0100618:	66 89 83 9c 1f 00 00 	mov    %ax,0x1f9c(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010061f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100624:	89 c8                	mov    %ecx,%eax
f0100626:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010062b:	ee                   	out    %al,(%dx)
f010062c:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100631:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100636:	89 fa                	mov    %edi,%edx
f0100638:	ee                   	out    %al,(%dx)
f0100639:	b8 0c 00 00 00       	mov    $0xc,%eax
f010063e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100643:	ee                   	out    %al,(%dx)
f0100644:	be f9 03 00 00       	mov    $0x3f9,%esi
f0100649:	89 c8                	mov    %ecx,%eax
f010064b:	89 f2                	mov    %esi,%edx
f010064d:	ee                   	out    %al,(%dx)
f010064e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100653:	89 fa                	mov    %edi,%edx
f0100655:	ee                   	out    %al,(%dx)
f0100656:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010065b:	89 c8                	mov    %ecx,%eax
f010065d:	ee                   	out    %al,(%dx)
f010065e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100663:	89 f2                	mov    %esi,%edx
f0100665:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100666:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010066b:	ec                   	in     (%dx),%al
f010066c:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010066e:	3c ff                	cmp    $0xff,%al
f0100670:	0f 95 83 a8 1f 00 00 	setne  0x1fa8(%ebx)
f0100677:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010067c:	ec                   	in     (%dx),%al
f010067d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100682:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100683:	80 f9 ff             	cmp    $0xff,%cl
f0100686:	74 1e                	je     f01006a6 <cons_init+0x101>
		cprintf("Serial port does not exist!\n");
}
f0100688:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010068b:	5b                   	pop    %ebx
f010068c:	5e                   	pop    %esi
f010068d:	5f                   	pop    %edi
f010068e:	5d                   	pop    %ebp
f010068f:	c3                   	ret    
		*cp = was;
f0100690:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
f0100697:	b9 d4 03 00 00       	mov    $0x3d4,%ecx
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010069c:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
f01006a1:	e9 3e ff ff ff       	jmp    f01005e4 <cons_init+0x3f>
		cprintf("Serial port does not exist!\n");
f01006a6:	83 ec 0c             	sub    $0xc,%esp
f01006a9:	8d 83 0d ce fe ff    	lea    -0x131f3(%ebx),%eax
f01006af:	50                   	push   %eax
f01006b0:	e8 c2 29 00 00       	call   f0103077 <cprintf>
f01006b5:	83 c4 10             	add    $0x10,%esp
}
f01006b8:	eb ce                	jmp    f0100688 <cons_init+0xe3>

f01006ba <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006ba:	55                   	push   %ebp
f01006bb:	89 e5                	mov    %esp,%ebp
f01006bd:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01006c3:	e8 2f fc ff ff       	call   f01002f7 <cons_putc>
}
f01006c8:	c9                   	leave  
f01006c9:	c3                   	ret    

f01006ca <getchar>:

int
getchar(void)
{
f01006ca:	55                   	push   %ebp
f01006cb:	89 e5                	mov    %esp,%ebp
f01006cd:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006d0:	e8 7c fe ff ff       	call   f0100551 <cons_getc>
f01006d5:	85 c0                	test   %eax,%eax
f01006d7:	74 f7                	je     f01006d0 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006d9:	c9                   	leave  
f01006da:	c3                   	ret    

f01006db <iscons>:
int
iscons(int fdnum)
{
	// used by readline
	return 1;
}
f01006db:	b8 01 00 00 00       	mov    $0x1,%eax
f01006e0:	c3                   	ret    

f01006e1 <__x86.get_pc_thunk.ax>:
f01006e1:	8b 04 24             	mov    (%esp),%eax
f01006e4:	c3                   	ret    

f01006e5 <__x86.get_pc_thunk.si>:
f01006e5:	8b 34 24             	mov    (%esp),%esi
f01006e8:	c3                   	ret    

f01006e9 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006e9:	55                   	push   %ebp
f01006ea:	89 e5                	mov    %esp,%ebp
f01006ec:	56                   	push   %esi
f01006ed:	53                   	push   %ebx
f01006ee:	e8 5c fa ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01006f3:	81 c3 19 6c 01 00    	add    $0x16c19,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006f9:	83 ec 04             	sub    $0x4,%esp
f01006fc:	8d 83 34 d0 fe ff    	lea    -0x12fcc(%ebx),%eax
f0100702:	50                   	push   %eax
f0100703:	8d 83 52 d0 fe ff    	lea    -0x12fae(%ebx),%eax
f0100709:	50                   	push   %eax
f010070a:	8d b3 57 d0 fe ff    	lea    -0x12fa9(%ebx),%esi
f0100710:	56                   	push   %esi
f0100711:	e8 61 29 00 00       	call   f0103077 <cprintf>
f0100716:	83 c4 0c             	add    $0xc,%esp
f0100719:	8d 83 04 d1 fe ff    	lea    -0x12efc(%ebx),%eax
f010071f:	50                   	push   %eax
f0100720:	8d 83 60 d0 fe ff    	lea    -0x12fa0(%ebx),%eax
f0100726:	50                   	push   %eax
f0100727:	56                   	push   %esi
f0100728:	e8 4a 29 00 00       	call   f0103077 <cprintf>
f010072d:	83 c4 0c             	add    $0xc,%esp
f0100730:	8d 83 69 d0 fe ff    	lea    -0x12f97(%ebx),%eax
f0100736:	50                   	push   %eax
f0100737:	8d 83 77 d0 fe ff    	lea    -0x12f89(%ebx),%eax
f010073d:	50                   	push   %eax
f010073e:	56                   	push   %esi
f010073f:	e8 33 29 00 00       	call   f0103077 <cprintf>
	return 0;
}
f0100744:	b8 00 00 00 00       	mov    $0x0,%eax
f0100749:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010074c:	5b                   	pop    %ebx
f010074d:	5e                   	pop    %esi
f010074e:	5d                   	pop    %ebp
f010074f:	c3                   	ret    

f0100750 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100750:	55                   	push   %ebp
f0100751:	89 e5                	mov    %esp,%ebp
f0100753:	57                   	push   %edi
f0100754:	56                   	push   %esi
f0100755:	53                   	push   %ebx
f0100756:	83 ec 18             	sub    $0x18,%esp
f0100759:	e8 f1 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010075e:	81 c3 ae 6b 01 00    	add    $0x16bae,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100764:	8d 83 81 d0 fe ff    	lea    -0x12f7f(%ebx),%eax
f010076a:	50                   	push   %eax
f010076b:	e8 07 29 00 00       	call   f0103077 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100770:	83 c4 08             	add    $0x8,%esp
f0100773:	ff b3 f4 ff ff ff    	push   -0xc(%ebx)
f0100779:	8d 83 2c d1 fe ff    	lea    -0x12ed4(%ebx),%eax
f010077f:	50                   	push   %eax
f0100780:	e8 f2 28 00 00       	call   f0103077 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100785:	83 c4 0c             	add    $0xc,%esp
f0100788:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010078e:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100794:	50                   	push   %eax
f0100795:	57                   	push   %edi
f0100796:	8d 83 54 d1 fe ff    	lea    -0x12eac(%ebx),%eax
f010079c:	50                   	push   %eax
f010079d:	e8 d5 28 00 00       	call   f0103077 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007a2:	83 c4 0c             	add    $0xc,%esp
f01007a5:	c7 c0 a1 40 10 f0    	mov    $0xf01040a1,%eax
f01007ab:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007b1:	52                   	push   %edx
f01007b2:	50                   	push   %eax
f01007b3:	8d 83 78 d1 fe ff    	lea    -0x12e88(%ebx),%eax
f01007b9:	50                   	push   %eax
f01007ba:	e8 b8 28 00 00       	call   f0103077 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007bf:	83 c4 0c             	add    $0xc,%esp
f01007c2:	c7 c0 60 90 11 f0    	mov    $0xf0119060,%eax
f01007c8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007ce:	52                   	push   %edx
f01007cf:	50                   	push   %eax
f01007d0:	8d 83 9c d1 fe ff    	lea    -0x12e64(%ebx),%eax
f01007d6:	50                   	push   %eax
f01007d7:	e8 9b 28 00 00       	call   f0103077 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007dc:	83 c4 0c             	add    $0xc,%esp
f01007df:	c7 c6 e0 96 11 f0    	mov    $0xf01196e0,%esi
f01007e5:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007eb:	50                   	push   %eax
f01007ec:	56                   	push   %esi
f01007ed:	8d 83 c0 d1 fe ff    	lea    -0x12e40(%ebx),%eax
f01007f3:	50                   	push   %eax
f01007f4:	e8 7e 28 00 00       	call   f0103077 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f9:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007fc:	29 fe                	sub    %edi,%esi
f01007fe:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100804:	c1 fe 0a             	sar    $0xa,%esi
f0100807:	56                   	push   %esi
f0100808:	8d 83 e4 d1 fe ff    	lea    -0x12e1c(%ebx),%eax
f010080e:	50                   	push   %eax
f010080f:	e8 63 28 00 00       	call   f0103077 <cprintf>
	return 0;
}
f0100814:	b8 00 00 00 00       	mov    $0x0,%eax
f0100819:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010081c:	5b                   	pop    %ebx
f010081d:	5e                   	pop    %esi
f010081e:	5f                   	pop    %edi
f010081f:	5d                   	pop    %ebp
f0100820:	c3                   	ret    

f0100821 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100821:	55                   	push   %ebp
f0100822:	89 e5                	mov    %esp,%ebp
f0100824:	57                   	push   %edi
f0100825:	56                   	push   %esi
f0100826:	53                   	push   %ebx
f0100827:	83 ec 48             	sub    $0x48,%esp
f010082a:	e8 20 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010082f:	81 c3 dd 6a 01 00    	add    $0x16add,%ebx
	cprintf ("Stack backtrace:\n");
f0100835:	8d 83 9a d0 fe ff    	lea    -0x12f66(%ebx),%eax
f010083b:	50                   	push   %eax
f010083c:	e8 36 28 00 00       	call   f0103077 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100841:	89 ee                	mov    %ebp,%esi
f0100843:	83 c4 10             	add    $0x10,%esp
        	args[0] = ((uint32_t *)ebp)[2];
        	args[1] = ((uint32_t *)ebp)[3];
        	args[2] = ((uint32_t *)ebp)[4];
        	args[3] = ((uint32_t *)ebp)[5];
        	args[4] = ((uint32_t *)ebp)[6];
        	cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",
f0100846:	8d 83 10 d2 fe ff    	lea    -0x12df0(%ebx),%eax
f010084c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
                	ebp, eip, args[0], args[1], args[2], args[3], args[4]);
                
        	debuginfo_eip (eip, &dbinfo);
        	cprintf("         %s:%d: %.*s+%d\n",
f010084f:	8d 83 ac d0 fe ff    	lea    -0x12f54(%ebx),%eax
f0100855:	89 45 c0             	mov    %eax,-0x40(%ebp)
        	eip = ((uint32_t *)ebp)[1];
f0100858:	8b 7e 04             	mov    0x4(%esi),%edi
        	cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n",
f010085b:	ff 76 18             	push   0x18(%esi)
f010085e:	ff 76 14             	push   0x14(%esi)
f0100861:	ff 76 10             	push   0x10(%esi)
f0100864:	ff 76 0c             	push   0xc(%esi)
f0100867:	ff 76 08             	push   0x8(%esi)
f010086a:	57                   	push   %edi
f010086b:	56                   	push   %esi
f010086c:	ff 75 c4             	push   -0x3c(%ebp)
f010086f:	e8 03 28 00 00       	call   f0103077 <cprintf>
        	debuginfo_eip (eip, &dbinfo);
f0100874:	83 c4 18             	add    $0x18,%esp
f0100877:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010087a:	50                   	push   %eax
f010087b:	57                   	push   %edi
f010087c:	e8 ff 28 00 00       	call   f0103180 <debuginfo_eip>
        	cprintf("         %s:%d: %.*s+%d\n",
f0100881:	83 c4 08             	add    $0x8,%esp
f0100884:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100887:	57                   	push   %edi
f0100888:	ff 75 d8             	push   -0x28(%ebp)
f010088b:	ff 75 dc             	push   -0x24(%ebp)
f010088e:	ff 75 d4             	push   -0x2c(%ebp)
f0100891:	ff 75 d0             	push   -0x30(%ebp)
f0100894:	ff 75 c0             	push   -0x40(%ebp)
f0100897:	e8 db 27 00 00       	call   f0103077 <cprintf>
                	dbinfo.eip_file, dbinfo.eip_line, dbinfo.eip_fn_namelen,
                	dbinfo.eip_fn_name, eip - dbinfo.eip_fn_addr);
                
        	ebp = *(uint32_t *)ebp;
f010089c:	8b 36                	mov    (%esi),%esi
    	} while (ebp);
f010089e:	83 c4 20             	add    $0x20,%esp
f01008a1:	85 f6                	test   %esi,%esi
f01008a3:	75 b3                	jne    f0100858 <mon_backtrace+0x37>

	return 0;
}
f01008a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01008aa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ad:	5b                   	pop    %ebx
f01008ae:	5e                   	pop    %esi
f01008af:	5f                   	pop    %edi
f01008b0:	5d                   	pop    %ebp
f01008b1:	c3                   	ret    

f01008b2 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008b2:	55                   	push   %ebp
f01008b3:	89 e5                	mov    %esp,%ebp
f01008b5:	57                   	push   %edi
f01008b6:	56                   	push   %esi
f01008b7:	53                   	push   %ebx
f01008b8:	83 ec 68             	sub    $0x68,%esp
f01008bb:	e8 8f f8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01008c0:	81 c3 4c 6a 01 00    	add    $0x16a4c,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008c6:	8d 83 48 d2 fe ff    	lea    -0x12db8(%ebx),%eax
f01008cc:	50                   	push   %eax
f01008cd:	e8 a5 27 00 00       	call   f0103077 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008d2:	8d 83 6c d2 fe ff    	lea    -0x12d94(%ebx),%eax
f01008d8:	89 04 24             	mov    %eax,(%esp)
f01008db:	e8 97 27 00 00       	call   f0103077 <cprintf>
f01008e0:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01008e3:	8d bb c9 d0 fe ff    	lea    -0x12f37(%ebx),%edi
f01008e9:	eb 4a                	jmp    f0100935 <monitor+0x83>
f01008eb:	83 ec 08             	sub    $0x8,%esp
f01008ee:	0f be c0             	movsbl %al,%eax
f01008f1:	50                   	push   %eax
f01008f2:	57                   	push   %edi
f01008f3:	e8 41 33 00 00       	call   f0103c39 <strchr>
f01008f8:	83 c4 10             	add    $0x10,%esp
f01008fb:	85 c0                	test   %eax,%eax
f01008fd:	74 08                	je     f0100907 <monitor+0x55>
			*buf++ = 0;
f01008ff:	c6 06 00             	movb   $0x0,(%esi)
f0100902:	8d 76 01             	lea    0x1(%esi),%esi
f0100905:	eb 76                	jmp    f010097d <monitor+0xcb>
		if (*buf == 0)
f0100907:	80 3e 00             	cmpb   $0x0,(%esi)
f010090a:	74 7c                	je     f0100988 <monitor+0xd6>
		if (argc == MAXARGS-1) {
f010090c:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100910:	74 0f                	je     f0100921 <monitor+0x6f>
		argv[argc++] = buf;
f0100912:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100915:	8d 48 01             	lea    0x1(%eax),%ecx
f0100918:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f010091b:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f010091f:	eb 41                	jmp    f0100962 <monitor+0xb0>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100921:	83 ec 08             	sub    $0x8,%esp
f0100924:	6a 10                	push   $0x10
f0100926:	8d 83 ce d0 fe ff    	lea    -0x12f32(%ebx),%eax
f010092c:	50                   	push   %eax
f010092d:	e8 45 27 00 00       	call   f0103077 <cprintf>
			return 0;
f0100932:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100935:	8d 83 c5 d0 fe ff    	lea    -0x12f3b(%ebx),%eax
f010093b:	89 c6                	mov    %eax,%esi
f010093d:	83 ec 0c             	sub    $0xc,%esp
f0100940:	56                   	push   %esi
f0100941:	e8 a2 30 00 00       	call   f01039e8 <readline>
		if (buf != NULL)
f0100946:	83 c4 10             	add    $0x10,%esp
f0100949:	85 c0                	test   %eax,%eax
f010094b:	74 f0                	je     f010093d <monitor+0x8b>
	argv[argc] = 0;
f010094d:	89 c6                	mov    %eax,%esi
f010094f:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100956:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f010095d:	eb 1e                	jmp    f010097d <monitor+0xcb>
			buf++;
f010095f:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100962:	0f b6 06             	movzbl (%esi),%eax
f0100965:	84 c0                	test   %al,%al
f0100967:	74 14                	je     f010097d <monitor+0xcb>
f0100969:	83 ec 08             	sub    $0x8,%esp
f010096c:	0f be c0             	movsbl %al,%eax
f010096f:	50                   	push   %eax
f0100970:	57                   	push   %edi
f0100971:	e8 c3 32 00 00       	call   f0103c39 <strchr>
f0100976:	83 c4 10             	add    $0x10,%esp
f0100979:	85 c0                	test   %eax,%eax
f010097b:	74 e2                	je     f010095f <monitor+0xad>
		while (*buf && strchr(WHITESPACE, *buf))
f010097d:	0f b6 06             	movzbl (%esi),%eax
f0100980:	84 c0                	test   %al,%al
f0100982:	0f 85 63 ff ff ff    	jne    f01008eb <monitor+0x39>
	argv[argc] = 0;
f0100988:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f010098b:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100992:	00 
	if (argc == 0)
f0100993:	85 c0                	test   %eax,%eax
f0100995:	74 9e                	je     f0100935 <monitor+0x83>
f0100997:	8d b3 14 1d 00 00    	lea    0x1d14(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010099d:	b8 00 00 00 00       	mov    $0x0,%eax
f01009a2:	89 7d a0             	mov    %edi,-0x60(%ebp)
f01009a5:	89 c7                	mov    %eax,%edi
		if (strcmp(argv[0], commands[i].name) == 0)
f01009a7:	83 ec 08             	sub    $0x8,%esp
f01009aa:	ff 36                	push   (%esi)
f01009ac:	ff 75 a8             	push   -0x58(%ebp)
f01009af:	e8 25 32 00 00       	call   f0103bd9 <strcmp>
f01009b4:	83 c4 10             	add    $0x10,%esp
f01009b7:	85 c0                	test   %eax,%eax
f01009b9:	74 28                	je     f01009e3 <monitor+0x131>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009bb:	83 c7 01             	add    $0x1,%edi
f01009be:	83 c6 0c             	add    $0xc,%esi
f01009c1:	83 ff 03             	cmp    $0x3,%edi
f01009c4:	75 e1                	jne    f01009a7 <monitor+0xf5>
	cprintf("Unknown command '%s'\n", argv[0]);
f01009c6:	8b 7d a0             	mov    -0x60(%ebp),%edi
f01009c9:	83 ec 08             	sub    $0x8,%esp
f01009cc:	ff 75 a8             	push   -0x58(%ebp)
f01009cf:	8d 83 eb d0 fe ff    	lea    -0x12f15(%ebx),%eax
f01009d5:	50                   	push   %eax
f01009d6:	e8 9c 26 00 00       	call   f0103077 <cprintf>
	return 0;
f01009db:	83 c4 10             	add    $0x10,%esp
f01009de:	e9 52 ff ff ff       	jmp    f0100935 <monitor+0x83>
			return commands[i].func(argc, argv, tf);
f01009e3:	89 f8                	mov    %edi,%eax
f01009e5:	8b 7d a0             	mov    -0x60(%ebp),%edi
f01009e8:	83 ec 04             	sub    $0x4,%esp
f01009eb:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01009ee:	ff 75 08             	push   0x8(%ebp)
f01009f1:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009f4:	52                   	push   %edx
f01009f5:	ff 75 a4             	push   -0x5c(%ebp)
f01009f8:	ff 94 83 1c 1d 00 00 	call   *0x1d1c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f01009ff:	83 c4 10             	add    $0x10,%esp
f0100a02:	85 c0                	test   %eax,%eax
f0100a04:	0f 89 2b ff ff ff    	jns    f0100935 <monitor+0x83>
				break;
	}
}
f0100a0a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a0d:	5b                   	pop    %ebx
f0100a0e:	5e                   	pop    %esi
f0100a0f:	5f                   	pop    %edi
f0100a10:	5d                   	pop    %ebp
f0100a11:	c3                   	ret    

f0100a12 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a12:	55                   	push   %ebp
f0100a13:	89 e5                	mov    %esp,%ebp
f0100a15:	57                   	push   %edi
f0100a16:	56                   	push   %esi
f0100a17:	53                   	push   %ebx
f0100a18:	83 ec 18             	sub    $0x18,%esp
f0100a1b:	e8 2f f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100a20:	81 c3 ec 68 01 00    	add    $0x168ec,%ebx
f0100a26:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a28:	50                   	push   %eax
f0100a29:	e8 c2 25 00 00       	call   f0102ff0 <mc146818_read>
f0100a2e:	89 c7                	mov    %eax,%edi
f0100a30:	83 c6 01             	add    $0x1,%esi
f0100a33:	89 34 24             	mov    %esi,(%esp)
f0100a36:	e8 b5 25 00 00       	call   f0102ff0 <mc146818_read>
f0100a3b:	c1 e0 08             	shl    $0x8,%eax
f0100a3e:	09 f8                	or     %edi,%eax
}
f0100a40:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a43:	5b                   	pop    %ebx
f0100a44:	5e                   	pop    %esi
f0100a45:	5f                   	pop    %edi
f0100a46:	5d                   	pop    %ebp
f0100a47:	c3                   	ret    

f0100a48 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a48:	e8 97 25 00 00       	call   f0102fe4 <__x86.get_pc_thunk.dx>
f0100a4d:	81 c2 bf 68 01 00    	add    $0x168bf,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a53:	83 ba b8 1f 00 00 00 	cmpl   $0x0,0x1fb8(%edx)
f0100a5a:	74 3d                	je     f0100a99 <boot_alloc+0x51>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n == 0) 
f0100a5c:	85 c0                	test   %eax,%eax
f0100a5e:	74 53                	je     f0100ab3 <boot_alloc+0x6b>
{
f0100a60:	55                   	push   %ebp
f0100a61:	89 e5                	mov    %esp,%ebp
f0100a63:	53                   	push   %ebx
f0100a64:	83 ec 04             	sub    $0x4,%esp
	{
		return nextfree;
	} 
	result = nextfree;
f0100a67:	8b 8a b8 1f 00 00    	mov    0x1fb8(%edx),%ecx
	nextfree = ROUNDUP(nextfree + n, PGSIZE);
f0100a6d:	8d 9c 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%ebx
f0100a74:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0100a7a:	89 9a b8 1f 00 00    	mov    %ebx,0x1fb8(%edx)
	if ((uint32_t)nextfree > KERNBASE + npages * PGSIZE) 
f0100a80:	8b 82 b4 1f 00 00    	mov    0x1fb4(%edx),%eax
f0100a86:	05 00 00 0f 00       	add    $0xf0000,%eax
f0100a8b:	c1 e0 0c             	shl    $0xc,%eax
f0100a8e:	39 d8                	cmp    %ebx,%eax
f0100a90:	72 2a                	jb     f0100abc <boot_alloc+0x74>
	{
		panic("Out of memory.\n");
	} 
	return result;
}
f0100a92:	89 c8                	mov    %ecx,%eax
f0100a94:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a97:	c9                   	leave  
f0100a98:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100a99:	c7 c1 e0 96 11 f0    	mov    $0xf01196e0,%ecx
f0100a9f:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100aa5:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100aab:	89 8a b8 1f 00 00    	mov    %ecx,0x1fb8(%edx)
f0100ab1:	eb a9                	jmp    f0100a5c <boot_alloc+0x14>
		return nextfree;
f0100ab3:	8b 8a b8 1f 00 00    	mov    0x1fb8(%edx),%ecx
}
f0100ab9:	89 c8                	mov    %ecx,%eax
f0100abb:	c3                   	ret    
		panic("Out of memory.\n");
f0100abc:	83 ec 04             	sub    $0x4,%esp
f0100abf:	8d 82 91 d2 fe ff    	lea    -0x12d6f(%edx),%eax
f0100ac5:	50                   	push   %eax
f0100ac6:	6a 71                	push   $0x71
f0100ac8:	8d 82 a1 d2 fe ff    	lea    -0x12d5f(%edx),%eax
f0100ace:	50                   	push   %eax
f0100acf:	89 d3                	mov    %edx,%ebx
f0100ad1:	e8 c3 f5 ff ff       	call   f0100099 <_panic>

f0100ad6 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100ad6:	55                   	push   %ebp
f0100ad7:	89 e5                	mov    %esp,%ebp
f0100ad9:	53                   	push   %ebx
f0100ada:	83 ec 04             	sub    $0x4,%esp
f0100add:	e8 06 25 00 00       	call   f0102fe8 <__x86.get_pc_thunk.cx>
f0100ae2:	81 c1 2a 68 01 00    	add    $0x1682a,%ecx
f0100ae8:	89 c3                	mov    %eax,%ebx
f0100aea:	89 d0                	mov    %edx,%eax
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100aec:	c1 ea 16             	shr    $0x16,%edx
	if (!(*pgdir & PTE_P))
f0100aef:	8b 14 93             	mov    (%ebx,%edx,4),%edx
f0100af2:	f6 c2 01             	test   $0x1,%dl
f0100af5:	74 54                	je     f0100b4b <check_va2pa+0x75>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100af7:	89 d3                	mov    %edx,%ebx
f0100af9:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100aff:	c1 ea 0c             	shr    $0xc,%edx
f0100b02:	3b 91 b4 1f 00 00    	cmp    0x1fb4(%ecx),%edx
f0100b08:	73 26                	jae    f0100b30 <check_va2pa+0x5a>
	if (!(p[PTX(va)] & PTE_P))
f0100b0a:	c1 e8 0c             	shr    $0xc,%eax
f0100b0d:	25 ff 03 00 00       	and    $0x3ff,%eax
f0100b12:	8b 94 83 00 00 00 f0 	mov    -0x10000000(%ebx,%eax,4),%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b19:	89 d0                	mov    %edx,%eax
f0100b1b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b20:	f6 c2 01             	test   $0x1,%dl
f0100b23:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b28:	0f 44 c2             	cmove  %edx,%eax
}
f0100b2b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b2e:	c9                   	leave  
f0100b2f:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b30:	53                   	push   %ebx
f0100b31:	8d 81 b8 d5 fe ff    	lea    -0x12a48(%ecx),%eax
f0100b37:	50                   	push   %eax
f0100b38:	68 06 03 00 00       	push   $0x306
f0100b3d:	8d 81 a1 d2 fe ff    	lea    -0x12d5f(%ecx),%eax
f0100b43:	50                   	push   %eax
f0100b44:	89 cb                	mov    %ecx,%ebx
f0100b46:	e8 4e f5 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100b4b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b50:	eb d9                	jmp    f0100b2b <check_va2pa+0x55>

f0100b52 <check_page_free_list>:
{
f0100b52:	55                   	push   %ebp
f0100b53:	89 e5                	mov    %esp,%ebp
f0100b55:	57                   	push   %edi
f0100b56:	56                   	push   %esi
f0100b57:	53                   	push   %ebx
f0100b58:	83 ec 2c             	sub    $0x2c,%esp
f0100b5b:	e8 8c 24 00 00       	call   f0102fec <__x86.get_pc_thunk.di>
f0100b60:	81 c7 ac 67 01 00    	add    $0x167ac,%edi
f0100b66:	89 7d d4             	mov    %edi,-0x2c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b69:	84 c0                	test   %al,%al
f0100b6b:	0f 85 dc 02 00 00    	jne    f0100e4d <check_page_free_list+0x2fb>
	if (!page_free_list)
f0100b71:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100b74:	83 b8 bc 1f 00 00 00 	cmpl   $0x0,0x1fbc(%eax)
f0100b7b:	74 0a                	je     f0100b87 <check_page_free_list+0x35>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b7d:	bf 00 04 00 00       	mov    $0x400,%edi
f0100b82:	e9 29 03 00 00       	jmp    f0100eb0 <check_page_free_list+0x35e>
		panic("'page_free_list' is a null pointer!");
f0100b87:	83 ec 04             	sub    $0x4,%esp
f0100b8a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100b8d:	8d 83 dc d5 fe ff    	lea    -0x12a24(%ebx),%eax
f0100b93:	50                   	push   %eax
f0100b94:	68 47 02 00 00       	push   $0x247
f0100b99:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0100b9f:	50                   	push   %eax
f0100ba0:	e8 f4 f4 ff ff       	call   f0100099 <_panic>
f0100ba5:	50                   	push   %eax
f0100ba6:	89 cb                	mov    %ecx,%ebx
f0100ba8:	8d 81 b8 d5 fe ff    	lea    -0x12a48(%ecx),%eax
f0100bae:	50                   	push   %eax
f0100baf:	6a 52                	push   $0x52
f0100bb1:	8d 81 ad d2 fe ff    	lea    -0x12d53(%ecx),%eax
f0100bb7:	50                   	push   %eax
f0100bb8:	e8 dc f4 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bbd:	8b 36                	mov    (%esi),%esi
f0100bbf:	85 f6                	test   %esi,%esi
f0100bc1:	74 47                	je     f0100c0a <check_page_free_list+0xb8>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bc3:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100bc6:	89 f0                	mov    %esi,%eax
f0100bc8:	2b 81 ac 1f 00 00    	sub    0x1fac(%ecx),%eax
f0100bce:	c1 f8 03             	sar    $0x3,%eax
f0100bd1:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100bd4:	89 c2                	mov    %eax,%edx
f0100bd6:	c1 ea 16             	shr    $0x16,%edx
f0100bd9:	39 fa                	cmp    %edi,%edx
f0100bdb:	73 e0                	jae    f0100bbd <check_page_free_list+0x6b>
	if (PGNUM(pa) >= npages)
f0100bdd:	89 c2                	mov    %eax,%edx
f0100bdf:	c1 ea 0c             	shr    $0xc,%edx
f0100be2:	3b 91 b4 1f 00 00    	cmp    0x1fb4(%ecx),%edx
f0100be8:	73 bb                	jae    f0100ba5 <check_page_free_list+0x53>
			memset(page2kva(pp), 0x97, 128);
f0100bea:	83 ec 04             	sub    $0x4,%esp
f0100bed:	68 80 00 00 00       	push   $0x80
f0100bf2:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100bf7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bfc:	50                   	push   %eax
f0100bfd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c00:	e8 73 30 00 00       	call   f0103c78 <memset>
f0100c05:	83 c4 10             	add    $0x10,%esp
f0100c08:	eb b3                	jmp    f0100bbd <check_page_free_list+0x6b>
	first_free_page = (char *) boot_alloc(0);
f0100c0a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c0f:	e8 34 fe ff ff       	call   f0100a48 <boot_alloc>
f0100c14:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c17:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c1a:	8b 90 bc 1f 00 00    	mov    0x1fbc(%eax),%edx
		assert(pp >= pages);
f0100c20:	8b 88 ac 1f 00 00    	mov    0x1fac(%eax),%ecx
		assert(pp < pages + npages);
f0100c26:	8b 80 b4 1f 00 00    	mov    0x1fb4(%eax),%eax
f0100c2c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100c2f:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c32:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c37:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c3c:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c3f:	e9 07 01 00 00       	jmp    f0100d4b <check_page_free_list+0x1f9>
		assert(pp >= pages);
f0100c44:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c47:	8d 83 bb d2 fe ff    	lea    -0x12d45(%ebx),%eax
f0100c4d:	50                   	push   %eax
f0100c4e:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0100c54:	50                   	push   %eax
f0100c55:	68 61 02 00 00       	push   $0x261
f0100c5a:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0100c60:	50                   	push   %eax
f0100c61:	e8 33 f4 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100c66:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c69:	8d 83 dc d2 fe ff    	lea    -0x12d24(%ebx),%eax
f0100c6f:	50                   	push   %eax
f0100c70:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0100c76:	50                   	push   %eax
f0100c77:	68 62 02 00 00       	push   $0x262
f0100c7c:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0100c82:	50                   	push   %eax
f0100c83:	e8 11 f4 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c88:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c8b:	8d 83 00 d6 fe ff    	lea    -0x12a00(%ebx),%eax
f0100c91:	50                   	push   %eax
f0100c92:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0100c98:	50                   	push   %eax
f0100c99:	68 63 02 00 00       	push   $0x263
f0100c9e:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0100ca4:	50                   	push   %eax
f0100ca5:	e8 ef f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100caa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100cad:	8d 83 f0 d2 fe ff    	lea    -0x12d10(%ebx),%eax
f0100cb3:	50                   	push   %eax
f0100cb4:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0100cba:	50                   	push   %eax
f0100cbb:	68 66 02 00 00       	push   $0x266
f0100cc0:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0100cc6:	50                   	push   %eax
f0100cc7:	e8 cd f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ccc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100ccf:	8d 83 01 d3 fe ff    	lea    -0x12cff(%ebx),%eax
f0100cd5:	50                   	push   %eax
f0100cd6:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0100cdc:	50                   	push   %eax
f0100cdd:	68 67 02 00 00       	push   $0x267
f0100ce2:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0100ce8:	50                   	push   %eax
f0100ce9:	e8 ab f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cee:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100cf1:	8d 83 34 d6 fe ff    	lea    -0x129cc(%ebx),%eax
f0100cf7:	50                   	push   %eax
f0100cf8:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0100cfe:	50                   	push   %eax
f0100cff:	68 68 02 00 00       	push   $0x268
f0100d04:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0100d0a:	50                   	push   %eax
f0100d0b:	e8 89 f3 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d10:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d13:	8d 83 1a d3 fe ff    	lea    -0x12ce6(%ebx),%eax
f0100d19:	50                   	push   %eax
f0100d1a:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0100d20:	50                   	push   %eax
f0100d21:	68 69 02 00 00       	push   $0x269
f0100d26:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0100d2c:	50                   	push   %eax
f0100d2d:	e8 67 f3 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100d32:	89 c3                	mov    %eax,%ebx
f0100d34:	c1 eb 0c             	shr    $0xc,%ebx
f0100d37:	39 5d cc             	cmp    %ebx,-0x34(%ebp)
f0100d3a:	76 6d                	jbe    f0100da9 <check_page_free_list+0x257>
	return (void *)(pa + KERNBASE);
f0100d3c:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d41:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d44:	77 7c                	ja     f0100dc2 <check_page_free_list+0x270>
			++nfree_extmem;
f0100d46:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d49:	8b 12                	mov    (%edx),%edx
f0100d4b:	85 d2                	test   %edx,%edx
f0100d4d:	0f 84 91 00 00 00    	je     f0100de4 <check_page_free_list+0x292>
		assert(pp >= pages);
f0100d53:	39 d1                	cmp    %edx,%ecx
f0100d55:	0f 87 e9 fe ff ff    	ja     f0100c44 <check_page_free_list+0xf2>
		assert(pp < pages + npages);
f0100d5b:	39 d6                	cmp    %edx,%esi
f0100d5d:	0f 86 03 ff ff ff    	jbe    f0100c66 <check_page_free_list+0x114>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d63:	89 d0                	mov    %edx,%eax
f0100d65:	29 c8                	sub    %ecx,%eax
f0100d67:	a8 07                	test   $0x7,%al
f0100d69:	0f 85 19 ff ff ff    	jne    f0100c88 <check_page_free_list+0x136>
	return (pp - pages) << PGSHIFT;
f0100d6f:	c1 f8 03             	sar    $0x3,%eax
		assert(page2pa(pp) != 0);
f0100d72:	c1 e0 0c             	shl    $0xc,%eax
f0100d75:	0f 84 2f ff ff ff    	je     f0100caa <check_page_free_list+0x158>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d7b:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100d80:	0f 84 46 ff ff ff    	je     f0100ccc <check_page_free_list+0x17a>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d86:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100d8b:	0f 84 5d ff ff ff    	je     f0100cee <check_page_free_list+0x19c>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d91:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d96:	0f 84 74 ff ff ff    	je     f0100d10 <check_page_free_list+0x1be>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d9c:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100da1:	77 8f                	ja     f0100d32 <check_page_free_list+0x1e0>
			++nfree_basemem;
f0100da3:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
f0100da7:	eb a0                	jmp    f0100d49 <check_page_free_list+0x1f7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100da9:	50                   	push   %eax
f0100daa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100dad:	8d 83 b8 d5 fe ff    	lea    -0x12a48(%ebx),%eax
f0100db3:	50                   	push   %eax
f0100db4:	6a 52                	push   $0x52
f0100db6:	8d 83 ad d2 fe ff    	lea    -0x12d53(%ebx),%eax
f0100dbc:	50                   	push   %eax
f0100dbd:	e8 d7 f2 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dc2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100dc5:	8d 83 58 d6 fe ff    	lea    -0x129a8(%ebx),%eax
f0100dcb:	50                   	push   %eax
f0100dcc:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0100dd2:	50                   	push   %eax
f0100dd3:	68 6a 02 00 00       	push   $0x26a
f0100dd8:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0100dde:	50                   	push   %eax
f0100ddf:	e8 b5 f2 ff ff       	call   f0100099 <_panic>
	assert(nfree_basemem > 0);
f0100de4:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0100de7:	85 db                	test   %ebx,%ebx
f0100de9:	7e 1e                	jle    f0100e09 <check_page_free_list+0x2b7>
	assert(nfree_extmem > 0);
f0100deb:	85 ff                	test   %edi,%edi
f0100ded:	7e 3c                	jle    f0100e2b <check_page_free_list+0x2d9>
	cprintf("check_page_free_list() succeeded!\n");
f0100def:	83 ec 0c             	sub    $0xc,%esp
f0100df2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100df5:	8d 83 a0 d6 fe ff    	lea    -0x12960(%ebx),%eax
f0100dfb:	50                   	push   %eax
f0100dfc:	e8 76 22 00 00       	call   f0103077 <cprintf>
}
f0100e01:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e04:	5b                   	pop    %ebx
f0100e05:	5e                   	pop    %esi
f0100e06:	5f                   	pop    %edi
f0100e07:	5d                   	pop    %ebp
f0100e08:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e09:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e0c:	8d 83 34 d3 fe ff    	lea    -0x12ccc(%ebx),%eax
f0100e12:	50                   	push   %eax
f0100e13:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0100e19:	50                   	push   %eax
f0100e1a:	68 72 02 00 00       	push   $0x272
f0100e1f:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0100e25:	50                   	push   %eax
f0100e26:	e8 6e f2 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0100e2b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100e2e:	8d 83 46 d3 fe ff    	lea    -0x12cba(%ebx),%eax
f0100e34:	50                   	push   %eax
f0100e35:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0100e3b:	50                   	push   %eax
f0100e3c:	68 73 02 00 00       	push   $0x273
f0100e41:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0100e47:	50                   	push   %eax
f0100e48:	e8 4c f2 ff ff       	call   f0100099 <_panic>
	if (!page_free_list)
f0100e4d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e50:	8b 80 bc 1f 00 00    	mov    0x1fbc(%eax),%eax
f0100e56:	85 c0                	test   %eax,%eax
f0100e58:	0f 84 29 fd ff ff    	je     f0100b87 <check_page_free_list+0x35>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e5e:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100e61:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e64:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e67:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100e6a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100e6d:	89 c2                	mov    %eax,%edx
f0100e6f:	2b 97 ac 1f 00 00    	sub    0x1fac(%edi),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100e75:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100e7b:	0f 95 c2             	setne  %dl
f0100e7e:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100e81:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100e85:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100e87:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e8b:	8b 00                	mov    (%eax),%eax
f0100e8d:	85 c0                	test   %eax,%eax
f0100e8f:	75 d9                	jne    f0100e6a <check_page_free_list+0x318>
		*tp[1] = 0;
f0100e91:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e94:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100e9a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e9d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ea0:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ea2:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ea5:	89 87 bc 1f 00 00    	mov    %eax,0x1fbc(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100eab:	bf 01 00 00 00       	mov    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100eb0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100eb3:	8b b0 bc 1f 00 00    	mov    0x1fbc(%eax),%esi
f0100eb9:	e9 01 fd ff ff       	jmp    f0100bbf <check_page_free_list+0x6d>

f0100ebe <page_init>:
{
f0100ebe:	55                   	push   %ebp
f0100ebf:	89 e5                	mov    %esp,%ebp
f0100ec1:	57                   	push   %edi
f0100ec2:	56                   	push   %esi
f0100ec3:	53                   	push   %ebx
f0100ec4:	83 ec 0c             	sub    $0xc,%esp
f0100ec7:	e8 19 f8 ff ff       	call   f01006e5 <__x86.get_pc_thunk.si>
f0100ecc:	81 c6 40 64 01 00    	add    $0x16440,%esi
	pages[0].pp_ref = 1;
f0100ed2:	8b 86 ac 1f 00 00    	mov    0x1fac(%esi),%eax
f0100ed8:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f0100ede:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	for (i = 1; i < npages; i++) 
f0100ee4:	bf 08 00 00 00       	mov    $0x8,%edi
f0100ee9:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100eee:	eb 32                	jmp    f0100f22 <page_init+0x64>
		} else if (i >= EXTPHYSMEM / PGSIZE && i < ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE) 
f0100ef0:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100ef6:	77 53                	ja     f0100f4b <page_init+0x8d>
			pages[i].pp_ref = 0;
f0100ef8:	89 f8                	mov    %edi,%eax
f0100efa:	03 86 ac 1f 00 00    	add    0x1fac(%esi),%eax
f0100f00:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
			pages[i].pp_link = page_free_list;
f0100f06:	8b 96 bc 1f 00 00    	mov    0x1fbc(%esi),%edx
f0100f0c:	89 10                	mov    %edx,(%eax)
			page_free_list = &pages[i];
f0100f0e:	89 f8                	mov    %edi,%eax
f0100f10:	03 86 ac 1f 00 00    	add    0x1fac(%esi),%eax
f0100f16:	89 86 bc 1f 00 00    	mov    %eax,0x1fbc(%esi)
	for (i = 1; i < npages; i++) 
f0100f1c:	83 c3 01             	add    $0x1,%ebx
f0100f1f:	83 c7 08             	add    $0x8,%edi
f0100f22:	39 9e b4 1f 00 00    	cmp    %ebx,0x1fb4(%esi)
f0100f28:	76 4d                	jbe    f0100f77 <page_init+0xb9>
		if (i >= IOPHYSMEM / PGSIZE && i < EXTPHYSMEM / PGSIZE) 
f0100f2a:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100f30:	83 f8 5f             	cmp    $0x5f,%eax
f0100f33:	77 bb                	ja     f0100ef0 <page_init+0x32>
			pages[i].pp_ref = 1;
f0100f35:	89 f8                	mov    %edi,%eax
f0100f37:	03 86 ac 1f 00 00    	add    0x1fac(%esi),%eax
f0100f3d:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f43:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100f49:	eb d1                	jmp    f0100f1c <page_init+0x5e>
		} else if (i >= EXTPHYSMEM / PGSIZE && i < ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE) 
f0100f4b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f50:	e8 f3 fa ff ff       	call   f0100a48 <boot_alloc>
f0100f55:	05 00 00 00 10       	add    $0x10000000,%eax
f0100f5a:	c1 e8 0c             	shr    $0xc,%eax
f0100f5d:	39 d8                	cmp    %ebx,%eax
f0100f5f:	76 97                	jbe    f0100ef8 <page_init+0x3a>
			pages[i].pp_ref = 1;
f0100f61:	89 f8                	mov    %edi,%eax
f0100f63:	03 86 ac 1f 00 00    	add    0x1fac(%esi),%eax
f0100f69:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f6f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100f75:	eb a5                	jmp    f0100f1c <page_init+0x5e>
}
f0100f77:	83 c4 0c             	add    $0xc,%esp
f0100f7a:	5b                   	pop    %ebx
f0100f7b:	5e                   	pop    %esi
f0100f7c:	5f                   	pop    %edi
f0100f7d:	5d                   	pop    %ebp
f0100f7e:	c3                   	ret    

f0100f7f <page_alloc>:
{
f0100f7f:	55                   	push   %ebp
f0100f80:	89 e5                	mov    %esp,%ebp
f0100f82:	56                   	push   %esi
f0100f83:	53                   	push   %ebx
f0100f84:	e8 c6 f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100f89:	81 c3 83 63 01 00    	add    $0x16383,%ebx
	if (page_free_list == NULL) 
f0100f8f:	8b b3 bc 1f 00 00    	mov    0x1fbc(%ebx),%esi
f0100f95:	85 f6                	test   %esi,%esi
f0100f97:	74 14                	je     f0100fad <page_alloc+0x2e>
	page_free_list = page_free_list->pp_link;
f0100f99:	8b 06                	mov    (%esi),%eax
f0100f9b:	89 83 bc 1f 00 00    	mov    %eax,0x1fbc(%ebx)
	page->pp_link = NULL;
f0100fa1:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if (alloc_flags & ALLOC_ZERO) 
f0100fa7:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100fab:	75 09                	jne    f0100fb6 <page_alloc+0x37>
}
f0100fad:	89 f0                	mov    %esi,%eax
f0100faf:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100fb2:	5b                   	pop    %ebx
f0100fb3:	5e                   	pop    %esi
f0100fb4:	5d                   	pop    %ebp
f0100fb5:	c3                   	ret    
f0100fb6:	89 f0                	mov    %esi,%eax
f0100fb8:	2b 83 ac 1f 00 00    	sub    0x1fac(%ebx),%eax
f0100fbe:	c1 f8 03             	sar    $0x3,%eax
f0100fc1:	89 c2                	mov    %eax,%edx
f0100fc3:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0100fc6:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0100fcb:	3b 83 b4 1f 00 00    	cmp    0x1fb4(%ebx),%eax
f0100fd1:	73 1b                	jae    f0100fee <page_alloc+0x6f>
		memset(page2kva(page), 0, PGSIZE);
f0100fd3:	83 ec 04             	sub    $0x4,%esp
f0100fd6:	68 00 10 00 00       	push   $0x1000
f0100fdb:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100fdd:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0100fe3:	52                   	push   %edx
f0100fe4:	e8 8f 2c 00 00       	call   f0103c78 <memset>
f0100fe9:	83 c4 10             	add    $0x10,%esp
f0100fec:	eb bf                	jmp    f0100fad <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fee:	52                   	push   %edx
f0100fef:	8d 83 b8 d5 fe ff    	lea    -0x12a48(%ebx),%eax
f0100ff5:	50                   	push   %eax
f0100ff6:	6a 52                	push   $0x52
f0100ff8:	8d 83 ad d2 fe ff    	lea    -0x12d53(%ebx),%eax
f0100ffe:	50                   	push   %eax
f0100fff:	e8 95 f0 ff ff       	call   f0100099 <_panic>

f0101004 <page_free>:
{
f0101004:	55                   	push   %ebp
f0101005:	89 e5                	mov    %esp,%ebp
f0101007:	53                   	push   %ebx
f0101008:	83 ec 04             	sub    $0x4,%esp
f010100b:	e8 3f f1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101010:	81 c3 fc 62 01 00    	add    $0x162fc,%ebx
f0101016:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref != 0) 
f0101019:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010101e:	75 18                	jne    f0101038 <page_free+0x34>
	if (pp->pp_link != NULL) 
f0101020:	83 38 00             	cmpl   $0x0,(%eax)
f0101023:	75 2e                	jne    f0101053 <page_free+0x4f>
	pp->pp_link = page_free_list;
f0101025:	8b 8b bc 1f 00 00    	mov    0x1fbc(%ebx),%ecx
f010102b:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f010102d:	89 83 bc 1f 00 00    	mov    %eax,0x1fbc(%ebx)
}
f0101033:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101036:	c9                   	leave  
f0101037:	c3                   	ret    
		panic("pp_ref non-NULL\n");
f0101038:	83 ec 04             	sub    $0x4,%esp
f010103b:	8d 83 57 d3 fe ff    	lea    -0x12ca9(%ebx),%eax
f0101041:	50                   	push   %eax
f0101042:	68 53 01 00 00       	push   $0x153
f0101047:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010104d:	50                   	push   %eax
f010104e:	e8 46 f0 ff ff       	call   f0100099 <_panic>
		panic("pp_link non-NULL\n");
f0101053:	83 ec 04             	sub    $0x4,%esp
f0101056:	8d 83 68 d3 fe ff    	lea    -0x12c98(%ebx),%eax
f010105c:	50                   	push   %eax
f010105d:	68 57 01 00 00       	push   $0x157
f0101062:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0101068:	50                   	push   %eax
f0101069:	e8 2b f0 ff ff       	call   f0100099 <_panic>

f010106e <page_decref>:
{
f010106e:	55                   	push   %ebp
f010106f:	89 e5                	mov    %esp,%ebp
f0101071:	83 ec 08             	sub    $0x8,%esp
f0101074:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101077:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010107b:	83 e8 01             	sub    $0x1,%eax
f010107e:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101082:	66 85 c0             	test   %ax,%ax
f0101085:	74 02                	je     f0101089 <page_decref+0x1b>
}
f0101087:	c9                   	leave  
f0101088:	c3                   	ret    
		page_free(pp);
f0101089:	83 ec 0c             	sub    $0xc,%esp
f010108c:	52                   	push   %edx
f010108d:	e8 72 ff ff ff       	call   f0101004 <page_free>
f0101092:	83 c4 10             	add    $0x10,%esp
}
f0101095:	eb f0                	jmp    f0101087 <page_decref+0x19>

f0101097 <pgdir_walk>:
{
f0101097:	55                   	push   %ebp
f0101098:	89 e5                	mov    %esp,%ebp
f010109a:	57                   	push   %edi
f010109b:	56                   	push   %esi
f010109c:	53                   	push   %ebx
f010109d:	83 ec 0c             	sub    $0xc,%esp
f01010a0:	e8 47 1f 00 00       	call   f0102fec <__x86.get_pc_thunk.di>
f01010a5:	81 c7 67 62 01 00    	add    $0x16267,%edi
f01010ab:	8b 75 0c             	mov    0xc(%ebp),%esi
	uintptr_t* pt_addr = pgdir + PDX(va);
f01010ae:	89 f3                	mov    %esi,%ebx
f01010b0:	c1 eb 16             	shr    $0x16,%ebx
f01010b3:	c1 e3 02             	shl    $0x2,%ebx
f01010b6:	03 5d 08             	add    0x8(%ebp),%ebx
	if (*pt_addr & PTE_P) 
f01010b9:	8b 03                	mov    (%ebx),%eax
f01010bb:	a8 01                	test   $0x1,%al
f01010bd:	75 58                	jne    f0101117 <pgdir_walk+0x80>
	if (create == false) 
f01010bf:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01010c3:	0f 84 a9 00 00 00    	je     f0101172 <pgdir_walk+0xdb>
	struct PageInfo* new_pg = page_alloc(ALLOC_ZERO);
f01010c9:	83 ec 0c             	sub    $0xc,%esp
f01010cc:	6a 01                	push   $0x1
f01010ce:	e8 ac fe ff ff       	call   f0100f7f <page_alloc>
	if (new_pg == NULL) 
f01010d3:	83 c4 10             	add    $0x10,%esp
f01010d6:	85 c0                	test   %eax,%eax
f01010d8:	74 35                	je     f010110f <pgdir_walk+0x78>
	new_pg->pp_ref ++;
f01010da:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01010df:	2b 87 ac 1f 00 00    	sub    0x1fac(%edi),%eax
f01010e5:	c1 f8 03             	sar    $0x3,%eax
f01010e8:	c1 e0 0c             	shl    $0xc,%eax
	*pt_addr = page2pa(new_pg) | PTE_U | PTE_W | PTE_P;
f01010eb:	89 c2                	mov    %eax,%edx
f01010ed:	83 ca 07             	or     $0x7,%edx
f01010f0:	89 13                	mov    %edx,(%ebx)
	if (PGNUM(pa) >= npages)
f01010f2:	89 c2                	mov    %eax,%edx
f01010f4:	c1 ea 0c             	shr    $0xc,%edx
f01010f7:	3b 97 b4 1f 00 00    	cmp    0x1fb4(%edi),%edx
f01010fd:	73 58                	jae    f0101157 <pgdir_walk+0xc0>
	return (pte_t *)KADDR(PTE_ADDR(*pt_addr)) + PTX(va);
f01010ff:	c1 ee 0a             	shr    $0xa,%esi
f0101102:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101108:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
}
f010110f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101112:	5b                   	pop    %ebx
f0101113:	5e                   	pop    %esi
f0101114:	5f                   	pop    %edi
f0101115:	5d                   	pop    %ebp
f0101116:	c3                   	ret    
		return (pte_t*)KADDR(PTE_ADDR(*pt_addr)) + PTX(va);
f0101117:	89 c2                	mov    %eax,%edx
f0101119:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010111f:	c1 e8 0c             	shr    $0xc,%eax
f0101122:	3b 87 b4 1f 00 00    	cmp    0x1fb4(%edi),%eax
f0101128:	73 12                	jae    f010113c <pgdir_walk+0xa5>
f010112a:	c1 ee 0a             	shr    $0xa,%esi
f010112d:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101133:	8d 84 32 00 00 00 f0 	lea    -0x10000000(%edx,%esi,1),%eax
f010113a:	eb d3                	jmp    f010110f <pgdir_walk+0x78>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010113c:	52                   	push   %edx
f010113d:	8d 87 b8 d5 fe ff    	lea    -0x12a48(%edi),%eax
f0101143:	50                   	push   %eax
f0101144:	68 89 01 00 00       	push   $0x189
f0101149:	8d 87 a1 d2 fe ff    	lea    -0x12d5f(%edi),%eax
f010114f:	50                   	push   %eax
f0101150:	89 fb                	mov    %edi,%ebx
f0101152:	e8 42 ef ff ff       	call   f0100099 <_panic>
f0101157:	50                   	push   %eax
f0101158:	8d 87 b8 d5 fe ff    	lea    -0x12a48(%edi),%eax
f010115e:	50                   	push   %eax
f010115f:	68 9a 01 00 00       	push   $0x19a
f0101164:	8d 87 a1 d2 fe ff    	lea    -0x12d5f(%edi),%eax
f010116a:	50                   	push   %eax
f010116b:	89 fb                	mov    %edi,%ebx
f010116d:	e8 27 ef ff ff       	call   f0100099 <_panic>
		return NULL;
f0101172:	b8 00 00 00 00       	mov    $0x0,%eax
f0101177:	eb 96                	jmp    f010110f <pgdir_walk+0x78>

f0101179 <boot_map_region>:
{
f0101179:	55                   	push   %ebp
f010117a:	89 e5                	mov    %esp,%ebp
f010117c:	57                   	push   %edi
f010117d:	56                   	push   %esi
f010117e:	53                   	push   %ebx
f010117f:	83 ec 1c             	sub    $0x1c,%esp
f0101182:	e8 65 1e 00 00       	call   f0102fec <__x86.get_pc_thunk.di>
f0101187:	81 c7 85 61 01 00    	add    $0x16185,%edi
f010118d:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0101190:	89 c7                	mov    %eax,%edi
f0101192:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101195:	89 ce                	mov    %ecx,%esi
	for (size_t i = 0; i < size; i += PGSIZE) 
f0101197:	bb 00 00 00 00       	mov    $0x0,%ebx
f010119c:	39 f3                	cmp    %esi,%ebx
f010119e:	73 4d                	jae    f01011ed <boot_map_region+0x74>
		p = pgdir_walk(pgdir, (void*)(va + i), 1);
f01011a0:	83 ec 04             	sub    $0x4,%esp
f01011a3:	6a 01                	push   $0x1
f01011a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011a8:	01 d8                	add    %ebx,%eax
f01011aa:	50                   	push   %eax
f01011ab:	57                   	push   %edi
f01011ac:	e8 e6 fe ff ff       	call   f0101097 <pgdir_walk>
f01011b1:	89 c2                	mov    %eax,%edx
		if (p == NULL) 
f01011b3:	83 c4 10             	add    $0x10,%esp
f01011b6:	85 c0                	test   %eax,%eax
f01011b8:	74 15                	je     f01011cf <boot_map_region+0x56>
		*p = (pa + i) | perm | PTE_P;
f01011ba:	89 d8                	mov    %ebx,%eax
f01011bc:	03 45 08             	add    0x8(%ebp),%eax
f01011bf:	0b 45 0c             	or     0xc(%ebp),%eax
f01011c2:	83 c8 01             	or     $0x1,%eax
f01011c5:	89 02                	mov    %eax,(%edx)
	for (size_t i = 0; i < size; i += PGSIZE) 
f01011c7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01011cd:	eb cd                	jmp    f010119c <boot_map_region+0x23>
			panic("Mapping failed\n");
f01011cf:	83 ec 04             	sub    $0x4,%esp
f01011d2:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01011d5:	8d 83 7a d3 fe ff    	lea    -0x12c86(%ebx),%eax
f01011db:	50                   	push   %eax
f01011dc:	68 b5 01 00 00       	push   $0x1b5
f01011e1:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01011e7:	50                   	push   %eax
f01011e8:	e8 ac ee ff ff       	call   f0100099 <_panic>
}
f01011ed:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011f0:	5b                   	pop    %ebx
f01011f1:	5e                   	pop    %esi
f01011f2:	5f                   	pop    %edi
f01011f3:	5d                   	pop    %ebp
f01011f4:	c3                   	ret    

f01011f5 <page_lookup>:
{
f01011f5:	55                   	push   %ebp
f01011f6:	89 e5                	mov    %esp,%ebp
f01011f8:	56                   	push   %esi
f01011f9:	53                   	push   %ebx
f01011fa:	e8 50 ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01011ff:	81 c3 0d 61 01 00    	add    $0x1610d,%ebx
f0101205:	8b 75 10             	mov    0x10(%ebp),%esi
	uintptr_t* p = pgdir_walk(pgdir, va, 0);
f0101208:	83 ec 04             	sub    $0x4,%esp
f010120b:	6a 00                	push   $0x0
f010120d:	ff 75 0c             	push   0xc(%ebp)
f0101210:	ff 75 08             	push   0x8(%ebp)
f0101213:	e8 7f fe ff ff       	call   f0101097 <pgdir_walk>
	if (p == NULL || (*p & PTE_P) == 0) 
f0101218:	83 c4 10             	add    $0x10,%esp
f010121b:	85 c0                	test   %eax,%eax
f010121d:	74 21                	je     f0101240 <page_lookup+0x4b>
f010121f:	f6 00 01             	testb  $0x1,(%eax)
f0101222:	74 3b                	je     f010125f <page_lookup+0x6a>
	if (pte_store != 0) 
f0101224:	85 f6                	test   %esi,%esi
f0101226:	74 02                	je     f010122a <page_lookup+0x35>
		*pte_store = p;
f0101228:	89 06                	mov    %eax,(%esi)
f010122a:	8b 00                	mov    (%eax),%eax
f010122c:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010122f:	39 83 b4 1f 00 00    	cmp    %eax,0x1fb4(%ebx)
f0101235:	76 10                	jbe    f0101247 <page_lookup+0x52>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101237:	8b 93 ac 1f 00 00    	mov    0x1fac(%ebx),%edx
f010123d:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0101240:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101243:	5b                   	pop    %ebx
f0101244:	5e                   	pop    %esi
f0101245:	5d                   	pop    %ebp
f0101246:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101247:	83 ec 04             	sub    $0x4,%esp
f010124a:	8d 83 c4 d6 fe ff    	lea    -0x1293c(%ebx),%eax
f0101250:	50                   	push   %eax
f0101251:	6a 4b                	push   $0x4b
f0101253:	8d 83 ad d2 fe ff    	lea    -0x12d53(%ebx),%eax
f0101259:	50                   	push   %eax
f010125a:	e8 3a ee ff ff       	call   f0100099 <_panic>
		return NULL;
f010125f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101264:	eb da                	jmp    f0101240 <page_lookup+0x4b>

f0101266 <page_remove>:
{
f0101266:	55                   	push   %ebp
f0101267:	89 e5                	mov    %esp,%ebp
f0101269:	53                   	push   %ebx
f010126a:	83 ec 18             	sub    $0x18,%esp
f010126d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *pg = page_lookup(pgdir, va, &p);
f0101270:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101273:	50                   	push   %eax
f0101274:	53                   	push   %ebx
f0101275:	ff 75 08             	push   0x8(%ebp)
f0101278:	e8 78 ff ff ff       	call   f01011f5 <page_lookup>
	if (pg == NULL) 
f010127d:	83 c4 10             	add    $0x10,%esp
f0101280:	85 c0                	test   %eax,%eax
f0101282:	74 18                	je     f010129c <page_remove+0x36>
	page_decref(pg);
f0101284:	83 ec 0c             	sub    $0xc,%esp
f0101287:	50                   	push   %eax
f0101288:	e8 e1 fd ff ff       	call   f010106e <page_decref>
	*p = 0;
f010128d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101290:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101296:	0f 01 3b             	invlpg (%ebx)
f0101299:	83 c4 10             	add    $0x10,%esp
}
f010129c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010129f:	c9                   	leave  
f01012a0:	c3                   	ret    

f01012a1 <page_insert>:
{
f01012a1:	55                   	push   %ebp
f01012a2:	89 e5                	mov    %esp,%ebp
f01012a4:	57                   	push   %edi
f01012a5:	56                   	push   %esi
f01012a6:	53                   	push   %ebx
f01012a7:	83 ec 10             	sub    $0x10,%esp
f01012aa:	e8 3d 1d 00 00       	call   f0102fec <__x86.get_pc_thunk.di>
f01012af:	81 c7 5d 60 01 00    	add    $0x1605d,%edi
f01012b5:	8b 75 08             	mov    0x8(%ebp),%esi
	uintptr_t* p = pgdir_walk(pgdir, va, 1);
f01012b8:	6a 01                	push   $0x1
f01012ba:	ff 75 10             	push   0x10(%ebp)
f01012bd:	56                   	push   %esi
f01012be:	e8 d4 fd ff ff       	call   f0101097 <pgdir_walk>
	if (p == NULL) 
f01012c3:	83 c4 10             	add    $0x10,%esp
f01012c6:	85 c0                	test   %eax,%eax
f01012c8:	74 50                	je     f010131a <page_insert+0x79>
f01012ca:	89 c3                	mov    %eax,%ebx
	pp->pp_ref ++;
f01012cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012cf:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	if ((*p & PTE_P) == 1) 
f01012d4:	f6 03 01             	testb  $0x1,(%ebx)
f01012d7:	75 30                	jne    f0101309 <page_insert+0x68>
	return (pp - pages) << PGSHIFT;
f01012d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012dc:	2b 87 ac 1f 00 00    	sub    0x1fac(%edi),%eax
f01012e2:	c1 f8 03             	sar    $0x3,%eax
f01012e5:	c1 e0 0c             	shl    $0xc,%eax
	*p = page2pa(pp) | perm | PTE_P;
f01012e8:	0b 45 14             	or     0x14(%ebp),%eax
f01012eb:	83 c8 01             	or     $0x1,%eax
f01012ee:	89 03                	mov    %eax,(%ebx)
	*(pgdir + PDX(va)) |= perm;
f01012f0:	8b 45 10             	mov    0x10(%ebp),%eax
f01012f3:	c1 e8 16             	shr    $0x16,%eax
f01012f6:	8b 55 14             	mov    0x14(%ebp),%edx
f01012f9:	09 14 86             	or     %edx,(%esi,%eax,4)
	return 0;
f01012fc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101301:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101304:	5b                   	pop    %ebx
f0101305:	5e                   	pop    %esi
f0101306:	5f                   	pop    %edi
f0101307:	5d                   	pop    %ebp
f0101308:	c3                   	ret    
		page_remove(pgdir, va);
f0101309:	83 ec 08             	sub    $0x8,%esp
f010130c:	ff 75 10             	push   0x10(%ebp)
f010130f:	56                   	push   %esi
f0101310:	e8 51 ff ff ff       	call   f0101266 <page_remove>
f0101315:	83 c4 10             	add    $0x10,%esp
f0101318:	eb bf                	jmp    f01012d9 <page_insert+0x38>
		return -E_NO_MEM;
f010131a:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010131f:	eb e0                	jmp    f0101301 <page_insert+0x60>

f0101321 <mem_init>:
{
f0101321:	55                   	push   %ebp
f0101322:	89 e5                	mov    %esp,%ebp
f0101324:	57                   	push   %edi
f0101325:	56                   	push   %esi
f0101326:	53                   	push   %ebx
f0101327:	83 ec 3c             	sub    $0x3c,%esp
f010132a:	e8 b2 f3 ff ff       	call   f01006e1 <__x86.get_pc_thunk.ax>
f010132f:	05 dd 5f 01 00       	add    $0x15fdd,%eax
f0101334:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f0101337:	b8 15 00 00 00       	mov    $0x15,%eax
f010133c:	e8 d1 f6 ff ff       	call   f0100a12 <nvram_read>
f0101341:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101343:	b8 17 00 00 00       	mov    $0x17,%eax
f0101348:	e8 c5 f6 ff ff       	call   f0100a12 <nvram_read>
f010134d:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010134f:	b8 34 00 00 00       	mov    $0x34,%eax
f0101354:	e8 b9 f6 ff ff       	call   f0100a12 <nvram_read>
	if (ext16mem)
f0101359:	c1 e0 06             	shl    $0x6,%eax
f010135c:	0f 84 c0 00 00 00    	je     f0101422 <mem_init+0x101>
		totalmem = 16 * 1024 + ext16mem;
f0101362:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f0101367:	89 c2                	mov    %eax,%edx
f0101369:	c1 ea 02             	shr    $0x2,%edx
f010136c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010136f:	89 91 b4 1f 00 00    	mov    %edx,0x1fb4(%ecx)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101375:	89 c2                	mov    %eax,%edx
f0101377:	29 da                	sub    %ebx,%edx
f0101379:	52                   	push   %edx
f010137a:	53                   	push   %ebx
f010137b:	50                   	push   %eax
f010137c:	8d 81 e4 d6 fe ff    	lea    -0x1291c(%ecx),%eax
f0101382:	50                   	push   %eax
f0101383:	89 cb                	mov    %ecx,%ebx
f0101385:	e8 ed 1c 00 00       	call   f0103077 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010138a:	b8 00 10 00 00       	mov    $0x1000,%eax
f010138f:	e8 b4 f6 ff ff       	call   f0100a48 <boot_alloc>
f0101394:	89 83 b0 1f 00 00    	mov    %eax,0x1fb0(%ebx)
	memset(kern_pgdir, 0, PGSIZE);
f010139a:	83 c4 0c             	add    $0xc,%esp
f010139d:	68 00 10 00 00       	push   $0x1000
f01013a2:	6a 00                	push   $0x0
f01013a4:	50                   	push   %eax
f01013a5:	e8 ce 28 00 00       	call   f0103c78 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013aa:	8b 83 b0 1f 00 00    	mov    0x1fb0(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f01013b0:	83 c4 10             	add    $0x10,%esp
f01013b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013b8:	76 78                	jbe    f0101432 <mem_init+0x111>
	return (physaddr_t)kva - KERNBASE;
f01013ba:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013c0:	83 ca 05             	or     $0x5,%edx
f01013c3:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo*)boot_alloc(npages * sizeof(struct PageInfo));
f01013c9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01013cc:	8b 87 b4 1f 00 00    	mov    0x1fb4(%edi),%eax
f01013d2:	c1 e0 03             	shl    $0x3,%eax
f01013d5:	e8 6e f6 ff ff       	call   f0100a48 <boot_alloc>
f01013da:	89 87 ac 1f 00 00    	mov    %eax,0x1fac(%edi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01013e0:	83 ec 04             	sub    $0x4,%esp
f01013e3:	8b 97 b4 1f 00 00    	mov    0x1fb4(%edi),%edx
f01013e9:	c1 e2 03             	shl    $0x3,%edx
f01013ec:	52                   	push   %edx
f01013ed:	6a 00                	push   $0x0
f01013ef:	50                   	push   %eax
f01013f0:	89 fb                	mov    %edi,%ebx
f01013f2:	e8 81 28 00 00       	call   f0103c78 <memset>
	page_init();
f01013f7:	e8 c2 fa ff ff       	call   f0100ebe <page_init>
	check_page_free_list(1);
f01013fc:	b8 01 00 00 00       	mov    $0x1,%eax
f0101401:	e8 4c f7 ff ff       	call   f0100b52 <check_page_free_list>
	if (!pages)
f0101406:	83 c4 10             	add    $0x10,%esp
f0101409:	83 bf ac 1f 00 00 00 	cmpl   $0x0,0x1fac(%edi)
f0101410:	74 3c                	je     f010144e <mem_init+0x12d>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101412:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101415:	8b 80 bc 1f 00 00    	mov    0x1fbc(%eax),%eax
f010141b:	be 00 00 00 00       	mov    $0x0,%esi
f0101420:	eb 4f                	jmp    f0101471 <mem_init+0x150>
		totalmem = 1 * 1024 + extmem;
f0101422:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0101428:	85 f6                	test   %esi,%esi
f010142a:	0f 44 c3             	cmove  %ebx,%eax
f010142d:	e9 35 ff ff ff       	jmp    f0101367 <mem_init+0x46>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101432:	50                   	push   %eax
f0101433:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101436:	8d 83 20 d7 fe ff    	lea    -0x128e0(%ebx),%eax
f010143c:	50                   	push   %eax
f010143d:	68 97 00 00 00       	push   $0x97
f0101442:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0101448:	50                   	push   %eax
f0101449:	e8 4b ec ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f010144e:	83 ec 04             	sub    $0x4,%esp
f0101451:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101454:	8d 83 8a d3 fe ff    	lea    -0x12c76(%ebx),%eax
f010145a:	50                   	push   %eax
f010145b:	68 86 02 00 00       	push   $0x286
f0101460:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0101466:	50                   	push   %eax
f0101467:	e8 2d ec ff ff       	call   f0100099 <_panic>
		++nfree;
f010146c:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010146f:	8b 00                	mov    (%eax),%eax
f0101471:	85 c0                	test   %eax,%eax
f0101473:	75 f7                	jne    f010146c <mem_init+0x14b>
	assert((pp0 = page_alloc(0)));
f0101475:	83 ec 0c             	sub    $0xc,%esp
f0101478:	6a 00                	push   $0x0
f010147a:	e8 00 fb ff ff       	call   f0100f7f <page_alloc>
f010147f:	89 c3                	mov    %eax,%ebx
f0101481:	83 c4 10             	add    $0x10,%esp
f0101484:	85 c0                	test   %eax,%eax
f0101486:	0f 84 3a 02 00 00    	je     f01016c6 <mem_init+0x3a5>
	assert((pp1 = page_alloc(0)));
f010148c:	83 ec 0c             	sub    $0xc,%esp
f010148f:	6a 00                	push   $0x0
f0101491:	e8 e9 fa ff ff       	call   f0100f7f <page_alloc>
f0101496:	89 c7                	mov    %eax,%edi
f0101498:	83 c4 10             	add    $0x10,%esp
f010149b:	85 c0                	test   %eax,%eax
f010149d:	0f 84 45 02 00 00    	je     f01016e8 <mem_init+0x3c7>
	assert((pp2 = page_alloc(0)));
f01014a3:	83 ec 0c             	sub    $0xc,%esp
f01014a6:	6a 00                	push   $0x0
f01014a8:	e8 d2 fa ff ff       	call   f0100f7f <page_alloc>
f01014ad:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01014b0:	83 c4 10             	add    $0x10,%esp
f01014b3:	85 c0                	test   %eax,%eax
f01014b5:	0f 84 4f 02 00 00    	je     f010170a <mem_init+0x3e9>
	assert(pp1 && pp1 != pp0);
f01014bb:	39 fb                	cmp    %edi,%ebx
f01014bd:	0f 84 69 02 00 00    	je     f010172c <mem_init+0x40b>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014c3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014c6:	39 c3                	cmp    %eax,%ebx
f01014c8:	0f 84 80 02 00 00    	je     f010174e <mem_init+0x42d>
f01014ce:	39 c7                	cmp    %eax,%edi
f01014d0:	0f 84 78 02 00 00    	je     f010174e <mem_init+0x42d>
	return (pp - pages) << PGSHIFT;
f01014d6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014d9:	8b 88 ac 1f 00 00    	mov    0x1fac(%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f01014df:	8b 90 b4 1f 00 00    	mov    0x1fb4(%eax),%edx
f01014e5:	c1 e2 0c             	shl    $0xc,%edx
f01014e8:	89 d8                	mov    %ebx,%eax
f01014ea:	29 c8                	sub    %ecx,%eax
f01014ec:	c1 f8 03             	sar    $0x3,%eax
f01014ef:	c1 e0 0c             	shl    $0xc,%eax
f01014f2:	39 d0                	cmp    %edx,%eax
f01014f4:	0f 83 76 02 00 00    	jae    f0101770 <mem_init+0x44f>
f01014fa:	89 f8                	mov    %edi,%eax
f01014fc:	29 c8                	sub    %ecx,%eax
f01014fe:	c1 f8 03             	sar    $0x3,%eax
f0101501:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101504:	39 c2                	cmp    %eax,%edx
f0101506:	0f 86 86 02 00 00    	jbe    f0101792 <mem_init+0x471>
f010150c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010150f:	29 c8                	sub    %ecx,%eax
f0101511:	c1 f8 03             	sar    $0x3,%eax
f0101514:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f0101517:	39 c2                	cmp    %eax,%edx
f0101519:	0f 86 95 02 00 00    	jbe    f01017b4 <mem_init+0x493>
	fl = page_free_list;
f010151f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101522:	8b 88 bc 1f 00 00    	mov    0x1fbc(%eax),%ecx
f0101528:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f010152b:	c7 80 bc 1f 00 00 00 	movl   $0x0,0x1fbc(%eax)
f0101532:	00 00 00 
	assert(!page_alloc(0));
f0101535:	83 ec 0c             	sub    $0xc,%esp
f0101538:	6a 00                	push   $0x0
f010153a:	e8 40 fa ff ff       	call   f0100f7f <page_alloc>
f010153f:	83 c4 10             	add    $0x10,%esp
f0101542:	85 c0                	test   %eax,%eax
f0101544:	0f 85 8c 02 00 00    	jne    f01017d6 <mem_init+0x4b5>
	page_free(pp0);
f010154a:	83 ec 0c             	sub    $0xc,%esp
f010154d:	53                   	push   %ebx
f010154e:	e8 b1 fa ff ff       	call   f0101004 <page_free>
	page_free(pp1);
f0101553:	89 3c 24             	mov    %edi,(%esp)
f0101556:	e8 a9 fa ff ff       	call   f0101004 <page_free>
	page_free(pp2);
f010155b:	83 c4 04             	add    $0x4,%esp
f010155e:	ff 75 d0             	push   -0x30(%ebp)
f0101561:	e8 9e fa ff ff       	call   f0101004 <page_free>
	assert((pp0 = page_alloc(0)));
f0101566:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010156d:	e8 0d fa ff ff       	call   f0100f7f <page_alloc>
f0101572:	89 c7                	mov    %eax,%edi
f0101574:	83 c4 10             	add    $0x10,%esp
f0101577:	85 c0                	test   %eax,%eax
f0101579:	0f 84 79 02 00 00    	je     f01017f8 <mem_init+0x4d7>
	assert((pp1 = page_alloc(0)));
f010157f:	83 ec 0c             	sub    $0xc,%esp
f0101582:	6a 00                	push   $0x0
f0101584:	e8 f6 f9 ff ff       	call   f0100f7f <page_alloc>
f0101589:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010158c:	83 c4 10             	add    $0x10,%esp
f010158f:	85 c0                	test   %eax,%eax
f0101591:	0f 84 83 02 00 00    	je     f010181a <mem_init+0x4f9>
	assert((pp2 = page_alloc(0)));
f0101597:	83 ec 0c             	sub    $0xc,%esp
f010159a:	6a 00                	push   $0x0
f010159c:	e8 de f9 ff ff       	call   f0100f7f <page_alloc>
f01015a1:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01015a4:	83 c4 10             	add    $0x10,%esp
f01015a7:	85 c0                	test   %eax,%eax
f01015a9:	0f 84 8d 02 00 00    	je     f010183c <mem_init+0x51b>
	assert(pp1 && pp1 != pp0);
f01015af:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f01015b2:	0f 84 a6 02 00 00    	je     f010185e <mem_init+0x53d>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015b8:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01015bb:	39 c7                	cmp    %eax,%edi
f01015bd:	0f 84 bd 02 00 00    	je     f0101880 <mem_init+0x55f>
f01015c3:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01015c6:	0f 84 b4 02 00 00    	je     f0101880 <mem_init+0x55f>
	assert(!page_alloc(0));
f01015cc:	83 ec 0c             	sub    $0xc,%esp
f01015cf:	6a 00                	push   $0x0
f01015d1:	e8 a9 f9 ff ff       	call   f0100f7f <page_alloc>
f01015d6:	83 c4 10             	add    $0x10,%esp
f01015d9:	85 c0                	test   %eax,%eax
f01015db:	0f 85 c1 02 00 00    	jne    f01018a2 <mem_init+0x581>
f01015e1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01015e4:	89 f8                	mov    %edi,%eax
f01015e6:	2b 81 ac 1f 00 00    	sub    0x1fac(%ecx),%eax
f01015ec:	c1 f8 03             	sar    $0x3,%eax
f01015ef:	89 c2                	mov    %eax,%edx
f01015f1:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01015f4:	25 ff ff 0f 00       	and    $0xfffff,%eax
f01015f9:	3b 81 b4 1f 00 00    	cmp    0x1fb4(%ecx),%eax
f01015ff:	0f 83 bf 02 00 00    	jae    f01018c4 <mem_init+0x5a3>
	memset(page2kva(pp0), 1, PGSIZE);
f0101605:	83 ec 04             	sub    $0x4,%esp
f0101608:	68 00 10 00 00       	push   $0x1000
f010160d:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f010160f:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101615:	52                   	push   %edx
f0101616:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101619:	e8 5a 26 00 00       	call   f0103c78 <memset>
	page_free(pp0);
f010161e:	89 3c 24             	mov    %edi,(%esp)
f0101621:	e8 de f9 ff ff       	call   f0101004 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101626:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010162d:	e8 4d f9 ff ff       	call   f0100f7f <page_alloc>
f0101632:	83 c4 10             	add    $0x10,%esp
f0101635:	85 c0                	test   %eax,%eax
f0101637:	0f 84 9f 02 00 00    	je     f01018dc <mem_init+0x5bb>
	assert(pp && pp0 == pp);
f010163d:	39 c7                	cmp    %eax,%edi
f010163f:	0f 85 b9 02 00 00    	jne    f01018fe <mem_init+0x5dd>
	return (pp - pages) << PGSHIFT;
f0101645:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101648:	2b 81 ac 1f 00 00    	sub    0x1fac(%ecx),%eax
f010164e:	c1 f8 03             	sar    $0x3,%eax
f0101651:	89 c2                	mov    %eax,%edx
f0101653:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101656:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010165b:	3b 81 b4 1f 00 00    	cmp    0x1fb4(%ecx),%eax
f0101661:	0f 83 b9 02 00 00    	jae    f0101920 <mem_init+0x5ff>
	return (void *)(pa + KERNBASE);
f0101667:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f010166d:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101673:	80 38 00             	cmpb   $0x0,(%eax)
f0101676:	0f 85 bc 02 00 00    	jne    f0101938 <mem_init+0x617>
	for (i = 0; i < PGSIZE; i++)
f010167c:	83 c0 01             	add    $0x1,%eax
f010167f:	39 c2                	cmp    %eax,%edx
f0101681:	75 f0                	jne    f0101673 <mem_init+0x352>
	page_free_list = fl;
f0101683:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101686:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101689:	89 8b bc 1f 00 00    	mov    %ecx,0x1fbc(%ebx)
	page_free(pp0);
f010168f:	83 ec 0c             	sub    $0xc,%esp
f0101692:	57                   	push   %edi
f0101693:	e8 6c f9 ff ff       	call   f0101004 <page_free>
	page_free(pp1);
f0101698:	83 c4 04             	add    $0x4,%esp
f010169b:	ff 75 d0             	push   -0x30(%ebp)
f010169e:	e8 61 f9 ff ff       	call   f0101004 <page_free>
	page_free(pp2);
f01016a3:	83 c4 04             	add    $0x4,%esp
f01016a6:	ff 75 cc             	push   -0x34(%ebp)
f01016a9:	e8 56 f9 ff ff       	call   f0101004 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016ae:	8b 83 bc 1f 00 00    	mov    0x1fbc(%ebx),%eax
f01016b4:	83 c4 10             	add    $0x10,%esp
f01016b7:	85 c0                	test   %eax,%eax
f01016b9:	0f 84 9b 02 00 00    	je     f010195a <mem_init+0x639>
		--nfree;
f01016bf:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016c2:	8b 00                	mov    (%eax),%eax
f01016c4:	eb f1                	jmp    f01016b7 <mem_init+0x396>
	assert((pp0 = page_alloc(0)));
f01016c6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016c9:	8d 83 a5 d3 fe ff    	lea    -0x12c5b(%ebx),%eax
f01016cf:	50                   	push   %eax
f01016d0:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01016d6:	50                   	push   %eax
f01016d7:	68 8e 02 00 00       	push   $0x28e
f01016dc:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01016e2:	50                   	push   %eax
f01016e3:	e8 b1 e9 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01016e8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016eb:	8d 83 bb d3 fe ff    	lea    -0x12c45(%ebx),%eax
f01016f1:	50                   	push   %eax
f01016f2:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01016f8:	50                   	push   %eax
f01016f9:	68 8f 02 00 00       	push   $0x28f
f01016fe:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0101704:	50                   	push   %eax
f0101705:	e8 8f e9 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010170a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010170d:	8d 83 d1 d3 fe ff    	lea    -0x12c2f(%ebx),%eax
f0101713:	50                   	push   %eax
f0101714:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010171a:	50                   	push   %eax
f010171b:	68 90 02 00 00       	push   $0x290
f0101720:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0101726:	50                   	push   %eax
f0101727:	e8 6d e9 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010172c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010172f:	8d 83 e7 d3 fe ff    	lea    -0x12c19(%ebx),%eax
f0101735:	50                   	push   %eax
f0101736:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010173c:	50                   	push   %eax
f010173d:	68 93 02 00 00       	push   $0x293
f0101742:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0101748:	50                   	push   %eax
f0101749:	e8 4b e9 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010174e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101751:	8d 83 44 d7 fe ff    	lea    -0x128bc(%ebx),%eax
f0101757:	50                   	push   %eax
f0101758:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010175e:	50                   	push   %eax
f010175f:	68 94 02 00 00       	push   $0x294
f0101764:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010176a:	50                   	push   %eax
f010176b:	e8 29 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101770:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101773:	8d 83 f9 d3 fe ff    	lea    -0x12c07(%ebx),%eax
f0101779:	50                   	push   %eax
f010177a:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0101780:	50                   	push   %eax
f0101781:	68 95 02 00 00       	push   $0x295
f0101786:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010178c:	50                   	push   %eax
f010178d:	e8 07 e9 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101792:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101795:	8d 83 16 d4 fe ff    	lea    -0x12bea(%ebx),%eax
f010179b:	50                   	push   %eax
f010179c:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01017a2:	50                   	push   %eax
f01017a3:	68 96 02 00 00       	push   $0x296
f01017a8:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01017ae:	50                   	push   %eax
f01017af:	e8 e5 e8 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01017b4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017b7:	8d 83 33 d4 fe ff    	lea    -0x12bcd(%ebx),%eax
f01017bd:	50                   	push   %eax
f01017be:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01017c4:	50                   	push   %eax
f01017c5:	68 97 02 00 00       	push   $0x297
f01017ca:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01017d0:	50                   	push   %eax
f01017d1:	e8 c3 e8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01017d6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017d9:	8d 83 50 d4 fe ff    	lea    -0x12bb0(%ebx),%eax
f01017df:	50                   	push   %eax
f01017e0:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01017e6:	50                   	push   %eax
f01017e7:	68 9e 02 00 00       	push   $0x29e
f01017ec:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01017f2:	50                   	push   %eax
f01017f3:	e8 a1 e8 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f01017f8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017fb:	8d 83 a5 d3 fe ff    	lea    -0x12c5b(%ebx),%eax
f0101801:	50                   	push   %eax
f0101802:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0101808:	50                   	push   %eax
f0101809:	68 a5 02 00 00       	push   $0x2a5
f010180e:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0101814:	50                   	push   %eax
f0101815:	e8 7f e8 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010181a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010181d:	8d 83 bb d3 fe ff    	lea    -0x12c45(%ebx),%eax
f0101823:	50                   	push   %eax
f0101824:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010182a:	50                   	push   %eax
f010182b:	68 a6 02 00 00       	push   $0x2a6
f0101830:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0101836:	50                   	push   %eax
f0101837:	e8 5d e8 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010183c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010183f:	8d 83 d1 d3 fe ff    	lea    -0x12c2f(%ebx),%eax
f0101845:	50                   	push   %eax
f0101846:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010184c:	50                   	push   %eax
f010184d:	68 a7 02 00 00       	push   $0x2a7
f0101852:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0101858:	50                   	push   %eax
f0101859:	e8 3b e8 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f010185e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101861:	8d 83 e7 d3 fe ff    	lea    -0x12c19(%ebx),%eax
f0101867:	50                   	push   %eax
f0101868:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010186e:	50                   	push   %eax
f010186f:	68 a9 02 00 00       	push   $0x2a9
f0101874:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010187a:	50                   	push   %eax
f010187b:	e8 19 e8 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101880:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101883:	8d 83 44 d7 fe ff    	lea    -0x128bc(%ebx),%eax
f0101889:	50                   	push   %eax
f010188a:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0101890:	50                   	push   %eax
f0101891:	68 aa 02 00 00       	push   $0x2aa
f0101896:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010189c:	50                   	push   %eax
f010189d:	e8 f7 e7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01018a2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018a5:	8d 83 50 d4 fe ff    	lea    -0x12bb0(%ebx),%eax
f01018ab:	50                   	push   %eax
f01018ac:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01018b2:	50                   	push   %eax
f01018b3:	68 ab 02 00 00       	push   $0x2ab
f01018b8:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01018be:	50                   	push   %eax
f01018bf:	e8 d5 e7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018c4:	52                   	push   %edx
f01018c5:	89 cb                	mov    %ecx,%ebx
f01018c7:	8d 81 b8 d5 fe ff    	lea    -0x12a48(%ecx),%eax
f01018cd:	50                   	push   %eax
f01018ce:	6a 52                	push   $0x52
f01018d0:	8d 81 ad d2 fe ff    	lea    -0x12d53(%ecx),%eax
f01018d6:	50                   	push   %eax
f01018d7:	e8 bd e7 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01018dc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018df:	8d 83 5f d4 fe ff    	lea    -0x12ba1(%ebx),%eax
f01018e5:	50                   	push   %eax
f01018e6:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01018ec:	50                   	push   %eax
f01018ed:	68 b0 02 00 00       	push   $0x2b0
f01018f2:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01018f8:	50                   	push   %eax
f01018f9:	e8 9b e7 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f01018fe:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101901:	8d 83 7d d4 fe ff    	lea    -0x12b83(%ebx),%eax
f0101907:	50                   	push   %eax
f0101908:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010190e:	50                   	push   %eax
f010190f:	68 b1 02 00 00       	push   $0x2b1
f0101914:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010191a:	50                   	push   %eax
f010191b:	e8 79 e7 ff ff       	call   f0100099 <_panic>
f0101920:	52                   	push   %edx
f0101921:	89 cb                	mov    %ecx,%ebx
f0101923:	8d 81 b8 d5 fe ff    	lea    -0x12a48(%ecx),%eax
f0101929:	50                   	push   %eax
f010192a:	6a 52                	push   $0x52
f010192c:	8d 81 ad d2 fe ff    	lea    -0x12d53(%ecx),%eax
f0101932:	50                   	push   %eax
f0101933:	e8 61 e7 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f0101938:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010193b:	8d 83 8d d4 fe ff    	lea    -0x12b73(%ebx),%eax
f0101941:	50                   	push   %eax
f0101942:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0101948:	50                   	push   %eax
f0101949:	68 b4 02 00 00       	push   $0x2b4
f010194e:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0101954:	50                   	push   %eax
f0101955:	e8 3f e7 ff ff       	call   f0100099 <_panic>
	assert(nfree == 0);
f010195a:	85 f6                	test   %esi,%esi
f010195c:	0f 85 2f 08 00 00    	jne    f0102191 <mem_init+0xe70>
	cprintf("check_page_alloc() succeeded!\n");
f0101962:	83 ec 0c             	sub    $0xc,%esp
f0101965:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101968:	8d 83 64 d7 fe ff    	lea    -0x1289c(%ebx),%eax
f010196e:	50                   	push   %eax
f010196f:	e8 03 17 00 00       	call   f0103077 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101974:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010197b:	e8 ff f5 ff ff       	call   f0100f7f <page_alloc>
f0101980:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101983:	83 c4 10             	add    $0x10,%esp
f0101986:	85 c0                	test   %eax,%eax
f0101988:	0f 84 25 08 00 00    	je     f01021b3 <mem_init+0xe92>
	assert((pp1 = page_alloc(0)));
f010198e:	83 ec 0c             	sub    $0xc,%esp
f0101991:	6a 00                	push   $0x0
f0101993:	e8 e7 f5 ff ff       	call   f0100f7f <page_alloc>
f0101998:	89 c7                	mov    %eax,%edi
f010199a:	83 c4 10             	add    $0x10,%esp
f010199d:	85 c0                	test   %eax,%eax
f010199f:	0f 84 30 08 00 00    	je     f01021d5 <mem_init+0xeb4>
	assert((pp2 = page_alloc(0)));
f01019a5:	83 ec 0c             	sub    $0xc,%esp
f01019a8:	6a 00                	push   $0x0
f01019aa:	e8 d0 f5 ff ff       	call   f0100f7f <page_alloc>
f01019af:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01019b2:	83 c4 10             	add    $0x10,%esp
f01019b5:	85 c0                	test   %eax,%eax
f01019b7:	0f 84 3a 08 00 00    	je     f01021f7 <mem_init+0xed6>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019bd:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f01019c0:	0f 84 53 08 00 00    	je     f0102219 <mem_init+0xef8>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019c6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01019c9:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01019cc:	0f 84 69 08 00 00    	je     f010223b <mem_init+0xf1a>
f01019d2:	39 c7                	cmp    %eax,%edi
f01019d4:	0f 84 61 08 00 00    	je     f010223b <mem_init+0xf1a>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01019da:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019dd:	8b 88 bc 1f 00 00    	mov    0x1fbc(%eax),%ecx
f01019e3:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f01019e6:	c7 80 bc 1f 00 00 00 	movl   $0x0,0x1fbc(%eax)
f01019ed:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01019f0:	83 ec 0c             	sub    $0xc,%esp
f01019f3:	6a 00                	push   $0x0
f01019f5:	e8 85 f5 ff ff       	call   f0100f7f <page_alloc>
f01019fa:	83 c4 10             	add    $0x10,%esp
f01019fd:	85 c0                	test   %eax,%eax
f01019ff:	0f 85 58 08 00 00    	jne    f010225d <mem_init+0xf3c>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a05:	83 ec 04             	sub    $0x4,%esp
f0101a08:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a0b:	50                   	push   %eax
f0101a0c:	6a 00                	push   $0x0
f0101a0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a11:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101a17:	e8 d9 f7 ff ff       	call   f01011f5 <page_lookup>
f0101a1c:	83 c4 10             	add    $0x10,%esp
f0101a1f:	85 c0                	test   %eax,%eax
f0101a21:	0f 85 58 08 00 00    	jne    f010227f <mem_init+0xf5e>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a27:	6a 02                	push   $0x2
f0101a29:	6a 00                	push   $0x0
f0101a2b:	57                   	push   %edi
f0101a2c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a2f:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101a35:	e8 67 f8 ff ff       	call   f01012a1 <page_insert>
f0101a3a:	83 c4 10             	add    $0x10,%esp
f0101a3d:	85 c0                	test   %eax,%eax
f0101a3f:	0f 89 5c 08 00 00    	jns    f01022a1 <mem_init+0xf80>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a45:	83 ec 0c             	sub    $0xc,%esp
f0101a48:	ff 75 cc             	push   -0x34(%ebp)
f0101a4b:	e8 b4 f5 ff ff       	call   f0101004 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a50:	6a 02                	push   $0x2
f0101a52:	6a 00                	push   $0x0
f0101a54:	57                   	push   %edi
f0101a55:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a58:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101a5e:	e8 3e f8 ff ff       	call   f01012a1 <page_insert>
f0101a63:	83 c4 20             	add    $0x20,%esp
f0101a66:	85 c0                	test   %eax,%eax
f0101a68:	0f 85 55 08 00 00    	jne    f01022c3 <mem_init+0xfa2>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a6e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a71:	8b 98 b0 1f 00 00    	mov    0x1fb0(%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101a77:	8b b0 ac 1f 00 00    	mov    0x1fac(%eax),%esi
f0101a7d:	8b 13                	mov    (%ebx),%edx
f0101a7f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a85:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101a88:	29 f0                	sub    %esi,%eax
f0101a8a:	c1 f8 03             	sar    $0x3,%eax
f0101a8d:	c1 e0 0c             	shl    $0xc,%eax
f0101a90:	39 c2                	cmp    %eax,%edx
f0101a92:	0f 85 4d 08 00 00    	jne    f01022e5 <mem_init+0xfc4>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a98:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a9d:	89 d8                	mov    %ebx,%eax
f0101a9f:	e8 32 f0 ff ff       	call   f0100ad6 <check_va2pa>
f0101aa4:	89 c2                	mov    %eax,%edx
f0101aa6:	89 f8                	mov    %edi,%eax
f0101aa8:	29 f0                	sub    %esi,%eax
f0101aaa:	c1 f8 03             	sar    $0x3,%eax
f0101aad:	c1 e0 0c             	shl    $0xc,%eax
f0101ab0:	39 c2                	cmp    %eax,%edx
f0101ab2:	0f 85 4f 08 00 00    	jne    f0102307 <mem_init+0xfe6>
	assert(pp1->pp_ref == 1);
f0101ab8:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101abd:	0f 85 66 08 00 00    	jne    f0102329 <mem_init+0x1008>
	assert(pp0->pp_ref == 1);
f0101ac3:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101ac6:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101acb:	0f 85 7a 08 00 00    	jne    f010234b <mem_init+0x102a>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ad1:	6a 02                	push   $0x2
f0101ad3:	68 00 10 00 00       	push   $0x1000
f0101ad8:	ff 75 d0             	push   -0x30(%ebp)
f0101adb:	53                   	push   %ebx
f0101adc:	e8 c0 f7 ff ff       	call   f01012a1 <page_insert>
f0101ae1:	83 c4 10             	add    $0x10,%esp
f0101ae4:	85 c0                	test   %eax,%eax
f0101ae6:	0f 85 81 08 00 00    	jne    f010236d <mem_init+0x104c>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101aec:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101af1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101af4:	8b 83 b0 1f 00 00    	mov    0x1fb0(%ebx),%eax
f0101afa:	e8 d7 ef ff ff       	call   f0100ad6 <check_va2pa>
f0101aff:	89 c2                	mov    %eax,%edx
f0101b01:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b04:	2b 83 ac 1f 00 00    	sub    0x1fac(%ebx),%eax
f0101b0a:	c1 f8 03             	sar    $0x3,%eax
f0101b0d:	c1 e0 0c             	shl    $0xc,%eax
f0101b10:	39 c2                	cmp    %eax,%edx
f0101b12:	0f 85 77 08 00 00    	jne    f010238f <mem_init+0x106e>
	assert(pp2->pp_ref == 1);
f0101b18:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b1b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b20:	0f 85 8b 08 00 00    	jne    f01023b1 <mem_init+0x1090>

	// should be no free memory
	assert(!page_alloc(0));
f0101b26:	83 ec 0c             	sub    $0xc,%esp
f0101b29:	6a 00                	push   $0x0
f0101b2b:	e8 4f f4 ff ff       	call   f0100f7f <page_alloc>
f0101b30:	83 c4 10             	add    $0x10,%esp
f0101b33:	85 c0                	test   %eax,%eax
f0101b35:	0f 85 98 08 00 00    	jne    f01023d3 <mem_init+0x10b2>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b3b:	6a 02                	push   $0x2
f0101b3d:	68 00 10 00 00       	push   $0x1000
f0101b42:	ff 75 d0             	push   -0x30(%ebp)
f0101b45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b48:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101b4e:	e8 4e f7 ff ff       	call   f01012a1 <page_insert>
f0101b53:	83 c4 10             	add    $0x10,%esp
f0101b56:	85 c0                	test   %eax,%eax
f0101b58:	0f 85 97 08 00 00    	jne    f01023f5 <mem_init+0x10d4>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b5e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b63:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b66:	8b 83 b0 1f 00 00    	mov    0x1fb0(%ebx),%eax
f0101b6c:	e8 65 ef ff ff       	call   f0100ad6 <check_va2pa>
f0101b71:	89 c2                	mov    %eax,%edx
f0101b73:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b76:	2b 83 ac 1f 00 00    	sub    0x1fac(%ebx),%eax
f0101b7c:	c1 f8 03             	sar    $0x3,%eax
f0101b7f:	c1 e0 0c             	shl    $0xc,%eax
f0101b82:	39 c2                	cmp    %eax,%edx
f0101b84:	0f 85 8d 08 00 00    	jne    f0102417 <mem_init+0x10f6>
	assert(pp2->pp_ref == 1);
f0101b8a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b8d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b92:	0f 85 a1 08 00 00    	jne    f0102439 <mem_init+0x1118>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101b98:	83 ec 0c             	sub    $0xc,%esp
f0101b9b:	6a 00                	push   $0x0
f0101b9d:	e8 dd f3 ff ff       	call   f0100f7f <page_alloc>
f0101ba2:	83 c4 10             	add    $0x10,%esp
f0101ba5:	85 c0                	test   %eax,%eax
f0101ba7:	0f 85 ae 08 00 00    	jne    f010245b <mem_init+0x113a>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101bad:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101bb0:	8b 91 b0 1f 00 00    	mov    0x1fb0(%ecx),%edx
f0101bb6:	8b 02                	mov    (%edx),%eax
f0101bb8:	89 c3                	mov    %eax,%ebx
f0101bba:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if (PGNUM(pa) >= npages)
f0101bc0:	c1 e8 0c             	shr    $0xc,%eax
f0101bc3:	3b 81 b4 1f 00 00    	cmp    0x1fb4(%ecx),%eax
f0101bc9:	0f 83 ae 08 00 00    	jae    f010247d <mem_init+0x115c>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101bcf:	83 ec 04             	sub    $0x4,%esp
f0101bd2:	6a 00                	push   $0x0
f0101bd4:	68 00 10 00 00       	push   $0x1000
f0101bd9:	52                   	push   %edx
f0101bda:	e8 b8 f4 ff ff       	call   f0101097 <pgdir_walk>
f0101bdf:	81 eb fc ff ff 0f    	sub    $0xffffffc,%ebx
f0101be5:	83 c4 10             	add    $0x10,%esp
f0101be8:	39 d8                	cmp    %ebx,%eax
f0101bea:	0f 85 a8 08 00 00    	jne    f0102498 <mem_init+0x1177>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101bf0:	6a 06                	push   $0x6
f0101bf2:	68 00 10 00 00       	push   $0x1000
f0101bf7:	ff 75 d0             	push   -0x30(%ebp)
f0101bfa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bfd:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101c03:	e8 99 f6 ff ff       	call   f01012a1 <page_insert>
f0101c08:	83 c4 10             	add    $0x10,%esp
f0101c0b:	85 c0                	test   %eax,%eax
f0101c0d:	0f 85 a7 08 00 00    	jne    f01024ba <mem_init+0x1199>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c13:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101c16:	8b 9e b0 1f 00 00    	mov    0x1fb0(%esi),%ebx
f0101c1c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c21:	89 d8                	mov    %ebx,%eax
f0101c23:	e8 ae ee ff ff       	call   f0100ad6 <check_va2pa>
f0101c28:	89 c2                	mov    %eax,%edx
	return (pp - pages) << PGSHIFT;
f0101c2a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c2d:	2b 86 ac 1f 00 00    	sub    0x1fac(%esi),%eax
f0101c33:	c1 f8 03             	sar    $0x3,%eax
f0101c36:	c1 e0 0c             	shl    $0xc,%eax
f0101c39:	39 c2                	cmp    %eax,%edx
f0101c3b:	0f 85 9b 08 00 00    	jne    f01024dc <mem_init+0x11bb>
	assert(pp2->pp_ref == 1);
f0101c41:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c44:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c49:	0f 85 af 08 00 00    	jne    f01024fe <mem_init+0x11dd>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101c4f:	83 ec 04             	sub    $0x4,%esp
f0101c52:	6a 00                	push   $0x0
f0101c54:	68 00 10 00 00       	push   $0x1000
f0101c59:	53                   	push   %ebx
f0101c5a:	e8 38 f4 ff ff       	call   f0101097 <pgdir_walk>
f0101c5f:	83 c4 10             	add    $0x10,%esp
f0101c62:	f6 00 04             	testb  $0x4,(%eax)
f0101c65:	0f 84 b5 08 00 00    	je     f0102520 <mem_init+0x11ff>
	assert(kern_pgdir[0] & PTE_U);
f0101c6b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c6e:	8b 80 b0 1f 00 00    	mov    0x1fb0(%eax),%eax
f0101c74:	f6 00 04             	testb  $0x4,(%eax)
f0101c77:	0f 84 c5 08 00 00    	je     f0102542 <mem_init+0x1221>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c7d:	6a 02                	push   $0x2
f0101c7f:	68 00 10 00 00       	push   $0x1000
f0101c84:	ff 75 d0             	push   -0x30(%ebp)
f0101c87:	50                   	push   %eax
f0101c88:	e8 14 f6 ff ff       	call   f01012a1 <page_insert>
f0101c8d:	83 c4 10             	add    $0x10,%esp
f0101c90:	85 c0                	test   %eax,%eax
f0101c92:	0f 85 cc 08 00 00    	jne    f0102564 <mem_init+0x1243>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101c98:	83 ec 04             	sub    $0x4,%esp
f0101c9b:	6a 00                	push   $0x0
f0101c9d:	68 00 10 00 00       	push   $0x1000
f0101ca2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ca5:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101cab:	e8 e7 f3 ff ff       	call   f0101097 <pgdir_walk>
f0101cb0:	83 c4 10             	add    $0x10,%esp
f0101cb3:	f6 00 02             	testb  $0x2,(%eax)
f0101cb6:	0f 84 ca 08 00 00    	je     f0102586 <mem_init+0x1265>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101cbc:	83 ec 04             	sub    $0x4,%esp
f0101cbf:	6a 00                	push   $0x0
f0101cc1:	68 00 10 00 00       	push   $0x1000
f0101cc6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cc9:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101ccf:	e8 c3 f3 ff ff       	call   f0101097 <pgdir_walk>
f0101cd4:	83 c4 10             	add    $0x10,%esp
f0101cd7:	f6 00 04             	testb  $0x4,(%eax)
f0101cda:	0f 85 c8 08 00 00    	jne    f01025a8 <mem_init+0x1287>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ce0:	6a 02                	push   $0x2
f0101ce2:	68 00 00 40 00       	push   $0x400000
f0101ce7:	ff 75 cc             	push   -0x34(%ebp)
f0101cea:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ced:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101cf3:	e8 a9 f5 ff ff       	call   f01012a1 <page_insert>
f0101cf8:	83 c4 10             	add    $0x10,%esp
f0101cfb:	85 c0                	test   %eax,%eax
f0101cfd:	0f 89 c7 08 00 00    	jns    f01025ca <mem_init+0x12a9>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101d03:	6a 02                	push   $0x2
f0101d05:	68 00 10 00 00       	push   $0x1000
f0101d0a:	57                   	push   %edi
f0101d0b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d0e:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101d14:	e8 88 f5 ff ff       	call   f01012a1 <page_insert>
f0101d19:	83 c4 10             	add    $0x10,%esp
f0101d1c:	85 c0                	test   %eax,%eax
f0101d1e:	0f 85 c8 08 00 00    	jne    f01025ec <mem_init+0x12cb>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d24:	83 ec 04             	sub    $0x4,%esp
f0101d27:	6a 00                	push   $0x0
f0101d29:	68 00 10 00 00       	push   $0x1000
f0101d2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d31:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0101d37:	e8 5b f3 ff ff       	call   f0101097 <pgdir_walk>
f0101d3c:	83 c4 10             	add    $0x10,%esp
f0101d3f:	f6 00 04             	testb  $0x4,(%eax)
f0101d42:	0f 85 c6 08 00 00    	jne    f010260e <mem_init+0x12ed>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101d48:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101d4b:	8b b3 b0 1f 00 00    	mov    0x1fb0(%ebx),%esi
f0101d51:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d56:	89 f0                	mov    %esi,%eax
f0101d58:	e8 79 ed ff ff       	call   f0100ad6 <check_va2pa>
f0101d5d:	89 d9                	mov    %ebx,%ecx
f0101d5f:	89 fb                	mov    %edi,%ebx
f0101d61:	2b 99 ac 1f 00 00    	sub    0x1fac(%ecx),%ebx
f0101d67:	c1 fb 03             	sar    $0x3,%ebx
f0101d6a:	c1 e3 0c             	shl    $0xc,%ebx
f0101d6d:	39 d8                	cmp    %ebx,%eax
f0101d6f:	0f 85 bb 08 00 00    	jne    f0102630 <mem_init+0x130f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101d75:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d7a:	89 f0                	mov    %esi,%eax
f0101d7c:	e8 55 ed ff ff       	call   f0100ad6 <check_va2pa>
f0101d81:	39 c3                	cmp    %eax,%ebx
f0101d83:	0f 85 c9 08 00 00    	jne    f0102652 <mem_init+0x1331>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101d89:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101d8e:	0f 85 e0 08 00 00    	jne    f0102674 <mem_init+0x1353>
	assert(pp2->pp_ref == 0);
f0101d94:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101d97:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101d9c:	0f 85 f4 08 00 00    	jne    f0102696 <mem_init+0x1375>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101da2:	83 ec 0c             	sub    $0xc,%esp
f0101da5:	6a 00                	push   $0x0
f0101da7:	e8 d3 f1 ff ff       	call   f0100f7f <page_alloc>
f0101dac:	83 c4 10             	add    $0x10,%esp
f0101daf:	85 c0                	test   %eax,%eax
f0101db1:	0f 84 01 09 00 00    	je     f01026b8 <mem_init+0x1397>
f0101db7:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101dba:	0f 85 f8 08 00 00    	jne    f01026b8 <mem_init+0x1397>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101dc0:	83 ec 08             	sub    $0x8,%esp
f0101dc3:	6a 00                	push   $0x0
f0101dc5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101dc8:	ff b3 b0 1f 00 00    	push   0x1fb0(%ebx)
f0101dce:	e8 93 f4 ff ff       	call   f0101266 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101dd3:	8b 9b b0 1f 00 00    	mov    0x1fb0(%ebx),%ebx
f0101dd9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dde:	89 d8                	mov    %ebx,%eax
f0101de0:	e8 f1 ec ff ff       	call   f0100ad6 <check_va2pa>
f0101de5:	83 c4 10             	add    $0x10,%esp
f0101de8:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101deb:	0f 85 e9 08 00 00    	jne    f01026da <mem_init+0x13b9>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101df1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101df6:	89 d8                	mov    %ebx,%eax
f0101df8:	e8 d9 ec ff ff       	call   f0100ad6 <check_va2pa>
f0101dfd:	89 c2                	mov    %eax,%edx
f0101dff:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e02:	89 f8                	mov    %edi,%eax
f0101e04:	2b 81 ac 1f 00 00    	sub    0x1fac(%ecx),%eax
f0101e0a:	c1 f8 03             	sar    $0x3,%eax
f0101e0d:	c1 e0 0c             	shl    $0xc,%eax
f0101e10:	39 c2                	cmp    %eax,%edx
f0101e12:	0f 85 e4 08 00 00    	jne    f01026fc <mem_init+0x13db>
	assert(pp1->pp_ref == 1);
f0101e18:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101e1d:	0f 85 fa 08 00 00    	jne    f010271d <mem_init+0x13fc>
	assert(pp2->pp_ref == 0);
f0101e23:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e26:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e2b:	0f 85 0e 09 00 00    	jne    f010273f <mem_init+0x141e>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101e31:	6a 00                	push   $0x0
f0101e33:	68 00 10 00 00       	push   $0x1000
f0101e38:	57                   	push   %edi
f0101e39:	53                   	push   %ebx
f0101e3a:	e8 62 f4 ff ff       	call   f01012a1 <page_insert>
f0101e3f:	83 c4 10             	add    $0x10,%esp
f0101e42:	85 c0                	test   %eax,%eax
f0101e44:	0f 85 17 09 00 00    	jne    f0102761 <mem_init+0x1440>
	assert(pp1->pp_ref);
f0101e4a:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101e4f:	0f 84 2e 09 00 00    	je     f0102783 <mem_init+0x1462>
	assert(pp1->pp_link == NULL);
f0101e55:	83 3f 00             	cmpl   $0x0,(%edi)
f0101e58:	0f 85 47 09 00 00    	jne    f01027a5 <mem_init+0x1484>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101e5e:	83 ec 08             	sub    $0x8,%esp
f0101e61:	68 00 10 00 00       	push   $0x1000
f0101e66:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101e69:	ff b3 b0 1f 00 00    	push   0x1fb0(%ebx)
f0101e6f:	e8 f2 f3 ff ff       	call   f0101266 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101e74:	8b 9b b0 1f 00 00    	mov    0x1fb0(%ebx),%ebx
f0101e7a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e7f:	89 d8                	mov    %ebx,%eax
f0101e81:	e8 50 ec ff ff       	call   f0100ad6 <check_va2pa>
f0101e86:	83 c4 10             	add    $0x10,%esp
f0101e89:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101e8c:	0f 85 35 09 00 00    	jne    f01027c7 <mem_init+0x14a6>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101e92:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e97:	89 d8                	mov    %ebx,%eax
f0101e99:	e8 38 ec ff ff       	call   f0100ad6 <check_va2pa>
f0101e9e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ea1:	0f 85 42 09 00 00    	jne    f01027e9 <mem_init+0x14c8>
	assert(pp1->pp_ref == 0);
f0101ea7:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101eac:	0f 85 59 09 00 00    	jne    f010280b <mem_init+0x14ea>
	assert(pp2->pp_ref == 0);
f0101eb2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101eb5:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101eba:	0f 85 6d 09 00 00    	jne    f010282d <mem_init+0x150c>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ec0:	83 ec 0c             	sub    $0xc,%esp
f0101ec3:	6a 00                	push   $0x0
f0101ec5:	e8 b5 f0 ff ff       	call   f0100f7f <page_alloc>
f0101eca:	83 c4 10             	add    $0x10,%esp
f0101ecd:	39 c7                	cmp    %eax,%edi
f0101ecf:	0f 85 7a 09 00 00    	jne    f010284f <mem_init+0x152e>
f0101ed5:	85 c0                	test   %eax,%eax
f0101ed7:	0f 84 72 09 00 00    	je     f010284f <mem_init+0x152e>

	// should be no free memory
	assert(!page_alloc(0));
f0101edd:	83 ec 0c             	sub    $0xc,%esp
f0101ee0:	6a 00                	push   $0x0
f0101ee2:	e8 98 f0 ff ff       	call   f0100f7f <page_alloc>
f0101ee7:	83 c4 10             	add    $0x10,%esp
f0101eea:	85 c0                	test   %eax,%eax
f0101eec:	0f 85 7f 09 00 00    	jne    f0102871 <mem_init+0x1550>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ef2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ef5:	8b 88 b0 1f 00 00    	mov    0x1fb0(%eax),%ecx
f0101efb:	8b 11                	mov    (%ecx),%edx
f0101efd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101f03:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101f06:	2b 98 ac 1f 00 00    	sub    0x1fac(%eax),%ebx
f0101f0c:	89 d8                	mov    %ebx,%eax
f0101f0e:	c1 f8 03             	sar    $0x3,%eax
f0101f11:	c1 e0 0c             	shl    $0xc,%eax
f0101f14:	39 c2                	cmp    %eax,%edx
f0101f16:	0f 85 77 09 00 00    	jne    f0102893 <mem_init+0x1572>
	kern_pgdir[0] = 0;
f0101f1c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101f22:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f25:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f2a:	0f 85 85 09 00 00    	jne    f01028b5 <mem_init+0x1594>
	pp0->pp_ref = 0;
f0101f30:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f33:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101f39:	83 ec 0c             	sub    $0xc,%esp
f0101f3c:	50                   	push   %eax
f0101f3d:	e8 c2 f0 ff ff       	call   f0101004 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101f42:	83 c4 0c             	add    $0xc,%esp
f0101f45:	6a 01                	push   $0x1
f0101f47:	68 00 10 40 00       	push   $0x401000
f0101f4c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101f4f:	ff b3 b0 1f 00 00    	push   0x1fb0(%ebx)
f0101f55:	e8 3d f1 ff ff       	call   f0101097 <pgdir_walk>
f0101f5a:	89 c6                	mov    %eax,%esi
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f5c:	89 d9                	mov    %ebx,%ecx
f0101f5e:	8b 9b b0 1f 00 00    	mov    0x1fb0(%ebx),%ebx
f0101f64:	8b 43 04             	mov    0x4(%ebx),%eax
f0101f67:	89 c2                	mov    %eax,%edx
f0101f69:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0101f6f:	8b 89 b4 1f 00 00    	mov    0x1fb4(%ecx),%ecx
f0101f75:	c1 e8 0c             	shr    $0xc,%eax
f0101f78:	83 c4 10             	add    $0x10,%esp
f0101f7b:	39 c8                	cmp    %ecx,%eax
f0101f7d:	0f 83 54 09 00 00    	jae    f01028d7 <mem_init+0x15b6>
	assert(ptep == ptep1 + PTX(va));
f0101f83:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0101f89:	39 d6                	cmp    %edx,%esi
f0101f8b:	0f 85 62 09 00 00    	jne    f01028f3 <mem_init+0x15d2>
	kern_pgdir[PDX(va)] = 0;
f0101f91:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0101f98:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f9b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f0101fa1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101fa4:	2b 83 ac 1f 00 00    	sub    0x1fac(%ebx),%eax
f0101faa:	c1 f8 03             	sar    $0x3,%eax
f0101fad:	89 c2                	mov    %eax,%edx
f0101faf:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101fb2:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0101fb7:	39 c1                	cmp    %eax,%ecx
f0101fb9:	0f 86 56 09 00 00    	jbe    f0102915 <mem_init+0x15f4>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101fbf:	83 ec 04             	sub    $0x4,%esp
f0101fc2:	68 00 10 00 00       	push   $0x1000
f0101fc7:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0101fcc:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101fd2:	52                   	push   %edx
f0101fd3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101fd6:	e8 9d 1c 00 00       	call   f0103c78 <memset>
	page_free(pp0);
f0101fdb:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101fde:	89 34 24             	mov    %esi,(%esp)
f0101fe1:	e8 1e f0 ff ff       	call   f0101004 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101fe6:	83 c4 0c             	add    $0xc,%esp
f0101fe9:	6a 01                	push   $0x1
f0101feb:	6a 00                	push   $0x0
f0101fed:	ff b3 b0 1f 00 00    	push   0x1fb0(%ebx)
f0101ff3:	e8 9f f0 ff ff       	call   f0101097 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0101ff8:	89 f0                	mov    %esi,%eax
f0101ffa:	2b 83 ac 1f 00 00    	sub    0x1fac(%ebx),%eax
f0102000:	c1 f8 03             	sar    $0x3,%eax
f0102003:	89 c2                	mov    %eax,%edx
f0102005:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102008:	25 ff ff 0f 00       	and    $0xfffff,%eax
f010200d:	83 c4 10             	add    $0x10,%esp
f0102010:	3b 83 b4 1f 00 00    	cmp    0x1fb4(%ebx),%eax
f0102016:	0f 83 0f 09 00 00    	jae    f010292b <mem_init+0x160a>
	return (void *)(pa + KERNBASE);
f010201c:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0102022:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102028:	8b 30                	mov    (%eax),%esi
f010202a:	83 e6 01             	and    $0x1,%esi
f010202d:	0f 85 11 09 00 00    	jne    f0102944 <mem_init+0x1623>
	for(i=0; i<NPTENTRIES; i++)
f0102033:	83 c0 04             	add    $0x4,%eax
f0102036:	39 c2                	cmp    %eax,%edx
f0102038:	75 ee                	jne    f0102028 <mem_init+0xd07>
	kern_pgdir[0] = 0;
f010203a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010203d:	8b 83 b0 1f 00 00    	mov    0x1fb0(%ebx),%eax
f0102043:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102049:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010204c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102052:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102055:	89 93 bc 1f 00 00    	mov    %edx,0x1fbc(%ebx)

	// free the pages we took
	page_free(pp0);
f010205b:	83 ec 0c             	sub    $0xc,%esp
f010205e:	50                   	push   %eax
f010205f:	e8 a0 ef ff ff       	call   f0101004 <page_free>
	page_free(pp1);
f0102064:	89 3c 24             	mov    %edi,(%esp)
f0102067:	e8 98 ef ff ff       	call   f0101004 <page_free>
	page_free(pp2);
f010206c:	83 c4 04             	add    $0x4,%esp
f010206f:	ff 75 d0             	push   -0x30(%ebp)
f0102072:	e8 8d ef ff ff       	call   f0101004 <page_free>

	cprintf("check_page() succeeded!\n");
f0102077:	8d 83 6e d5 fe ff    	lea    -0x12a92(%ebx),%eax
f010207d:	89 04 24             	mov    %eax,(%esp)
f0102080:	e8 f2 0f 00 00       	call   f0103077 <cprintf>
	boot_map_region(kern_pgdir, UPAGES, npages * sizeof(struct PageInfo), PADDR(pages), PTE_U | PTE_P);
f0102085:	8b 83 ac 1f 00 00    	mov    0x1fac(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f010208b:	83 c4 10             	add    $0x10,%esp
f010208e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102093:	0f 86 cd 08 00 00    	jbe    f0102966 <mem_init+0x1645>
f0102099:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010209c:	8b 8f b4 1f 00 00    	mov    0x1fb4(%edi),%ecx
f01020a2:	c1 e1 03             	shl    $0x3,%ecx
f01020a5:	83 ec 08             	sub    $0x8,%esp
f01020a8:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f01020aa:	05 00 00 00 10       	add    $0x10000000,%eax
f01020af:	50                   	push   %eax
f01020b0:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020b5:	8b 87 b0 1f 00 00    	mov    0x1fb0(%edi),%eax
f01020bb:	e8 b9 f0 ff ff       	call   f0101179 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f01020c0:	c7 c0 00 e0 10 f0    	mov    $0xf010e000,%eax
f01020c6:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01020c9:	83 c4 10             	add    $0x10,%esp
f01020cc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01020d1:	0f 86 ab 08 00 00    	jbe    f0102982 <mem_init+0x1661>
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f01020d7:	83 ec 08             	sub    $0x8,%esp
f01020da:	6a 02                	push   $0x2
	return (physaddr_t)kva - KERNBASE;
f01020dc:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01020df:	05 00 00 00 10       	add    $0x10000000,%eax
f01020e4:	50                   	push   %eax
f01020e5:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01020ea:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01020ef:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01020f2:	8b 87 b0 1f 00 00    	mov    0x1fb0(%edi),%eax
f01020f8:	e8 7c f0 ff ff       	call   f0101179 <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f01020fd:	83 c4 08             	add    $0x8,%esp
f0102100:	6a 02                	push   $0x2
f0102102:	6a 00                	push   $0x0
f0102104:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102109:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010210e:	8b 87 b0 1f 00 00    	mov    0x1fb0(%edi),%eax
f0102114:	e8 60 f0 ff ff       	call   f0101179 <boot_map_region>
	pgdir = kern_pgdir;
f0102119:	89 f9                	mov    %edi,%ecx
f010211b:	8b bf b0 1f 00 00    	mov    0x1fb0(%edi),%edi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102121:	8b 81 b4 1f 00 00    	mov    0x1fb4(%ecx),%eax
f0102127:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010212a:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102131:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102136:	89 c2                	mov    %eax,%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102138:	8b 81 ac 1f 00 00    	mov    0x1fac(%ecx),%eax
f010213e:	89 45 bc             	mov    %eax,-0x44(%ebp)
f0102141:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0102147:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f010214a:	83 c4 10             	add    $0x10,%esp
f010214d:	89 f3                	mov    %esi,%ebx
f010214f:	89 75 c0             	mov    %esi,-0x40(%ebp)
f0102152:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102155:	89 d6                	mov    %edx,%esi
f0102157:	89 c7                	mov    %eax,%edi
f0102159:	39 de                	cmp    %ebx,%esi
f010215b:	0f 86 82 08 00 00    	jbe    f01029e3 <mem_init+0x16c2>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102161:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102167:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010216a:	e8 67 e9 ff ff       	call   f0100ad6 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f010216f:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0102175:	0f 86 28 08 00 00    	jbe    f01029a3 <mem_init+0x1682>
f010217b:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010217e:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f0102181:	39 d0                	cmp    %edx,%eax
f0102183:	0f 85 38 08 00 00    	jne    f01029c1 <mem_init+0x16a0>
	for (i = 0; i < n; i += PGSIZE)
f0102189:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010218f:	eb c8                	jmp    f0102159 <mem_init+0xe38>
	assert(nfree == 0);
f0102191:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102194:	8d 83 97 d4 fe ff    	lea    -0x12b69(%ebx),%eax
f010219a:	50                   	push   %eax
f010219b:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01021a1:	50                   	push   %eax
f01021a2:	68 c1 02 00 00       	push   $0x2c1
f01021a7:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01021ad:	50                   	push   %eax
f01021ae:	e8 e6 de ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f01021b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021b6:	8d 83 a5 d3 fe ff    	lea    -0x12c5b(%ebx),%eax
f01021bc:	50                   	push   %eax
f01021bd:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01021c3:	50                   	push   %eax
f01021c4:	68 1a 03 00 00       	push   $0x31a
f01021c9:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01021cf:	50                   	push   %eax
f01021d0:	e8 c4 de ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01021d5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021d8:	8d 83 bb d3 fe ff    	lea    -0x12c45(%ebx),%eax
f01021de:	50                   	push   %eax
f01021df:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01021e5:	50                   	push   %eax
f01021e6:	68 1b 03 00 00       	push   $0x31b
f01021eb:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01021f1:	50                   	push   %eax
f01021f2:	e8 a2 de ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01021f7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021fa:	8d 83 d1 d3 fe ff    	lea    -0x12c2f(%ebx),%eax
f0102200:	50                   	push   %eax
f0102201:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102207:	50                   	push   %eax
f0102208:	68 1c 03 00 00       	push   $0x31c
f010220d:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102213:	50                   	push   %eax
f0102214:	e8 80 de ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f0102219:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010221c:	8d 83 e7 d3 fe ff    	lea    -0x12c19(%ebx),%eax
f0102222:	50                   	push   %eax
f0102223:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102229:	50                   	push   %eax
f010222a:	68 1f 03 00 00       	push   $0x31f
f010222f:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102235:	50                   	push   %eax
f0102236:	e8 5e de ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010223b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010223e:	8d 83 44 d7 fe ff    	lea    -0x128bc(%ebx),%eax
f0102244:	50                   	push   %eax
f0102245:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010224b:	50                   	push   %eax
f010224c:	68 20 03 00 00       	push   $0x320
f0102251:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102257:	50                   	push   %eax
f0102258:	e8 3c de ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010225d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102260:	8d 83 50 d4 fe ff    	lea    -0x12bb0(%ebx),%eax
f0102266:	50                   	push   %eax
f0102267:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010226d:	50                   	push   %eax
f010226e:	68 27 03 00 00       	push   $0x327
f0102273:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102279:	50                   	push   %eax
f010227a:	e8 1a de ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010227f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102282:	8d 83 84 d7 fe ff    	lea    -0x1287c(%ebx),%eax
f0102288:	50                   	push   %eax
f0102289:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010228f:	50                   	push   %eax
f0102290:	68 2a 03 00 00       	push   $0x32a
f0102295:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010229b:	50                   	push   %eax
f010229c:	e8 f8 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01022a1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022a4:	8d 83 bc d7 fe ff    	lea    -0x12844(%ebx),%eax
f01022aa:	50                   	push   %eax
f01022ab:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01022b1:	50                   	push   %eax
f01022b2:	68 2d 03 00 00       	push   $0x32d
f01022b7:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01022bd:	50                   	push   %eax
f01022be:	e8 d6 dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01022c3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022c6:	8d 83 ec d7 fe ff    	lea    -0x12814(%ebx),%eax
f01022cc:	50                   	push   %eax
f01022cd:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01022d3:	50                   	push   %eax
f01022d4:	68 31 03 00 00       	push   $0x331
f01022d9:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01022df:	50                   	push   %eax
f01022e0:	e8 b4 dd ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022e5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022e8:	8d 83 1c d8 fe ff    	lea    -0x127e4(%ebx),%eax
f01022ee:	50                   	push   %eax
f01022ef:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01022f5:	50                   	push   %eax
f01022f6:	68 32 03 00 00       	push   $0x332
f01022fb:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102301:	50                   	push   %eax
f0102302:	e8 92 dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0102307:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010230a:	8d 83 44 d8 fe ff    	lea    -0x127bc(%ebx),%eax
f0102310:	50                   	push   %eax
f0102311:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102317:	50                   	push   %eax
f0102318:	68 33 03 00 00       	push   $0x333
f010231d:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102323:	50                   	push   %eax
f0102324:	e8 70 dd ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102329:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010232c:	8d 83 a2 d4 fe ff    	lea    -0x12b5e(%ebx),%eax
f0102332:	50                   	push   %eax
f0102333:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102339:	50                   	push   %eax
f010233a:	68 34 03 00 00       	push   $0x334
f010233f:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102345:	50                   	push   %eax
f0102346:	e8 4e dd ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f010234b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010234e:	8d 83 b3 d4 fe ff    	lea    -0x12b4d(%ebx),%eax
f0102354:	50                   	push   %eax
f0102355:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010235b:	50                   	push   %eax
f010235c:	68 35 03 00 00       	push   $0x335
f0102361:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102367:	50                   	push   %eax
f0102368:	e8 2c dd ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010236d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102370:	8d 83 74 d8 fe ff    	lea    -0x1278c(%ebx),%eax
f0102376:	50                   	push   %eax
f0102377:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010237d:	50                   	push   %eax
f010237e:	68 38 03 00 00       	push   $0x338
f0102383:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102389:	50                   	push   %eax
f010238a:	e8 0a dd ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010238f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102392:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102398:	50                   	push   %eax
f0102399:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010239f:	50                   	push   %eax
f01023a0:	68 39 03 00 00       	push   $0x339
f01023a5:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01023ab:	50                   	push   %eax
f01023ac:	e8 e8 dc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01023b1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023b4:	8d 83 c4 d4 fe ff    	lea    -0x12b3c(%ebx),%eax
f01023ba:	50                   	push   %eax
f01023bb:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01023c1:	50                   	push   %eax
f01023c2:	68 3a 03 00 00       	push   $0x33a
f01023c7:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01023cd:	50                   	push   %eax
f01023ce:	e8 c6 dc ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01023d3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023d6:	8d 83 50 d4 fe ff    	lea    -0x12bb0(%ebx),%eax
f01023dc:	50                   	push   %eax
f01023dd:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01023e3:	50                   	push   %eax
f01023e4:	68 3d 03 00 00       	push   $0x33d
f01023e9:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01023ef:	50                   	push   %eax
f01023f0:	e8 a4 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023f5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023f8:	8d 83 74 d8 fe ff    	lea    -0x1278c(%ebx),%eax
f01023fe:	50                   	push   %eax
f01023ff:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102405:	50                   	push   %eax
f0102406:	68 40 03 00 00       	push   $0x340
f010240b:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102411:	50                   	push   %eax
f0102412:	e8 82 dc ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102417:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010241a:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f0102420:	50                   	push   %eax
f0102421:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102427:	50                   	push   %eax
f0102428:	68 41 03 00 00       	push   $0x341
f010242d:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102433:	50                   	push   %eax
f0102434:	e8 60 dc ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102439:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010243c:	8d 83 c4 d4 fe ff    	lea    -0x12b3c(%ebx),%eax
f0102442:	50                   	push   %eax
f0102443:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102449:	50                   	push   %eax
f010244a:	68 42 03 00 00       	push   $0x342
f010244f:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102455:	50                   	push   %eax
f0102456:	e8 3e dc ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010245b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010245e:	8d 83 50 d4 fe ff    	lea    -0x12bb0(%ebx),%eax
f0102464:	50                   	push   %eax
f0102465:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010246b:	50                   	push   %eax
f010246c:	68 46 03 00 00       	push   $0x346
f0102471:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102477:	50                   	push   %eax
f0102478:	e8 1c dc ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010247d:	53                   	push   %ebx
f010247e:	89 cb                	mov    %ecx,%ebx
f0102480:	8d 81 b8 d5 fe ff    	lea    -0x12a48(%ecx),%eax
f0102486:	50                   	push   %eax
f0102487:	68 49 03 00 00       	push   $0x349
f010248c:	8d 81 a1 d2 fe ff    	lea    -0x12d5f(%ecx),%eax
f0102492:	50                   	push   %eax
f0102493:	e8 01 dc ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102498:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010249b:	8d 83 e0 d8 fe ff    	lea    -0x12720(%ebx),%eax
f01024a1:	50                   	push   %eax
f01024a2:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01024a8:	50                   	push   %eax
f01024a9:	68 4a 03 00 00       	push   $0x34a
f01024ae:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01024b4:	50                   	push   %eax
f01024b5:	e8 df db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01024ba:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024bd:	8d 83 20 d9 fe ff    	lea    -0x126e0(%ebx),%eax
f01024c3:	50                   	push   %eax
f01024c4:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01024ca:	50                   	push   %eax
f01024cb:	68 4d 03 00 00       	push   $0x34d
f01024d0:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01024d6:	50                   	push   %eax
f01024d7:	e8 bd db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01024dc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024df:	8d 83 b0 d8 fe ff    	lea    -0x12750(%ebx),%eax
f01024e5:	50                   	push   %eax
f01024e6:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01024ec:	50                   	push   %eax
f01024ed:	68 4e 03 00 00       	push   $0x34e
f01024f2:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01024f8:	50                   	push   %eax
f01024f9:	e8 9b db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01024fe:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102501:	8d 83 c4 d4 fe ff    	lea    -0x12b3c(%ebx),%eax
f0102507:	50                   	push   %eax
f0102508:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010250e:	50                   	push   %eax
f010250f:	68 4f 03 00 00       	push   $0x34f
f0102514:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010251a:	50                   	push   %eax
f010251b:	e8 79 db ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102520:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102523:	8d 83 60 d9 fe ff    	lea    -0x126a0(%ebx),%eax
f0102529:	50                   	push   %eax
f010252a:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102530:	50                   	push   %eax
f0102531:	68 50 03 00 00       	push   $0x350
f0102536:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010253c:	50                   	push   %eax
f010253d:	e8 57 db ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102542:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102545:	8d 83 d5 d4 fe ff    	lea    -0x12b2b(%ebx),%eax
f010254b:	50                   	push   %eax
f010254c:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102552:	50                   	push   %eax
f0102553:	68 51 03 00 00       	push   $0x351
f0102558:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010255e:	50                   	push   %eax
f010255f:	e8 35 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102564:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102567:	8d 83 74 d8 fe ff    	lea    -0x1278c(%ebx),%eax
f010256d:	50                   	push   %eax
f010256e:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102574:	50                   	push   %eax
f0102575:	68 54 03 00 00       	push   $0x354
f010257a:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102580:	50                   	push   %eax
f0102581:	e8 13 db ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102586:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102589:	8d 83 94 d9 fe ff    	lea    -0x1266c(%ebx),%eax
f010258f:	50                   	push   %eax
f0102590:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102596:	50                   	push   %eax
f0102597:	68 55 03 00 00       	push   $0x355
f010259c:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01025a2:	50                   	push   %eax
f01025a3:	e8 f1 da ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01025a8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025ab:	8d 83 c8 d9 fe ff    	lea    -0x12638(%ebx),%eax
f01025b1:	50                   	push   %eax
f01025b2:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01025b8:	50                   	push   %eax
f01025b9:	68 56 03 00 00       	push   $0x356
f01025be:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01025c4:	50                   	push   %eax
f01025c5:	e8 cf da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01025ca:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025cd:	8d 83 00 da fe ff    	lea    -0x12600(%ebx),%eax
f01025d3:	50                   	push   %eax
f01025d4:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01025da:	50                   	push   %eax
f01025db:	68 59 03 00 00       	push   $0x359
f01025e0:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01025e6:	50                   	push   %eax
f01025e7:	e8 ad da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01025ec:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025ef:	8d 83 38 da fe ff    	lea    -0x125c8(%ebx),%eax
f01025f5:	50                   	push   %eax
f01025f6:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01025fc:	50                   	push   %eax
f01025fd:	68 5c 03 00 00       	push   $0x35c
f0102602:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102608:	50                   	push   %eax
f0102609:	e8 8b da ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010260e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102611:	8d 83 c8 d9 fe ff    	lea    -0x12638(%ebx),%eax
f0102617:	50                   	push   %eax
f0102618:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010261e:	50                   	push   %eax
f010261f:	68 5d 03 00 00       	push   $0x35d
f0102624:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010262a:	50                   	push   %eax
f010262b:	e8 69 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102630:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102633:	8d 83 74 da fe ff    	lea    -0x1258c(%ebx),%eax
f0102639:	50                   	push   %eax
f010263a:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102640:	50                   	push   %eax
f0102641:	68 60 03 00 00       	push   $0x360
f0102646:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010264c:	50                   	push   %eax
f010264d:	e8 47 da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102652:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102655:	8d 83 a0 da fe ff    	lea    -0x12560(%ebx),%eax
f010265b:	50                   	push   %eax
f010265c:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102662:	50                   	push   %eax
f0102663:	68 61 03 00 00       	push   $0x361
f0102668:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010266e:	50                   	push   %eax
f010266f:	e8 25 da ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f0102674:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102677:	8d 83 eb d4 fe ff    	lea    -0x12b15(%ebx),%eax
f010267d:	50                   	push   %eax
f010267e:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102684:	50                   	push   %eax
f0102685:	68 63 03 00 00       	push   $0x363
f010268a:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102690:	50                   	push   %eax
f0102691:	e8 03 da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102696:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102699:	8d 83 fc d4 fe ff    	lea    -0x12b04(%ebx),%eax
f010269f:	50                   	push   %eax
f01026a0:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01026a6:	50                   	push   %eax
f01026a7:	68 64 03 00 00       	push   $0x364
f01026ac:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01026b2:	50                   	push   %eax
f01026b3:	e8 e1 d9 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f01026b8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026bb:	8d 83 d0 da fe ff    	lea    -0x12530(%ebx),%eax
f01026c1:	50                   	push   %eax
f01026c2:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01026c8:	50                   	push   %eax
f01026c9:	68 67 03 00 00       	push   $0x367
f01026ce:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01026d4:	50                   	push   %eax
f01026d5:	e8 bf d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01026da:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026dd:	8d 83 f4 da fe ff    	lea    -0x1250c(%ebx),%eax
f01026e3:	50                   	push   %eax
f01026e4:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01026ea:	50                   	push   %eax
f01026eb:	68 6b 03 00 00       	push   $0x36b
f01026f0:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01026f6:	50                   	push   %eax
f01026f7:	e8 9d d9 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026fc:	89 cb                	mov    %ecx,%ebx
f01026fe:	8d 81 a0 da fe ff    	lea    -0x12560(%ecx),%eax
f0102704:	50                   	push   %eax
f0102705:	8d 81 c7 d2 fe ff    	lea    -0x12d39(%ecx),%eax
f010270b:	50                   	push   %eax
f010270c:	68 6c 03 00 00       	push   $0x36c
f0102711:	8d 81 a1 d2 fe ff    	lea    -0x12d5f(%ecx),%eax
f0102717:	50                   	push   %eax
f0102718:	e8 7c d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f010271d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102720:	8d 83 a2 d4 fe ff    	lea    -0x12b5e(%ebx),%eax
f0102726:	50                   	push   %eax
f0102727:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010272d:	50                   	push   %eax
f010272e:	68 6d 03 00 00       	push   $0x36d
f0102733:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102739:	50                   	push   %eax
f010273a:	e8 5a d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f010273f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102742:	8d 83 fc d4 fe ff    	lea    -0x12b04(%ebx),%eax
f0102748:	50                   	push   %eax
f0102749:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010274f:	50                   	push   %eax
f0102750:	68 6e 03 00 00       	push   $0x36e
f0102755:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010275b:	50                   	push   %eax
f010275c:	e8 38 d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102761:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102764:	8d 83 18 db fe ff    	lea    -0x124e8(%ebx),%eax
f010276a:	50                   	push   %eax
f010276b:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102771:	50                   	push   %eax
f0102772:	68 71 03 00 00       	push   $0x371
f0102777:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010277d:	50                   	push   %eax
f010277e:	e8 16 d9 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f0102783:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102786:	8d 83 0d d5 fe ff    	lea    -0x12af3(%ebx),%eax
f010278c:	50                   	push   %eax
f010278d:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102793:	50                   	push   %eax
f0102794:	68 72 03 00 00       	push   $0x372
f0102799:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010279f:	50                   	push   %eax
f01027a0:	e8 f4 d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f01027a5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027a8:	8d 83 19 d5 fe ff    	lea    -0x12ae7(%ebx),%eax
f01027ae:	50                   	push   %eax
f01027af:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01027b5:	50                   	push   %eax
f01027b6:	68 73 03 00 00       	push   $0x373
f01027bb:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01027c1:	50                   	push   %eax
f01027c2:	e8 d2 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01027c7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027ca:	8d 83 f4 da fe ff    	lea    -0x1250c(%ebx),%eax
f01027d0:	50                   	push   %eax
f01027d1:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01027d7:	50                   	push   %eax
f01027d8:	68 77 03 00 00       	push   $0x377
f01027dd:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01027e3:	50                   	push   %eax
f01027e4:	e8 b0 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01027e9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027ec:	8d 83 50 db fe ff    	lea    -0x124b0(%ebx),%eax
f01027f2:	50                   	push   %eax
f01027f3:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01027f9:	50                   	push   %eax
f01027fa:	68 78 03 00 00       	push   $0x378
f01027ff:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102805:	50                   	push   %eax
f0102806:	e8 8e d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f010280b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010280e:	8d 83 2e d5 fe ff    	lea    -0x12ad2(%ebx),%eax
f0102814:	50                   	push   %eax
f0102815:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010281b:	50                   	push   %eax
f010281c:	68 79 03 00 00       	push   $0x379
f0102821:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102827:	50                   	push   %eax
f0102828:	e8 6c d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f010282d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102830:	8d 83 fc d4 fe ff    	lea    -0x12b04(%ebx),%eax
f0102836:	50                   	push   %eax
f0102837:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010283d:	50                   	push   %eax
f010283e:	68 7a 03 00 00       	push   $0x37a
f0102843:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102849:	50                   	push   %eax
f010284a:	e8 4a d8 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f010284f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102852:	8d 83 78 db fe ff    	lea    -0x12488(%ebx),%eax
f0102858:	50                   	push   %eax
f0102859:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f010285f:	50                   	push   %eax
f0102860:	68 7d 03 00 00       	push   $0x37d
f0102865:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010286b:	50                   	push   %eax
f010286c:	e8 28 d8 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102871:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102874:	8d 83 50 d4 fe ff    	lea    -0x12bb0(%ebx),%eax
f010287a:	50                   	push   %eax
f010287b:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102881:	50                   	push   %eax
f0102882:	68 80 03 00 00       	push   $0x380
f0102887:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010288d:	50                   	push   %eax
f010288e:	e8 06 d8 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102893:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102896:	8d 83 1c d8 fe ff    	lea    -0x127e4(%ebx),%eax
f010289c:	50                   	push   %eax
f010289d:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01028a3:	50                   	push   %eax
f01028a4:	68 83 03 00 00       	push   $0x383
f01028a9:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01028af:	50                   	push   %eax
f01028b0:	e8 e4 d7 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01028b5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028b8:	8d 83 b3 d4 fe ff    	lea    -0x12b4d(%ebx),%eax
f01028be:	50                   	push   %eax
f01028bf:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01028c5:	50                   	push   %eax
f01028c6:	68 85 03 00 00       	push   $0x385
f01028cb:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01028d1:	50                   	push   %eax
f01028d2:	e8 c2 d7 ff ff       	call   f0100099 <_panic>
f01028d7:	52                   	push   %edx
f01028d8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028db:	8d 83 b8 d5 fe ff    	lea    -0x12a48(%ebx),%eax
f01028e1:	50                   	push   %eax
f01028e2:	68 8c 03 00 00       	push   $0x38c
f01028e7:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01028ed:	50                   	push   %eax
f01028ee:	e8 a6 d7 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01028f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028f6:	8d 83 3f d5 fe ff    	lea    -0x12ac1(%ebx),%eax
f01028fc:	50                   	push   %eax
f01028fd:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102903:	50                   	push   %eax
f0102904:	68 8d 03 00 00       	push   $0x38d
f0102909:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010290f:	50                   	push   %eax
f0102910:	e8 84 d7 ff ff       	call   f0100099 <_panic>
f0102915:	52                   	push   %edx
f0102916:	8d 83 b8 d5 fe ff    	lea    -0x12a48(%ebx),%eax
f010291c:	50                   	push   %eax
f010291d:	6a 52                	push   $0x52
f010291f:	8d 83 ad d2 fe ff    	lea    -0x12d53(%ebx),%eax
f0102925:	50                   	push   %eax
f0102926:	e8 6e d7 ff ff       	call   f0100099 <_panic>
f010292b:	52                   	push   %edx
f010292c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010292f:	8d 83 b8 d5 fe ff    	lea    -0x12a48(%ebx),%eax
f0102935:	50                   	push   %eax
f0102936:	6a 52                	push   $0x52
f0102938:	8d 83 ad d2 fe ff    	lea    -0x12d53(%ebx),%eax
f010293e:	50                   	push   %eax
f010293f:	e8 55 d7 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102944:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102947:	8d 83 57 d5 fe ff    	lea    -0x12aa9(%ebx),%eax
f010294d:	50                   	push   %eax
f010294e:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102954:	50                   	push   %eax
f0102955:	68 97 03 00 00       	push   $0x397
f010295a:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102960:	50                   	push   %eax
f0102961:	e8 33 d7 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102966:	50                   	push   %eax
f0102967:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010296a:	8d 83 20 d7 fe ff    	lea    -0x128e0(%ebx),%eax
f0102970:	50                   	push   %eax
f0102971:	68 ba 00 00 00       	push   $0xba
f0102976:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010297c:	50                   	push   %eax
f010297d:	e8 17 d7 ff ff       	call   f0100099 <_panic>
f0102982:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102985:	ff b3 fc ff ff ff    	push   -0x4(%ebx)
f010298b:	8d 83 20 d7 fe ff    	lea    -0x128e0(%ebx),%eax
f0102991:	50                   	push   %eax
f0102992:	68 c7 00 00 00       	push   $0xc7
f0102997:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f010299d:	50                   	push   %eax
f010299e:	e8 f6 d6 ff ff       	call   f0100099 <_panic>
f01029a3:	ff 75 bc             	push   -0x44(%ebp)
f01029a6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029a9:	8d 83 20 d7 fe ff    	lea    -0x128e0(%ebx),%eax
f01029af:	50                   	push   %eax
f01029b0:	68 d9 02 00 00       	push   $0x2d9
f01029b5:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01029bb:	50                   	push   %eax
f01029bc:	e8 d8 d6 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01029c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029c4:	8d 83 9c db fe ff    	lea    -0x12464(%ebx),%eax
f01029ca:	50                   	push   %eax
f01029cb:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f01029d1:	50                   	push   %eax
f01029d2:	68 d9 02 00 00       	push   $0x2d9
f01029d7:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f01029dd:	50                   	push   %eax
f01029de:	e8 b6 d6 ff ff       	call   f0100099 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01029e3:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01029e6:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01029e9:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01029ec:	c1 e0 0c             	shl    $0xc,%eax
f01029ef:	89 f3                	mov    %esi,%ebx
f01029f1:	89 75 d0             	mov    %esi,-0x30(%ebp)
f01029f4:	89 c6                	mov    %eax,%esi
f01029f6:	39 f3                	cmp    %esi,%ebx
f01029f8:	73 3b                	jae    f0102a35 <mem_init+0x1714>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01029fa:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102a00:	89 f8                	mov    %edi,%eax
f0102a02:	e8 cf e0 ff ff       	call   f0100ad6 <check_va2pa>
f0102a07:	39 c3                	cmp    %eax,%ebx
f0102a09:	75 08                	jne    f0102a13 <mem_init+0x16f2>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a0b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102a11:	eb e3                	jmp    f01029f6 <mem_init+0x16d5>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102a13:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a16:	8d 83 d0 db fe ff    	lea    -0x12430(%ebx),%eax
f0102a1c:	50                   	push   %eax
f0102a1d:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102a23:	50                   	push   %eax
f0102a24:	68 de 02 00 00       	push   $0x2de
f0102a29:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102a2f:	50                   	push   %eax
f0102a30:	e8 64 d6 ff ff       	call   f0100099 <_panic>
f0102a35:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102a3a:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102a3d:	05 00 80 00 20       	add    $0x20008000,%eax
f0102a42:	89 c6                	mov    %eax,%esi
f0102a44:	89 da                	mov    %ebx,%edx
f0102a46:	89 f8                	mov    %edi,%eax
f0102a48:	e8 89 e0 ff ff       	call   f0100ad6 <check_va2pa>
f0102a4d:	89 c2                	mov    %eax,%edx
f0102a4f:	8d 04 1e             	lea    (%esi,%ebx,1),%eax
f0102a52:	39 c2                	cmp    %eax,%edx
f0102a54:	75 44                	jne    f0102a9a <mem_init+0x1779>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a56:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102a5c:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102a62:	75 e0                	jne    f0102a44 <mem_init+0x1723>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102a64:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102a67:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102a6c:	89 f8                	mov    %edi,%eax
f0102a6e:	e8 63 e0 ff ff       	call   f0100ad6 <check_va2pa>
f0102a73:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a76:	74 71                	je     f0102ae9 <mem_init+0x17c8>
f0102a78:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a7b:	8d 83 40 dc fe ff    	lea    -0x123c0(%ebx),%eax
f0102a81:	50                   	push   %eax
f0102a82:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102a88:	50                   	push   %eax
f0102a89:	68 e3 02 00 00       	push   $0x2e3
f0102a8e:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102a94:	50                   	push   %eax
f0102a95:	e8 ff d5 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102a9a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a9d:	8d 83 f8 db fe ff    	lea    -0x12408(%ebx),%eax
f0102aa3:	50                   	push   %eax
f0102aa4:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102aaa:	50                   	push   %eax
f0102aab:	68 e2 02 00 00       	push   $0x2e2
f0102ab0:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102ab6:	50                   	push   %eax
f0102ab7:	e8 dd d5 ff ff       	call   f0100099 <_panic>
		switch (i) {
f0102abc:	81 fe bf 03 00 00    	cmp    $0x3bf,%esi
f0102ac2:	75 25                	jne    f0102ae9 <mem_init+0x17c8>
			assert(pgdir[i] & PTE_P);
f0102ac4:	f6 04 b7 01          	testb  $0x1,(%edi,%esi,4)
f0102ac8:	74 4f                	je     f0102b19 <mem_init+0x17f8>
	for (i = 0; i < NPDENTRIES; i++) {
f0102aca:	83 c6 01             	add    $0x1,%esi
f0102acd:	81 fe ff 03 00 00    	cmp    $0x3ff,%esi
f0102ad3:	0f 87 b1 00 00 00    	ja     f0102b8a <mem_init+0x1869>
		switch (i) {
f0102ad9:	81 fe bd 03 00 00    	cmp    $0x3bd,%esi
f0102adf:	77 db                	ja     f0102abc <mem_init+0x179b>
f0102ae1:	81 fe bb 03 00 00    	cmp    $0x3bb,%esi
f0102ae7:	77 db                	ja     f0102ac4 <mem_init+0x17a3>
			if (i >= PDX(KERNBASE)) {
f0102ae9:	81 fe bf 03 00 00    	cmp    $0x3bf,%esi
f0102aef:	77 4a                	ja     f0102b3b <mem_init+0x181a>
				assert(pgdir[i] == 0);
f0102af1:	83 3c b7 00          	cmpl   $0x0,(%edi,%esi,4)
f0102af5:	74 d3                	je     f0102aca <mem_init+0x17a9>
f0102af7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102afa:	8d 83 a9 d5 fe ff    	lea    -0x12a57(%ebx),%eax
f0102b00:	50                   	push   %eax
f0102b01:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102b07:	50                   	push   %eax
f0102b08:	68 f2 02 00 00       	push   $0x2f2
f0102b0d:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102b13:	50                   	push   %eax
f0102b14:	e8 80 d5 ff ff       	call   f0100099 <_panic>
			assert(pgdir[i] & PTE_P);
f0102b19:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b1c:	8d 83 87 d5 fe ff    	lea    -0x12a79(%ebx),%eax
f0102b22:	50                   	push   %eax
f0102b23:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102b29:	50                   	push   %eax
f0102b2a:	68 eb 02 00 00       	push   $0x2eb
f0102b2f:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102b35:	50                   	push   %eax
f0102b36:	e8 5e d5 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102b3b:	8b 04 b7             	mov    (%edi,%esi,4),%eax
f0102b3e:	a8 01                	test   $0x1,%al
f0102b40:	74 26                	je     f0102b68 <mem_init+0x1847>
				assert(pgdir[i] & PTE_W);
f0102b42:	a8 02                	test   $0x2,%al
f0102b44:	75 84                	jne    f0102aca <mem_init+0x17a9>
f0102b46:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b49:	8d 83 98 d5 fe ff    	lea    -0x12a68(%ebx),%eax
f0102b4f:	50                   	push   %eax
f0102b50:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102b56:	50                   	push   %eax
f0102b57:	68 f0 02 00 00       	push   $0x2f0
f0102b5c:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102b62:	50                   	push   %eax
f0102b63:	e8 31 d5 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102b68:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b6b:	8d 83 87 d5 fe ff    	lea    -0x12a79(%ebx),%eax
f0102b71:	50                   	push   %eax
f0102b72:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102b78:	50                   	push   %eax
f0102b79:	68 ef 02 00 00       	push   $0x2ef
f0102b7e:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102b84:	50                   	push   %eax
f0102b85:	e8 0f d5 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102b8a:	83 ec 0c             	sub    $0xc,%esp
f0102b8d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b90:	8d 83 70 dc fe ff    	lea    -0x12390(%ebx),%eax
f0102b96:	50                   	push   %eax
f0102b97:	e8 db 04 00 00       	call   f0103077 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102b9c:	8b 83 b0 1f 00 00    	mov    0x1fb0(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f0102ba2:	83 c4 10             	add    $0x10,%esp
f0102ba5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102baa:	0f 86 2c 02 00 00    	jbe    f0102ddc <mem_init+0x1abb>
	return (physaddr_t)kva - KERNBASE;
f0102bb0:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102bb5:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102bb8:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bbd:	e8 90 df ff ff       	call   f0100b52 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102bc2:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102bc5:	83 e0 f3             	and    $0xfffffff3,%eax
f0102bc8:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102bcd:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102bd0:	83 ec 0c             	sub    $0xc,%esp
f0102bd3:	6a 00                	push   $0x0
f0102bd5:	e8 a5 e3 ff ff       	call   f0100f7f <page_alloc>
f0102bda:	89 c6                	mov    %eax,%esi
f0102bdc:	83 c4 10             	add    $0x10,%esp
f0102bdf:	85 c0                	test   %eax,%eax
f0102be1:	0f 84 11 02 00 00    	je     f0102df8 <mem_init+0x1ad7>
	assert((pp1 = page_alloc(0)));
f0102be7:	83 ec 0c             	sub    $0xc,%esp
f0102bea:	6a 00                	push   $0x0
f0102bec:	e8 8e e3 ff ff       	call   f0100f7f <page_alloc>
f0102bf1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102bf4:	83 c4 10             	add    $0x10,%esp
f0102bf7:	85 c0                	test   %eax,%eax
f0102bf9:	0f 84 1b 02 00 00    	je     f0102e1a <mem_init+0x1af9>
	assert((pp2 = page_alloc(0)));
f0102bff:	83 ec 0c             	sub    $0xc,%esp
f0102c02:	6a 00                	push   $0x0
f0102c04:	e8 76 e3 ff ff       	call   f0100f7f <page_alloc>
f0102c09:	89 c7                	mov    %eax,%edi
f0102c0b:	83 c4 10             	add    $0x10,%esp
f0102c0e:	85 c0                	test   %eax,%eax
f0102c10:	0f 84 26 02 00 00    	je     f0102e3c <mem_init+0x1b1b>
	page_free(pp0);
f0102c16:	83 ec 0c             	sub    $0xc,%esp
f0102c19:	56                   	push   %esi
f0102c1a:	e8 e5 e3 ff ff       	call   f0101004 <page_free>
	return (pp - pages) << PGSHIFT;
f0102c1f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102c22:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c25:	2b 81 ac 1f 00 00    	sub    0x1fac(%ecx),%eax
f0102c2b:	c1 f8 03             	sar    $0x3,%eax
f0102c2e:	89 c2                	mov    %eax,%edx
f0102c30:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c33:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102c38:	83 c4 10             	add    $0x10,%esp
f0102c3b:	3b 81 b4 1f 00 00    	cmp    0x1fb4(%ecx),%eax
f0102c41:	0f 83 17 02 00 00    	jae    f0102e5e <mem_init+0x1b3d>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c47:	83 ec 04             	sub    $0x4,%esp
f0102c4a:	68 00 10 00 00       	push   $0x1000
f0102c4f:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102c51:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102c57:	52                   	push   %edx
f0102c58:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c5b:	e8 18 10 00 00       	call   f0103c78 <memset>
	return (pp - pages) << PGSHIFT;
f0102c60:	89 f8                	mov    %edi,%eax
f0102c62:	2b 83 ac 1f 00 00    	sub    0x1fac(%ebx),%eax
f0102c68:	c1 f8 03             	sar    $0x3,%eax
f0102c6b:	89 c2                	mov    %eax,%edx
f0102c6d:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102c70:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102c75:	83 c4 10             	add    $0x10,%esp
f0102c78:	3b 83 b4 1f 00 00    	cmp    0x1fb4(%ebx),%eax
f0102c7e:	0f 83 f2 01 00 00    	jae    f0102e76 <mem_init+0x1b55>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c84:	83 ec 04             	sub    $0x4,%esp
f0102c87:	68 00 10 00 00       	push   $0x1000
f0102c8c:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c8e:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0102c94:	52                   	push   %edx
f0102c95:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c98:	e8 db 0f 00 00       	call   f0103c78 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c9d:	6a 02                	push   $0x2
f0102c9f:	68 00 10 00 00       	push   $0x1000
f0102ca4:	ff 75 d0             	push   -0x30(%ebp)
f0102ca7:	ff b3 b0 1f 00 00    	push   0x1fb0(%ebx)
f0102cad:	e8 ef e5 ff ff       	call   f01012a1 <page_insert>
	assert(pp1->pp_ref == 1);
f0102cb2:	83 c4 20             	add    $0x20,%esp
f0102cb5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102cb8:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102cbd:	0f 85 cc 01 00 00    	jne    f0102e8f <mem_init+0x1b6e>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102cc3:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102cca:	01 01 01 
f0102ccd:	0f 85 de 01 00 00    	jne    f0102eb1 <mem_init+0x1b90>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102cd3:	6a 02                	push   $0x2
f0102cd5:	68 00 10 00 00       	push   $0x1000
f0102cda:	57                   	push   %edi
f0102cdb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cde:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0102ce4:	e8 b8 e5 ff ff       	call   f01012a1 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ce9:	83 c4 10             	add    $0x10,%esp
f0102cec:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102cf3:	02 02 02 
f0102cf6:	0f 85 d7 01 00 00    	jne    f0102ed3 <mem_init+0x1bb2>
	assert(pp2->pp_ref == 1);
f0102cfc:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102d01:	0f 85 ee 01 00 00    	jne    f0102ef5 <mem_init+0x1bd4>
	assert(pp1->pp_ref == 0);
f0102d07:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102d0a:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102d0f:	0f 85 02 02 00 00    	jne    f0102f17 <mem_init+0x1bf6>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d15:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d1c:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102d1f:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102d22:	89 f8                	mov    %edi,%eax
f0102d24:	2b 81 ac 1f 00 00    	sub    0x1fac(%ecx),%eax
f0102d2a:	c1 f8 03             	sar    $0x3,%eax
f0102d2d:	89 c2                	mov    %eax,%edx
f0102d2f:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102d32:	25 ff ff 0f 00       	and    $0xfffff,%eax
f0102d37:	3b 81 b4 1f 00 00    	cmp    0x1fb4(%ecx),%eax
f0102d3d:	0f 83 f6 01 00 00    	jae    f0102f39 <mem_init+0x1c18>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d43:	81 ba 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%edx)
f0102d4a:	03 03 03 
f0102d4d:	0f 85 fe 01 00 00    	jne    f0102f51 <mem_init+0x1c30>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d53:	83 ec 08             	sub    $0x8,%esp
f0102d56:	68 00 10 00 00       	push   $0x1000
f0102d5b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d5e:	ff b0 b0 1f 00 00    	push   0x1fb0(%eax)
f0102d64:	e8 fd e4 ff ff       	call   f0101266 <page_remove>
	assert(pp2->pp_ref == 0);
f0102d69:	83 c4 10             	add    $0x10,%esp
f0102d6c:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d71:	0f 85 fc 01 00 00    	jne    f0102f73 <mem_init+0x1c52>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d77:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d7a:	8b 88 b0 1f 00 00    	mov    0x1fb0(%eax),%ecx
f0102d80:	8b 11                	mov    (%ecx),%edx
f0102d82:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102d88:	89 f7                	mov    %esi,%edi
f0102d8a:	2b b8 ac 1f 00 00    	sub    0x1fac(%eax),%edi
f0102d90:	89 f8                	mov    %edi,%eax
f0102d92:	c1 f8 03             	sar    $0x3,%eax
f0102d95:	c1 e0 0c             	shl    $0xc,%eax
f0102d98:	39 c2                	cmp    %eax,%edx
f0102d9a:	0f 85 f5 01 00 00    	jne    f0102f95 <mem_init+0x1c74>
	kern_pgdir[0] = 0;
f0102da0:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102da6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102dab:	0f 85 06 02 00 00    	jne    f0102fb7 <mem_init+0x1c96>
	pp0->pp_ref = 0;
f0102db1:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102db7:	83 ec 0c             	sub    $0xc,%esp
f0102dba:	56                   	push   %esi
f0102dbb:	e8 44 e2 ff ff       	call   f0101004 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102dc0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dc3:	8d 83 04 dd fe ff    	lea    -0x122fc(%ebx),%eax
f0102dc9:	89 04 24             	mov    %eax,(%esp)
f0102dcc:	e8 a6 02 00 00       	call   f0103077 <cprintf>
}
f0102dd1:	83 c4 10             	add    $0x10,%esp
f0102dd4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102dd7:	5b                   	pop    %ebx
f0102dd8:	5e                   	pop    %esi
f0102dd9:	5f                   	pop    %edi
f0102dda:	5d                   	pop    %ebp
f0102ddb:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ddc:	50                   	push   %eax
f0102ddd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102de0:	8d 83 20 d7 fe ff    	lea    -0x128e0(%ebx),%eax
f0102de6:	50                   	push   %eax
f0102de7:	68 dd 00 00 00       	push   $0xdd
f0102dec:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102df2:	50                   	push   %eax
f0102df3:	e8 a1 d2 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102df8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dfb:	8d 83 a5 d3 fe ff    	lea    -0x12c5b(%ebx),%eax
f0102e01:	50                   	push   %eax
f0102e02:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102e08:	50                   	push   %eax
f0102e09:	68 b2 03 00 00       	push   $0x3b2
f0102e0e:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102e14:	50                   	push   %eax
f0102e15:	e8 7f d2 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102e1a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e1d:	8d 83 bb d3 fe ff    	lea    -0x12c45(%ebx),%eax
f0102e23:	50                   	push   %eax
f0102e24:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102e2a:	50                   	push   %eax
f0102e2b:	68 b3 03 00 00       	push   $0x3b3
f0102e30:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102e36:	50                   	push   %eax
f0102e37:	e8 5d d2 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f0102e3c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e3f:	8d 83 d1 d3 fe ff    	lea    -0x12c2f(%ebx),%eax
f0102e45:	50                   	push   %eax
f0102e46:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102e4c:	50                   	push   %eax
f0102e4d:	68 b4 03 00 00       	push   $0x3b4
f0102e52:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102e58:	50                   	push   %eax
f0102e59:	e8 3b d2 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e5e:	52                   	push   %edx
f0102e5f:	89 cb                	mov    %ecx,%ebx
f0102e61:	8d 81 b8 d5 fe ff    	lea    -0x12a48(%ecx),%eax
f0102e67:	50                   	push   %eax
f0102e68:	6a 52                	push   $0x52
f0102e6a:	8d 81 ad d2 fe ff    	lea    -0x12d53(%ecx),%eax
f0102e70:	50                   	push   %eax
f0102e71:	e8 23 d2 ff ff       	call   f0100099 <_panic>
f0102e76:	52                   	push   %edx
f0102e77:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e7a:	8d 83 b8 d5 fe ff    	lea    -0x12a48(%ebx),%eax
f0102e80:	50                   	push   %eax
f0102e81:	6a 52                	push   $0x52
f0102e83:	8d 83 ad d2 fe ff    	lea    -0x12d53(%ebx),%eax
f0102e89:	50                   	push   %eax
f0102e8a:	e8 0a d2 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0102e8f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e92:	8d 83 a2 d4 fe ff    	lea    -0x12b5e(%ebx),%eax
f0102e98:	50                   	push   %eax
f0102e99:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102e9f:	50                   	push   %eax
f0102ea0:	68 b9 03 00 00       	push   $0x3b9
f0102ea5:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102eab:	50                   	push   %eax
f0102eac:	e8 e8 d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102eb1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102eb4:	8d 83 90 dc fe ff    	lea    -0x12370(%ebx),%eax
f0102eba:	50                   	push   %eax
f0102ebb:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102ec1:	50                   	push   %eax
f0102ec2:	68 ba 03 00 00       	push   $0x3ba
f0102ec7:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102ecd:	50                   	push   %eax
f0102ece:	e8 c6 d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102ed3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ed6:	8d 83 b4 dc fe ff    	lea    -0x1234c(%ebx),%eax
f0102edc:	50                   	push   %eax
f0102edd:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102ee3:	50                   	push   %eax
f0102ee4:	68 bc 03 00 00       	push   $0x3bc
f0102ee9:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102eef:	50                   	push   %eax
f0102ef0:	e8 a4 d1 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102ef5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ef8:	8d 83 c4 d4 fe ff    	lea    -0x12b3c(%ebx),%eax
f0102efe:	50                   	push   %eax
f0102eff:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102f05:	50                   	push   %eax
f0102f06:	68 bd 03 00 00       	push   $0x3bd
f0102f0b:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102f11:	50                   	push   %eax
f0102f12:	e8 82 d1 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102f17:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f1a:	8d 83 2e d5 fe ff    	lea    -0x12ad2(%ebx),%eax
f0102f20:	50                   	push   %eax
f0102f21:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102f27:	50                   	push   %eax
f0102f28:	68 be 03 00 00       	push   $0x3be
f0102f2d:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102f33:	50                   	push   %eax
f0102f34:	e8 60 d1 ff ff       	call   f0100099 <_panic>
f0102f39:	52                   	push   %edx
f0102f3a:	89 cb                	mov    %ecx,%ebx
f0102f3c:	8d 81 b8 d5 fe ff    	lea    -0x12a48(%ecx),%eax
f0102f42:	50                   	push   %eax
f0102f43:	6a 52                	push   $0x52
f0102f45:	8d 81 ad d2 fe ff    	lea    -0x12d53(%ecx),%eax
f0102f4b:	50                   	push   %eax
f0102f4c:	e8 48 d1 ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102f51:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f54:	8d 83 d8 dc fe ff    	lea    -0x12328(%ebx),%eax
f0102f5a:	50                   	push   %eax
f0102f5b:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102f61:	50                   	push   %eax
f0102f62:	68 c0 03 00 00       	push   $0x3c0
f0102f67:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102f6d:	50                   	push   %eax
f0102f6e:	e8 26 d1 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102f73:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f76:	8d 83 fc d4 fe ff    	lea    -0x12b04(%ebx),%eax
f0102f7c:	50                   	push   %eax
f0102f7d:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102f83:	50                   	push   %eax
f0102f84:	68 c2 03 00 00       	push   $0x3c2
f0102f89:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102f8f:	50                   	push   %eax
f0102f90:	e8 04 d1 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f95:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f98:	8d 83 1c d8 fe ff    	lea    -0x127e4(%ebx),%eax
f0102f9e:	50                   	push   %eax
f0102f9f:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102fa5:	50                   	push   %eax
f0102fa6:	68 c5 03 00 00       	push   $0x3c5
f0102fab:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102fb1:	50                   	push   %eax
f0102fb2:	e8 e2 d0 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102fb7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fba:	8d 83 b3 d4 fe ff    	lea    -0x12b4d(%ebx),%eax
f0102fc0:	50                   	push   %eax
f0102fc1:	8d 83 c7 d2 fe ff    	lea    -0x12d39(%ebx),%eax
f0102fc7:	50                   	push   %eax
f0102fc8:	68 c7 03 00 00       	push   $0x3c7
f0102fcd:	8d 83 a1 d2 fe ff    	lea    -0x12d5f(%ebx),%eax
f0102fd3:	50                   	push   %eax
f0102fd4:	e8 c0 d0 ff ff       	call   f0100099 <_panic>

f0102fd9 <tlb_invalidate>:
{
f0102fd9:	55                   	push   %ebp
f0102fda:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102fdc:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fdf:	0f 01 38             	invlpg (%eax)
}
f0102fe2:	5d                   	pop    %ebp
f0102fe3:	c3                   	ret    

f0102fe4 <__x86.get_pc_thunk.dx>:
f0102fe4:	8b 14 24             	mov    (%esp),%edx
f0102fe7:	c3                   	ret    

f0102fe8 <__x86.get_pc_thunk.cx>:
f0102fe8:	8b 0c 24             	mov    (%esp),%ecx
f0102feb:	c3                   	ret    

f0102fec <__x86.get_pc_thunk.di>:
f0102fec:	8b 3c 24             	mov    (%esp),%edi
f0102fef:	c3                   	ret    

f0102ff0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102ff0:	55                   	push   %ebp
f0102ff1:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ff3:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ff6:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ffb:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102ffc:	ba 71 00 00 00       	mov    $0x71,%edx
f0103001:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103002:	0f b6 c0             	movzbl %al,%eax
}
f0103005:	5d                   	pop    %ebp
f0103006:	c3                   	ret    

f0103007 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103007:	55                   	push   %ebp
f0103008:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010300a:	8b 45 08             	mov    0x8(%ebp),%eax
f010300d:	ba 70 00 00 00       	mov    $0x70,%edx
f0103012:	ee                   	out    %al,(%dx)
f0103013:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103016:	ba 71 00 00 00       	mov    $0x71,%edx
f010301b:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010301c:	5d                   	pop    %ebp
f010301d:	c3                   	ret    

f010301e <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010301e:	55                   	push   %ebp
f010301f:	89 e5                	mov    %esp,%ebp
f0103021:	53                   	push   %ebx
f0103022:	83 ec 10             	sub    $0x10,%esp
f0103025:	e8 25 d1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010302a:	81 c3 e2 42 01 00    	add    $0x142e2,%ebx
	cputchar(ch);
f0103030:	ff 75 08             	push   0x8(%ebp)
f0103033:	e8 82 d6 ff ff       	call   f01006ba <cputchar>
	*cnt++;
}
f0103038:	83 c4 10             	add    $0x10,%esp
f010303b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010303e:	c9                   	leave  
f010303f:	c3                   	ret    

f0103040 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103040:	55                   	push   %ebp
f0103041:	89 e5                	mov    %esp,%ebp
f0103043:	53                   	push   %ebx
f0103044:	83 ec 14             	sub    $0x14,%esp
f0103047:	e8 03 d1 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010304c:	81 c3 c0 42 01 00    	add    $0x142c0,%ebx
	int cnt = 0;
f0103052:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103059:	ff 75 0c             	push   0xc(%ebp)
f010305c:	ff 75 08             	push   0x8(%ebp)
f010305f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103062:	50                   	push   %eax
f0103063:	8d 83 12 bd fe ff    	lea    -0x142ee(%ebx),%eax
f0103069:	50                   	push   %eax
f010306a:	e8 5c 04 00 00       	call   f01034cb <vprintfmt>
	return cnt;
}
f010306f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103072:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103075:	c9                   	leave  
f0103076:	c3                   	ret    

f0103077 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103077:	55                   	push   %ebp
f0103078:	89 e5                	mov    %esp,%ebp
f010307a:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010307d:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103080:	50                   	push   %eax
f0103081:	ff 75 08             	push   0x8(%ebp)
f0103084:	e8 b7 ff ff ff       	call   f0103040 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103089:	c9                   	leave  
f010308a:	c3                   	ret    

f010308b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010308b:	55                   	push   %ebp
f010308c:	89 e5                	mov    %esp,%ebp
f010308e:	57                   	push   %edi
f010308f:	56                   	push   %esi
f0103090:	53                   	push   %ebx
f0103091:	83 ec 14             	sub    $0x14,%esp
f0103094:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103097:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010309a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010309d:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01030a0:	8b 1a                	mov    (%edx),%ebx
f01030a2:	8b 01                	mov    (%ecx),%eax
f01030a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01030a7:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01030ae:	eb 2f                	jmp    f01030df <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01030b0:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f01030b3:	39 c3                	cmp    %eax,%ebx
f01030b5:	7f 4e                	jg     f0103105 <stab_binsearch+0x7a>
f01030b7:	0f b6 0a             	movzbl (%edx),%ecx
f01030ba:	83 ea 0c             	sub    $0xc,%edx
f01030bd:	39 f1                	cmp    %esi,%ecx
f01030bf:	75 ef                	jne    f01030b0 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01030c1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01030c4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01030c7:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01030cb:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01030ce:	73 3a                	jae    f010310a <stab_binsearch+0x7f>
			*region_left = m;
f01030d0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01030d3:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01030d5:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f01030d8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01030df:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01030e2:	7f 53                	jg     f0103137 <stab_binsearch+0xac>
		int true_m = (l + r) / 2, m = true_m;
f01030e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01030e7:	8d 14 03             	lea    (%ebx,%eax,1),%edx
f01030ea:	89 d0                	mov    %edx,%eax
f01030ec:	c1 e8 1f             	shr    $0x1f,%eax
f01030ef:	01 d0                	add    %edx,%eax
f01030f1:	89 c7                	mov    %eax,%edi
f01030f3:	d1 ff                	sar    %edi
f01030f5:	83 e0 fe             	and    $0xfffffffe,%eax
f01030f8:	01 f8                	add    %edi,%eax
f01030fa:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01030fd:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0103101:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0103103:	eb ae                	jmp    f01030b3 <stab_binsearch+0x28>
			l = true_m + 1;
f0103105:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0103108:	eb d5                	jmp    f01030df <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f010310a:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010310d:	76 14                	jbe    f0103123 <stab_binsearch+0x98>
			*region_right = m - 1;
f010310f:	83 e8 01             	sub    $0x1,%eax
f0103112:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103115:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103118:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f010311a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103121:	eb bc                	jmp    f01030df <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103123:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103126:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0103128:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010312c:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f010312e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103135:	eb a8                	jmp    f01030df <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0103137:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010313b:	75 15                	jne    f0103152 <stab_binsearch+0xc7>
		*region_right = *region_left - 1;
f010313d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103140:	8b 00                	mov    (%eax),%eax
f0103142:	83 e8 01             	sub    $0x1,%eax
f0103145:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103148:	89 07                	mov    %eax,(%edi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f010314a:	83 c4 14             	add    $0x14,%esp
f010314d:	5b                   	pop    %ebx
f010314e:	5e                   	pop    %esi
f010314f:	5f                   	pop    %edi
f0103150:	5d                   	pop    %ebp
f0103151:	c3                   	ret    
		for (l = *region_right;
f0103152:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103155:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103157:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010315a:	8b 0f                	mov    (%edi),%ecx
f010315c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010315f:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103162:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f0103166:	39 c1                	cmp    %eax,%ecx
f0103168:	7d 0f                	jge    f0103179 <stab_binsearch+0xee>
f010316a:	0f b6 1a             	movzbl (%edx),%ebx
f010316d:	83 ea 0c             	sub    $0xc,%edx
f0103170:	39 f3                	cmp    %esi,%ebx
f0103172:	74 05                	je     f0103179 <stab_binsearch+0xee>
		     l--)
f0103174:	83 e8 01             	sub    $0x1,%eax
f0103177:	eb ed                	jmp    f0103166 <stab_binsearch+0xdb>
		*region_left = l;
f0103179:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010317c:	89 07                	mov    %eax,(%edi)
}
f010317e:	eb ca                	jmp    f010314a <stab_binsearch+0xbf>

f0103180 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103180:	55                   	push   %ebp
f0103181:	89 e5                	mov    %esp,%ebp
f0103183:	57                   	push   %edi
f0103184:	56                   	push   %esi
f0103185:	53                   	push   %ebx
f0103186:	83 ec 3c             	sub    $0x3c,%esp
f0103189:	e8 c1 cf ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010318e:	81 c3 7e 41 01 00    	add    $0x1417e,%ebx
f0103194:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103197:	8d 83 2d dd fe ff    	lea    -0x122d3(%ebx),%eax
f010319d:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f010319f:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01031a6:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f01031a9:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01031b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01031b3:	89 46 10             	mov    %eax,0x10(%esi)
	info->eip_fn_narg = 0;
f01031b6:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01031bd:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f01031c2:	0f 86 3e 01 00 00    	jbe    f0103306 <debuginfo_eip+0x186>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01031c8:	c7 c0 19 b7 10 f0    	mov    $0xf010b719,%eax
f01031ce:	39 83 f8 ff ff ff    	cmp    %eax,-0x8(%ebx)
f01031d4:	0f 86 d0 01 00 00    	jbe    f01033aa <debuginfo_eip+0x22a>
f01031da:	c7 c0 4f d4 10 f0    	mov    $0xf010d44f,%eax
f01031e0:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01031e4:	0f 85 c7 01 00 00    	jne    f01033b1 <debuginfo_eip+0x231>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01031ea:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01031f1:	c7 c0 50 52 10 f0    	mov    $0xf0105250,%eax
f01031f7:	c7 c2 18 b7 10 f0    	mov    $0xf010b718,%edx
f01031fd:	29 c2                	sub    %eax,%edx
f01031ff:	c1 fa 02             	sar    $0x2,%edx
f0103202:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103208:	83 ea 01             	sub    $0x1,%edx
f010320b:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010320e:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103211:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103214:	83 ec 08             	sub    $0x8,%esp
f0103217:	ff 75 08             	push   0x8(%ebp)
f010321a:	6a 64                	push   $0x64
f010321c:	e8 6a fe ff ff       	call   f010308b <stab_binsearch>
	if (lfile == 0)
f0103221:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103224:	83 c4 10             	add    $0x10,%esp
f0103227:	85 ff                	test   %edi,%edi
f0103229:	0f 84 89 01 00 00    	je     f01033b8 <debuginfo_eip+0x238>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010322f:	89 7d dc             	mov    %edi,-0x24(%ebp)
	rfun = rfile;
f0103232:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103235:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0103238:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010323b:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010323e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103241:	83 ec 08             	sub    $0x8,%esp
f0103244:	ff 75 08             	push   0x8(%ebp)
f0103247:	6a 24                	push   $0x24
f0103249:	c7 c0 50 52 10 f0    	mov    $0xf0105250,%eax
f010324f:	e8 37 fe ff ff       	call   f010308b <stab_binsearch>

	if (lfun <= rfun) {
f0103254:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103257:	89 4d bc             	mov    %ecx,-0x44(%ebp)
f010325a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010325d:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103260:	83 c4 10             	add    $0x10,%esp
f0103263:	89 f8                	mov    %edi,%eax
f0103265:	39 d1                	cmp    %edx,%ecx
f0103267:	7f 39                	jg     f01032a2 <debuginfo_eip+0x122>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103269:	8d 04 49             	lea    (%ecx,%ecx,2),%eax
f010326c:	c7 c2 50 52 10 f0    	mov    $0xf0105250,%edx
f0103272:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0103275:	8b 11                	mov    (%ecx),%edx
f0103277:	c7 c0 4f d4 10 f0    	mov    $0xf010d44f,%eax
f010327d:	81 e8 19 b7 10 f0    	sub    $0xf010b719,%eax
f0103283:	39 c2                	cmp    %eax,%edx
f0103285:	73 09                	jae    f0103290 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103287:	81 c2 19 b7 10 f0    	add    $0xf010b719,%edx
f010328d:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103290:	8b 41 08             	mov    0x8(%ecx),%eax
f0103293:	89 46 10             	mov    %eax,0x10(%esi)
		addr -= info->eip_fn_addr;
f0103296:	29 45 08             	sub    %eax,0x8(%ebp)
f0103299:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010329c:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010329f:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f01032a2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01032a5:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01032a8:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01032ab:	83 ec 08             	sub    $0x8,%esp
f01032ae:	6a 3a                	push   $0x3a
f01032b0:	ff 76 08             	push   0x8(%esi)
f01032b3:	e8 a4 09 00 00       	call   f0103c5c <strfind>
f01032b8:	2b 46 08             	sub    0x8(%esi),%eax
f01032bb:	89 46 0c             	mov    %eax,0xc(%esi)
	//
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01032be:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01032c1:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01032c4:	83 c4 08             	add    $0x8,%esp
f01032c7:	ff 75 08             	push   0x8(%ebp)
f01032ca:	6a 44                	push   $0x44
f01032cc:	c7 c0 50 52 10 f0    	mov    $0xf0105250,%eax
f01032d2:	e8 b4 fd ff ff       	call   f010308b <stab_binsearch>
	if (lline <= rline) 
f01032d7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032da:	83 c4 10             	add    $0x10,%esp
f01032dd:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01032e0:	0f 8f d9 00 00 00    	jg     f01033bf <debuginfo_eip+0x23f>
	{
    		info->eip_line = stabs[lline].n_desc;
f01032e6:	89 45 c0             	mov    %eax,-0x40(%ebp)
f01032e9:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01032ec:	c7 c0 50 52 10 f0    	mov    $0xf0105250,%eax
f01032f2:	0f b7 54 88 06       	movzwl 0x6(%eax,%ecx,4),%edx
f01032f7:	89 56 04             	mov    %edx,0x4(%esi)
f01032fa:	8d 44 88 04          	lea    0x4(%eax,%ecx,4),%eax
f01032fe:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0103301:	89 75 0c             	mov    %esi,0xc(%ebp)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103304:	eb 1e                	jmp    f0103324 <debuginfo_eip+0x1a4>
  	        panic("User address");
f0103306:	83 ec 04             	sub    $0x4,%esp
f0103309:	8d 83 37 dd fe ff    	lea    -0x122c9(%ebx),%eax
f010330f:	50                   	push   %eax
f0103310:	6a 7f                	push   $0x7f
f0103312:	8d 83 44 dd fe ff    	lea    -0x122bc(%ebx),%eax
f0103318:	50                   	push   %eax
f0103319:	e8 7b cd ff ff       	call   f0100099 <_panic>
f010331e:	83 ea 01             	sub    $0x1,%edx
f0103321:	83 e8 0c             	sub    $0xc,%eax
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103324:	39 d7                	cmp    %edx,%edi
f0103326:	7f 3c                	jg     f0103364 <debuginfo_eip+0x1e4>
	       && stabs[lline].n_type != N_SOL
f0103328:	0f b6 08             	movzbl (%eax),%ecx
f010332b:	80 f9 84             	cmp    $0x84,%cl
f010332e:	74 0b                	je     f010333b <debuginfo_eip+0x1bb>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103330:	80 f9 64             	cmp    $0x64,%cl
f0103333:	75 e9                	jne    f010331e <debuginfo_eip+0x19e>
f0103335:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0103339:	74 e3                	je     f010331e <debuginfo_eip+0x19e>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010333b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010333e:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103341:	c7 c0 50 52 10 f0    	mov    $0xf0105250,%eax
f0103347:	8b 14 90             	mov    (%eax,%edx,4),%edx
f010334a:	c7 c0 4f d4 10 f0    	mov    $0xf010d44f,%eax
f0103350:	81 e8 19 b7 10 f0    	sub    $0xf010b719,%eax
f0103356:	39 c2                	cmp    %eax,%edx
f0103358:	73 0d                	jae    f0103367 <debuginfo_eip+0x1e7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010335a:	81 c2 19 b7 10 f0    	add    $0xf010b719,%edx
f0103360:	89 16                	mov    %edx,(%esi)
f0103362:	eb 03                	jmp    f0103367 <debuginfo_eip+0x1e7>
f0103364:	8b 75 0c             	mov    0xc(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103367:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f010336c:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010336f:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103372:	39 cf                	cmp    %ecx,%edi
f0103374:	7d 55                	jge    f01033cb <debuginfo_eip+0x24b>
		for (lline = lfun + 1;
f0103376:	83 c7 01             	add    $0x1,%edi
f0103379:	89 f8                	mov    %edi,%eax
f010337b:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f010337e:	c7 c2 50 52 10 f0    	mov    $0xf0105250,%edx
f0103384:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0103388:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f010338b:	eb 04                	jmp    f0103391 <debuginfo_eip+0x211>
			info->eip_fn_narg++;
f010338d:	83 46 14 01          	addl   $0x1,0x14(%esi)
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103391:	39 c3                	cmp    %eax,%ebx
f0103393:	7e 31                	jle    f01033c6 <debuginfo_eip+0x246>
f0103395:	0f b6 0a             	movzbl (%edx),%ecx
f0103398:	83 c0 01             	add    $0x1,%eax
f010339b:	83 c2 0c             	add    $0xc,%edx
f010339e:	80 f9 a0             	cmp    $0xa0,%cl
f01033a1:	74 ea                	je     f010338d <debuginfo_eip+0x20d>
	return 0;
f01033a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01033a8:	eb 21                	jmp    f01033cb <debuginfo_eip+0x24b>
		return -1;
f01033aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01033af:	eb 1a                	jmp    f01033cb <debuginfo_eip+0x24b>
f01033b1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01033b6:	eb 13                	jmp    f01033cb <debuginfo_eip+0x24b>
		return -1;
f01033b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01033bd:	eb 0c                	jmp    f01033cb <debuginfo_eip+0x24b>
		return -1; 
f01033bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01033c4:	eb 05                	jmp    f01033cb <debuginfo_eip+0x24b>
	return 0;
f01033c6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01033cb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033ce:	5b                   	pop    %ebx
f01033cf:	5e                   	pop    %esi
f01033d0:	5f                   	pop    %edi
f01033d1:	5d                   	pop    %ebp
f01033d2:	c3                   	ret    

f01033d3 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01033d3:	55                   	push   %ebp
f01033d4:	89 e5                	mov    %esp,%ebp
f01033d6:	57                   	push   %edi
f01033d7:	56                   	push   %esi
f01033d8:	53                   	push   %ebx
f01033d9:	83 ec 2c             	sub    $0x2c,%esp
f01033dc:	e8 07 fc ff ff       	call   f0102fe8 <__x86.get_pc_thunk.cx>
f01033e1:	81 c1 2b 3f 01 00    	add    $0x13f2b,%ecx
f01033e7:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01033ea:	89 c7                	mov    %eax,%edi
f01033ec:	89 d6                	mov    %edx,%esi
f01033ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01033f1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01033f4:	89 d1                	mov    %edx,%ecx
f01033f6:	89 c2                	mov    %eax,%edx
f01033f8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01033fb:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01033fe:	8b 45 10             	mov    0x10(%ebp),%eax
f0103401:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103404:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103407:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f010340e:	39 c2                	cmp    %eax,%edx
f0103410:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0103413:	72 41                	jb     f0103456 <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103415:	83 ec 0c             	sub    $0xc,%esp
f0103418:	ff 75 18             	push   0x18(%ebp)
f010341b:	83 eb 01             	sub    $0x1,%ebx
f010341e:	53                   	push   %ebx
f010341f:	50                   	push   %eax
f0103420:	83 ec 08             	sub    $0x8,%esp
f0103423:	ff 75 e4             	push   -0x1c(%ebp)
f0103426:	ff 75 e0             	push   -0x20(%ebp)
f0103429:	ff 75 d4             	push   -0x2c(%ebp)
f010342c:	ff 75 d0             	push   -0x30(%ebp)
f010342f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103432:	e8 39 0a 00 00       	call   f0103e70 <__udivdi3>
f0103437:	83 c4 18             	add    $0x18,%esp
f010343a:	52                   	push   %edx
f010343b:	50                   	push   %eax
f010343c:	89 f2                	mov    %esi,%edx
f010343e:	89 f8                	mov    %edi,%eax
f0103440:	e8 8e ff ff ff       	call   f01033d3 <printnum>
f0103445:	83 c4 20             	add    $0x20,%esp
f0103448:	eb 13                	jmp    f010345d <printnum+0x8a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010344a:	83 ec 08             	sub    $0x8,%esp
f010344d:	56                   	push   %esi
f010344e:	ff 75 18             	push   0x18(%ebp)
f0103451:	ff d7                	call   *%edi
f0103453:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0103456:	83 eb 01             	sub    $0x1,%ebx
f0103459:	85 db                	test   %ebx,%ebx
f010345b:	7f ed                	jg     f010344a <printnum+0x77>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010345d:	83 ec 08             	sub    $0x8,%esp
f0103460:	56                   	push   %esi
f0103461:	83 ec 04             	sub    $0x4,%esp
f0103464:	ff 75 e4             	push   -0x1c(%ebp)
f0103467:	ff 75 e0             	push   -0x20(%ebp)
f010346a:	ff 75 d4             	push   -0x2c(%ebp)
f010346d:	ff 75 d0             	push   -0x30(%ebp)
f0103470:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103473:	e8 18 0b 00 00       	call   f0103f90 <__umoddi3>
f0103478:	83 c4 14             	add    $0x14,%esp
f010347b:	0f be 84 03 52 dd fe 	movsbl -0x122ae(%ebx,%eax,1),%eax
f0103482:	ff 
f0103483:	50                   	push   %eax
f0103484:	ff d7                	call   *%edi
}
f0103486:	83 c4 10             	add    $0x10,%esp
f0103489:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010348c:	5b                   	pop    %ebx
f010348d:	5e                   	pop    %esi
f010348e:	5f                   	pop    %edi
f010348f:	5d                   	pop    %ebp
f0103490:	c3                   	ret    

f0103491 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103491:	55                   	push   %ebp
f0103492:	89 e5                	mov    %esp,%ebp
f0103494:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103497:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010349b:	8b 10                	mov    (%eax),%edx
f010349d:	3b 50 04             	cmp    0x4(%eax),%edx
f01034a0:	73 0a                	jae    f01034ac <sprintputch+0x1b>
		*b->buf++ = ch;
f01034a2:	8d 4a 01             	lea    0x1(%edx),%ecx
f01034a5:	89 08                	mov    %ecx,(%eax)
f01034a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01034aa:	88 02                	mov    %al,(%edx)
}
f01034ac:	5d                   	pop    %ebp
f01034ad:	c3                   	ret    

f01034ae <printfmt>:
{
f01034ae:	55                   	push   %ebp
f01034af:	89 e5                	mov    %esp,%ebp
f01034b1:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01034b4:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01034b7:	50                   	push   %eax
f01034b8:	ff 75 10             	push   0x10(%ebp)
f01034bb:	ff 75 0c             	push   0xc(%ebp)
f01034be:	ff 75 08             	push   0x8(%ebp)
f01034c1:	e8 05 00 00 00       	call   f01034cb <vprintfmt>
}
f01034c6:	83 c4 10             	add    $0x10,%esp
f01034c9:	c9                   	leave  
f01034ca:	c3                   	ret    

f01034cb <vprintfmt>:
{
f01034cb:	55                   	push   %ebp
f01034cc:	89 e5                	mov    %esp,%ebp
f01034ce:	57                   	push   %edi
f01034cf:	56                   	push   %esi
f01034d0:	53                   	push   %ebx
f01034d1:	83 ec 3c             	sub    $0x3c,%esp
f01034d4:	e8 08 d2 ff ff       	call   f01006e1 <__x86.get_pc_thunk.ax>
f01034d9:	05 33 3e 01 00       	add    $0x13e33,%eax
f01034de:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01034e1:	8b 75 08             	mov    0x8(%ebp),%esi
f01034e4:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01034e7:	8b 5d 10             	mov    0x10(%ebp),%ebx
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01034ea:	8d 80 38 1d 00 00    	lea    0x1d38(%eax),%eax
f01034f0:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01034f3:	eb 0a                	jmp    f01034ff <vprintfmt+0x34>
			putch(ch, putdat);
f01034f5:	83 ec 08             	sub    $0x8,%esp
f01034f8:	57                   	push   %edi
f01034f9:	50                   	push   %eax
f01034fa:	ff d6                	call   *%esi
f01034fc:	83 c4 10             	add    $0x10,%esp
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01034ff:	83 c3 01             	add    $0x1,%ebx
f0103502:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0103506:	83 f8 25             	cmp    $0x25,%eax
f0103509:	74 0c                	je     f0103517 <vprintfmt+0x4c>
			if (ch == '\0')
f010350b:	85 c0                	test   %eax,%eax
f010350d:	75 e6                	jne    f01034f5 <vprintfmt+0x2a>
}
f010350f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103512:	5b                   	pop    %ebx
f0103513:	5e                   	pop    %esi
f0103514:	5f                   	pop    %edi
f0103515:	5d                   	pop    %ebp
f0103516:	c3                   	ret    
		padc = ' ';
f0103517:	c6 45 cf 20          	movb   $0x20,-0x31(%ebp)
		altflag = 0;
f010351b:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
		precision = -1;
f0103522:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f0103529:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		lflag = 0;
f0103530:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103535:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0103538:	89 75 08             	mov    %esi,0x8(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010353b:	8d 43 01             	lea    0x1(%ebx),%eax
f010353e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103541:	0f b6 13             	movzbl (%ebx),%edx
f0103544:	8d 42 dd             	lea    -0x23(%edx),%eax
f0103547:	3c 55                	cmp    $0x55,%al
f0103549:	0f 87 fd 03 00 00    	ja     f010394c <.L20>
f010354f:	0f b6 c0             	movzbl %al,%eax
f0103552:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103555:	89 ce                	mov    %ecx,%esi
f0103557:	03 b4 81 dc dd fe ff 	add    -0x12224(%ecx,%eax,4),%esi
f010355e:	ff e6                	jmp    *%esi

f0103560 <.L68>:
f0103560:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f0103563:	c6 45 cf 2d          	movb   $0x2d,-0x31(%ebp)
f0103567:	eb d2                	jmp    f010353b <vprintfmt+0x70>

f0103569 <.L32>:
		switch (ch = *(unsigned char *) fmt++) {
f0103569:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010356c:	c6 45 cf 30          	movb   $0x30,-0x31(%ebp)
f0103570:	eb c9                	jmp    f010353b <vprintfmt+0x70>

f0103572 <.L31>:
f0103572:	0f b6 d2             	movzbl %dl,%edx
f0103575:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f0103578:	b8 00 00 00 00       	mov    $0x0,%eax
f010357d:	8b 75 08             	mov    0x8(%ebp),%esi
				precision = precision * 10 + ch - '0';
f0103580:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103583:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103587:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f010358a:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010358d:	83 f9 09             	cmp    $0x9,%ecx
f0103590:	77 58                	ja     f01035ea <.L36+0xf>
			for (precision = 0; ; ++fmt) {
f0103592:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f0103595:	eb e9                	jmp    f0103580 <.L31+0xe>

f0103597 <.L34>:
			precision = va_arg(ap, int);
f0103597:	8b 45 14             	mov    0x14(%ebp),%eax
f010359a:	8b 00                	mov    (%eax),%eax
f010359c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010359f:	8b 45 14             	mov    0x14(%ebp),%eax
f01035a2:	8d 40 04             	lea    0x4(%eax),%eax
f01035a5:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01035a8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f01035ab:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01035af:	79 8a                	jns    f010353b <vprintfmt+0x70>
				width = precision, precision = -1;
f01035b1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01035b4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01035b7:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f01035be:	e9 78 ff ff ff       	jmp    f010353b <vprintfmt+0x70>

f01035c3 <.L33>:
f01035c3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01035c6:	85 d2                	test   %edx,%edx
f01035c8:	b8 00 00 00 00       	mov    $0x0,%eax
f01035cd:	0f 49 c2             	cmovns %edx,%eax
f01035d0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01035d3:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f01035d6:	e9 60 ff ff ff       	jmp    f010353b <vprintfmt+0x70>

f01035db <.L36>:
		switch (ch = *(unsigned char *) fmt++) {
f01035db:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f01035de:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f01035e5:	e9 51 ff ff ff       	jmp    f010353b <vprintfmt+0x70>
f01035ea:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01035ed:	89 75 08             	mov    %esi,0x8(%ebp)
f01035f0:	eb b9                	jmp    f01035ab <.L34+0x14>

f01035f2 <.L27>:
			lflag++;
f01035f2:	83 45 c8 01          	addl   $0x1,-0x38(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01035f6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f01035f9:	e9 3d ff ff ff       	jmp    f010353b <vprintfmt+0x70>

f01035fe <.L30>:
			putch(va_arg(ap, int), putdat);
f01035fe:	8b 75 08             	mov    0x8(%ebp),%esi
f0103601:	8b 45 14             	mov    0x14(%ebp),%eax
f0103604:	8d 58 04             	lea    0x4(%eax),%ebx
f0103607:	83 ec 08             	sub    $0x8,%esp
f010360a:	57                   	push   %edi
f010360b:	ff 30                	push   (%eax)
f010360d:	ff d6                	call   *%esi
			break;
f010360f:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103612:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f0103615:	e9 c8 02 00 00       	jmp    f01038e2 <.L25+0x45>

f010361a <.L28>:
			err = va_arg(ap, int);
f010361a:	8b 75 08             	mov    0x8(%ebp),%esi
f010361d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103620:	8d 58 04             	lea    0x4(%eax),%ebx
f0103623:	8b 10                	mov    (%eax),%edx
f0103625:	89 d0                	mov    %edx,%eax
f0103627:	f7 d8                	neg    %eax
f0103629:	0f 48 c2             	cmovs  %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010362c:	83 f8 06             	cmp    $0x6,%eax
f010362f:	7f 27                	jg     f0103658 <.L28+0x3e>
f0103631:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0103634:	8b 14 82             	mov    (%edx,%eax,4),%edx
f0103637:	85 d2                	test   %edx,%edx
f0103639:	74 1d                	je     f0103658 <.L28+0x3e>
				printfmt(putch, putdat, "%s", p);
f010363b:	52                   	push   %edx
f010363c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010363f:	8d 80 d9 d2 fe ff    	lea    -0x12d27(%eax),%eax
f0103645:	50                   	push   %eax
f0103646:	57                   	push   %edi
f0103647:	56                   	push   %esi
f0103648:	e8 61 fe ff ff       	call   f01034ae <printfmt>
f010364d:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103650:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0103653:	e9 8a 02 00 00       	jmp    f01038e2 <.L25+0x45>
				printfmt(putch, putdat, "error %d", err);
f0103658:	50                   	push   %eax
f0103659:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010365c:	8d 80 6a dd fe ff    	lea    -0x12296(%eax),%eax
f0103662:	50                   	push   %eax
f0103663:	57                   	push   %edi
f0103664:	56                   	push   %esi
f0103665:	e8 44 fe ff ff       	call   f01034ae <printfmt>
f010366a:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010366d:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0103670:	e9 6d 02 00 00       	jmp    f01038e2 <.L25+0x45>

f0103675 <.L24>:
			if ((p = va_arg(ap, char *)) == NULL)
f0103675:	8b 75 08             	mov    0x8(%ebp),%esi
f0103678:	8b 45 14             	mov    0x14(%ebp),%eax
f010367b:	83 c0 04             	add    $0x4,%eax
f010367e:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0103681:	8b 45 14             	mov    0x14(%ebp),%eax
f0103684:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f0103686:	85 d2                	test   %edx,%edx
f0103688:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010368b:	8d 80 63 dd fe ff    	lea    -0x1229d(%eax),%eax
f0103691:	0f 45 c2             	cmovne %edx,%eax
f0103694:	89 45 c8             	mov    %eax,-0x38(%ebp)
			if (width > 0 && padc != '-')
f0103697:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010369b:	7e 06                	jle    f01036a3 <.L24+0x2e>
f010369d:	80 7d cf 2d          	cmpb   $0x2d,-0x31(%ebp)
f01036a1:	75 0d                	jne    f01036b0 <.L24+0x3b>
				for (width -= strnlen(p, precision); width > 0; width--)
f01036a3:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01036a6:	89 c3                	mov    %eax,%ebx
f01036a8:	03 45 d4             	add    -0x2c(%ebp),%eax
f01036ab:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01036ae:	eb 58                	jmp    f0103708 <.L24+0x93>
f01036b0:	83 ec 08             	sub    $0x8,%esp
f01036b3:	ff 75 d8             	push   -0x28(%ebp)
f01036b6:	ff 75 c8             	push   -0x38(%ebp)
f01036b9:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01036bc:	e8 44 04 00 00       	call   f0103b05 <strnlen>
f01036c1:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01036c4:	29 c2                	sub    %eax,%edx
f01036c6:	89 55 bc             	mov    %edx,-0x44(%ebp)
f01036c9:	83 c4 10             	add    $0x10,%esp
f01036cc:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f01036ce:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f01036d2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01036d5:	eb 0f                	jmp    f01036e6 <.L24+0x71>
					putch(padc, putdat);
f01036d7:	83 ec 08             	sub    $0x8,%esp
f01036da:	57                   	push   %edi
f01036db:	ff 75 d4             	push   -0x2c(%ebp)
f01036de:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f01036e0:	83 eb 01             	sub    $0x1,%ebx
f01036e3:	83 c4 10             	add    $0x10,%esp
f01036e6:	85 db                	test   %ebx,%ebx
f01036e8:	7f ed                	jg     f01036d7 <.L24+0x62>
f01036ea:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01036ed:	85 d2                	test   %edx,%edx
f01036ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01036f4:	0f 49 c2             	cmovns %edx,%eax
f01036f7:	29 c2                	sub    %eax,%edx
f01036f9:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01036fc:	eb a5                	jmp    f01036a3 <.L24+0x2e>
					putch(ch, putdat);
f01036fe:	83 ec 08             	sub    $0x8,%esp
f0103701:	57                   	push   %edi
f0103702:	52                   	push   %edx
f0103703:	ff d6                	call   *%esi
f0103705:	83 c4 10             	add    $0x10,%esp
f0103708:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010370b:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010370d:	83 c3 01             	add    $0x1,%ebx
f0103710:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0103714:	0f be d0             	movsbl %al,%edx
f0103717:	85 d2                	test   %edx,%edx
f0103719:	74 4b                	je     f0103766 <.L24+0xf1>
f010371b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010371f:	78 06                	js     f0103727 <.L24+0xb2>
f0103721:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f0103725:	78 1e                	js     f0103745 <.L24+0xd0>
				if (altflag && (ch < ' ' || ch > '~'))
f0103727:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f010372b:	74 d1                	je     f01036fe <.L24+0x89>
f010372d:	0f be c0             	movsbl %al,%eax
f0103730:	83 e8 20             	sub    $0x20,%eax
f0103733:	83 f8 5e             	cmp    $0x5e,%eax
f0103736:	76 c6                	jbe    f01036fe <.L24+0x89>
					putch('?', putdat);
f0103738:	83 ec 08             	sub    $0x8,%esp
f010373b:	57                   	push   %edi
f010373c:	6a 3f                	push   $0x3f
f010373e:	ff d6                	call   *%esi
f0103740:	83 c4 10             	add    $0x10,%esp
f0103743:	eb c3                	jmp    f0103708 <.L24+0x93>
f0103745:	89 cb                	mov    %ecx,%ebx
f0103747:	eb 0e                	jmp    f0103757 <.L24+0xe2>
				putch(' ', putdat);
f0103749:	83 ec 08             	sub    $0x8,%esp
f010374c:	57                   	push   %edi
f010374d:	6a 20                	push   $0x20
f010374f:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0103751:	83 eb 01             	sub    $0x1,%ebx
f0103754:	83 c4 10             	add    $0x10,%esp
f0103757:	85 db                	test   %ebx,%ebx
f0103759:	7f ee                	jg     f0103749 <.L24+0xd4>
			if ((p = va_arg(ap, char *)) == NULL)
f010375b:	8b 45 c0             	mov    -0x40(%ebp),%eax
f010375e:	89 45 14             	mov    %eax,0x14(%ebp)
f0103761:	e9 7c 01 00 00       	jmp    f01038e2 <.L25+0x45>
f0103766:	89 cb                	mov    %ecx,%ebx
f0103768:	eb ed                	jmp    f0103757 <.L24+0xe2>

f010376a <.L29>:
	if (lflag >= 2)
f010376a:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010376d:	8b 75 08             	mov    0x8(%ebp),%esi
f0103770:	83 f9 01             	cmp    $0x1,%ecx
f0103773:	7f 1b                	jg     f0103790 <.L29+0x26>
	else if (lflag)
f0103775:	85 c9                	test   %ecx,%ecx
f0103777:	74 63                	je     f01037dc <.L29+0x72>
		return va_arg(*ap, long);
f0103779:	8b 45 14             	mov    0x14(%ebp),%eax
f010377c:	8b 00                	mov    (%eax),%eax
f010377e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103781:	99                   	cltd   
f0103782:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103785:	8b 45 14             	mov    0x14(%ebp),%eax
f0103788:	8d 40 04             	lea    0x4(%eax),%eax
f010378b:	89 45 14             	mov    %eax,0x14(%ebp)
f010378e:	eb 17                	jmp    f01037a7 <.L29+0x3d>
		return va_arg(*ap, long long);
f0103790:	8b 45 14             	mov    0x14(%ebp),%eax
f0103793:	8b 50 04             	mov    0x4(%eax),%edx
f0103796:	8b 00                	mov    (%eax),%eax
f0103798:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010379b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010379e:	8b 45 14             	mov    0x14(%ebp),%eax
f01037a1:	8d 40 08             	lea    0x8(%eax),%eax
f01037a4:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01037a7:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01037aa:	8b 5d dc             	mov    -0x24(%ebp),%ebx
			base = 10;
f01037ad:	ba 0a 00 00 00       	mov    $0xa,%edx
			if ((long long) num < 0) {
f01037b2:	85 db                	test   %ebx,%ebx
f01037b4:	0f 89 0e 01 00 00    	jns    f01038c8 <.L25+0x2b>
				putch('-', putdat);
f01037ba:	83 ec 08             	sub    $0x8,%esp
f01037bd:	57                   	push   %edi
f01037be:	6a 2d                	push   $0x2d
f01037c0:	ff d6                	call   *%esi
				num = -(long long) num;
f01037c2:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01037c5:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01037c8:	f7 d9                	neg    %ecx
f01037ca:	83 d3 00             	adc    $0x0,%ebx
f01037cd:	f7 db                	neg    %ebx
f01037cf:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01037d2:	ba 0a 00 00 00       	mov    $0xa,%edx
f01037d7:	e9 ec 00 00 00       	jmp    f01038c8 <.L25+0x2b>
		return va_arg(*ap, int);
f01037dc:	8b 45 14             	mov    0x14(%ebp),%eax
f01037df:	8b 00                	mov    (%eax),%eax
f01037e1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01037e4:	99                   	cltd   
f01037e5:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01037e8:	8b 45 14             	mov    0x14(%ebp),%eax
f01037eb:	8d 40 04             	lea    0x4(%eax),%eax
f01037ee:	89 45 14             	mov    %eax,0x14(%ebp)
f01037f1:	eb b4                	jmp    f01037a7 <.L29+0x3d>

f01037f3 <.L23>:
	if (lflag >= 2)
f01037f3:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01037f6:	8b 75 08             	mov    0x8(%ebp),%esi
f01037f9:	83 f9 01             	cmp    $0x1,%ecx
f01037fc:	7f 1e                	jg     f010381c <.L23+0x29>
	else if (lflag)
f01037fe:	85 c9                	test   %ecx,%ecx
f0103800:	74 32                	je     f0103834 <.L23+0x41>
		return va_arg(*ap, unsigned long);
f0103802:	8b 45 14             	mov    0x14(%ebp),%eax
f0103805:	8b 08                	mov    (%eax),%ecx
f0103807:	bb 00 00 00 00       	mov    $0x0,%ebx
f010380c:	8d 40 04             	lea    0x4(%eax),%eax
f010380f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103812:	ba 0a 00 00 00       	mov    $0xa,%edx
		return va_arg(*ap, unsigned long);
f0103817:	e9 ac 00 00 00       	jmp    f01038c8 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f010381c:	8b 45 14             	mov    0x14(%ebp),%eax
f010381f:	8b 08                	mov    (%eax),%ecx
f0103821:	8b 58 04             	mov    0x4(%eax),%ebx
f0103824:	8d 40 08             	lea    0x8(%eax),%eax
f0103827:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010382a:	ba 0a 00 00 00       	mov    $0xa,%edx
		return va_arg(*ap, unsigned long long);
f010382f:	e9 94 00 00 00       	jmp    f01038c8 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0103834:	8b 45 14             	mov    0x14(%ebp),%eax
f0103837:	8b 08                	mov    (%eax),%ecx
f0103839:	bb 00 00 00 00       	mov    $0x0,%ebx
f010383e:	8d 40 04             	lea    0x4(%eax),%eax
f0103841:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103844:	ba 0a 00 00 00       	mov    $0xa,%edx
		return va_arg(*ap, unsigned int);
f0103849:	eb 7d                	jmp    f01038c8 <.L25+0x2b>

f010384b <.L26>:
	if (lflag >= 2)
f010384b:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010384e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103851:	83 f9 01             	cmp    $0x1,%ecx
f0103854:	7f 1b                	jg     f0103871 <.L26+0x26>
	else if (lflag)
f0103856:	85 c9                	test   %ecx,%ecx
f0103858:	74 2c                	je     f0103886 <.L26+0x3b>
		return va_arg(*ap, unsigned long);
f010385a:	8b 45 14             	mov    0x14(%ebp),%eax
f010385d:	8b 08                	mov    (%eax),%ecx
f010385f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103864:	8d 40 04             	lea    0x4(%eax),%eax
f0103867:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010386a:	ba 08 00 00 00       	mov    $0x8,%edx
		return va_arg(*ap, unsigned long);
f010386f:	eb 57                	jmp    f01038c8 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0103871:	8b 45 14             	mov    0x14(%ebp),%eax
f0103874:	8b 08                	mov    (%eax),%ecx
f0103876:	8b 58 04             	mov    0x4(%eax),%ebx
f0103879:	8d 40 08             	lea    0x8(%eax),%eax
f010387c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f010387f:	ba 08 00 00 00       	mov    $0x8,%edx
		return va_arg(*ap, unsigned long long);
f0103884:	eb 42                	jmp    f01038c8 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0103886:	8b 45 14             	mov    0x14(%ebp),%eax
f0103889:	8b 08                	mov    (%eax),%ecx
f010388b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103890:	8d 40 04             	lea    0x4(%eax),%eax
f0103893:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0103896:	ba 08 00 00 00       	mov    $0x8,%edx
		return va_arg(*ap, unsigned int);
f010389b:	eb 2b                	jmp    f01038c8 <.L25+0x2b>

f010389d <.L25>:
			putch('0', putdat);
f010389d:	8b 75 08             	mov    0x8(%ebp),%esi
f01038a0:	83 ec 08             	sub    $0x8,%esp
f01038a3:	57                   	push   %edi
f01038a4:	6a 30                	push   $0x30
f01038a6:	ff d6                	call   *%esi
			putch('x', putdat);
f01038a8:	83 c4 08             	add    $0x8,%esp
f01038ab:	57                   	push   %edi
f01038ac:	6a 78                	push   $0x78
f01038ae:	ff d6                	call   *%esi
			num = (unsigned long long)
f01038b0:	8b 45 14             	mov    0x14(%ebp),%eax
f01038b3:	8b 08                	mov    (%eax),%ecx
f01038b5:	bb 00 00 00 00       	mov    $0x0,%ebx
			goto number;
f01038ba:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f01038bd:	8d 40 04             	lea    0x4(%eax),%eax
f01038c0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01038c3:	ba 10 00 00 00       	mov    $0x10,%edx
			printnum(putch, putdat, num, base, width, padc);
f01038c8:	83 ec 0c             	sub    $0xc,%esp
f01038cb:	0f be 45 cf          	movsbl -0x31(%ebp),%eax
f01038cf:	50                   	push   %eax
f01038d0:	ff 75 d4             	push   -0x2c(%ebp)
f01038d3:	52                   	push   %edx
f01038d4:	53                   	push   %ebx
f01038d5:	51                   	push   %ecx
f01038d6:	89 fa                	mov    %edi,%edx
f01038d8:	89 f0                	mov    %esi,%eax
f01038da:	e8 f4 fa ff ff       	call   f01033d3 <printnum>
			break;
f01038df:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01038e2:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01038e5:	e9 15 fc ff ff       	jmp    f01034ff <vprintfmt+0x34>

f01038ea <.L21>:
	if (lflag >= 2)
f01038ea:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01038ed:	8b 75 08             	mov    0x8(%ebp),%esi
f01038f0:	83 f9 01             	cmp    $0x1,%ecx
f01038f3:	7f 1b                	jg     f0103910 <.L21+0x26>
	else if (lflag)
f01038f5:	85 c9                	test   %ecx,%ecx
f01038f7:	74 2c                	je     f0103925 <.L21+0x3b>
		return va_arg(*ap, unsigned long);
f01038f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01038fc:	8b 08                	mov    (%eax),%ecx
f01038fe:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103903:	8d 40 04             	lea    0x4(%eax),%eax
f0103906:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103909:	ba 10 00 00 00       	mov    $0x10,%edx
		return va_arg(*ap, unsigned long);
f010390e:	eb b8                	jmp    f01038c8 <.L25+0x2b>
		return va_arg(*ap, unsigned long long);
f0103910:	8b 45 14             	mov    0x14(%ebp),%eax
f0103913:	8b 08                	mov    (%eax),%ecx
f0103915:	8b 58 04             	mov    0x4(%eax),%ebx
f0103918:	8d 40 08             	lea    0x8(%eax),%eax
f010391b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010391e:	ba 10 00 00 00       	mov    $0x10,%edx
		return va_arg(*ap, unsigned long long);
f0103923:	eb a3                	jmp    f01038c8 <.L25+0x2b>
		return va_arg(*ap, unsigned int);
f0103925:	8b 45 14             	mov    0x14(%ebp),%eax
f0103928:	8b 08                	mov    (%eax),%ecx
f010392a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010392f:	8d 40 04             	lea    0x4(%eax),%eax
f0103932:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103935:	ba 10 00 00 00       	mov    $0x10,%edx
		return va_arg(*ap, unsigned int);
f010393a:	eb 8c                	jmp    f01038c8 <.L25+0x2b>

f010393c <.L35>:
			putch(ch, putdat);
f010393c:	8b 75 08             	mov    0x8(%ebp),%esi
f010393f:	83 ec 08             	sub    $0x8,%esp
f0103942:	57                   	push   %edi
f0103943:	6a 25                	push   $0x25
f0103945:	ff d6                	call   *%esi
			break;
f0103947:	83 c4 10             	add    $0x10,%esp
f010394a:	eb 96                	jmp    f01038e2 <.L25+0x45>

f010394c <.L20>:
			putch('%', putdat);
f010394c:	8b 75 08             	mov    0x8(%ebp),%esi
f010394f:	83 ec 08             	sub    $0x8,%esp
f0103952:	57                   	push   %edi
f0103953:	6a 25                	push   $0x25
f0103955:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103957:	83 c4 10             	add    $0x10,%esp
f010395a:	89 d8                	mov    %ebx,%eax
f010395c:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103960:	74 05                	je     f0103967 <.L20+0x1b>
f0103962:	83 e8 01             	sub    $0x1,%eax
f0103965:	eb f5                	jmp    f010395c <.L20+0x10>
f0103967:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010396a:	e9 73 ff ff ff       	jmp    f01038e2 <.L25+0x45>

f010396f <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010396f:	55                   	push   %ebp
f0103970:	89 e5                	mov    %esp,%ebp
f0103972:	53                   	push   %ebx
f0103973:	83 ec 14             	sub    $0x14,%esp
f0103976:	e8 d4 c7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010397b:	81 c3 91 39 01 00    	add    $0x13991,%ebx
f0103981:	8b 45 08             	mov    0x8(%ebp),%eax
f0103984:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103987:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010398a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010398e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103991:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103998:	85 c0                	test   %eax,%eax
f010399a:	74 2b                	je     f01039c7 <vsnprintf+0x58>
f010399c:	85 d2                	test   %edx,%edx
f010399e:	7e 27                	jle    f01039c7 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01039a0:	ff 75 14             	push   0x14(%ebp)
f01039a3:	ff 75 10             	push   0x10(%ebp)
f01039a6:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01039a9:	50                   	push   %eax
f01039aa:	8d 83 85 c1 fe ff    	lea    -0x13e7b(%ebx),%eax
f01039b0:	50                   	push   %eax
f01039b1:	e8 15 fb ff ff       	call   f01034cb <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01039b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01039b9:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01039bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01039bf:	83 c4 10             	add    $0x10,%esp
}
f01039c2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01039c5:	c9                   	leave  
f01039c6:	c3                   	ret    
		return -E_INVAL;
f01039c7:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01039cc:	eb f4                	jmp    f01039c2 <vsnprintf+0x53>

f01039ce <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01039ce:	55                   	push   %ebp
f01039cf:	89 e5                	mov    %esp,%ebp
f01039d1:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01039d4:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01039d7:	50                   	push   %eax
f01039d8:	ff 75 10             	push   0x10(%ebp)
f01039db:	ff 75 0c             	push   0xc(%ebp)
f01039de:	ff 75 08             	push   0x8(%ebp)
f01039e1:	e8 89 ff ff ff       	call   f010396f <vsnprintf>
	va_end(ap);

	return rc;
}
f01039e6:	c9                   	leave  
f01039e7:	c3                   	ret    

f01039e8 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01039e8:	55                   	push   %ebp
f01039e9:	89 e5                	mov    %esp,%ebp
f01039eb:	57                   	push   %edi
f01039ec:	56                   	push   %esi
f01039ed:	53                   	push   %ebx
f01039ee:	83 ec 1c             	sub    $0x1c,%esp
f01039f1:	e8 59 c7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01039f6:	81 c3 16 39 01 00    	add    $0x13916,%ebx
f01039fc:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01039ff:	85 c0                	test   %eax,%eax
f0103a01:	74 13                	je     f0103a16 <readline+0x2e>
		cprintf("%s", prompt);
f0103a03:	83 ec 08             	sub    $0x8,%esp
f0103a06:	50                   	push   %eax
f0103a07:	8d 83 d9 d2 fe ff    	lea    -0x12d27(%ebx),%eax
f0103a0d:	50                   	push   %eax
f0103a0e:	e8 64 f6 ff ff       	call   f0103077 <cprintf>
f0103a13:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103a16:	83 ec 0c             	sub    $0xc,%esp
f0103a19:	6a 00                	push   $0x0
f0103a1b:	e8 bb cc ff ff       	call   f01006db <iscons>
f0103a20:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a23:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103a26:	bf 00 00 00 00       	mov    $0x0,%edi
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
			buf[i++] = c;
f0103a2b:	8d 83 d4 1f 00 00    	lea    0x1fd4(%ebx),%eax
f0103a31:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103a34:	eb 45                	jmp    f0103a7b <readline+0x93>
			cprintf("read error: %e\n", c);
f0103a36:	83 ec 08             	sub    $0x8,%esp
f0103a39:	50                   	push   %eax
f0103a3a:	8d 83 34 df fe ff    	lea    -0x120cc(%ebx),%eax
f0103a40:	50                   	push   %eax
f0103a41:	e8 31 f6 ff ff       	call   f0103077 <cprintf>
			return NULL;
f0103a46:	83 c4 10             	add    $0x10,%esp
f0103a49:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103a4e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a51:	5b                   	pop    %ebx
f0103a52:	5e                   	pop    %esi
f0103a53:	5f                   	pop    %edi
f0103a54:	5d                   	pop    %ebp
f0103a55:	c3                   	ret    
			if (echoing)
f0103a56:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103a5a:	75 05                	jne    f0103a61 <readline+0x79>
			i--;
f0103a5c:	83 ef 01             	sub    $0x1,%edi
f0103a5f:	eb 1a                	jmp    f0103a7b <readline+0x93>
				cputchar('\b');
f0103a61:	83 ec 0c             	sub    $0xc,%esp
f0103a64:	6a 08                	push   $0x8
f0103a66:	e8 4f cc ff ff       	call   f01006ba <cputchar>
f0103a6b:	83 c4 10             	add    $0x10,%esp
f0103a6e:	eb ec                	jmp    f0103a5c <readline+0x74>
			buf[i++] = c;
f0103a70:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103a73:	89 f0                	mov    %esi,%eax
f0103a75:	88 04 39             	mov    %al,(%ecx,%edi,1)
f0103a78:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103a7b:	e8 4a cc ff ff       	call   f01006ca <getchar>
f0103a80:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0103a82:	85 c0                	test   %eax,%eax
f0103a84:	78 b0                	js     f0103a36 <readline+0x4e>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103a86:	83 f8 08             	cmp    $0x8,%eax
f0103a89:	0f 94 c0             	sete   %al
f0103a8c:	83 fe 7f             	cmp    $0x7f,%esi
f0103a8f:	0f 94 c2             	sete   %dl
f0103a92:	08 d0                	or     %dl,%al
f0103a94:	74 04                	je     f0103a9a <readline+0xb2>
f0103a96:	85 ff                	test   %edi,%edi
f0103a98:	7f bc                	jg     f0103a56 <readline+0x6e>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103a9a:	83 fe 1f             	cmp    $0x1f,%esi
f0103a9d:	7e 1c                	jle    f0103abb <readline+0xd3>
f0103a9f:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103aa5:	7f 14                	jg     f0103abb <readline+0xd3>
			if (echoing)
f0103aa7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103aab:	74 c3                	je     f0103a70 <readline+0x88>
				cputchar(c);
f0103aad:	83 ec 0c             	sub    $0xc,%esp
f0103ab0:	56                   	push   %esi
f0103ab1:	e8 04 cc ff ff       	call   f01006ba <cputchar>
f0103ab6:	83 c4 10             	add    $0x10,%esp
f0103ab9:	eb b5                	jmp    f0103a70 <readline+0x88>
		} else if (c == '\n' || c == '\r') {
f0103abb:	83 fe 0a             	cmp    $0xa,%esi
f0103abe:	74 05                	je     f0103ac5 <readline+0xdd>
f0103ac0:	83 fe 0d             	cmp    $0xd,%esi
f0103ac3:	75 b6                	jne    f0103a7b <readline+0x93>
			if (echoing)
f0103ac5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103ac9:	75 13                	jne    f0103ade <readline+0xf6>
			buf[i] = 0;
f0103acb:	c6 84 3b d4 1f 00 00 	movb   $0x0,0x1fd4(%ebx,%edi,1)
f0103ad2:	00 
			return buf;
f0103ad3:	8d 83 d4 1f 00 00    	lea    0x1fd4(%ebx),%eax
f0103ad9:	e9 70 ff ff ff       	jmp    f0103a4e <readline+0x66>
				cputchar('\n');
f0103ade:	83 ec 0c             	sub    $0xc,%esp
f0103ae1:	6a 0a                	push   $0xa
f0103ae3:	e8 d2 cb ff ff       	call   f01006ba <cputchar>
f0103ae8:	83 c4 10             	add    $0x10,%esp
f0103aeb:	eb de                	jmp    f0103acb <readline+0xe3>

f0103aed <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103aed:	55                   	push   %ebp
f0103aee:	89 e5                	mov    %esp,%ebp
f0103af0:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103af3:	b8 00 00 00 00       	mov    $0x0,%eax
f0103af8:	eb 03                	jmp    f0103afd <strlen+0x10>
		n++;
f0103afa:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0103afd:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103b01:	75 f7                	jne    f0103afa <strlen+0xd>
	return n;
}
f0103b03:	5d                   	pop    %ebp
f0103b04:	c3                   	ret    

f0103b05 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103b05:	55                   	push   %ebp
f0103b06:	89 e5                	mov    %esp,%ebp
f0103b08:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b0b:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103b0e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b13:	eb 03                	jmp    f0103b18 <strnlen+0x13>
		n++;
f0103b15:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103b18:	39 d0                	cmp    %edx,%eax
f0103b1a:	74 08                	je     f0103b24 <strnlen+0x1f>
f0103b1c:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103b20:	75 f3                	jne    f0103b15 <strnlen+0x10>
f0103b22:	89 c2                	mov    %eax,%edx
	return n;
}
f0103b24:	89 d0                	mov    %edx,%eax
f0103b26:	5d                   	pop    %ebp
f0103b27:	c3                   	ret    

f0103b28 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103b28:	55                   	push   %ebp
f0103b29:	89 e5                	mov    %esp,%ebp
f0103b2b:	53                   	push   %ebx
f0103b2c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b2f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103b32:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b37:	0f b6 14 03          	movzbl (%ebx,%eax,1),%edx
f0103b3b:	88 14 01             	mov    %dl,(%ecx,%eax,1)
f0103b3e:	83 c0 01             	add    $0x1,%eax
f0103b41:	84 d2                	test   %dl,%dl
f0103b43:	75 f2                	jne    f0103b37 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0103b45:	89 c8                	mov    %ecx,%eax
f0103b47:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b4a:	c9                   	leave  
f0103b4b:	c3                   	ret    

f0103b4c <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103b4c:	55                   	push   %ebp
f0103b4d:	89 e5                	mov    %esp,%ebp
f0103b4f:	53                   	push   %ebx
f0103b50:	83 ec 10             	sub    $0x10,%esp
f0103b53:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103b56:	53                   	push   %ebx
f0103b57:	e8 91 ff ff ff       	call   f0103aed <strlen>
f0103b5c:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f0103b5f:	ff 75 0c             	push   0xc(%ebp)
f0103b62:	01 d8                	add    %ebx,%eax
f0103b64:	50                   	push   %eax
f0103b65:	e8 be ff ff ff       	call   f0103b28 <strcpy>
	return dst;
}
f0103b6a:	89 d8                	mov    %ebx,%eax
f0103b6c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b6f:	c9                   	leave  
f0103b70:	c3                   	ret    

f0103b71 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103b71:	55                   	push   %ebp
f0103b72:	89 e5                	mov    %esp,%ebp
f0103b74:	56                   	push   %esi
f0103b75:	53                   	push   %ebx
f0103b76:	8b 75 08             	mov    0x8(%ebp),%esi
f0103b79:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b7c:	89 f3                	mov    %esi,%ebx
f0103b7e:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103b81:	89 f0                	mov    %esi,%eax
f0103b83:	eb 0f                	jmp    f0103b94 <strncpy+0x23>
		*dst++ = *src;
f0103b85:	83 c0 01             	add    $0x1,%eax
f0103b88:	0f b6 0a             	movzbl (%edx),%ecx
f0103b8b:	88 48 ff             	mov    %cl,-0x1(%eax)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103b8e:	80 f9 01             	cmp    $0x1,%cl
f0103b91:	83 da ff             	sbb    $0xffffffff,%edx
	for (i = 0; i < size; i++) {
f0103b94:	39 d8                	cmp    %ebx,%eax
f0103b96:	75 ed                	jne    f0103b85 <strncpy+0x14>
	}
	return ret;
}
f0103b98:	89 f0                	mov    %esi,%eax
f0103b9a:	5b                   	pop    %ebx
f0103b9b:	5e                   	pop    %esi
f0103b9c:	5d                   	pop    %ebp
f0103b9d:	c3                   	ret    

f0103b9e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103b9e:	55                   	push   %ebp
f0103b9f:	89 e5                	mov    %esp,%ebp
f0103ba1:	56                   	push   %esi
f0103ba2:	53                   	push   %ebx
f0103ba3:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ba6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103ba9:	8b 55 10             	mov    0x10(%ebp),%edx
f0103bac:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103bae:	85 d2                	test   %edx,%edx
f0103bb0:	74 21                	je     f0103bd3 <strlcpy+0x35>
f0103bb2:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103bb6:	89 f2                	mov    %esi,%edx
f0103bb8:	eb 09                	jmp    f0103bc3 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103bba:	83 c1 01             	add    $0x1,%ecx
f0103bbd:	83 c2 01             	add    $0x1,%edx
f0103bc0:	88 5a ff             	mov    %bl,-0x1(%edx)
		while (--size > 0 && *src != '\0')
f0103bc3:	39 c2                	cmp    %eax,%edx
f0103bc5:	74 09                	je     f0103bd0 <strlcpy+0x32>
f0103bc7:	0f b6 19             	movzbl (%ecx),%ebx
f0103bca:	84 db                	test   %bl,%bl
f0103bcc:	75 ec                	jne    f0103bba <strlcpy+0x1c>
f0103bce:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f0103bd0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103bd3:	29 f0                	sub    %esi,%eax
}
f0103bd5:	5b                   	pop    %ebx
f0103bd6:	5e                   	pop    %esi
f0103bd7:	5d                   	pop    %ebp
f0103bd8:	c3                   	ret    

f0103bd9 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103bd9:	55                   	push   %ebp
f0103bda:	89 e5                	mov    %esp,%ebp
f0103bdc:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103bdf:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103be2:	eb 06                	jmp    f0103bea <strcmp+0x11>
		p++, q++;
f0103be4:	83 c1 01             	add    $0x1,%ecx
f0103be7:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0103bea:	0f b6 01             	movzbl (%ecx),%eax
f0103bed:	84 c0                	test   %al,%al
f0103bef:	74 04                	je     f0103bf5 <strcmp+0x1c>
f0103bf1:	3a 02                	cmp    (%edx),%al
f0103bf3:	74 ef                	je     f0103be4 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103bf5:	0f b6 c0             	movzbl %al,%eax
f0103bf8:	0f b6 12             	movzbl (%edx),%edx
f0103bfb:	29 d0                	sub    %edx,%eax
}
f0103bfd:	5d                   	pop    %ebp
f0103bfe:	c3                   	ret    

f0103bff <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103bff:	55                   	push   %ebp
f0103c00:	89 e5                	mov    %esp,%ebp
f0103c02:	53                   	push   %ebx
f0103c03:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c06:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c09:	89 c3                	mov    %eax,%ebx
f0103c0b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103c0e:	eb 06                	jmp    f0103c16 <strncmp+0x17>
		n--, p++, q++;
f0103c10:	83 c0 01             	add    $0x1,%eax
f0103c13:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0103c16:	39 d8                	cmp    %ebx,%eax
f0103c18:	74 18                	je     f0103c32 <strncmp+0x33>
f0103c1a:	0f b6 08             	movzbl (%eax),%ecx
f0103c1d:	84 c9                	test   %cl,%cl
f0103c1f:	74 04                	je     f0103c25 <strncmp+0x26>
f0103c21:	3a 0a                	cmp    (%edx),%cl
f0103c23:	74 eb                	je     f0103c10 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103c25:	0f b6 00             	movzbl (%eax),%eax
f0103c28:	0f b6 12             	movzbl (%edx),%edx
f0103c2b:	29 d0                	sub    %edx,%eax
}
f0103c2d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103c30:	c9                   	leave  
f0103c31:	c3                   	ret    
		return 0;
f0103c32:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c37:	eb f4                	jmp    f0103c2d <strncmp+0x2e>

f0103c39 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103c39:	55                   	push   %ebp
f0103c3a:	89 e5                	mov    %esp,%ebp
f0103c3c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c3f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103c43:	eb 03                	jmp    f0103c48 <strchr+0xf>
f0103c45:	83 c0 01             	add    $0x1,%eax
f0103c48:	0f b6 10             	movzbl (%eax),%edx
f0103c4b:	84 d2                	test   %dl,%dl
f0103c4d:	74 06                	je     f0103c55 <strchr+0x1c>
		if (*s == c)
f0103c4f:	38 ca                	cmp    %cl,%dl
f0103c51:	75 f2                	jne    f0103c45 <strchr+0xc>
f0103c53:	eb 05                	jmp    f0103c5a <strchr+0x21>
			return (char *) s;
	return 0;
f0103c55:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103c5a:	5d                   	pop    %ebp
f0103c5b:	c3                   	ret    

f0103c5c <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103c5c:	55                   	push   %ebp
f0103c5d:	89 e5                	mov    %esp,%ebp
f0103c5f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c62:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103c66:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103c69:	38 ca                	cmp    %cl,%dl
f0103c6b:	74 09                	je     f0103c76 <strfind+0x1a>
f0103c6d:	84 d2                	test   %dl,%dl
f0103c6f:	74 05                	je     f0103c76 <strfind+0x1a>
	for (; *s; s++)
f0103c71:	83 c0 01             	add    $0x1,%eax
f0103c74:	eb f0                	jmp    f0103c66 <strfind+0xa>
			break;
	return (char *) s;
}
f0103c76:	5d                   	pop    %ebp
f0103c77:	c3                   	ret    

f0103c78 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103c78:	55                   	push   %ebp
f0103c79:	89 e5                	mov    %esp,%ebp
f0103c7b:	57                   	push   %edi
f0103c7c:	56                   	push   %esi
f0103c7d:	53                   	push   %ebx
f0103c7e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103c81:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103c84:	85 c9                	test   %ecx,%ecx
f0103c86:	74 2f                	je     f0103cb7 <memset+0x3f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103c88:	89 f8                	mov    %edi,%eax
f0103c8a:	09 c8                	or     %ecx,%eax
f0103c8c:	a8 03                	test   $0x3,%al
f0103c8e:	75 21                	jne    f0103cb1 <memset+0x39>
		c &= 0xFF;
f0103c90:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103c94:	89 d0                	mov    %edx,%eax
f0103c96:	c1 e0 08             	shl    $0x8,%eax
f0103c99:	89 d3                	mov    %edx,%ebx
f0103c9b:	c1 e3 18             	shl    $0x18,%ebx
f0103c9e:	89 d6                	mov    %edx,%esi
f0103ca0:	c1 e6 10             	shl    $0x10,%esi
f0103ca3:	09 f3                	or     %esi,%ebx
f0103ca5:	09 da                	or     %ebx,%edx
f0103ca7:	09 d0                	or     %edx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103ca9:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0103cac:	fc                   	cld    
f0103cad:	f3 ab                	rep stos %eax,%es:(%edi)
f0103caf:	eb 06                	jmp    f0103cb7 <memset+0x3f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103cb1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103cb4:	fc                   	cld    
f0103cb5:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103cb7:	89 f8                	mov    %edi,%eax
f0103cb9:	5b                   	pop    %ebx
f0103cba:	5e                   	pop    %esi
f0103cbb:	5f                   	pop    %edi
f0103cbc:	5d                   	pop    %ebp
f0103cbd:	c3                   	ret    

f0103cbe <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103cbe:	55                   	push   %ebp
f0103cbf:	89 e5                	mov    %esp,%ebp
f0103cc1:	57                   	push   %edi
f0103cc2:	56                   	push   %esi
f0103cc3:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cc6:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103cc9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103ccc:	39 c6                	cmp    %eax,%esi
f0103cce:	73 32                	jae    f0103d02 <memmove+0x44>
f0103cd0:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103cd3:	39 c2                	cmp    %eax,%edx
f0103cd5:	76 2b                	jbe    f0103d02 <memmove+0x44>
		s += n;
		d += n;
f0103cd7:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103cda:	89 d6                	mov    %edx,%esi
f0103cdc:	09 fe                	or     %edi,%esi
f0103cde:	09 ce                	or     %ecx,%esi
f0103ce0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103ce6:	75 0e                	jne    f0103cf6 <memmove+0x38>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103ce8:	83 ef 04             	sub    $0x4,%edi
f0103ceb:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103cee:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0103cf1:	fd                   	std    
f0103cf2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103cf4:	eb 09                	jmp    f0103cff <memmove+0x41>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103cf6:	83 ef 01             	sub    $0x1,%edi
f0103cf9:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0103cfc:	fd                   	std    
f0103cfd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103cff:	fc                   	cld    
f0103d00:	eb 1a                	jmp    f0103d1c <memmove+0x5e>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103d02:	89 f2                	mov    %esi,%edx
f0103d04:	09 c2                	or     %eax,%edx
f0103d06:	09 ca                	or     %ecx,%edx
f0103d08:	f6 c2 03             	test   $0x3,%dl
f0103d0b:	75 0a                	jne    f0103d17 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103d0d:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0103d10:	89 c7                	mov    %eax,%edi
f0103d12:	fc                   	cld    
f0103d13:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103d15:	eb 05                	jmp    f0103d1c <memmove+0x5e>
		else
			asm volatile("cld; rep movsb\n"
f0103d17:	89 c7                	mov    %eax,%edi
f0103d19:	fc                   	cld    
f0103d1a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103d1c:	5e                   	pop    %esi
f0103d1d:	5f                   	pop    %edi
f0103d1e:	5d                   	pop    %ebp
f0103d1f:	c3                   	ret    

f0103d20 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103d20:	55                   	push   %ebp
f0103d21:	89 e5                	mov    %esp,%ebp
f0103d23:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103d26:	ff 75 10             	push   0x10(%ebp)
f0103d29:	ff 75 0c             	push   0xc(%ebp)
f0103d2c:	ff 75 08             	push   0x8(%ebp)
f0103d2f:	e8 8a ff ff ff       	call   f0103cbe <memmove>
}
f0103d34:	c9                   	leave  
f0103d35:	c3                   	ret    

f0103d36 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103d36:	55                   	push   %ebp
f0103d37:	89 e5                	mov    %esp,%ebp
f0103d39:	56                   	push   %esi
f0103d3a:	53                   	push   %ebx
f0103d3b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d3e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103d41:	89 c6                	mov    %eax,%esi
f0103d43:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103d46:	eb 06                	jmp    f0103d4e <memcmp+0x18>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0103d48:	83 c0 01             	add    $0x1,%eax
f0103d4b:	83 c2 01             	add    $0x1,%edx
	while (n-- > 0) {
f0103d4e:	39 f0                	cmp    %esi,%eax
f0103d50:	74 14                	je     f0103d66 <memcmp+0x30>
		if (*s1 != *s2)
f0103d52:	0f b6 08             	movzbl (%eax),%ecx
f0103d55:	0f b6 1a             	movzbl (%edx),%ebx
f0103d58:	38 d9                	cmp    %bl,%cl
f0103d5a:	74 ec                	je     f0103d48 <memcmp+0x12>
			return (int) *s1 - (int) *s2;
f0103d5c:	0f b6 c1             	movzbl %cl,%eax
f0103d5f:	0f b6 db             	movzbl %bl,%ebx
f0103d62:	29 d8                	sub    %ebx,%eax
f0103d64:	eb 05                	jmp    f0103d6b <memcmp+0x35>
	}

	return 0;
f0103d66:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103d6b:	5b                   	pop    %ebx
f0103d6c:	5e                   	pop    %esi
f0103d6d:	5d                   	pop    %ebp
f0103d6e:	c3                   	ret    

f0103d6f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103d6f:	55                   	push   %ebp
f0103d70:	89 e5                	mov    %esp,%ebp
f0103d72:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d75:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0103d78:	89 c2                	mov    %eax,%edx
f0103d7a:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103d7d:	eb 03                	jmp    f0103d82 <memfind+0x13>
f0103d7f:	83 c0 01             	add    $0x1,%eax
f0103d82:	39 d0                	cmp    %edx,%eax
f0103d84:	73 04                	jae    f0103d8a <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103d86:	38 08                	cmp    %cl,(%eax)
f0103d88:	75 f5                	jne    f0103d7f <memfind+0x10>
			break;
	return (void *) s;
}
f0103d8a:	5d                   	pop    %ebp
f0103d8b:	c3                   	ret    

f0103d8c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103d8c:	55                   	push   %ebp
f0103d8d:	89 e5                	mov    %esp,%ebp
f0103d8f:	57                   	push   %edi
f0103d90:	56                   	push   %esi
f0103d91:	53                   	push   %ebx
f0103d92:	8b 55 08             	mov    0x8(%ebp),%edx
f0103d95:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d98:	eb 03                	jmp    f0103d9d <strtol+0x11>
		s++;
f0103d9a:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0103d9d:	0f b6 02             	movzbl (%edx),%eax
f0103da0:	3c 20                	cmp    $0x20,%al
f0103da2:	74 f6                	je     f0103d9a <strtol+0xe>
f0103da4:	3c 09                	cmp    $0x9,%al
f0103da6:	74 f2                	je     f0103d9a <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0103da8:	3c 2b                	cmp    $0x2b,%al
f0103daa:	74 2a                	je     f0103dd6 <strtol+0x4a>
	int neg = 0;
f0103dac:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0103db1:	3c 2d                	cmp    $0x2d,%al
f0103db3:	74 2b                	je     f0103de0 <strtol+0x54>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103db5:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103dbb:	75 0f                	jne    f0103dcc <strtol+0x40>
f0103dbd:	80 3a 30             	cmpb   $0x30,(%edx)
f0103dc0:	74 28                	je     f0103dea <strtol+0x5e>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103dc2:	85 db                	test   %ebx,%ebx
f0103dc4:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103dc9:	0f 44 d8             	cmove  %eax,%ebx
f0103dcc:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103dd1:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103dd4:	eb 46                	jmp    f0103e1c <strtol+0x90>
		s++;
f0103dd6:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f0103dd9:	bf 00 00 00 00       	mov    $0x0,%edi
f0103dde:	eb d5                	jmp    f0103db5 <strtol+0x29>
		s++, neg = 1;
f0103de0:	83 c2 01             	add    $0x1,%edx
f0103de3:	bf 01 00 00 00       	mov    $0x1,%edi
f0103de8:	eb cb                	jmp    f0103db5 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103dea:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103dee:	74 0e                	je     f0103dfe <strtol+0x72>
	else if (base == 0 && s[0] == '0')
f0103df0:	85 db                	test   %ebx,%ebx
f0103df2:	75 d8                	jne    f0103dcc <strtol+0x40>
		s++, base = 8;
f0103df4:	83 c2 01             	add    $0x1,%edx
f0103df7:	bb 08 00 00 00       	mov    $0x8,%ebx
f0103dfc:	eb ce                	jmp    f0103dcc <strtol+0x40>
		s += 2, base = 16;
f0103dfe:	83 c2 02             	add    $0x2,%edx
f0103e01:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103e06:	eb c4                	jmp    f0103dcc <strtol+0x40>
	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
f0103e08:	0f be c0             	movsbl %al,%eax
f0103e0b:	83 e8 30             	sub    $0x30,%eax
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103e0e:	3b 45 10             	cmp    0x10(%ebp),%eax
f0103e11:	7d 3a                	jge    f0103e4d <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0103e13:	83 c2 01             	add    $0x1,%edx
f0103e16:	0f af 4d 10          	imul   0x10(%ebp),%ecx
f0103e1a:	01 c1                	add    %eax,%ecx
		if (*s >= '0' && *s <= '9')
f0103e1c:	0f b6 02             	movzbl (%edx),%eax
f0103e1f:	8d 70 d0             	lea    -0x30(%eax),%esi
f0103e22:	89 f3                	mov    %esi,%ebx
f0103e24:	80 fb 09             	cmp    $0x9,%bl
f0103e27:	76 df                	jbe    f0103e08 <strtol+0x7c>
		else if (*s >= 'a' && *s <= 'z')
f0103e29:	8d 70 9f             	lea    -0x61(%eax),%esi
f0103e2c:	89 f3                	mov    %esi,%ebx
f0103e2e:	80 fb 19             	cmp    $0x19,%bl
f0103e31:	77 08                	ja     f0103e3b <strtol+0xaf>
			dig = *s - 'a' + 10;
f0103e33:	0f be c0             	movsbl %al,%eax
f0103e36:	83 e8 57             	sub    $0x57,%eax
f0103e39:	eb d3                	jmp    f0103e0e <strtol+0x82>
		else if (*s >= 'A' && *s <= 'Z')
f0103e3b:	8d 70 bf             	lea    -0x41(%eax),%esi
f0103e3e:	89 f3                	mov    %esi,%ebx
f0103e40:	80 fb 19             	cmp    $0x19,%bl
f0103e43:	77 08                	ja     f0103e4d <strtol+0xc1>
			dig = *s - 'A' + 10;
f0103e45:	0f be c0             	movsbl %al,%eax
f0103e48:	83 e8 37             	sub    $0x37,%eax
f0103e4b:	eb c1                	jmp    f0103e0e <strtol+0x82>
		// we don't properly detect overflow!
	}

	if (endptr)
f0103e4d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103e51:	74 05                	je     f0103e58 <strtol+0xcc>
		*endptr = (char *) s;
f0103e53:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103e56:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f0103e58:	89 c8                	mov    %ecx,%eax
f0103e5a:	f7 d8                	neg    %eax
f0103e5c:	85 ff                	test   %edi,%edi
f0103e5e:	0f 45 c8             	cmovne %eax,%ecx
}
f0103e61:	89 c8                	mov    %ecx,%eax
f0103e63:	5b                   	pop    %ebx
f0103e64:	5e                   	pop    %esi
f0103e65:	5f                   	pop    %edi
f0103e66:	5d                   	pop    %ebp
f0103e67:	c3                   	ret    
f0103e68:	66 90                	xchg   %ax,%ax
f0103e6a:	66 90                	xchg   %ax,%ax
f0103e6c:	66 90                	xchg   %ax,%ax
f0103e6e:	66 90                	xchg   %ax,%ax

f0103e70 <__udivdi3>:
f0103e70:	f3 0f 1e fb          	endbr32 
f0103e74:	55                   	push   %ebp
f0103e75:	57                   	push   %edi
f0103e76:	56                   	push   %esi
f0103e77:	53                   	push   %ebx
f0103e78:	83 ec 1c             	sub    $0x1c,%esp
f0103e7b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0103e7f:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0103e83:	8b 74 24 34          	mov    0x34(%esp),%esi
f0103e87:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0103e8b:	85 c0                	test   %eax,%eax
f0103e8d:	75 19                	jne    f0103ea8 <__udivdi3+0x38>
f0103e8f:	39 f3                	cmp    %esi,%ebx
f0103e91:	76 4d                	jbe    f0103ee0 <__udivdi3+0x70>
f0103e93:	31 ff                	xor    %edi,%edi
f0103e95:	89 e8                	mov    %ebp,%eax
f0103e97:	89 f2                	mov    %esi,%edx
f0103e99:	f7 f3                	div    %ebx
f0103e9b:	89 fa                	mov    %edi,%edx
f0103e9d:	83 c4 1c             	add    $0x1c,%esp
f0103ea0:	5b                   	pop    %ebx
f0103ea1:	5e                   	pop    %esi
f0103ea2:	5f                   	pop    %edi
f0103ea3:	5d                   	pop    %ebp
f0103ea4:	c3                   	ret    
f0103ea5:	8d 76 00             	lea    0x0(%esi),%esi
f0103ea8:	39 f0                	cmp    %esi,%eax
f0103eaa:	76 14                	jbe    f0103ec0 <__udivdi3+0x50>
f0103eac:	31 ff                	xor    %edi,%edi
f0103eae:	31 c0                	xor    %eax,%eax
f0103eb0:	89 fa                	mov    %edi,%edx
f0103eb2:	83 c4 1c             	add    $0x1c,%esp
f0103eb5:	5b                   	pop    %ebx
f0103eb6:	5e                   	pop    %esi
f0103eb7:	5f                   	pop    %edi
f0103eb8:	5d                   	pop    %ebp
f0103eb9:	c3                   	ret    
f0103eba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ec0:	0f bd f8             	bsr    %eax,%edi
f0103ec3:	83 f7 1f             	xor    $0x1f,%edi
f0103ec6:	75 48                	jne    f0103f10 <__udivdi3+0xa0>
f0103ec8:	39 f0                	cmp    %esi,%eax
f0103eca:	72 06                	jb     f0103ed2 <__udivdi3+0x62>
f0103ecc:	31 c0                	xor    %eax,%eax
f0103ece:	39 eb                	cmp    %ebp,%ebx
f0103ed0:	77 de                	ja     f0103eb0 <__udivdi3+0x40>
f0103ed2:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ed7:	eb d7                	jmp    f0103eb0 <__udivdi3+0x40>
f0103ed9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103ee0:	89 d9                	mov    %ebx,%ecx
f0103ee2:	85 db                	test   %ebx,%ebx
f0103ee4:	75 0b                	jne    f0103ef1 <__udivdi3+0x81>
f0103ee6:	b8 01 00 00 00       	mov    $0x1,%eax
f0103eeb:	31 d2                	xor    %edx,%edx
f0103eed:	f7 f3                	div    %ebx
f0103eef:	89 c1                	mov    %eax,%ecx
f0103ef1:	31 d2                	xor    %edx,%edx
f0103ef3:	89 f0                	mov    %esi,%eax
f0103ef5:	f7 f1                	div    %ecx
f0103ef7:	89 c6                	mov    %eax,%esi
f0103ef9:	89 e8                	mov    %ebp,%eax
f0103efb:	89 f7                	mov    %esi,%edi
f0103efd:	f7 f1                	div    %ecx
f0103eff:	89 fa                	mov    %edi,%edx
f0103f01:	83 c4 1c             	add    $0x1c,%esp
f0103f04:	5b                   	pop    %ebx
f0103f05:	5e                   	pop    %esi
f0103f06:	5f                   	pop    %edi
f0103f07:	5d                   	pop    %ebp
f0103f08:	c3                   	ret    
f0103f09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103f10:	89 f9                	mov    %edi,%ecx
f0103f12:	ba 20 00 00 00       	mov    $0x20,%edx
f0103f17:	29 fa                	sub    %edi,%edx
f0103f19:	d3 e0                	shl    %cl,%eax
f0103f1b:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f1f:	89 d1                	mov    %edx,%ecx
f0103f21:	89 d8                	mov    %ebx,%eax
f0103f23:	d3 e8                	shr    %cl,%eax
f0103f25:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0103f29:	09 c1                	or     %eax,%ecx
f0103f2b:	89 f0                	mov    %esi,%eax
f0103f2d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103f31:	89 f9                	mov    %edi,%ecx
f0103f33:	d3 e3                	shl    %cl,%ebx
f0103f35:	89 d1                	mov    %edx,%ecx
f0103f37:	d3 e8                	shr    %cl,%eax
f0103f39:	89 f9                	mov    %edi,%ecx
f0103f3b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103f3f:	89 eb                	mov    %ebp,%ebx
f0103f41:	d3 e6                	shl    %cl,%esi
f0103f43:	89 d1                	mov    %edx,%ecx
f0103f45:	d3 eb                	shr    %cl,%ebx
f0103f47:	09 f3                	or     %esi,%ebx
f0103f49:	89 c6                	mov    %eax,%esi
f0103f4b:	89 f2                	mov    %esi,%edx
f0103f4d:	89 d8                	mov    %ebx,%eax
f0103f4f:	f7 74 24 08          	divl   0x8(%esp)
f0103f53:	89 d6                	mov    %edx,%esi
f0103f55:	89 c3                	mov    %eax,%ebx
f0103f57:	f7 64 24 0c          	mull   0xc(%esp)
f0103f5b:	39 d6                	cmp    %edx,%esi
f0103f5d:	72 19                	jb     f0103f78 <__udivdi3+0x108>
f0103f5f:	89 f9                	mov    %edi,%ecx
f0103f61:	d3 e5                	shl    %cl,%ebp
f0103f63:	39 c5                	cmp    %eax,%ebp
f0103f65:	73 04                	jae    f0103f6b <__udivdi3+0xfb>
f0103f67:	39 d6                	cmp    %edx,%esi
f0103f69:	74 0d                	je     f0103f78 <__udivdi3+0x108>
f0103f6b:	89 d8                	mov    %ebx,%eax
f0103f6d:	31 ff                	xor    %edi,%edi
f0103f6f:	e9 3c ff ff ff       	jmp    f0103eb0 <__udivdi3+0x40>
f0103f74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f78:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0103f7b:	31 ff                	xor    %edi,%edi
f0103f7d:	e9 2e ff ff ff       	jmp    f0103eb0 <__udivdi3+0x40>
f0103f82:	66 90                	xchg   %ax,%ax
f0103f84:	66 90                	xchg   %ax,%ax
f0103f86:	66 90                	xchg   %ax,%ax
f0103f88:	66 90                	xchg   %ax,%ax
f0103f8a:	66 90                	xchg   %ax,%ax
f0103f8c:	66 90                	xchg   %ax,%ax
f0103f8e:	66 90                	xchg   %ax,%ax

f0103f90 <__umoddi3>:
f0103f90:	f3 0f 1e fb          	endbr32 
f0103f94:	55                   	push   %ebp
f0103f95:	57                   	push   %edi
f0103f96:	56                   	push   %esi
f0103f97:	53                   	push   %ebx
f0103f98:	83 ec 1c             	sub    $0x1c,%esp
f0103f9b:	8b 74 24 30          	mov    0x30(%esp),%esi
f0103f9f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0103fa3:	8b 7c 24 3c          	mov    0x3c(%esp),%edi
f0103fa7:	8b 6c 24 38          	mov    0x38(%esp),%ebp
f0103fab:	89 f0                	mov    %esi,%eax
f0103fad:	89 da                	mov    %ebx,%edx
f0103faf:	85 ff                	test   %edi,%edi
f0103fb1:	75 15                	jne    f0103fc8 <__umoddi3+0x38>
f0103fb3:	39 dd                	cmp    %ebx,%ebp
f0103fb5:	76 39                	jbe    f0103ff0 <__umoddi3+0x60>
f0103fb7:	f7 f5                	div    %ebp
f0103fb9:	89 d0                	mov    %edx,%eax
f0103fbb:	31 d2                	xor    %edx,%edx
f0103fbd:	83 c4 1c             	add    $0x1c,%esp
f0103fc0:	5b                   	pop    %ebx
f0103fc1:	5e                   	pop    %esi
f0103fc2:	5f                   	pop    %edi
f0103fc3:	5d                   	pop    %ebp
f0103fc4:	c3                   	ret    
f0103fc5:	8d 76 00             	lea    0x0(%esi),%esi
f0103fc8:	39 df                	cmp    %ebx,%edi
f0103fca:	77 f1                	ja     f0103fbd <__umoddi3+0x2d>
f0103fcc:	0f bd cf             	bsr    %edi,%ecx
f0103fcf:	83 f1 1f             	xor    $0x1f,%ecx
f0103fd2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103fd6:	75 40                	jne    f0104018 <__umoddi3+0x88>
f0103fd8:	39 df                	cmp    %ebx,%edi
f0103fda:	72 04                	jb     f0103fe0 <__umoddi3+0x50>
f0103fdc:	39 f5                	cmp    %esi,%ebp
f0103fde:	77 dd                	ja     f0103fbd <__umoddi3+0x2d>
f0103fe0:	89 da                	mov    %ebx,%edx
f0103fe2:	89 f0                	mov    %esi,%eax
f0103fe4:	29 e8                	sub    %ebp,%eax
f0103fe6:	19 fa                	sbb    %edi,%edx
f0103fe8:	eb d3                	jmp    f0103fbd <__umoddi3+0x2d>
f0103fea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ff0:	89 e9                	mov    %ebp,%ecx
f0103ff2:	85 ed                	test   %ebp,%ebp
f0103ff4:	75 0b                	jne    f0104001 <__umoddi3+0x71>
f0103ff6:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ffb:	31 d2                	xor    %edx,%edx
f0103ffd:	f7 f5                	div    %ebp
f0103fff:	89 c1                	mov    %eax,%ecx
f0104001:	89 d8                	mov    %ebx,%eax
f0104003:	31 d2                	xor    %edx,%edx
f0104005:	f7 f1                	div    %ecx
f0104007:	89 f0                	mov    %esi,%eax
f0104009:	f7 f1                	div    %ecx
f010400b:	89 d0                	mov    %edx,%eax
f010400d:	31 d2                	xor    %edx,%edx
f010400f:	eb ac                	jmp    f0103fbd <__umoddi3+0x2d>
f0104011:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104018:	8b 44 24 04          	mov    0x4(%esp),%eax
f010401c:	ba 20 00 00 00       	mov    $0x20,%edx
f0104021:	29 c2                	sub    %eax,%edx
f0104023:	89 c1                	mov    %eax,%ecx
f0104025:	89 e8                	mov    %ebp,%eax
f0104027:	d3 e7                	shl    %cl,%edi
f0104029:	89 d1                	mov    %edx,%ecx
f010402b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010402f:	d3 e8                	shr    %cl,%eax
f0104031:	89 c1                	mov    %eax,%ecx
f0104033:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104037:	09 f9                	or     %edi,%ecx
f0104039:	89 df                	mov    %ebx,%edi
f010403b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010403f:	89 c1                	mov    %eax,%ecx
f0104041:	d3 e5                	shl    %cl,%ebp
f0104043:	89 d1                	mov    %edx,%ecx
f0104045:	d3 ef                	shr    %cl,%edi
f0104047:	89 c1                	mov    %eax,%ecx
f0104049:	89 f0                	mov    %esi,%eax
f010404b:	d3 e3                	shl    %cl,%ebx
f010404d:	89 d1                	mov    %edx,%ecx
f010404f:	89 fa                	mov    %edi,%edx
f0104051:	d3 e8                	shr    %cl,%eax
f0104053:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104058:	09 d8                	or     %ebx,%eax
f010405a:	f7 74 24 08          	divl   0x8(%esp)
f010405e:	89 d3                	mov    %edx,%ebx
f0104060:	d3 e6                	shl    %cl,%esi
f0104062:	f7 e5                	mul    %ebp
f0104064:	89 c7                	mov    %eax,%edi
f0104066:	89 d1                	mov    %edx,%ecx
f0104068:	39 d3                	cmp    %edx,%ebx
f010406a:	72 06                	jb     f0104072 <__umoddi3+0xe2>
f010406c:	75 0e                	jne    f010407c <__umoddi3+0xec>
f010406e:	39 c6                	cmp    %eax,%esi
f0104070:	73 0a                	jae    f010407c <__umoddi3+0xec>
f0104072:	29 e8                	sub    %ebp,%eax
f0104074:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0104078:	89 d1                	mov    %edx,%ecx
f010407a:	89 c7                	mov    %eax,%edi
f010407c:	89 f5                	mov    %esi,%ebp
f010407e:	8b 74 24 04          	mov    0x4(%esp),%esi
f0104082:	29 fd                	sub    %edi,%ebp
f0104084:	19 cb                	sbb    %ecx,%ebx
f0104086:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f010408b:	89 d8                	mov    %ebx,%eax
f010408d:	d3 e0                	shl    %cl,%eax
f010408f:	89 f1                	mov    %esi,%ecx
f0104091:	d3 ed                	shr    %cl,%ebp
f0104093:	d3 eb                	shr    %cl,%ebx
f0104095:	09 e8                	or     %ebp,%eax
f0104097:	89 da                	mov    %ebx,%edx
f0104099:	83 c4 1c             	add    $0x1c,%esp
f010409c:	5b                   	pop    %ebx
f010409d:	5e                   	pop    %esi
f010409e:	5f                   	pop    %edi
f010409f:	5d                   	pop    %ebp
f01040a0:	c3                   	ret    

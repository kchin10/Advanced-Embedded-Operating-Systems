
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
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

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
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 50 79 11 f0       	mov    $0xf0117950,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 00 33 00 00       	call   f010335d <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 6d 04 00 00       	call   f01004cf <cons_init>

//	cprintf("6828 decimal is %o octal!\n", 6828);

	// Lab 2 memory management initialization functions
	mem_init();
f0100062:	e8 95 0f 00 00       	call   f0100ffc <mem_init>
f0100067:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010006a:	83 ec 0c             	sub    $0xc,%esp
f010006d:	6a 00                	push   $0x0
f010006f:	e8 0f 07 00 00       	call   f0100783 <monitor>
f0100074:	83 c4 10             	add    $0x10,%esp
f0100077:	eb f1                	jmp    f010006a <i386_init+0x2a>

f0100079 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100079:	55                   	push   %ebp
f010007a:	89 e5                	mov    %esp,%ebp
f010007c:	56                   	push   %esi
f010007d:	53                   	push   %ebx
f010007e:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100081:	83 3d 40 79 11 f0 00 	cmpl   $0x0,0xf0117940
f0100088:	74 0f                	je     f0100099 <_panic+0x20>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 ef 06 00 00       	call   f0100783 <monitor>
f0100094:	83 c4 10             	add    $0x10,%esp
f0100097:	eb f1                	jmp    f010008a <_panic+0x11>
{
	va_list ap;

	if (panicstr)
		goto dead;
	panicstr = fmt;
f0100099:	89 35 40 79 11 f0    	mov    %esi,0xf0117940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f010009f:	fa                   	cli    
f01000a0:	fc                   	cld    

	va_start(ap, fmt);
f01000a1:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a4:	83 ec 04             	sub    $0x4,%esp
f01000a7:	ff 75 0c             	pushl  0xc(%ebp)
f01000aa:	ff 75 08             	pushl  0x8(%ebp)
f01000ad:	68 a0 37 10 f0       	push   $0xf01037a0
f01000b2:	e8 96 27 00 00       	call   f010284d <cprintf>
	vcprintf(fmt, ap);
f01000b7:	83 c4 08             	add    $0x8,%esp
f01000ba:	53                   	push   %ebx
f01000bb:	56                   	push   %esi
f01000bc:	e8 66 27 00 00       	call   f0102827 <vcprintf>
	cprintf("\n");
f01000c1:	c7 04 24 55 47 10 f0 	movl   $0xf0104755,(%esp)
f01000c8:	e8 80 27 00 00       	call   f010284d <cprintf>
f01000cd:	83 c4 10             	add    $0x10,%esp
f01000d0:	eb b8                	jmp    f010008a <_panic+0x11>

f01000d2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000d2:	55                   	push   %ebp
f01000d3:	89 e5                	mov    %esp,%ebp
f01000d5:	53                   	push   %ebx
f01000d6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000d9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000dc:	ff 75 0c             	pushl  0xc(%ebp)
f01000df:	ff 75 08             	pushl  0x8(%ebp)
f01000e2:	68 b8 37 10 f0       	push   $0xf01037b8
f01000e7:	e8 61 27 00 00       	call   f010284d <cprintf>
	vcprintf(fmt, ap);
f01000ec:	83 c4 08             	add    $0x8,%esp
f01000ef:	53                   	push   %ebx
f01000f0:	ff 75 10             	pushl  0x10(%ebp)
f01000f3:	e8 2f 27 00 00       	call   f0102827 <vcprintf>
	cprintf("\n");
f01000f8:	c7 04 24 55 47 10 f0 	movl   $0xf0104755,(%esp)
f01000ff:	e8 49 27 00 00       	call   f010284d <cprintf>
	va_end(ap);
}
f0100104:	83 c4 10             	add    $0x10,%esp
f0100107:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010010a:	c9                   	leave  
f010010b:	c3                   	ret    

f010010c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010010c:	55                   	push   %ebp
f010010d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010010f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100114:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100115:	a8 01                	test   $0x1,%al
f0100117:	74 0b                	je     f0100124 <serial_proc_data+0x18>
f0100119:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010011e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010011f:	0f b6 c0             	movzbl %al,%eax
}
f0100122:	5d                   	pop    %ebp
f0100123:	c3                   	ret    

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100124:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100129:	eb f7                	jmp    f0100122 <serial_proc_data+0x16>

f010012b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010012b:	55                   	push   %ebp
f010012c:	89 e5                	mov    %esp,%ebp
f010012e:	53                   	push   %ebx
f010012f:	83 ec 04             	sub    $0x4,%esp
f0100132:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100134:	ff d3                	call   *%ebx
f0100136:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100139:	74 2d                	je     f0100168 <cons_intr+0x3d>
		if (c == 0)
f010013b:	85 c0                	test   %eax,%eax
f010013d:	74 f5                	je     f0100134 <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f010013f:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100145:	8d 51 01             	lea    0x1(%ecx),%edx
f0100148:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f010014e:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100154:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010015a:	75 d8                	jne    f0100134 <cons_intr+0x9>
			cons.wpos = 0;
f010015c:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f0100163:	00 00 00 
f0100166:	eb cc                	jmp    f0100134 <cons_intr+0x9>
	}
}
f0100168:	83 c4 04             	add    $0x4,%esp
f010016b:	5b                   	pop    %ebx
f010016c:	5d                   	pop    %ebp
f010016d:	c3                   	ret    

f010016e <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010016e:	55                   	push   %ebp
f010016f:	89 e5                	mov    %esp,%ebp
f0100171:	53                   	push   %ebx
f0100172:	83 ec 04             	sub    $0x4,%esp
f0100175:	ba 64 00 00 00       	mov    $0x64,%edx
f010017a:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f010017b:	a8 01                	test   $0x1,%al
f010017d:	0f 84 eb 00 00 00    	je     f010026e <kbd_proc_data+0x100>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f0100183:	a8 20                	test   $0x20,%al
f0100185:	0f 85 ea 00 00 00    	jne    f0100275 <kbd_proc_data+0x107>
f010018b:	ba 60 00 00 00       	mov    $0x60,%edx
f0100190:	ec                   	in     (%dx),%al
f0100191:	88 c2                	mov    %al,%dl
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100193:	3c e0                	cmp    $0xe0,%al
f0100195:	74 73                	je     f010020a <kbd_proc_data+0x9c>
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100197:	84 c0                	test   %al,%al
f0100199:	78 7d                	js     f0100218 <kbd_proc_data+0xaa>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
		shift &= ~(shiftcode[data] | E0ESC);
		return 0;
	} else if (shift & E0ESC) {
f010019b:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001a1:	f6 c1 40             	test   $0x40,%cl
f01001a4:	74 0e                	je     f01001b4 <kbd_proc_data+0x46>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001a6:	83 c8 80             	or     $0xffffff80,%eax
f01001a9:	88 c2                	mov    %al,%dl
		shift &= ~E0ESC;
f01001ab:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001ae:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f01001b4:	0f b6 d2             	movzbl %dl,%edx
f01001b7:	0f b6 82 20 39 10 f0 	movzbl -0xfefc6e0(%edx),%eax
f01001be:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
	shift ^= togglecode[data];
f01001c4:	0f b6 8a 20 38 10 f0 	movzbl -0xfefc7e0(%edx),%ecx
f01001cb:	31 c8                	xor    %ecx,%eax
f01001cd:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f01001d2:	89 c1                	mov    %eax,%ecx
f01001d4:	83 e1 03             	and    $0x3,%ecx
f01001d7:	8b 0c 8d 00 38 10 f0 	mov    -0xfefc800(,%ecx,4),%ecx
f01001de:	8a 14 11             	mov    (%ecx,%edx,1),%dl
f01001e1:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01001e4:	a8 08                	test   $0x8,%al
f01001e6:	74 0d                	je     f01001f5 <kbd_proc_data+0x87>
		if ('a' <= c && c <= 'z')
f01001e8:	89 da                	mov    %ebx,%edx
f01001ea:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01001ed:	83 f9 19             	cmp    $0x19,%ecx
f01001f0:	77 55                	ja     f0100247 <kbd_proc_data+0xd9>
			c += 'A' - 'a';
f01001f2:	83 eb 20             	sub    $0x20,%ebx
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01001f5:	f7 d0                	not    %eax
f01001f7:	a8 06                	test   $0x6,%al
f01001f9:	75 08                	jne    f0100203 <kbd_proc_data+0x95>
f01001fb:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100201:	74 51                	je     f0100254 <kbd_proc_data+0xe6>
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100203:	89 d8                	mov    %ebx,%eax
f0100205:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100208:	c9                   	leave  
f0100209:	c3                   	ret    

	data = inb(KBDATAP);

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
f010020a:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f0100211:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100216:	eb eb                	jmp    f0100203 <kbd_proc_data+0x95>
	} else if (data & 0x80) {
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100218:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f010021e:	f6 c1 40             	test   $0x40,%cl
f0100221:	75 05                	jne    f0100228 <kbd_proc_data+0xba>
f0100223:	83 e0 7f             	and    $0x7f,%eax
f0100226:	88 c2                	mov    %al,%dl
		shift &= ~(shiftcode[data] | E0ESC);
f0100228:	0f b6 d2             	movzbl %dl,%edx
f010022b:	8a 82 20 39 10 f0    	mov    -0xfefc6e0(%edx),%al
f0100231:	83 c8 40             	or     $0x40,%eax
f0100234:	0f b6 c0             	movzbl %al,%eax
f0100237:	f7 d0                	not    %eax
f0100239:	21 c8                	and    %ecx,%eax
f010023b:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f0100240:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100245:	eb bc                	jmp    f0100203 <kbd_proc_data+0x95>

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
f0100247:	83 ea 41             	sub    $0x41,%edx
f010024a:	83 fa 19             	cmp    $0x19,%edx
f010024d:	77 a6                	ja     f01001f5 <kbd_proc_data+0x87>
			c += 'a' - 'A';
f010024f:	83 c3 20             	add    $0x20,%ebx
f0100252:	eb a1                	jmp    f01001f5 <kbd_proc_data+0x87>
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
f0100254:	83 ec 0c             	sub    $0xc,%esp
f0100257:	68 d2 37 10 f0       	push   $0xf01037d2
f010025c:	e8 ec 25 00 00       	call   f010284d <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100261:	ba 92 00 00 00       	mov    $0x92,%edx
f0100266:	b0 03                	mov    $0x3,%al
f0100268:	ee                   	out    %al,(%dx)
f0100269:	83 c4 10             	add    $0x10,%esp
f010026c:	eb 95                	jmp    f0100203 <kbd_proc_data+0x95>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f010026e:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f0100273:	eb 8e                	jmp    f0100203 <kbd_proc_data+0x95>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f0100275:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f010027a:	eb 87                	jmp    f0100203 <kbd_proc_data+0x95>

f010027c <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010027c:	55                   	push   %ebp
f010027d:	89 e5                	mov    %esp,%ebp
f010027f:	57                   	push   %edi
f0100280:	56                   	push   %esi
f0100281:	53                   	push   %ebx
f0100282:	83 ec 1c             	sub    $0x1c,%esp
f0100285:	89 c7                	mov    %eax,%edi
f0100287:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010028c:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100291:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100296:	eb 06                	jmp    f010029e <cons_putc+0x22>
f0100298:	89 ca                	mov    %ecx,%edx
f010029a:	ec                   	in     (%dx),%al
f010029b:	ec                   	in     (%dx),%al
f010029c:	ec                   	in     (%dx),%al
f010029d:	ec                   	in     (%dx),%al
f010029e:	89 f2                	mov    %esi,%edx
f01002a0:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a1:	a8 20                	test   $0x20,%al
f01002a3:	75 03                	jne    f01002a8 <cons_putc+0x2c>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002a5:	4b                   	dec    %ebx
f01002a6:	75 f0                	jne    f0100298 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002a8:	89 f8                	mov    %edi,%eax
f01002aa:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ad:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002b2:	ee                   	out    %al,(%dx)
f01002b3:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002b8:	be 79 03 00 00       	mov    $0x379,%esi
f01002bd:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002c2:	eb 06                	jmp    f01002ca <cons_putc+0x4e>
f01002c4:	89 ca                	mov    %ecx,%edx
f01002c6:	ec                   	in     (%dx),%al
f01002c7:	ec                   	in     (%dx),%al
f01002c8:	ec                   	in     (%dx),%al
f01002c9:	ec                   	in     (%dx),%al
f01002ca:	89 f2                	mov    %esi,%edx
f01002cc:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002cd:	84 c0                	test   %al,%al
f01002cf:	78 03                	js     f01002d4 <cons_putc+0x58>
f01002d1:	4b                   	dec    %ebx
f01002d2:	75 f0                	jne    f01002c4 <cons_putc+0x48>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d4:	ba 78 03 00 00       	mov    $0x378,%edx
f01002d9:	8a 45 e7             	mov    -0x19(%ebp),%al
f01002dc:	ee                   	out    %al,(%dx)
f01002dd:	ba 7a 03 00 00       	mov    $0x37a,%edx
f01002e2:	b0 0d                	mov    $0xd,%al
f01002e4:	ee                   	out    %al,(%dx)
f01002e5:	b0 08                	mov    $0x8,%al
f01002e7:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01002e8:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f01002ee:	75 06                	jne    f01002f6 <cons_putc+0x7a>
		c |= 0x0700;
f01002f0:	81 cf 00 07 00 00    	or     $0x700,%edi

	switch (c & 0xff) {
f01002f6:	89 f8                	mov    %edi,%eax
f01002f8:	0f b6 c0             	movzbl %al,%eax
f01002fb:	83 f8 09             	cmp    $0x9,%eax
f01002fe:	0f 84 b1 00 00 00    	je     f01003b5 <cons_putc+0x139>
f0100304:	83 f8 09             	cmp    $0x9,%eax
f0100307:	7e 70                	jle    f0100379 <cons_putc+0xfd>
f0100309:	83 f8 0a             	cmp    $0xa,%eax
f010030c:	0f 84 96 00 00 00    	je     f01003a8 <cons_putc+0x12c>
f0100312:	83 f8 0d             	cmp    $0xd,%eax
f0100315:	0f 85 d1 00 00 00    	jne    f01003ec <cons_putc+0x170>
		break;
	case '\n':
		crt_pos += CRT_COLS;
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010031b:	66 8b 0d 28 75 11 f0 	mov    0xf0117528,%cx
f0100322:	bb 50 00 00 00       	mov    $0x50,%ebx
f0100327:	89 c8                	mov    %ecx,%eax
f0100329:	ba 00 00 00 00       	mov    $0x0,%edx
f010032e:	66 f7 f3             	div    %bx
f0100331:	29 d1                	sub    %edx,%ecx
f0100333:	66 89 0d 28 75 11 f0 	mov    %cx,0xf0117528
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010033a:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f0100341:	cf 07 
f0100343:	0f 87 c5 00 00 00    	ja     f010040e <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100349:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f010034f:	b0 0e                	mov    $0xe,%al
f0100351:	89 ca                	mov    %ecx,%edx
f0100353:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100354:	8d 59 01             	lea    0x1(%ecx),%ebx
f0100357:	66 a1 28 75 11 f0    	mov    0xf0117528,%ax
f010035d:	66 c1 e8 08          	shr    $0x8,%ax
f0100361:	89 da                	mov    %ebx,%edx
f0100363:	ee                   	out    %al,(%dx)
f0100364:	b0 0f                	mov    $0xf,%al
f0100366:	89 ca                	mov    %ecx,%edx
f0100368:	ee                   	out    %al,(%dx)
f0100369:	a0 28 75 11 f0       	mov    0xf0117528,%al
f010036e:	89 da                	mov    %ebx,%edx
f0100370:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100371:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100374:	5b                   	pop    %ebx
f0100375:	5e                   	pop    %esi
f0100376:	5f                   	pop    %edi
f0100377:	5d                   	pop    %ebp
f0100378:	c3                   	ret    
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
		c |= 0x0700;

	switch (c & 0xff) {
f0100379:	83 f8 08             	cmp    $0x8,%eax
f010037c:	75 6e                	jne    f01003ec <cons_putc+0x170>
	case '\b':
		if (crt_pos > 0) {
f010037e:	66 a1 28 75 11 f0    	mov    0xf0117528,%ax
f0100384:	66 85 c0             	test   %ax,%ax
f0100387:	74 c0                	je     f0100349 <cons_putc+0xcd>
			crt_pos--;
f0100389:	48                   	dec    %eax
f010038a:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100390:	0f b7 c0             	movzwl %ax,%eax
f0100393:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f0100399:	83 cf 20             	or     $0x20,%edi
f010039c:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003a2:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003a6:	eb 92                	jmp    f010033a <cons_putc+0xbe>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003a8:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f01003af:	50 
f01003b0:	e9 66 ff ff ff       	jmp    f010031b <cons_putc+0x9f>
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
		break;
	case '\t':
		cons_putc(' ');
f01003b5:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ba:	e8 bd fe ff ff       	call   f010027c <cons_putc>
		cons_putc(' ');
f01003bf:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c4:	e8 b3 fe ff ff       	call   f010027c <cons_putc>
		cons_putc(' ');
f01003c9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ce:	e8 a9 fe ff ff       	call   f010027c <cons_putc>
		cons_putc(' ');
f01003d3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d8:	e8 9f fe ff ff       	call   f010027c <cons_putc>
		cons_putc(' ');
f01003dd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e2:	e8 95 fe ff ff       	call   f010027c <cons_putc>
f01003e7:	e9 4e ff ff ff       	jmp    f010033a <cons_putc+0xbe>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003ec:	66 a1 28 75 11 f0    	mov    0xf0117528,%ax
f01003f2:	8d 50 01             	lea    0x1(%eax),%edx
f01003f5:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f01003fc:	0f b7 c0             	movzwl %ax,%eax
f01003ff:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100405:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100409:	e9 2c ff ff ff       	jmp    f010033a <cons_putc+0xbe>

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010040e:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f0100413:	83 ec 04             	sub    $0x4,%esp
f0100416:	68 00 0f 00 00       	push   $0xf00
f010041b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100421:	52                   	push   %edx
f0100422:	50                   	push   %eax
f0100423:	e8 82 2f 00 00       	call   f01033aa <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100428:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f010042e:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100434:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010043a:	83 c4 10             	add    $0x10,%esp
f010043d:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100442:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100445:	39 d0                	cmp    %edx,%eax
f0100447:	75 f4                	jne    f010043d <cons_putc+0x1c1>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100449:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100450:	50 
f0100451:	e9 f3 fe ff ff       	jmp    f0100349 <cons_putc+0xcd>

f0100456 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100456:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f010045d:	75 01                	jne    f0100460 <serial_intr+0xa>
		cons_intr(serial_proc_data);
}
f010045f:	c3                   	ret    
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100460:	55                   	push   %ebp
f0100461:	89 e5                	mov    %esp,%ebp
f0100463:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100466:	b8 0c 01 10 f0       	mov    $0xf010010c,%eax
f010046b:	e8 bb fc ff ff       	call   f010012b <cons_intr>
}
f0100470:	c9                   	leave  
f0100471:	eb ec                	jmp    f010045f <serial_intr+0x9>

f0100473 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100473:	55                   	push   %ebp
f0100474:	89 e5                	mov    %esp,%ebp
f0100476:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100479:	b8 6e 01 10 f0       	mov    $0xf010016e,%eax
f010047e:	e8 a8 fc ff ff       	call   f010012b <cons_intr>
}
f0100483:	c9                   	leave  
f0100484:	c3                   	ret    

f0100485 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100485:	55                   	push   %ebp
f0100486:	89 e5                	mov    %esp,%ebp
f0100488:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010048b:	e8 c6 ff ff ff       	call   f0100456 <serial_intr>
	kbd_intr();
f0100490:	e8 de ff ff ff       	call   f0100473 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100495:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f010049a:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004a0:	74 26                	je     f01004c8 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004a2:	8d 50 01             	lea    0x1(%eax),%edx
f01004a5:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004ab:	0f b6 80 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%eax
		if (cons.rpos == CONSBUFSIZE)
f01004b2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004b8:	74 02                	je     f01004bc <cons_getc+0x37>
			cons.rpos = 0;
		return c;
	}
	return 0;
}
f01004ba:	c9                   	leave  
f01004bb:	c3                   	ret    

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004bc:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f01004c3:	00 00 00 
f01004c6:	eb f2                	jmp    f01004ba <cons_getc+0x35>
		return c;
	}
	return 0;
f01004c8:	b8 00 00 00 00       	mov    $0x0,%eax
f01004cd:	eb eb                	jmp    f01004ba <cons_getc+0x35>

f01004cf <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004cf:	55                   	push   %ebp
f01004d0:	89 e5                	mov    %esp,%ebp
f01004d2:	56                   	push   %esi
f01004d3:	53                   	push   %ebx
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004d4:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f01004db:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01004e2:	5a a5 
	if (*cp != 0xA55A) {
f01004e4:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f01004ea:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01004ee:	0f 84 a2 00 00 00    	je     f0100596 <cons_init+0xc7>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01004f4:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f01004fb:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01004fe:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100503:	b0 0e                	mov    $0xe,%al
f0100505:	8b 15 30 75 11 f0    	mov    0xf0117530,%edx
f010050b:	ee                   	out    %al,(%dx)
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
f010050c:	8d 4a 01             	lea    0x1(%edx),%ecx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010050f:	89 ca                	mov    %ecx,%edx
f0100511:	ec                   	in     (%dx),%al
f0100512:	0f b6 c0             	movzbl %al,%eax
f0100515:	c1 e0 08             	shl    $0x8,%eax
f0100518:	89 c3                	mov    %eax,%ebx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010051a:	b0 0f                	mov    $0xf,%al
f010051c:	8b 15 30 75 11 f0    	mov    0xf0117530,%edx
f0100522:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100523:	89 ca                	mov    %ecx,%edx
f0100525:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100526:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010052c:	0f b6 c0             	movzbl %al,%eax
f010052f:	09 d8                	or     %ebx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100531:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100537:	be fa 03 00 00       	mov    $0x3fa,%esi
f010053c:	b0 00                	mov    $0x0,%al
f010053e:	89 f2                	mov    %esi,%edx
f0100540:	ee                   	out    %al,(%dx)
f0100541:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100546:	b0 80                	mov    $0x80,%al
f0100548:	ee                   	out    %al,(%dx)
f0100549:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010054e:	b0 0c                	mov    $0xc,%al
f0100550:	89 da                	mov    %ebx,%edx
f0100552:	ee                   	out    %al,(%dx)
f0100553:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100558:	b0 00                	mov    $0x0,%al
f010055a:	ee                   	out    %al,(%dx)
f010055b:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100560:	b0 03                	mov    $0x3,%al
f0100562:	ee                   	out    %al,(%dx)
f0100563:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100568:	b0 00                	mov    $0x0,%al
f010056a:	ee                   	out    %al,(%dx)
f010056b:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100570:	b0 01                	mov    $0x1,%al
f0100572:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100573:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100578:	ec                   	in     (%dx),%al
f0100579:	88 c1                	mov    %al,%cl
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010057b:	3c ff                	cmp    $0xff,%al
f010057d:	0f 95 05 34 75 11 f0 	setne  0xf0117534
f0100584:	89 f2                	mov    %esi,%edx
f0100586:	ec                   	in     (%dx),%al
f0100587:	89 da                	mov    %ebx,%edx
f0100589:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010058a:	80 f9 ff             	cmp    $0xff,%cl
f010058d:	74 22                	je     f01005b1 <cons_init+0xe2>
		cprintf("Serial port does not exist!\n");
}
f010058f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100592:	5b                   	pop    %ebx
f0100593:	5e                   	pop    %esi
f0100594:	5d                   	pop    %ebp
f0100595:	c3                   	ret    
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100596:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059d:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f01005a4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a7:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f01005ac:	e9 52 ff ff ff       	jmp    f0100503 <cons_init+0x34>
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
		cprintf("Serial port does not exist!\n");
f01005b1:	83 ec 0c             	sub    $0xc,%esp
f01005b4:	68 de 37 10 f0       	push   $0xf01037de
f01005b9:	e8 8f 22 00 00       	call   f010284d <cprintf>
f01005be:	83 c4 10             	add    $0x10,%esp
}
f01005c1:	eb cc                	jmp    f010058f <cons_init+0xc0>

f01005c3 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005c3:	55                   	push   %ebp
f01005c4:	89 e5                	mov    %esp,%ebp
f01005c6:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01005cc:	e8 ab fc ff ff       	call   f010027c <cons_putc>
}
f01005d1:	c9                   	leave  
f01005d2:	c3                   	ret    

f01005d3 <getchar>:

int
getchar(void)
{
f01005d3:	55                   	push   %ebp
f01005d4:	89 e5                	mov    %esp,%ebp
f01005d6:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01005d9:	e8 a7 fe ff ff       	call   f0100485 <cons_getc>
f01005de:	85 c0                	test   %eax,%eax
f01005e0:	74 f7                	je     f01005d9 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01005e2:	c9                   	leave  
f01005e3:	c3                   	ret    

f01005e4 <iscons>:

int
iscons(int fdnum)
{
f01005e4:	55                   	push   %ebp
f01005e5:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01005e7:	b8 01 00 00 00       	mov    $0x1,%eax
f01005ec:	5d                   	pop    %ebp
f01005ed:	c3                   	ret    
	...

f01005f0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01005f0:	55                   	push   %ebp
f01005f1:	89 e5                	mov    %esp,%ebp
f01005f3:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01005f6:	68 20 3a 10 f0       	push   $0xf0103a20
f01005fb:	68 3e 3a 10 f0       	push   $0xf0103a3e
f0100600:	68 43 3a 10 f0       	push   $0xf0103a43
f0100605:	e8 43 22 00 00       	call   f010284d <cprintf>
f010060a:	83 c4 0c             	add    $0xc,%esp
f010060d:	68 f8 3a 10 f0       	push   $0xf0103af8
f0100612:	68 4c 3a 10 f0       	push   $0xf0103a4c
f0100617:	68 43 3a 10 f0       	push   $0xf0103a43
f010061c:	e8 2c 22 00 00       	call   f010284d <cprintf>
f0100621:	83 c4 0c             	add    $0xc,%esp
f0100624:	68 20 3b 10 f0       	push   $0xf0103b20
f0100629:	68 55 3a 10 f0       	push   $0xf0103a55
f010062e:	68 43 3a 10 f0       	push   $0xf0103a43
f0100633:	e8 15 22 00 00       	call   f010284d <cprintf>
	return 0;
}
f0100638:	b8 00 00 00 00       	mov    $0x0,%eax
f010063d:	c9                   	leave  
f010063e:	c3                   	ret    

f010063f <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010063f:	55                   	push   %ebp
f0100640:	89 e5                	mov    %esp,%ebp
f0100642:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100645:	68 5f 3a 10 f0       	push   $0xf0103a5f
f010064a:	e8 fe 21 00 00       	call   f010284d <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010064f:	83 c4 08             	add    $0x8,%esp
f0100652:	68 0c 00 10 00       	push   $0x10000c
f0100657:	68 40 3b 10 f0       	push   $0xf0103b40
f010065c:	e8 ec 21 00 00       	call   f010284d <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100661:	83 c4 0c             	add    $0xc,%esp
f0100664:	68 0c 00 10 00       	push   $0x10000c
f0100669:	68 0c 00 10 f0       	push   $0xf010000c
f010066e:	68 68 3b 10 f0       	push   $0xf0103b68
f0100673:	e8 d5 21 00 00       	call   f010284d <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100678:	83 c4 0c             	add    $0xc,%esp
f010067b:	68 8c 37 10 00       	push   $0x10378c
f0100680:	68 8c 37 10 f0       	push   $0xf010378c
f0100685:	68 8c 3b 10 f0       	push   $0xf0103b8c
f010068a:	e8 be 21 00 00       	call   f010284d <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010068f:	83 c4 0c             	add    $0xc,%esp
f0100692:	68 00 73 11 00       	push   $0x117300
f0100697:	68 00 73 11 f0       	push   $0xf0117300
f010069c:	68 b0 3b 10 f0       	push   $0xf0103bb0
f01006a1:	e8 a7 21 00 00       	call   f010284d <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006a6:	83 c4 0c             	add    $0xc,%esp
f01006a9:	68 50 79 11 00       	push   $0x117950
f01006ae:	68 50 79 11 f0       	push   $0xf0117950
f01006b3:	68 d4 3b 10 f0       	push   $0xf0103bd4
f01006b8:	e8 90 21 00 00       	call   f010284d <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006bd:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01006c0:	b8 4f 7d 11 f0       	mov    $0xf0117d4f,%eax
f01006c5:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006ca:	c1 f8 0a             	sar    $0xa,%eax
f01006cd:	50                   	push   %eax
f01006ce:	68 f8 3b 10 f0       	push   $0xf0103bf8
f01006d3:	e8 75 21 00 00       	call   f010284d <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01006dd:	c9                   	leave  
f01006de:	c3                   	ret    

f01006df <mon_backtrace>:

int mon_backtrace(int argc, char **argv, struct Trapframe *tf) {
f01006df:	55                   	push   %ebp
f01006e0:	89 e5                	mov    %esp,%ebp
f01006e2:	57                   	push   %edi
f01006e3:	56                   	push   %esi
f01006e4:	53                   	push   %ebx
f01006e5:	83 ec 48             	sub    $0x48,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01006e8:	89 e8                	mov    %ebp,%eax
	int i;
	uint32_t *ebp = (uint32_t *)read_ebp();
f01006ea:	89 c6                	mov    %eax,%esi
	uint32_t eip = ebp[1];
f01006ec:	8b 78 04             	mov    0x4(%eax),%edi
	struct Eipdebuginfo eip_info;
	cprintf("Stack backtrace:\n");
f01006ef:	68 78 3a 10 f0       	push   $0xf0103a78
f01006f4:	e8 54 21 00 00       	call   f010284d <cprintf>
	while(ebp) {
f01006f9:	83 c4 10             	add    $0x10,%esp
f01006fc:	eb 74                	jmp    f0100772 <mon_backtrace+0x93>
		cprintf("ebp %08x eip %08x args ",ebp,eip);
f01006fe:	83 ec 04             	sub    $0x4,%esp
f0100701:	57                   	push   %edi
f0100702:	56                   	push   %esi
f0100703:	68 8a 3a 10 f0       	push   $0xf0103a8a
f0100708:	e8 40 21 00 00       	call   f010284d <cprintf>
f010070d:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100710:	8d 46 1c             	lea    0x1c(%esi),%eax
f0100713:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100716:	83 c4 10             	add    $0x10,%esp
		for (i = 2; i < 7;i++) {
			cprintf("%08x ",ebp[i]);
f0100719:	83 ec 08             	sub    $0x8,%esp
f010071c:	ff 33                	pushl  (%ebx)
f010071e:	68 a2 3a 10 f0       	push   $0xf0103aa2
f0100723:	e8 25 21 00 00       	call   f010284d <cprintf>
f0100728:	83 c3 04             	add    $0x4,%ebx
	uint32_t eip = ebp[1];
	struct Eipdebuginfo eip_info;
	cprintf("Stack backtrace:\n");
	while(ebp) {
		cprintf("ebp %08x eip %08x args ",ebp,eip);
		for (i = 2; i < 7;i++) {
f010072b:	83 c4 10             	add    $0x10,%esp
f010072e:	3b 5d c4             	cmp    -0x3c(%ebp),%ebx
f0100731:	75 e6                	jne    f0100719 <mon_backtrace+0x3a>
			cprintf("%08x ",ebp[i]);
		}
		cprintf("\n");
f0100733:	83 ec 0c             	sub    $0xc,%esp
f0100736:	68 55 47 10 f0       	push   $0xf0104755
f010073b:	e8 0d 21 00 00       	call   f010284d <cprintf>
		debuginfo_eip(eip, &eip_info);
f0100740:	83 c4 08             	add    $0x8,%esp
f0100743:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100746:	50                   	push   %eax
f0100747:	57                   	push   %edi
f0100748:	e8 04 22 00 00       	call   f0102951 <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",eip_info.eip_file,eip_info.eip_line,eip_info.eip_fn_namelen,eip_info.eip_fn_name,eip-eip_info.eip_fn_addr);
f010074d:	83 c4 08             	add    $0x8,%esp
f0100750:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100753:	57                   	push   %edi
f0100754:	ff 75 d8             	pushl  -0x28(%ebp)
f0100757:	ff 75 dc             	pushl  -0x24(%ebp)
f010075a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010075d:	ff 75 d0             	pushl  -0x30(%ebp)
f0100760:	68 a8 3a 10 f0       	push   $0xf0103aa8
f0100765:	e8 e3 20 00 00       	call   f010284d <cprintf>
		ebp = (uint32_t *)(ebp[0]);
f010076a:	8b 36                	mov    (%esi),%esi
		eip = ebp[1];
f010076c:	8b 7e 04             	mov    0x4(%esi),%edi
f010076f:	83 c4 20             	add    $0x20,%esp
	int i;
	uint32_t *ebp = (uint32_t *)read_ebp();
	uint32_t eip = ebp[1];
	struct Eipdebuginfo eip_info;
	cprintf("Stack backtrace:\n");
	while(ebp) {
f0100772:	85 f6                	test   %esi,%esi
f0100774:	75 88                	jne    f01006fe <mon_backtrace+0x1f>
		cprintf("\t%s:%d: %.*s+%d\n",eip_info.eip_file,eip_info.eip_line,eip_info.eip_fn_namelen,eip_info.eip_fn_name,eip-eip_info.eip_fn_addr);
		ebp = (uint32_t *)(ebp[0]);
		eip = ebp[1];
	}
	return 0;
}
f0100776:	b8 00 00 00 00       	mov    $0x0,%eax
f010077b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010077e:	5b                   	pop    %ebx
f010077f:	5e                   	pop    %esi
f0100780:	5f                   	pop    %edi
f0100781:	5d                   	pop    %ebp
f0100782:	c3                   	ret    

f0100783 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100783:	55                   	push   %ebp
f0100784:	89 e5                	mov    %esp,%ebp
f0100786:	57                   	push   %edi
f0100787:	56                   	push   %esi
f0100788:	53                   	push   %ebx
f0100789:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010078c:	68 24 3c 10 f0       	push   $0xf0103c24
f0100791:	e8 b7 20 00 00       	call   f010284d <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100796:	c7 04 24 48 3c 10 f0 	movl   $0xf0103c48,(%esp)
f010079d:	e8 ab 20 00 00       	call   f010284d <cprintf>
f01007a2:	83 c4 10             	add    $0x10,%esp
f01007a5:	eb 47                	jmp    f01007ee <monitor+0x6b>
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007a7:	83 ec 08             	sub    $0x8,%esp
f01007aa:	0f be c0             	movsbl %al,%eax
f01007ad:	50                   	push   %eax
f01007ae:	68 bd 3a 10 f0       	push   $0xf0103abd
f01007b3:	e8 70 2b 00 00       	call   f0103328 <strchr>
f01007b8:	83 c4 10             	add    $0x10,%esp
f01007bb:	85 c0                	test   %eax,%eax
f01007bd:	74 0a                	je     f01007c9 <monitor+0x46>
			*buf++ = 0;
f01007bf:	c6 03 00             	movb   $0x0,(%ebx)
f01007c2:	89 f7                	mov    %esi,%edi
f01007c4:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007c7:	eb 68                	jmp    f0100831 <monitor+0xae>
		if (*buf == 0)
f01007c9:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007cc:	74 6f                	je     f010083d <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007ce:	83 fe 0f             	cmp    $0xf,%esi
f01007d1:	74 09                	je     f01007dc <monitor+0x59>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
f01007d3:	8d 7e 01             	lea    0x1(%esi),%edi
f01007d6:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007da:	eb 37                	jmp    f0100813 <monitor+0x90>
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007dc:	83 ec 08             	sub    $0x8,%esp
f01007df:	6a 10                	push   $0x10
f01007e1:	68 c2 3a 10 f0       	push   $0xf0103ac2
f01007e6:	e8 62 20 00 00       	call   f010284d <cprintf>
f01007eb:	83 c4 10             	add    $0x10,%esp
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f01007ee:	83 ec 0c             	sub    $0xc,%esp
f01007f1:	68 b9 3a 10 f0       	push   $0xf0103ab9
f01007f6:	e8 21 29 00 00       	call   f010311c <readline>
f01007fb:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007fd:	83 c4 10             	add    $0x10,%esp
f0100800:	85 c0                	test   %eax,%eax
f0100802:	74 ea                	je     f01007ee <monitor+0x6b>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100804:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010080b:	be 00 00 00 00       	mov    $0x0,%esi
f0100810:	eb 21                	jmp    f0100833 <monitor+0xb0>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100812:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100813:	8a 03                	mov    (%ebx),%al
f0100815:	84 c0                	test   %al,%al
f0100817:	74 18                	je     f0100831 <monitor+0xae>
f0100819:	83 ec 08             	sub    $0x8,%esp
f010081c:	0f be c0             	movsbl %al,%eax
f010081f:	50                   	push   %eax
f0100820:	68 bd 3a 10 f0       	push   $0xf0103abd
f0100825:	e8 fe 2a 00 00       	call   f0103328 <strchr>
f010082a:	83 c4 10             	add    $0x10,%esp
f010082d:	85 c0                	test   %eax,%eax
f010082f:	74 e1                	je     f0100812 <monitor+0x8f>
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100831:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100833:	8a 03                	mov    (%ebx),%al
f0100835:	84 c0                	test   %al,%al
f0100837:	0f 85 6a ff ff ff    	jne    f01007a7 <monitor+0x24>
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;
f010083d:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100844:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100845:	85 f6                	test   %esi,%esi
f0100847:	74 a5                	je     f01007ee <monitor+0x6b>
f0100849:	bf 80 3c 10 f0       	mov    $0xf0103c80,%edi
f010084e:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100853:	83 ec 08             	sub    $0x8,%esp
f0100856:	ff 37                	pushl  (%edi)
f0100858:	ff 75 a8             	pushl  -0x58(%ebp)
f010085b:	e8 74 2a 00 00       	call   f01032d4 <strcmp>
f0100860:	83 c4 10             	add    $0x10,%esp
f0100863:	85 c0                	test   %eax,%eax
f0100865:	74 21                	je     f0100888 <monitor+0x105>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100867:	43                   	inc    %ebx
f0100868:	83 c7 0c             	add    $0xc,%edi
f010086b:	83 fb 03             	cmp    $0x3,%ebx
f010086e:	75 e3                	jne    f0100853 <monitor+0xd0>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100870:	83 ec 08             	sub    $0x8,%esp
f0100873:	ff 75 a8             	pushl  -0x58(%ebp)
f0100876:	68 df 3a 10 f0       	push   $0xf0103adf
f010087b:	e8 cd 1f 00 00       	call   f010284d <cprintf>
f0100880:	83 c4 10             	add    $0x10,%esp
f0100883:	e9 66 ff ff ff       	jmp    f01007ee <monitor+0x6b>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f0100888:	83 ec 04             	sub    $0x4,%esp
f010088b:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
f010088e:	01 c3                	add    %eax,%ebx
f0100890:	ff 75 08             	pushl  0x8(%ebp)
f0100893:	8d 45 a8             	lea    -0x58(%ebp),%eax
f0100896:	50                   	push   %eax
f0100897:	56                   	push   %esi
f0100898:	ff 14 9d 88 3c 10 f0 	call   *-0xfefc378(,%ebx,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010089f:	83 c4 10             	add    $0x10,%esp
f01008a2:	85 c0                	test   %eax,%eax
f01008a4:	0f 89 44 ff ff ff    	jns    f01007ee <monitor+0x6b>
				break;
	}
}
f01008aa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ad:	5b                   	pop    %ebx
f01008ae:	5e                   	pop    %esi
f01008af:	5f                   	pop    %edi
f01008b0:	5d                   	pop    %ebp
f01008b1:	c3                   	ret    
	...

f01008b4 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01008b4:	55                   	push   %ebp
f01008b5:	89 e5                	mov    %esp,%ebp
f01008b7:	56                   	push   %esi
f01008b8:	53                   	push   %ebx
f01008b9:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01008bb:	83 ec 0c             	sub    $0xc,%esp
f01008be:	50                   	push   %eax
f01008bf:	e8 20 1f 00 00       	call   f01027e4 <mc146818_read>
f01008c4:	89 c3                	mov    %eax,%ebx
f01008c6:	46                   	inc    %esi
f01008c7:	89 34 24             	mov    %esi,(%esp)
f01008ca:	e8 15 1f 00 00       	call   f01027e4 <mc146818_read>
f01008cf:	c1 e0 08             	shl    $0x8,%eax
f01008d2:	09 d8                	or     %ebx,%eax
}
f01008d4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01008d7:	5b                   	pop    %ebx
f01008d8:	5e                   	pop    %esi
f01008d9:	5d                   	pop    %ebp
f01008da:	c3                   	ret    

f01008db <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008db:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f01008e2:	74 33                	je     f0100917 <boot_alloc+0x3c>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
	}
	//cprintf("boot_alloc -> next free location: %x\n",nextfree);

	if(n!=0) {
f01008e4:	85 c0                	test   %eax,%eax
f01008e6:	74 5c                	je     f0100944 <boot_alloc+0x69>
		char *result = nextfree;
f01008e8:	8b 0d 38 75 11 f0    	mov    0xf0117538,%ecx
		nextfree = ROUNDUP((char *)(nextfree + n),PGSIZE);
f01008ee:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f01008f5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008fb:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
		if ((uint32_t)nextfree - KERNBASE > npages*PGSIZE){
f0100901:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0100907:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f010090c:	c1 e0 0c             	shl    $0xc,%eax
f010090f:	39 c2                	cmp    %eax,%edx
f0100911:	77 17                	ja     f010092a <boot_alloc+0x4f>
			panic("Ran out of memory in boot_alloc, requested size %d bytes, available %d bytes, free location at: %x\n"\
					,(uint32_t)nextfree - KERNBASE ,npages*PGSIZE,result);
		}
		return result;
f0100913:	89 c8                	mov    %ecx,%eax
f0100915:	eb 32                	jmp    f0100949 <boot_alloc+0x6e>
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100917:	ba 4f 89 11 f0       	mov    $0xf011894f,%edx
f010091c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100922:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
f0100928:	eb ba                	jmp    f01008e4 <boot_alloc+0x9>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f010092a:	55                   	push   %ebp
f010092b:	89 e5                	mov    %esp,%ebp
f010092d:	83 ec 10             	sub    $0x10,%esp

	if(n!=0) {
		char *result = nextfree;
		nextfree = ROUNDUP((char *)(nextfree + n),PGSIZE);
		if ((uint32_t)nextfree - KERNBASE > npages*PGSIZE){
			panic("Ran out of memory in boot_alloc, requested size %d bytes, available %d bytes, free location at: %x\n"\
f0100930:	51                   	push   %ecx
f0100931:	50                   	push   %eax
f0100932:	52                   	push   %edx
f0100933:	68 a4 3c 10 f0       	push   $0xf0103ca4
f0100938:	6a 6a                	push   $0x6a
f010093a:	68 a4 44 10 f0       	push   $0xf01044a4
f010093f:	e8 35 f7 ff ff       	call   f0100079 <_panic>
					,(uint32_t)nextfree - KERNBASE ,npages*PGSIZE,result);
		}
		return result;
	} else {
		return nextfree;
f0100944:	a1 38 75 11 f0       	mov    0xf0117538,%eax
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	cprintf("boot_alloc: Somthings not right -> returning empty");
	return NULL;
}
f0100949:	c3                   	ret    

f010094a <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f010094a:	89 d1                	mov    %edx,%ecx
f010094c:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f010094f:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100952:	a8 01                	test   $0x1,%al
f0100954:	75 06                	jne    f010095c <check_va2pa+0x12>
		return ~0;
f0100956:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f010095b:	c3                   	ret    
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010095c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100961:	89 c1                	mov    %eax,%ecx
f0100963:	c1 e9 0c             	shr    $0xc,%ecx
f0100966:	3b 0d 44 79 11 f0    	cmp    0xf0117944,%ecx
f010096c:	73 1b                	jae    f0100989 <check_va2pa+0x3f>
	if (!(p[PTX(va)] & PTE_P))
f010096e:	c1 ea 0c             	shr    $0xc,%edx
f0100971:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100977:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f010097e:	a8 01                	test   $0x1,%al
f0100980:	75 22                	jne    f01009a4 <check_va2pa+0x5a>
		return ~0;
f0100982:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100987:	eb d2                	jmp    f010095b <check_va2pa+0x11>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100989:	55                   	push   %ebp
f010098a:	89 e5                	mov    %esp,%ebp
f010098c:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010098f:	50                   	push   %eax
f0100990:	68 08 3d 10 f0       	push   $0xf0103d08
f0100995:	68 d3 02 00 00       	push   $0x2d3
f010099a:	68 a4 44 10 f0       	push   $0xf01044a4
f010099f:	e8 d5 f6 ff ff       	call   f0100079 <_panic>
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009a4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009a9:	eb b0                	jmp    f010095b <check_va2pa+0x11>

f01009ab <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009ab:	55                   	push   %ebp
f01009ac:	89 e5                	mov    %esp,%ebp
f01009ae:	57                   	push   %edi
f01009af:	56                   	push   %esi
f01009b0:	53                   	push   %ebx
f01009b1:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009b4:	84 c0                	test   %al,%al
f01009b6:	0f 85 43 02 00 00    	jne    f0100bff <check_page_free_list+0x254>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f01009bc:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f01009c3:	74 0a                	je     f01009cf <check_page_free_list+0x24>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009c5:	be 00 04 00 00       	mov    $0x400,%esi
f01009ca:	e9 8b 02 00 00       	jmp    f0100c5a <check_page_free_list+0x2af>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009cf:	83 ec 04             	sub    $0x4,%esp
f01009d2:	68 2c 3d 10 f0       	push   $0xf0103d2c
f01009d7:	68 16 02 00 00       	push   $0x216
f01009dc:	68 a4 44 10 f0       	push   $0xf01044a4
f01009e1:	e8 93 f6 ff ff       	call   f0100079 <_panic>
f01009e6:	50                   	push   %eax
f01009e7:	68 08 3d 10 f0       	push   $0xf0103d08
f01009ec:	6a 52                	push   $0x52
f01009ee:	68 b0 44 10 f0       	push   $0xf01044b0
f01009f3:	e8 81 f6 ff ff       	call   f0100079 <_panic>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009f8:	8b 1b                	mov    (%ebx),%ebx
f01009fa:	85 db                	test   %ebx,%ebx
f01009fc:	74 41                	je     f0100a3f <check_page_free_list+0x94>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009fe:	89 d8                	mov    %ebx,%eax
f0100a00:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0100a06:	c1 f8 03             	sar    $0x3,%eax
f0100a09:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a0c:	89 c2                	mov    %eax,%edx
f0100a0e:	c1 ea 16             	shr    $0x16,%edx
f0100a11:	39 f2                	cmp    %esi,%edx
f0100a13:	73 e3                	jae    f01009f8 <check_page_free_list+0x4d>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a15:	89 c2                	mov    %eax,%edx
f0100a17:	c1 ea 0c             	shr    $0xc,%edx
f0100a1a:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100a20:	73 c4                	jae    f01009e6 <check_page_free_list+0x3b>
			memset(page2kva(pp), 0x97, 128);
f0100a22:	83 ec 04             	sub    $0x4,%esp
f0100a25:	68 80 00 00 00       	push   $0x80
f0100a2a:	68 97 00 00 00       	push   $0x97
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0100a2f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a34:	50                   	push   %eax
f0100a35:	e8 23 29 00 00       	call   f010335d <memset>
f0100a3a:	83 c4 10             	add    $0x10,%esp
f0100a3d:	eb b9                	jmp    f01009f8 <check_page_free_list+0x4d>

	first_free_page = (char *) boot_alloc(0);
f0100a3f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a44:	e8 92 fe ff ff       	call   f01008db <boot_alloc>
f0100a49:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a4c:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a52:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
		assert(pp < pages + npages);
f0100a58:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0100a5d:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a60:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a63:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a66:	be 00 00 00 00       	mov    $0x0,%esi
f0100a6b:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a6e:	e9 c8 00 00 00       	jmp    f0100b3b <check_page_free_list+0x190>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a73:	68 be 44 10 f0       	push   $0xf01044be
f0100a78:	68 ca 44 10 f0       	push   $0xf01044ca
f0100a7d:	68 30 02 00 00       	push   $0x230
f0100a82:	68 a4 44 10 f0       	push   $0xf01044a4
f0100a87:	e8 ed f5 ff ff       	call   f0100079 <_panic>
		assert(pp < pages + npages);
f0100a8c:	68 df 44 10 f0       	push   $0xf01044df
f0100a91:	68 ca 44 10 f0       	push   $0xf01044ca
f0100a96:	68 31 02 00 00       	push   $0x231
f0100a9b:	68 a4 44 10 f0       	push   $0xf01044a4
f0100aa0:	e8 d4 f5 ff ff       	call   f0100079 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aa5:	68 50 3d 10 f0       	push   $0xf0103d50
f0100aaa:	68 ca 44 10 f0       	push   $0xf01044ca
f0100aaf:	68 32 02 00 00       	push   $0x232
f0100ab4:	68 a4 44 10 f0       	push   $0xf01044a4
f0100ab9:	e8 bb f5 ff ff       	call   f0100079 <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100abe:	68 f3 44 10 f0       	push   $0xf01044f3
f0100ac3:	68 ca 44 10 f0       	push   $0xf01044ca
f0100ac8:	68 35 02 00 00       	push   $0x235
f0100acd:	68 a4 44 10 f0       	push   $0xf01044a4
f0100ad2:	e8 a2 f5 ff ff       	call   f0100079 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ad7:	68 04 45 10 f0       	push   $0xf0104504
f0100adc:	68 ca 44 10 f0       	push   $0xf01044ca
f0100ae1:	68 36 02 00 00       	push   $0x236
f0100ae6:	68 a4 44 10 f0       	push   $0xf01044a4
f0100aeb:	e8 89 f5 ff ff       	call   f0100079 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100af0:	68 84 3d 10 f0       	push   $0xf0103d84
f0100af5:	68 ca 44 10 f0       	push   $0xf01044ca
f0100afa:	68 37 02 00 00       	push   $0x237
f0100aff:	68 a4 44 10 f0       	push   $0xf01044a4
f0100b04:	e8 70 f5 ff ff       	call   f0100079 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b09:	68 1d 45 10 f0       	push   $0xf010451d
f0100b0e:	68 ca 44 10 f0       	push   $0xf01044ca
f0100b13:	68 38 02 00 00       	push   $0x238
f0100b18:	68 a4 44 10 f0       	push   $0xf01044a4
f0100b1d:	e8 57 f5 ff ff       	call   f0100079 <_panic>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b22:	89 c3                	mov    %eax,%ebx
f0100b24:	c1 eb 0c             	shr    $0xc,%ebx
f0100b27:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b2a:	76 63                	jbe    f0100b8f <check_page_free_list+0x1e4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0100b2c:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b31:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b34:	77 6b                	ja     f0100ba1 <check_page_free_list+0x1f6>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
		else
			++nfree_extmem;
f0100b36:	ff 45 d0             	incl   -0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b39:	8b 12                	mov    (%edx),%edx
f0100b3b:	85 d2                	test   %edx,%edx
f0100b3d:	74 7b                	je     f0100bba <check_page_free_list+0x20f>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b3f:	39 ca                	cmp    %ecx,%edx
f0100b41:	0f 82 2c ff ff ff    	jb     f0100a73 <check_page_free_list+0xc8>
		assert(pp < pages + npages);
f0100b47:	39 fa                	cmp    %edi,%edx
f0100b49:	0f 83 3d ff ff ff    	jae    f0100a8c <check_page_free_list+0xe1>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b4f:	89 d0                	mov    %edx,%eax
f0100b51:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b54:	a8 07                	test   $0x7,%al
f0100b56:	0f 85 49 ff ff ff    	jne    f0100aa5 <check_page_free_list+0xfa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b5c:	c1 f8 03             	sar    $0x3,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b5f:	c1 e0 0c             	shl    $0xc,%eax
f0100b62:	0f 84 56 ff ff ff    	je     f0100abe <check_page_free_list+0x113>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b68:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b6d:	0f 84 64 ff ff ff    	je     f0100ad7 <check_page_free_list+0x12c>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b73:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b78:	0f 84 72 ff ff ff    	je     f0100af0 <check_page_free_list+0x145>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b7e:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b83:	74 84                	je     f0100b09 <check_page_free_list+0x15e>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b85:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b8a:	77 96                	ja     f0100b22 <check_page_free_list+0x177>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100b8c:	46                   	inc    %esi
f0100b8d:	eb aa                	jmp    f0100b39 <check_page_free_list+0x18e>

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b8f:	50                   	push   %eax
f0100b90:	68 08 3d 10 f0       	push   $0xf0103d08
f0100b95:	6a 52                	push   $0x52
f0100b97:	68 b0 44 10 f0       	push   $0xf01044b0
f0100b9c:	e8 d8 f4 ff ff       	call   f0100079 <_panic>
		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100ba1:	68 a8 3d 10 f0       	push   $0xf0103da8
f0100ba6:	68 ca 44 10 f0       	push   $0xf01044ca
f0100bab:	68 39 02 00 00       	push   $0x239
f0100bb0:	68 a4 44 10 f0       	push   $0xf01044a4
f0100bb5:	e8 bf f4 ff ff       	call   f0100079 <_panic>
f0100bba:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100bbd:	85 f6                	test   %esi,%esi
f0100bbf:	7e 0c                	jle    f0100bcd <check_page_free_list+0x222>
	assert(nfree_extmem > 0);
f0100bc1:	85 db                	test   %ebx,%ebx
f0100bc3:	7e 21                	jle    f0100be6 <check_page_free_list+0x23b>
}
f0100bc5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100bc8:	5b                   	pop    %ebx
f0100bc9:	5e                   	pop    %esi
f0100bca:	5f                   	pop    %edi
f0100bcb:	5d                   	pop    %ebp
f0100bcc:	c3                   	ret    
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100bcd:	68 37 45 10 f0       	push   $0xf0104537
f0100bd2:	68 ca 44 10 f0       	push   $0xf01044ca
f0100bd7:	68 41 02 00 00       	push   $0x241
f0100bdc:	68 a4 44 10 f0       	push   $0xf01044a4
f0100be1:	e8 93 f4 ff ff       	call   f0100079 <_panic>
	assert(nfree_extmem > 0);
f0100be6:	68 49 45 10 f0       	push   $0xf0104549
f0100beb:	68 ca 44 10 f0       	push   $0xf01044ca
f0100bf0:	68 42 02 00 00       	push   $0x242
f0100bf5:	68 a4 44 10 f0       	push   $0xf01044a4
f0100bfa:	e8 7a f4 ff ff       	call   f0100079 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100bff:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100c04:	85 c0                	test   %eax,%eax
f0100c06:	0f 84 c3 fd ff ff    	je     f01009cf <check_page_free_list+0x24>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100c0c:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100c0f:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c12:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c15:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c18:	89 c2                	mov    %eax,%edx
f0100c1a:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100c20:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100c26:	0f 95 c2             	setne  %dl
f0100c29:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100c2c:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100c30:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c32:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c36:	8b 00                	mov    (%eax),%eax
f0100c38:	85 c0                	test   %eax,%eax
f0100c3a:	75 dc                	jne    f0100c18 <check_page_free_list+0x26d>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100c3c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c3f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c45:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c48:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c4b:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100c4d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c50:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c55:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c5a:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100c60:	e9 95 fd ff ff       	jmp    f01009fa <check_page_free_list+0x4f>

f0100c65 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c65:	55                   	push   %ebp
f0100c66:	89 e5                	mov    %esp,%ebp
f0100c68:	57                   	push   %edi
f0100c69:	56                   	push   %esi
f0100c6a:	53                   	push   %ebx
f0100c6b:	83 ec 1c             	sub    $0x1c,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	int init_allocated_mem = (int)(boot_alloc(0) - KERNBASE)/PGSIZE;
f0100c6e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c73:	e8 63 fc ff ff       	call   f01008db <boot_alloc>
f0100c78:	05 00 00 00 10       	add    $0x10000000,%eax
f0100c7d:	89 c2                	mov    %eax,%edx
f0100c7f:	85 c0                	test   %eax,%eax
f0100c81:	78 21                	js     f0100ca4 <page_init+0x3f>
f0100c83:	89 d6                	mov    %edx,%esi
f0100c85:	c1 fe 0c             	sar    $0xc,%esi
f0100c88:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
//	int io_hole = IOPHYSMEM/KERNBASE = 96;
	for (i = 0; i < npages; i++) {
f0100c8e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c93:	b1 00                	mov    $0x0,%cl
f0100c95:	b8 00 00 00 00       	mov    $0x0,%eax
		} else if ((i >= 96) && (i <= init_allocated_mem)) {
			pages[i].pp_ref = 1;
		} else {
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
f0100c9a:	bf 01 00 00 00       	mov    $0x1,%edi
f0100c9f:	89 75 e4             	mov    %esi,-0x1c(%ebp)
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	int init_allocated_mem = (int)(boot_alloc(0) - KERNBASE)/PGSIZE;
//	int io_hole = IOPHYSMEM/KERNBASE = 96;
	for (i = 0; i < npages; i++) {
f0100ca2:	eb 3f                	jmp    f0100ce3 <page_init+0x7e>
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	int init_allocated_mem = (int)(boot_alloc(0) - KERNBASE)/PGSIZE;
f0100ca4:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100caa:	eb d7                	jmp    f0100c83 <page_init+0x1e>
//	int io_hole = IOPHYSMEM/KERNBASE = 96;
	for (i = 0; i < npages; i++) {
		if(i == 0){
			pages[i].pp_ref = 1;
		} else if ((i >= 96) && (i <= init_allocated_mem)) {
f0100cac:	83 f8 5f             	cmp    $0x5f,%eax
f0100caf:	76 14                	jbe    f0100cc5 <page_init+0x60>
f0100cb1:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
f0100cb4:	77 0f                	ja     f0100cc5 <page_init+0x60>
			pages[i].pp_ref = 1;
f0100cb6:	8b 35 4c 79 11 f0    	mov    0xf011794c,%esi
f0100cbc:	66 c7 44 16 04 01 00 	movw   $0x1,0x4(%esi,%edx,1)
f0100cc3:	eb 1a                	jmp    f0100cdf <page_init+0x7a>
		} else {
			pages[i].pp_ref = 0;
f0100cc5:	89 d1                	mov    %edx,%ecx
f0100cc7:	03 0d 4c 79 11 f0    	add    0xf011794c,%ecx
f0100ccd:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
			pages[i].pp_link = page_free_list;
f0100cd3:	89 19                	mov    %ebx,(%ecx)
			page_free_list = &pages[i];
f0100cd5:	89 d3                	mov    %edx,%ebx
f0100cd7:	03 1d 4c 79 11 f0    	add    0xf011794c,%ebx
f0100cdd:	89 f9                	mov    %edi,%ecx
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	int init_allocated_mem = (int)(boot_alloc(0) - KERNBASE)/PGSIZE;
//	int io_hole = IOPHYSMEM/KERNBASE = 96;
	for (i = 0; i < npages; i++) {
f0100cdf:	40                   	inc    %eax
f0100ce0:	83 c2 08             	add    $0x8,%edx
f0100ce3:	3b 05 44 79 11 f0    	cmp    0xf0117944,%eax
f0100ce9:	73 12                	jae    f0100cfd <page_init+0x98>
		if(i == 0){
f0100ceb:	85 c0                	test   %eax,%eax
f0100ced:	75 bd                	jne    f0100cac <page_init+0x47>
			pages[i].pp_ref = 1;
f0100cef:	8b 35 4c 79 11 f0    	mov    0xf011794c,%esi
f0100cf5:	66 c7 46 04 01 00    	movw   $0x1,0x4(%esi)
f0100cfb:	eb e2                	jmp    f0100cdf <page_init+0x7a>
f0100cfd:	84 c9                	test   %cl,%cl
f0100cff:	75 08                	jne    f0100d09 <page_init+0xa4>
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100d01:	83 c4 1c             	add    $0x1c,%esp
f0100d04:	5b                   	pop    %ebx
f0100d05:	5e                   	pop    %esi
f0100d06:	5f                   	pop    %edi
f0100d07:	5d                   	pop    %ebp
f0100d08:	c3                   	ret    
f0100d09:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c
f0100d0f:	eb f0                	jmp    f0100d01 <page_init+0x9c>

f0100d11 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d11:	55                   	push   %ebp
f0100d12:	89 e5                	mov    %esp,%ebp
f0100d14:	53                   	push   %ebx
f0100d15:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if(page_free_list){
f0100d18:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100d1e:	85 db                	test   %ebx,%ebx
f0100d20:	74 13                	je     f0100d35 <page_alloc+0x24>
		struct PageInfo *ret = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100d22:	8b 03                	mov    (%ebx),%eax
f0100d24:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
		ret->pp_link = NULL;
f0100d29:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if (alloc_flags & ALLOC_ZERO) {
f0100d2f:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d33:	75 07                	jne    f0100d3c <page_alloc+0x2b>
			memset(page2kva(ret),0,PGSIZE);
		}
		return ret;
	}
	return 0;
}
f0100d35:	89 d8                	mov    %ebx,%eax
f0100d37:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d3a:	c9                   	leave  
f0100d3b:	c3                   	ret    
f0100d3c:	89 d8                	mov    %ebx,%eax
f0100d3e:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0100d44:	c1 f8 03             	sar    $0x3,%eax
f0100d47:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d4a:	89 c2                	mov    %eax,%edx
f0100d4c:	c1 ea 0c             	shr    $0xc,%edx
f0100d4f:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100d55:	73 1a                	jae    f0100d71 <page_alloc+0x60>
	if(page_free_list){
		struct PageInfo *ret = page_free_list;
		page_free_list = page_free_list->pp_link;
		ret->pp_link = NULL;
		if (alloc_flags & ALLOC_ZERO) {
			memset(page2kva(ret),0,PGSIZE);
f0100d57:	83 ec 04             	sub    $0x4,%esp
f0100d5a:	68 00 10 00 00       	push   $0x1000
f0100d5f:	6a 00                	push   $0x0
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0100d61:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d66:	50                   	push   %eax
f0100d67:	e8 f1 25 00 00       	call   f010335d <memset>
f0100d6c:	83 c4 10             	add    $0x10,%esp
f0100d6f:	eb c4                	jmp    f0100d35 <page_alloc+0x24>

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d71:	50                   	push   %eax
f0100d72:	68 08 3d 10 f0       	push   $0xf0103d08
f0100d77:	6a 52                	push   $0x52
f0100d79:	68 b0 44 10 f0       	push   $0xf01044b0
f0100d7e:	e8 f6 f2 ff ff       	call   f0100079 <_panic>

f0100d83 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100d83:	55                   	push   %ebp
f0100d84:	89 e5                	mov    %esp,%ebp
f0100d86:	83 ec 08             	sub    $0x8,%esp
f0100d89:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref !=0) {
f0100d8c:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100d91:	75 13                	jne    f0100da6 <page_free+0x23>
		panic("Page is use is being asked to free");
	} else if (pp != NULL) {
f0100d93:	85 c0                	test   %eax,%eax
f0100d95:	74 0d                	je     f0100da4 <page_free+0x21>
		pp->pp_link = page_free_list;
f0100d97:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100d9d:	89 10                	mov    %edx,(%eax)
		page_free_list = pp;
f0100d9f:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	}
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f0100da4:	c9                   	leave  
f0100da5:	c3                   	ret    
//
void
page_free(struct PageInfo *pp)
{
	if (pp->pp_ref !=0) {
		panic("Page is use is being asked to free");
f0100da6:	83 ec 04             	sub    $0x4,%esp
f0100da9:	68 f0 3d 10 f0       	push   $0xf0103df0
f0100dae:	68 41 01 00 00       	push   $0x141
f0100db3:	68 a4 44 10 f0       	push   $0xf01044a4
f0100db8:	e8 bc f2 ff ff       	call   f0100079 <_panic>

f0100dbd <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100dbd:	55                   	push   %ebp
f0100dbe:	89 e5                	mov    %esp,%ebp
f0100dc0:	83 ec 08             	sub    $0x8,%esp
f0100dc3:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100dc6:	8b 42 04             	mov    0x4(%edx),%eax
f0100dc9:	48                   	dec    %eax
f0100dca:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100dce:	66 85 c0             	test   %ax,%ax
f0100dd1:	74 02                	je     f0100dd5 <page_decref+0x18>
		page_free(pp);
}
f0100dd3:	c9                   	leave  
f0100dd4:	c3                   	ret    
//
void
page_decref(struct PageInfo* pp)
{
	if (--pp->pp_ref == 0)
		page_free(pp);
f0100dd5:	83 ec 0c             	sub    $0xc,%esp
f0100dd8:	52                   	push   %edx
f0100dd9:	e8 a5 ff ff ff       	call   f0100d83 <page_free>
f0100dde:	83 c4 10             	add    $0x10,%esp
}
f0100de1:	eb f0                	jmp    f0100dd3 <page_decref+0x16>

f0100de3 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100de3:	55                   	push   %ebp
f0100de4:	89 e5                	mov    %esp,%ebp
f0100de6:	56                   	push   %esi
f0100de7:	53                   	push   %ebx
f0100de8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	int dict_idx = PDX(va), table_idx = PTX(va);
f0100deb:	89 de                	mov    %ebx,%esi
f0100ded:	c1 ee 0c             	shr    $0xc,%esi
f0100df0:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100df6:	c1 eb 16             	shr    $0x16,%ebx
	if (!(pgdir[dict_idx] & PTE_P)) {
f0100df9:	c1 e3 02             	shl    $0x2,%ebx
f0100dfc:	03 5d 08             	add    0x8(%ebp),%ebx
f0100dff:	f6 03 01             	testb  $0x1,(%ebx)
f0100e02:	75 2c                	jne    f0100e30 <pgdir_walk+0x4d>
		if(create) {
f0100e04:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e08:	74 5d                	je     f0100e67 <pgdir_walk+0x84>
			struct PageInfo *newpage = page_alloc(ALLOC_ZERO);
f0100e0a:	83 ec 0c             	sub    $0xc,%esp
f0100e0d:	6a 01                	push   $0x1
f0100e0f:	e8 fd fe ff ff       	call   f0100d11 <page_alloc>
			if (!newpage) {
f0100e14:	83 c4 10             	add    $0x10,%esp
f0100e17:	85 c0                	test   %eax,%eax
f0100e19:	74 53                	je     f0100e6e <pgdir_walk+0x8b>
				return NULL;
			}
			newpage->pp_ref++;
f0100e1b:	66 ff 40 04          	incw   0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e1f:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0100e25:	c1 f8 03             	sar    $0x3,%eax
f0100e28:	c1 e0 0c             	shl    $0xc,%eax
			pgdir[dict_idx] = page2pa(newpage) | PTE_P | PTE_W | PTE_U;
f0100e2b:	83 c8 07             	or     $0x7,%eax
f0100e2e:	89 03                	mov    %eax,(%ebx)
		} else {
			return NULL;
		}
	}
	pte_t *table_base = KADDR(PTE_ADDR(pgdir[dict_idx]));
f0100e30:	8b 03                	mov    (%ebx),%eax
f0100e32:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e37:	89 c2                	mov    %eax,%edx
f0100e39:	c1 ea 0c             	shr    $0xc,%edx
f0100e3c:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0100e42:	73 0e                	jae    f0100e52 <pgdir_walk+0x6f>
	// Fill this function in
	return &table_base[table_idx];
f0100e44:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
}
f0100e4b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e4e:	5b                   	pop    %ebx
f0100e4f:	5e                   	pop    %esi
f0100e50:	5d                   	pop    %ebp
f0100e51:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e52:	50                   	push   %eax
f0100e53:	68 08 3d 10 f0       	push   $0xf0103d08
f0100e58:	68 7c 01 00 00       	push   $0x17c
f0100e5d:	68 a4 44 10 f0       	push   $0xf01044a4
f0100e62:	e8 12 f2 ff ff       	call   f0100079 <_panic>
				return NULL;
			}
			newpage->pp_ref++;
			pgdir[dict_idx] = page2pa(newpage) | PTE_P | PTE_W | PTE_U;
		} else {
			return NULL;
f0100e67:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e6c:	eb dd                	jmp    f0100e4b <pgdir_walk+0x68>
	int dict_idx = PDX(va), table_idx = PTX(va);
	if (!(pgdir[dict_idx] & PTE_P)) {
		if(create) {
			struct PageInfo *newpage = page_alloc(ALLOC_ZERO);
			if (!newpage) {
				return NULL;
f0100e6e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e73:	eb d6                	jmp    f0100e4b <pgdir_walk+0x68>

f0100e75 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100e75:	55                   	push   %ebp
f0100e76:	89 e5                	mov    %esp,%ebp
f0100e78:	57                   	push   %edi
f0100e79:	56                   	push   %esi
f0100e7a:	53                   	push   %ebx
f0100e7b:	83 ec 1c             	sub    $0x1c,%esp
f0100e7e:	89 c7                	mov    %eax,%edi
f0100e80:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	pte_t *pte;
	for (i = 0; i < size/PGSIZE ; ++i, va += PGSIZE, pa += PGSIZE) {
f0100e83:	c1 e9 0c             	shr    $0xc,%ecx
f0100e86:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100e89:	89 c3                	mov    %eax,%ebx
f0100e8b:	be 00 00 00 00       	mov    $0x0,%esi
		pte = pgdir_walk(pgdir, (void *)va, 1);
f0100e90:	29 c2                	sub    %eax,%edx
f0100e92:	89 55 e0             	mov    %edx,-0x20(%ebp)
		if (!pte) {
			panic("boot_map_region panic -> No memory");
		}
		*pte = pa | perm | PTE_P;
f0100e95:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e98:	83 c8 01             	or     $0x1,%eax
f0100e9b:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	pte_t *pte;
	for (i = 0; i < size/PGSIZE ; ++i, va += PGSIZE, pa += PGSIZE) {
f0100e9e:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100ea1:	74 3f                	je     f0100ee2 <boot_map_region+0x6d>
		pte = pgdir_walk(pgdir, (void *)va, 1);
f0100ea3:	83 ec 04             	sub    $0x4,%esp
f0100ea6:	6a 01                	push   $0x1
f0100ea8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eab:	01 d8                	add    %ebx,%eax
f0100ead:	50                   	push   %eax
f0100eae:	57                   	push   %edi
f0100eaf:	e8 2f ff ff ff       	call   f0100de3 <pgdir_walk>
		if (!pte) {
f0100eb4:	83 c4 10             	add    $0x10,%esp
f0100eb7:	85 c0                	test   %eax,%eax
f0100eb9:	74 10                	je     f0100ecb <boot_map_region+0x56>
			panic("boot_map_region panic -> No memory");
		}
		*pte = pa | perm | PTE_P;
f0100ebb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ebe:	09 da                	or     %ebx,%edx
f0100ec0:	89 10                	mov    %edx,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	pte_t *pte;
	for (i = 0; i < size/PGSIZE ; ++i, va += PGSIZE, pa += PGSIZE) {
f0100ec2:	46                   	inc    %esi
f0100ec3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100ec9:	eb d3                	jmp    f0100e9e <boot_map_region+0x29>
		pte = pgdir_walk(pgdir, (void *)va, 1);
		if (!pte) {
			panic("boot_map_region panic -> No memory");
f0100ecb:	83 ec 04             	sub    $0x4,%esp
f0100ece:	68 14 3e 10 f0       	push   $0xf0103e14
f0100ed3:	68 94 01 00 00       	push   $0x194
f0100ed8:	68 a4 44 10 f0       	push   $0xf01044a4
f0100edd:	e8 97 f1 ff ff       	call   f0100079 <_panic>
		}
		*pte = pa | perm | PTE_P;
	}
	// Fill this function in
}
f0100ee2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ee5:	5b                   	pop    %ebx
f0100ee6:	5e                   	pop    %esi
f0100ee7:	5f                   	pop    %edi
f0100ee8:	5d                   	pop    %ebp
f0100ee9:	c3                   	ret    

f0100eea <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100eea:	55                   	push   %ebp
f0100eeb:	89 e5                	mov    %esp,%ebp
f0100eed:	53                   	push   %ebx
f0100eee:	83 ec 08             	sub    $0x8,%esp
f0100ef1:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir,va,0);
f0100ef4:	6a 00                	push   $0x0
f0100ef6:	ff 75 0c             	pushl  0xc(%ebp)
f0100ef9:	ff 75 08             	pushl  0x8(%ebp)
f0100efc:	e8 e2 fe ff ff       	call   f0100de3 <pgdir_walk>
	if(!pte || !(*pte & PTE_P)) {
f0100f01:	83 c4 10             	add    $0x10,%esp
f0100f04:	85 c0                	test   %eax,%eax
f0100f06:	74 3a                	je     f0100f42 <page_lookup+0x58>
f0100f08:	f6 00 01             	testb  $0x1,(%eax)
f0100f0b:	74 3c                	je     f0100f49 <page_lookup+0x5f>
		return NULL;
	}
	if(pte_store) {
f0100f0d:	85 db                	test   %ebx,%ebx
f0100f0f:	74 02                	je     f0100f13 <page_lookup+0x29>
		*pte_store = pte;
f0100f11:	89 03                	mov    %eax,(%ebx)
f0100f13:	8b 00                	mov    (%eax),%eax
f0100f15:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f18:	39 05 44 79 11 f0    	cmp    %eax,0xf0117944
f0100f1e:	76 0e                	jbe    f0100f2e <page_lookup+0x44>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0100f20:	8b 15 4c 79 11 f0    	mov    0xf011794c,%edx
f0100f26:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	}
	// Fill this function in
	return pa2page(PTE_ADDR(*pte));
}
f0100f29:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f2c:	c9                   	leave  
f0100f2d:	c3                   	ret    

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f0100f2e:	83 ec 04             	sub    $0x4,%esp
f0100f31:	68 38 3e 10 f0       	push   $0xf0103e38
f0100f36:	6a 4b                	push   $0x4b
f0100f38:	68 b0 44 10 f0       	push   $0xf01044b0
f0100f3d:	e8 37 f1 ff ff       	call   f0100079 <_panic>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir,va,0);
	if(!pte || !(*pte & PTE_P)) {
		return NULL;
f0100f42:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f47:	eb e0                	jmp    f0100f29 <page_lookup+0x3f>
f0100f49:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f4e:	eb d9                	jmp    f0100f29 <page_lookup+0x3f>

f0100f50 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f50:	55                   	push   %ebp
f0100f51:	89 e5                	mov    %esp,%ebp
f0100f53:	53                   	push   %ebx
f0100f54:	83 ec 18             	sub    $0x18,%esp
f0100f57:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct PageInfo *page = page_lookup(pgdir,va,&pte);
f0100f5a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100f5d:	50                   	push   %eax
f0100f5e:	53                   	push   %ebx
f0100f5f:	ff 75 08             	pushl  0x8(%ebp)
f0100f62:	e8 83 ff ff ff       	call   f0100eea <page_lookup>
	if (page && (*pte & PTE_P)) {
f0100f67:	83 c4 10             	add    $0x10,%esp
f0100f6a:	85 c0                	test   %eax,%eax
f0100f6c:	74 08                	je     f0100f76 <page_remove+0x26>
f0100f6e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100f71:	f6 02 01             	testb  $0x1,(%edx)
f0100f74:	75 05                	jne    f0100f7b <page_remove+0x2b>
		page_decref(page);
		tlb_invalidate(pgdir,va);
		*pte = (*pte & 0);
	}
	// Fill this function in
}
f0100f76:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f79:	c9                   	leave  
f0100f7a:	c3                   	ret    
page_remove(pde_t *pgdir, void *va)
{
	pte_t *pte;
	struct PageInfo *page = page_lookup(pgdir,va,&pte);
	if (page && (*pte & PTE_P)) {
		page_decref(page);
f0100f7b:	83 ec 0c             	sub    $0xc,%esp
f0100f7e:	50                   	push   %eax
f0100f7f:	e8 39 fe ff ff       	call   f0100dbd <page_decref>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100f84:	0f 01 3b             	invlpg (%ebx)
		tlb_invalidate(pgdir,va);
		*pte = (*pte & 0);
f0100f87:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f8a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100f90:	83 c4 10             	add    $0x10,%esp
	}
	// Fill this function in
}
f0100f93:	eb e1                	jmp    f0100f76 <page_remove+0x26>

f0100f95 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100f95:	55                   	push   %ebp
f0100f96:	89 e5                	mov    %esp,%ebp
f0100f98:	57                   	push   %edi
f0100f99:	56                   	push   %esi
f0100f9a:	53                   	push   %ebx
f0100f9b:	83 ec 10             	sub    $0x10,%esp
f0100f9e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fa1:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte = pgdir_walk(pgdir,va,1);
f0100fa4:	6a 01                	push   $0x1
f0100fa6:	57                   	push   %edi
f0100fa7:	ff 75 08             	pushl  0x8(%ebp)
f0100faa:	e8 34 fe ff ff       	call   f0100de3 <pgdir_walk>
	if (pte == NULL){
f0100faf:	83 c4 10             	add    $0x10,%esp
f0100fb2:	85 c0                	test   %eax,%eax
f0100fb4:	74 3f                	je     f0100ff5 <page_insert+0x60>
f0100fb6:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	}
	pp->pp_ref++;
f0100fb8:	66 ff 43 04          	incw   0x4(%ebx)
	if (*pte & PTE_P){
f0100fbc:	f6 00 01             	testb  $0x1,(%eax)
f0100fbf:	75 23                	jne    f0100fe4 <page_insert+0x4f>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fc1:	2b 1d 4c 79 11 f0    	sub    0xf011794c,%ebx
f0100fc7:	c1 fb 03             	sar    $0x3,%ebx
f0100fca:	c1 e3 0c             	shl    $0xc,%ebx
		page_remove(pgdir,va);
	}
	*pte = page2pa(pp) | perm | PTE_P;
f0100fcd:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd0:	83 c8 01             	or     $0x1,%eax
f0100fd3:	09 c3                	or     %eax,%ebx
f0100fd5:	89 1e                	mov    %ebx,(%esi)
	// Fill this function in
	return 0;
f0100fd7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100fdc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fdf:	5b                   	pop    %ebx
f0100fe0:	5e                   	pop    %esi
f0100fe1:	5f                   	pop    %edi
f0100fe2:	5d                   	pop    %ebp
f0100fe3:	c3                   	ret    
	if (pte == NULL){
		return -E_NO_MEM;
	}
	pp->pp_ref++;
	if (*pte & PTE_P){
		page_remove(pgdir,va);
f0100fe4:	83 ec 08             	sub    $0x8,%esp
f0100fe7:	57                   	push   %edi
f0100fe8:	ff 75 08             	pushl  0x8(%ebp)
f0100feb:	e8 60 ff ff ff       	call   f0100f50 <page_remove>
f0100ff0:	83 c4 10             	add    $0x10,%esp
f0100ff3:	eb cc                	jmp    f0100fc1 <page_insert+0x2c>
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *pte = pgdir_walk(pgdir,va,1);
	if (pte == NULL){
		return -E_NO_MEM;
f0100ff5:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0100ffa:	eb e0                	jmp    f0100fdc <page_insert+0x47>

f0100ffc <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100ffc:	55                   	push   %ebp
f0100ffd:	89 e5                	mov    %esp,%ebp
f0100fff:	57                   	push   %edi
f0101000:	56                   	push   %esi
f0101001:	53                   	push   %ebx
f0101002:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101005:	b8 15 00 00 00       	mov    $0x15,%eax
f010100a:	e8 a5 f8 ff ff       	call   f01008b4 <nvram_read>
f010100f:	89 c6                	mov    %eax,%esi
	extmem = nvram_read(NVRAM_EXTLO);
f0101011:	b8 17 00 00 00       	mov    $0x17,%eax
f0101016:	e8 99 f8 ff ff       	call   f01008b4 <nvram_read>
f010101b:	89 c3                	mov    %eax,%ebx
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010101d:	b8 34 00 00 00       	mov    $0x34,%eax
f0101022:	e8 8d f8 ff ff       	call   f01008b4 <nvram_read>

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101027:	c1 e0 06             	shl    $0x6,%eax
f010102a:	75 10                	jne    f010103c <mem_init+0x40>
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
f010102c:	85 db                	test   %ebx,%ebx
f010102e:	0f 84 b8 00 00 00    	je     f01010ec <mem_init+0xf0>
		totalmem = 1 * 1024 + extmem;
f0101034:	8d 83 00 04 00 00    	lea    0x400(%ebx),%eax
f010103a:	eb 05                	jmp    f0101041 <mem_init+0x45>
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
		totalmem = 16 * 1024 + ext16mem;
f010103c:	05 00 40 00 00       	add    $0x4000,%eax
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101041:	89 c2                	mov    %eax,%edx
f0101043:	c1 ea 02             	shr    $0x2,%edx
f0101046:	89 15 44 79 11 f0    	mov    %edx,0xf0117944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010104c:	89 c2                	mov    %eax,%edx
f010104e:	29 f2                	sub    %esi,%edx
f0101050:	52                   	push   %edx
f0101051:	56                   	push   %esi
f0101052:	50                   	push   %eax
f0101053:	68 58 3e 10 f0       	push   $0xf0103e58
f0101058:	e8 f0 17 00 00       	call   f010284d <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010105d:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101062:	e8 74 f8 ff ff       	call   f01008db <boot_alloc>
f0101067:	a3 48 79 11 f0       	mov    %eax,0xf0117948
	memset(kern_pgdir, 0, PGSIZE);
f010106c:	83 c4 0c             	add    $0xc,%esp
f010106f:	68 00 10 00 00       	push   $0x1000
f0101074:	6a 00                	push   $0x0
f0101076:	50                   	push   %eax
f0101077:	e8 e1 22 00 00       	call   f010335d <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010107c:	a1 48 79 11 f0       	mov    0xf0117948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101081:	83 c4 10             	add    $0x10,%esp
f0101084:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101089:	76 68                	jbe    f01010f3 <mem_init+0xf7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f010108b:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101091:	83 ca 05             	or     $0x5,%edx
f0101094:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *)boot_alloc(npages*sizeof(struct PageInfo));
f010109a:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f010109f:	c1 e0 03             	shl    $0x3,%eax
f01010a2:	e8 34 f8 ff ff       	call   f01008db <boot_alloc>
f01010a7:	a3 4c 79 11 f0       	mov    %eax,0xf011794c
//	memset(pages,0,ROUNDUP(npages*sizeof(struct PageInfo),PGSIZE));
	memset(pages,0,npages*sizeof(struct PageInfo));
f01010ac:	83 ec 04             	sub    $0x4,%esp
f01010af:	8b 0d 44 79 11 f0    	mov    0xf0117944,%ecx
f01010b5:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01010bc:	52                   	push   %edx
f01010bd:	6a 00                	push   $0x0
f01010bf:	50                   	push   %eax
f01010c0:	e8 98 22 00 00       	call   f010335d <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01010c5:	e8 9b fb ff ff       	call   f0100c65 <page_init>

	check_page_free_list(1);
f01010ca:	b8 01 00 00 00       	mov    $0x1,%eax
f01010cf:	e8 d7 f8 ff ff       	call   f01009ab <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01010d4:	83 c4 10             	add    $0x10,%esp
f01010d7:	83 3d 4c 79 11 f0 00 	cmpl   $0x0,0xf011794c
f01010de:	74 28                	je     f0101108 <mem_init+0x10c>
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01010e0:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01010e5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01010ea:	eb 36                	jmp    f0101122 <mem_init+0x126>
	if (ext16mem)
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
	else
		totalmem = basemem;
f01010ec:	89 f0                	mov    %esi,%eax
f01010ee:	e9 4e ff ff ff       	jmp    f0101041 <mem_init+0x45>

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010f3:	50                   	push   %eax
f01010f4:	68 94 3e 10 f0       	push   $0xf0103e94
f01010f9:	68 9a 00 00 00       	push   $0x9a
f01010fe:	68 a4 44 10 f0       	push   $0xf01044a4
f0101103:	e8 71 ef ff ff       	call   f0100079 <_panic>
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
		panic("'pages' is a null pointer!");
f0101108:	83 ec 04             	sub    $0x4,%esp
f010110b:	68 5a 45 10 f0       	push   $0xf010455a
f0101110:	68 53 02 00 00       	push   $0x253
f0101115:	68 a4 44 10 f0       	push   $0xf01044a4
f010111a:	e8 5a ef ff ff       	call   f0100079 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
		++nfree;
f010111f:	43                   	inc    %ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101120:	8b 00                	mov    (%eax),%eax
f0101122:	85 c0                	test   %eax,%eax
f0101124:	75 f9                	jne    f010111f <mem_init+0x123>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101126:	83 ec 0c             	sub    $0xc,%esp
f0101129:	6a 00                	push   $0x0
f010112b:	e8 e1 fb ff ff       	call   f0100d11 <page_alloc>
f0101130:	89 c7                	mov    %eax,%edi
f0101132:	83 c4 10             	add    $0x10,%esp
f0101135:	85 c0                	test   %eax,%eax
f0101137:	0f 84 10 02 00 00    	je     f010134d <mem_init+0x351>
	assert((pp1 = page_alloc(0)));
f010113d:	83 ec 0c             	sub    $0xc,%esp
f0101140:	6a 00                	push   $0x0
f0101142:	e8 ca fb ff ff       	call   f0100d11 <page_alloc>
f0101147:	89 c6                	mov    %eax,%esi
f0101149:	83 c4 10             	add    $0x10,%esp
f010114c:	85 c0                	test   %eax,%eax
f010114e:	0f 84 12 02 00 00    	je     f0101366 <mem_init+0x36a>
	assert((pp2 = page_alloc(0)));
f0101154:	83 ec 0c             	sub    $0xc,%esp
f0101157:	6a 00                	push   $0x0
f0101159:	e8 b3 fb ff ff       	call   f0100d11 <page_alloc>
f010115e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101161:	83 c4 10             	add    $0x10,%esp
f0101164:	85 c0                	test   %eax,%eax
f0101166:	0f 84 13 02 00 00    	je     f010137f <mem_init+0x383>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010116c:	39 f7                	cmp    %esi,%edi
f010116e:	0f 84 24 02 00 00    	je     f0101398 <mem_init+0x39c>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101174:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101177:	39 c6                	cmp    %eax,%esi
f0101179:	0f 84 32 02 00 00    	je     f01013b1 <mem_init+0x3b5>
f010117f:	39 c7                	cmp    %eax,%edi
f0101181:	0f 84 2a 02 00 00    	je     f01013b1 <mem_init+0x3b5>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101187:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010118d:	8b 15 44 79 11 f0    	mov    0xf0117944,%edx
f0101193:	c1 e2 0c             	shl    $0xc,%edx
f0101196:	89 f8                	mov    %edi,%eax
f0101198:	29 c8                	sub    %ecx,%eax
f010119a:	c1 f8 03             	sar    $0x3,%eax
f010119d:	c1 e0 0c             	shl    $0xc,%eax
f01011a0:	39 d0                	cmp    %edx,%eax
f01011a2:	0f 83 22 02 00 00    	jae    f01013ca <mem_init+0x3ce>
f01011a8:	89 f0                	mov    %esi,%eax
f01011aa:	29 c8                	sub    %ecx,%eax
f01011ac:	c1 f8 03             	sar    $0x3,%eax
f01011af:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01011b2:	39 c2                	cmp    %eax,%edx
f01011b4:	0f 86 29 02 00 00    	jbe    f01013e3 <mem_init+0x3e7>
f01011ba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011bd:	29 c8                	sub    %ecx,%eax
f01011bf:	c1 f8 03             	sar    $0x3,%eax
f01011c2:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01011c5:	39 c2                	cmp    %eax,%edx
f01011c7:	0f 86 2f 02 00 00    	jbe    f01013fc <mem_init+0x400>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01011cd:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01011d2:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01011d5:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01011dc:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01011df:	83 ec 0c             	sub    $0xc,%esp
f01011e2:	6a 00                	push   $0x0
f01011e4:	e8 28 fb ff ff       	call   f0100d11 <page_alloc>
f01011e9:	83 c4 10             	add    $0x10,%esp
f01011ec:	85 c0                	test   %eax,%eax
f01011ee:	0f 85 21 02 00 00    	jne    f0101415 <mem_init+0x419>

	// free and re-allocate?
	page_free(pp0);
f01011f4:	83 ec 0c             	sub    $0xc,%esp
f01011f7:	57                   	push   %edi
f01011f8:	e8 86 fb ff ff       	call   f0100d83 <page_free>
	page_free(pp1);
f01011fd:	89 34 24             	mov    %esi,(%esp)
f0101200:	e8 7e fb ff ff       	call   f0100d83 <page_free>
	page_free(pp2);
f0101205:	83 c4 04             	add    $0x4,%esp
f0101208:	ff 75 d4             	pushl  -0x2c(%ebp)
f010120b:	e8 73 fb ff ff       	call   f0100d83 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101210:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101217:	e8 f5 fa ff ff       	call   f0100d11 <page_alloc>
f010121c:	89 c6                	mov    %eax,%esi
f010121e:	83 c4 10             	add    $0x10,%esp
f0101221:	85 c0                	test   %eax,%eax
f0101223:	0f 84 05 02 00 00    	je     f010142e <mem_init+0x432>
	assert((pp1 = page_alloc(0)));
f0101229:	83 ec 0c             	sub    $0xc,%esp
f010122c:	6a 00                	push   $0x0
f010122e:	e8 de fa ff ff       	call   f0100d11 <page_alloc>
f0101233:	89 c7                	mov    %eax,%edi
f0101235:	83 c4 10             	add    $0x10,%esp
f0101238:	85 c0                	test   %eax,%eax
f010123a:	0f 84 07 02 00 00    	je     f0101447 <mem_init+0x44b>
	assert((pp2 = page_alloc(0)));
f0101240:	83 ec 0c             	sub    $0xc,%esp
f0101243:	6a 00                	push   $0x0
f0101245:	e8 c7 fa ff ff       	call   f0100d11 <page_alloc>
f010124a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010124d:	83 c4 10             	add    $0x10,%esp
f0101250:	85 c0                	test   %eax,%eax
f0101252:	0f 84 08 02 00 00    	je     f0101460 <mem_init+0x464>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101258:	39 fe                	cmp    %edi,%esi
f010125a:	0f 84 19 02 00 00    	je     f0101479 <mem_init+0x47d>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101260:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101263:	39 c7                	cmp    %eax,%edi
f0101265:	0f 84 27 02 00 00    	je     f0101492 <mem_init+0x496>
f010126b:	39 c6                	cmp    %eax,%esi
f010126d:	0f 84 1f 02 00 00    	je     f0101492 <mem_init+0x496>
	assert(!page_alloc(0));
f0101273:	83 ec 0c             	sub    $0xc,%esp
f0101276:	6a 00                	push   $0x0
f0101278:	e8 94 fa ff ff       	call   f0100d11 <page_alloc>
f010127d:	83 c4 10             	add    $0x10,%esp
f0101280:	85 c0                	test   %eax,%eax
f0101282:	0f 85 23 02 00 00    	jne    f01014ab <mem_init+0x4af>
f0101288:	89 f0                	mov    %esi,%eax
f010128a:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0101290:	c1 f8 03             	sar    $0x3,%eax
f0101293:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101296:	89 c2                	mov    %eax,%edx
f0101298:	c1 ea 0c             	shr    $0xc,%edx
f010129b:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f01012a1:	0f 83 1d 02 00 00    	jae    f01014c4 <mem_init+0x4c8>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01012a7:	83 ec 04             	sub    $0x4,%esp
f01012aa:	68 00 10 00 00       	push   $0x1000
f01012af:	6a 01                	push   $0x1
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f01012b1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01012b6:	50                   	push   %eax
f01012b7:	e8 a1 20 00 00       	call   f010335d <memset>
	page_free(pp0);
f01012bc:	89 34 24             	mov    %esi,(%esp)
f01012bf:	e8 bf fa ff ff       	call   f0100d83 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01012c4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01012cb:	e8 41 fa ff ff       	call   f0100d11 <page_alloc>
f01012d0:	83 c4 10             	add    $0x10,%esp
f01012d3:	85 c0                	test   %eax,%eax
f01012d5:	0f 84 fb 01 00 00    	je     f01014d6 <mem_init+0x4da>
	assert(pp && pp0 == pp);
f01012db:	39 c6                	cmp    %eax,%esi
f01012dd:	0f 85 0c 02 00 00    	jne    f01014ef <mem_init+0x4f3>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012e3:	89 f0                	mov    %esi,%eax
f01012e5:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f01012eb:	c1 f8 03             	sar    $0x3,%eax
f01012ee:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012f1:	89 c2                	mov    %eax,%edx
f01012f3:	c1 ea 0c             	shr    $0xc,%edx
f01012f6:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f01012fc:	0f 83 06 02 00 00    	jae    f0101508 <mem_init+0x50c>
f0101302:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0101308:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010130e:	80 38 00             	cmpb   $0x0,(%eax)
f0101311:	0f 85 03 02 00 00    	jne    f010151a <mem_init+0x51e>
f0101317:	40                   	inc    %eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101318:	39 d0                	cmp    %edx,%eax
f010131a:	75 f2                	jne    f010130e <mem_init+0x312>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010131c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010131f:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101324:	83 ec 0c             	sub    $0xc,%esp
f0101327:	56                   	push   %esi
f0101328:	e8 56 fa ff ff       	call   f0100d83 <page_free>
	page_free(pp1);
f010132d:	89 3c 24             	mov    %edi,(%esp)
f0101330:	e8 4e fa ff ff       	call   f0100d83 <page_free>
	page_free(pp2);
f0101335:	83 c4 04             	add    $0x4,%esp
f0101338:	ff 75 d4             	pushl  -0x2c(%ebp)
f010133b:	e8 43 fa ff ff       	call   f0100d83 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101340:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101345:	83 c4 10             	add    $0x10,%esp
f0101348:	e9 e9 01 00 00       	jmp    f0101536 <mem_init+0x53a>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010134d:	68 75 45 10 f0       	push   $0xf0104575
f0101352:	68 ca 44 10 f0       	push   $0xf01044ca
f0101357:	68 5b 02 00 00       	push   $0x25b
f010135c:	68 a4 44 10 f0       	push   $0xf01044a4
f0101361:	e8 13 ed ff ff       	call   f0100079 <_panic>
	assert((pp1 = page_alloc(0)));
f0101366:	68 8b 45 10 f0       	push   $0xf010458b
f010136b:	68 ca 44 10 f0       	push   $0xf01044ca
f0101370:	68 5c 02 00 00       	push   $0x25c
f0101375:	68 a4 44 10 f0       	push   $0xf01044a4
f010137a:	e8 fa ec ff ff       	call   f0100079 <_panic>
	assert((pp2 = page_alloc(0)));
f010137f:	68 a1 45 10 f0       	push   $0xf01045a1
f0101384:	68 ca 44 10 f0       	push   $0xf01044ca
f0101389:	68 5d 02 00 00       	push   $0x25d
f010138e:	68 a4 44 10 f0       	push   $0xf01044a4
f0101393:	e8 e1 ec ff ff       	call   f0100079 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101398:	68 b7 45 10 f0       	push   $0xf01045b7
f010139d:	68 ca 44 10 f0       	push   $0xf01044ca
f01013a2:	68 60 02 00 00       	push   $0x260
f01013a7:	68 a4 44 10 f0       	push   $0xf01044a4
f01013ac:	e8 c8 ec ff ff       	call   f0100079 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013b1:	68 b8 3e 10 f0       	push   $0xf0103eb8
f01013b6:	68 ca 44 10 f0       	push   $0xf01044ca
f01013bb:	68 61 02 00 00       	push   $0x261
f01013c0:	68 a4 44 10 f0       	push   $0xf01044a4
f01013c5:	e8 af ec ff ff       	call   f0100079 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01013ca:	68 c9 45 10 f0       	push   $0xf01045c9
f01013cf:	68 ca 44 10 f0       	push   $0xf01044ca
f01013d4:	68 62 02 00 00       	push   $0x262
f01013d9:	68 a4 44 10 f0       	push   $0xf01044a4
f01013de:	e8 96 ec ff ff       	call   f0100079 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01013e3:	68 e6 45 10 f0       	push   $0xf01045e6
f01013e8:	68 ca 44 10 f0       	push   $0xf01044ca
f01013ed:	68 63 02 00 00       	push   $0x263
f01013f2:	68 a4 44 10 f0       	push   $0xf01044a4
f01013f7:	e8 7d ec ff ff       	call   f0100079 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01013fc:	68 03 46 10 f0       	push   $0xf0104603
f0101401:	68 ca 44 10 f0       	push   $0xf01044ca
f0101406:	68 64 02 00 00       	push   $0x264
f010140b:	68 a4 44 10 f0       	push   $0xf01044a4
f0101410:	e8 64 ec ff ff       	call   f0100079 <_panic>
	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;

	// should be no free memory
	assert(!page_alloc(0));
f0101415:	68 20 46 10 f0       	push   $0xf0104620
f010141a:	68 ca 44 10 f0       	push   $0xf01044ca
f010141f:	68 6b 02 00 00       	push   $0x26b
f0101424:	68 a4 44 10 f0       	push   $0xf01044a4
f0101429:	e8 4b ec ff ff       	call   f0100079 <_panic>
	// free and re-allocate?
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010142e:	68 75 45 10 f0       	push   $0xf0104575
f0101433:	68 ca 44 10 f0       	push   $0xf01044ca
f0101438:	68 72 02 00 00       	push   $0x272
f010143d:	68 a4 44 10 f0       	push   $0xf01044a4
f0101442:	e8 32 ec ff ff       	call   f0100079 <_panic>
	assert((pp1 = page_alloc(0)));
f0101447:	68 8b 45 10 f0       	push   $0xf010458b
f010144c:	68 ca 44 10 f0       	push   $0xf01044ca
f0101451:	68 73 02 00 00       	push   $0x273
f0101456:	68 a4 44 10 f0       	push   $0xf01044a4
f010145b:	e8 19 ec ff ff       	call   f0100079 <_panic>
	assert((pp2 = page_alloc(0)));
f0101460:	68 a1 45 10 f0       	push   $0xf01045a1
f0101465:	68 ca 44 10 f0       	push   $0xf01044ca
f010146a:	68 74 02 00 00       	push   $0x274
f010146f:	68 a4 44 10 f0       	push   $0xf01044a4
f0101474:	e8 00 ec ff ff       	call   f0100079 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101479:	68 b7 45 10 f0       	push   $0xf01045b7
f010147e:	68 ca 44 10 f0       	push   $0xf01044ca
f0101483:	68 76 02 00 00       	push   $0x276
f0101488:	68 a4 44 10 f0       	push   $0xf01044a4
f010148d:	e8 e7 eb ff ff       	call   f0100079 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101492:	68 b8 3e 10 f0       	push   $0xf0103eb8
f0101497:	68 ca 44 10 f0       	push   $0xf01044ca
f010149c:	68 77 02 00 00       	push   $0x277
f01014a1:	68 a4 44 10 f0       	push   $0xf01044a4
f01014a6:	e8 ce eb ff ff       	call   f0100079 <_panic>
	assert(!page_alloc(0));
f01014ab:	68 20 46 10 f0       	push   $0xf0104620
f01014b0:	68 ca 44 10 f0       	push   $0xf01044ca
f01014b5:	68 78 02 00 00       	push   $0x278
f01014ba:	68 a4 44 10 f0       	push   $0xf01044a4
f01014bf:	e8 b5 eb ff ff       	call   f0100079 <_panic>

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014c4:	50                   	push   %eax
f01014c5:	68 08 3d 10 f0       	push   $0xf0103d08
f01014ca:	6a 52                	push   $0x52
f01014cc:	68 b0 44 10 f0       	push   $0xf01044b0
f01014d1:	e8 a3 eb ff ff       	call   f0100079 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
f01014d6:	68 2f 46 10 f0       	push   $0xf010462f
f01014db:	68 ca 44 10 f0       	push   $0xf01044ca
f01014e0:	68 7d 02 00 00       	push   $0x27d
f01014e5:	68 a4 44 10 f0       	push   $0xf01044a4
f01014ea:	e8 8a eb ff ff       	call   f0100079 <_panic>
	assert(pp && pp0 == pp);
f01014ef:	68 4d 46 10 f0       	push   $0xf010464d
f01014f4:	68 ca 44 10 f0       	push   $0xf01044ca
f01014f9:	68 7e 02 00 00       	push   $0x27e
f01014fe:	68 a4 44 10 f0       	push   $0xf01044a4
f0101503:	e8 71 eb ff ff       	call   f0100079 <_panic>
f0101508:	50                   	push   %eax
f0101509:	68 08 3d 10 f0       	push   $0xf0103d08
f010150e:	6a 52                	push   $0x52
f0101510:	68 b0 44 10 f0       	push   $0xf01044b0
f0101515:	e8 5f eb ff ff       	call   f0100079 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010151a:	68 5d 46 10 f0       	push   $0xf010465d
f010151f:	68 ca 44 10 f0       	push   $0xf01044ca
f0101524:	68 81 02 00 00       	push   $0x281
f0101529:	68 a4 44 10 f0       	push   $0xf01044a4
f010152e:	e8 46 eb ff ff       	call   f0100079 <_panic>
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
		--nfree;
f0101533:	4b                   	dec    %ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101534:	8b 00                	mov    (%eax),%eax
f0101536:	85 c0                	test   %eax,%eax
f0101538:	75 f9                	jne    f0101533 <mem_init+0x537>
		--nfree;
	assert(nfree == 0);
f010153a:	85 db                	test   %ebx,%ebx
f010153c:	0f 85 8b 07 00 00    	jne    f0101ccd <mem_init+0xcd1>

	cprintf("check_page_alloc() succeeded!\n");
f0101542:	83 ec 0c             	sub    $0xc,%esp
f0101545:	68 d8 3e 10 f0       	push   $0xf0103ed8
f010154a:	e8 fe 12 00 00       	call   f010284d <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010154f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101556:	e8 b6 f7 ff ff       	call   f0100d11 <page_alloc>
f010155b:	89 c7                	mov    %eax,%edi
f010155d:	83 c4 10             	add    $0x10,%esp
f0101560:	85 c0                	test   %eax,%eax
f0101562:	0f 84 7e 07 00 00    	je     f0101ce6 <mem_init+0xcea>
	assert((pp1 = page_alloc(0)));
f0101568:	83 ec 0c             	sub    $0xc,%esp
f010156b:	6a 00                	push   $0x0
f010156d:	e8 9f f7 ff ff       	call   f0100d11 <page_alloc>
f0101572:	89 c3                	mov    %eax,%ebx
f0101574:	83 c4 10             	add    $0x10,%esp
f0101577:	85 c0                	test   %eax,%eax
f0101579:	0f 84 80 07 00 00    	je     f0101cff <mem_init+0xd03>
	assert((pp2 = page_alloc(0)));
f010157f:	83 ec 0c             	sub    $0xc,%esp
f0101582:	6a 00                	push   $0x0
f0101584:	e8 88 f7 ff ff       	call   f0100d11 <page_alloc>
f0101589:	89 c6                	mov    %eax,%esi
f010158b:	83 c4 10             	add    $0x10,%esp
f010158e:	85 c0                	test   %eax,%eax
f0101590:	0f 84 82 07 00 00    	je     f0101d18 <mem_init+0xd1c>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101596:	39 df                	cmp    %ebx,%edi
f0101598:	0f 84 93 07 00 00    	je     f0101d31 <mem_init+0xd35>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010159e:	39 c3                	cmp    %eax,%ebx
f01015a0:	0f 84 a4 07 00 00    	je     f0101d4a <mem_init+0xd4e>
f01015a6:	39 c7                	cmp    %eax,%edi
f01015a8:	0f 84 9c 07 00 00    	je     f0101d4a <mem_init+0xd4e>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015ae:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01015b3:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f01015b6:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01015bd:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015c0:	83 ec 0c             	sub    $0xc,%esp
f01015c3:	6a 00                	push   $0x0
f01015c5:	e8 47 f7 ff ff       	call   f0100d11 <page_alloc>
f01015ca:	83 c4 10             	add    $0x10,%esp
f01015cd:	85 c0                	test   %eax,%eax
f01015cf:	0f 85 8e 07 00 00    	jne    f0101d63 <mem_init+0xd67>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01015d5:	83 ec 04             	sub    $0x4,%esp
f01015d8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01015db:	50                   	push   %eax
f01015dc:	6a 00                	push   $0x0
f01015de:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01015e4:	e8 01 f9 ff ff       	call   f0100eea <page_lookup>
f01015e9:	83 c4 10             	add    $0x10,%esp
f01015ec:	85 c0                	test   %eax,%eax
f01015ee:	0f 85 88 07 00 00    	jne    f0101d7c <mem_init+0xd80>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01015f4:	6a 02                	push   $0x2
f01015f6:	6a 00                	push   $0x0
f01015f8:	53                   	push   %ebx
f01015f9:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01015ff:	e8 91 f9 ff ff       	call   f0100f95 <page_insert>
f0101604:	83 c4 10             	add    $0x10,%esp
f0101607:	85 c0                	test   %eax,%eax
f0101609:	0f 89 86 07 00 00    	jns    f0101d95 <mem_init+0xd99>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010160f:	83 ec 0c             	sub    $0xc,%esp
f0101612:	57                   	push   %edi
f0101613:	e8 6b f7 ff ff       	call   f0100d83 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101618:	6a 02                	push   $0x2
f010161a:	6a 00                	push   $0x0
f010161c:	53                   	push   %ebx
f010161d:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101623:	e8 6d f9 ff ff       	call   f0100f95 <page_insert>
f0101628:	83 c4 20             	add    $0x20,%esp
f010162b:	85 c0                	test   %eax,%eax
f010162d:	0f 85 7b 07 00 00    	jne    f0101dae <mem_init+0xdb2>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101633:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101638:	89 45 d4             	mov    %eax,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010163b:	8b 0d 4c 79 11 f0    	mov    0xf011794c,%ecx
f0101641:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0101644:	8b 00                	mov    (%eax),%eax
f0101646:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101649:	89 c2                	mov    %eax,%edx
f010164b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101651:	89 f8                	mov    %edi,%eax
f0101653:	29 c8                	sub    %ecx,%eax
f0101655:	c1 f8 03             	sar    $0x3,%eax
f0101658:	c1 e0 0c             	shl    $0xc,%eax
f010165b:	39 c2                	cmp    %eax,%edx
f010165d:	0f 85 64 07 00 00    	jne    f0101dc7 <mem_init+0xdcb>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101663:	ba 00 00 00 00       	mov    $0x0,%edx
f0101668:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010166b:	e8 da f2 ff ff       	call   f010094a <check_va2pa>
f0101670:	89 da                	mov    %ebx,%edx
f0101672:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101675:	c1 fa 03             	sar    $0x3,%edx
f0101678:	c1 e2 0c             	shl    $0xc,%edx
f010167b:	39 d0                	cmp    %edx,%eax
f010167d:	0f 85 5d 07 00 00    	jne    f0101de0 <mem_init+0xde4>
	assert(pp1->pp_ref == 1);
f0101683:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101688:	0f 85 6b 07 00 00    	jne    f0101df9 <mem_init+0xdfd>
	assert(pp0->pp_ref == 1);
f010168e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101693:	0f 85 79 07 00 00    	jne    f0101e12 <mem_init+0xe16>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101699:	6a 02                	push   $0x2
f010169b:	68 00 10 00 00       	push   $0x1000
f01016a0:	56                   	push   %esi
f01016a1:	ff 75 d4             	pushl  -0x2c(%ebp)
f01016a4:	e8 ec f8 ff ff       	call   f0100f95 <page_insert>
f01016a9:	83 c4 10             	add    $0x10,%esp
f01016ac:	85 c0                	test   %eax,%eax
f01016ae:	0f 85 77 07 00 00    	jne    f0101e2b <mem_init+0xe2f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01016b4:	ba 00 10 00 00       	mov    $0x1000,%edx
f01016b9:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01016be:	e8 87 f2 ff ff       	call   f010094a <check_va2pa>
f01016c3:	89 f2                	mov    %esi,%edx
f01016c5:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f01016cb:	c1 fa 03             	sar    $0x3,%edx
f01016ce:	c1 e2 0c             	shl    $0xc,%edx
f01016d1:	39 d0                	cmp    %edx,%eax
f01016d3:	0f 85 6b 07 00 00    	jne    f0101e44 <mem_init+0xe48>
	assert(pp2->pp_ref == 1);
f01016d9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01016de:	0f 85 79 07 00 00    	jne    f0101e5d <mem_init+0xe61>

	// should be no free memory
	assert(!page_alloc(0));
f01016e4:	83 ec 0c             	sub    $0xc,%esp
f01016e7:	6a 00                	push   $0x0
f01016e9:	e8 23 f6 ff ff       	call   f0100d11 <page_alloc>
f01016ee:	83 c4 10             	add    $0x10,%esp
f01016f1:	85 c0                	test   %eax,%eax
f01016f3:	0f 85 7d 07 00 00    	jne    f0101e76 <mem_init+0xe7a>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01016f9:	6a 02                	push   $0x2
f01016fb:	68 00 10 00 00       	push   $0x1000
f0101700:	56                   	push   %esi
f0101701:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101707:	e8 89 f8 ff ff       	call   f0100f95 <page_insert>
f010170c:	83 c4 10             	add    $0x10,%esp
f010170f:	85 c0                	test   %eax,%eax
f0101711:	0f 85 78 07 00 00    	jne    f0101e8f <mem_init+0xe93>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101717:	ba 00 10 00 00       	mov    $0x1000,%edx
f010171c:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101721:	e8 24 f2 ff ff       	call   f010094a <check_va2pa>
f0101726:	89 f2                	mov    %esi,%edx
f0101728:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f010172e:	c1 fa 03             	sar    $0x3,%edx
f0101731:	c1 e2 0c             	shl    $0xc,%edx
f0101734:	39 d0                	cmp    %edx,%eax
f0101736:	0f 85 6c 07 00 00    	jne    f0101ea8 <mem_init+0xeac>
	assert(pp2->pp_ref == 1);
f010173c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101741:	0f 85 7a 07 00 00    	jne    f0101ec1 <mem_init+0xec5>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101747:	83 ec 0c             	sub    $0xc,%esp
f010174a:	6a 00                	push   $0x0
f010174c:	e8 c0 f5 ff ff       	call   f0100d11 <page_alloc>
f0101751:	83 c4 10             	add    $0x10,%esp
f0101754:	85 c0                	test   %eax,%eax
f0101756:	0f 85 7e 07 00 00    	jne    f0101eda <mem_init+0xede>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010175c:	8b 15 48 79 11 f0    	mov    0xf0117948,%edx
f0101762:	8b 02                	mov    (%edx),%eax
f0101764:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101769:	89 c1                	mov    %eax,%ecx
f010176b:	c1 e9 0c             	shr    $0xc,%ecx
f010176e:	3b 0d 44 79 11 f0    	cmp    0xf0117944,%ecx
f0101774:	0f 83 79 07 00 00    	jae    f0101ef3 <mem_init+0xef7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f010177a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010177f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101782:	83 ec 04             	sub    $0x4,%esp
f0101785:	6a 00                	push   $0x0
f0101787:	68 00 10 00 00       	push   $0x1000
f010178c:	52                   	push   %edx
f010178d:	e8 51 f6 ff ff       	call   f0100de3 <pgdir_walk>
f0101792:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101795:	8d 51 04             	lea    0x4(%ecx),%edx
f0101798:	83 c4 10             	add    $0x10,%esp
f010179b:	39 d0                	cmp    %edx,%eax
f010179d:	0f 85 65 07 00 00    	jne    f0101f08 <mem_init+0xf0c>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01017a3:	6a 06                	push   $0x6
f01017a5:	68 00 10 00 00       	push   $0x1000
f01017aa:	56                   	push   %esi
f01017ab:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01017b1:	e8 df f7 ff ff       	call   f0100f95 <page_insert>
f01017b6:	83 c4 10             	add    $0x10,%esp
f01017b9:	85 c0                	test   %eax,%eax
f01017bb:	0f 85 60 07 00 00    	jne    f0101f21 <mem_init+0xf25>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017c1:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01017c6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017c9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017ce:	e8 77 f1 ff ff       	call   f010094a <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01017d3:	89 f2                	mov    %esi,%edx
f01017d5:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f01017db:	c1 fa 03             	sar    $0x3,%edx
f01017de:	c1 e2 0c             	shl    $0xc,%edx
f01017e1:	39 d0                	cmp    %edx,%eax
f01017e3:	0f 85 51 07 00 00    	jne    f0101f3a <mem_init+0xf3e>
	assert(pp2->pp_ref == 1);
f01017e9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01017ee:	0f 85 5f 07 00 00    	jne    f0101f53 <mem_init+0xf57>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01017f4:	83 ec 04             	sub    $0x4,%esp
f01017f7:	6a 00                	push   $0x0
f01017f9:	68 00 10 00 00       	push   $0x1000
f01017fe:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101801:	e8 dd f5 ff ff       	call   f0100de3 <pgdir_walk>
f0101806:	83 c4 10             	add    $0x10,%esp
f0101809:	f6 00 04             	testb  $0x4,(%eax)
f010180c:	0f 84 5a 07 00 00    	je     f0101f6c <mem_init+0xf70>
	assert(kern_pgdir[0] & PTE_U);
f0101812:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101817:	f6 00 04             	testb  $0x4,(%eax)
f010181a:	0f 84 65 07 00 00    	je     f0101f85 <mem_init+0xf89>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101820:	6a 02                	push   $0x2
f0101822:	68 00 10 00 00       	push   $0x1000
f0101827:	56                   	push   %esi
f0101828:	50                   	push   %eax
f0101829:	e8 67 f7 ff ff       	call   f0100f95 <page_insert>
f010182e:	83 c4 10             	add    $0x10,%esp
f0101831:	85 c0                	test   %eax,%eax
f0101833:	0f 85 65 07 00 00    	jne    f0101f9e <mem_init+0xfa2>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101839:	83 ec 04             	sub    $0x4,%esp
f010183c:	6a 00                	push   $0x0
f010183e:	68 00 10 00 00       	push   $0x1000
f0101843:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101849:	e8 95 f5 ff ff       	call   f0100de3 <pgdir_walk>
f010184e:	83 c4 10             	add    $0x10,%esp
f0101851:	f6 00 02             	testb  $0x2,(%eax)
f0101854:	0f 84 5d 07 00 00    	je     f0101fb7 <mem_init+0xfbb>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010185a:	83 ec 04             	sub    $0x4,%esp
f010185d:	6a 00                	push   $0x0
f010185f:	68 00 10 00 00       	push   $0x1000
f0101864:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010186a:	e8 74 f5 ff ff       	call   f0100de3 <pgdir_walk>
f010186f:	83 c4 10             	add    $0x10,%esp
f0101872:	f6 00 04             	testb  $0x4,(%eax)
f0101875:	0f 85 55 07 00 00    	jne    f0101fd0 <mem_init+0xfd4>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010187b:	6a 02                	push   $0x2
f010187d:	68 00 00 40 00       	push   $0x400000
f0101882:	57                   	push   %edi
f0101883:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101889:	e8 07 f7 ff ff       	call   f0100f95 <page_insert>
f010188e:	83 c4 10             	add    $0x10,%esp
f0101891:	85 c0                	test   %eax,%eax
f0101893:	0f 89 50 07 00 00    	jns    f0101fe9 <mem_init+0xfed>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101899:	6a 02                	push   $0x2
f010189b:	68 00 10 00 00       	push   $0x1000
f01018a0:	53                   	push   %ebx
f01018a1:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01018a7:	e8 e9 f6 ff ff       	call   f0100f95 <page_insert>
f01018ac:	83 c4 10             	add    $0x10,%esp
f01018af:	85 c0                	test   %eax,%eax
f01018b1:	0f 85 4b 07 00 00    	jne    f0102002 <mem_init+0x1006>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01018b7:	83 ec 04             	sub    $0x4,%esp
f01018ba:	6a 00                	push   $0x0
f01018bc:	68 00 10 00 00       	push   $0x1000
f01018c1:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01018c7:	e8 17 f5 ff ff       	call   f0100de3 <pgdir_walk>
f01018cc:	83 c4 10             	add    $0x10,%esp
f01018cf:	f6 00 04             	testb  $0x4,(%eax)
f01018d2:	0f 85 43 07 00 00    	jne    f010201b <mem_init+0x101f>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01018d8:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01018dd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018e0:	ba 00 00 00 00       	mov    $0x0,%edx
f01018e5:	e8 60 f0 ff ff       	call   f010094a <check_va2pa>
f01018ea:	89 c1                	mov    %eax,%ecx
f01018ec:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01018ef:	89 d8                	mov    %ebx,%eax
f01018f1:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f01018f7:	c1 f8 03             	sar    $0x3,%eax
f01018fa:	c1 e0 0c             	shl    $0xc,%eax
f01018fd:	39 c1                	cmp    %eax,%ecx
f01018ff:	0f 85 2f 07 00 00    	jne    f0102034 <mem_init+0x1038>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101905:	ba 00 10 00 00       	mov    $0x1000,%edx
f010190a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010190d:	e8 38 f0 ff ff       	call   f010094a <check_va2pa>
f0101912:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101915:	0f 85 32 07 00 00    	jne    f010204d <mem_init+0x1051>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010191b:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101920:	0f 85 40 07 00 00    	jne    f0102066 <mem_init+0x106a>
	assert(pp2->pp_ref == 0);
f0101926:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010192b:	0f 85 4e 07 00 00    	jne    f010207f <mem_init+0x1083>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101931:	83 ec 0c             	sub    $0xc,%esp
f0101934:	6a 00                	push   $0x0
f0101936:	e8 d6 f3 ff ff       	call   f0100d11 <page_alloc>
f010193b:	83 c4 10             	add    $0x10,%esp
f010193e:	85 c0                	test   %eax,%eax
f0101940:	0f 84 52 07 00 00    	je     f0102098 <mem_init+0x109c>
f0101946:	39 c6                	cmp    %eax,%esi
f0101948:	0f 85 4a 07 00 00    	jne    f0102098 <mem_init+0x109c>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010194e:	83 ec 08             	sub    $0x8,%esp
f0101951:	6a 00                	push   $0x0
f0101953:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101959:	e8 f2 f5 ff ff       	call   f0100f50 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010195e:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101963:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101966:	ba 00 00 00 00       	mov    $0x0,%edx
f010196b:	e8 da ef ff ff       	call   f010094a <check_va2pa>
f0101970:	83 c4 10             	add    $0x10,%esp
f0101973:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101976:	0f 85 35 07 00 00    	jne    f01020b1 <mem_init+0x10b5>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010197c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101981:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101984:	e8 c1 ef ff ff       	call   f010094a <check_va2pa>
f0101989:	89 da                	mov    %ebx,%edx
f010198b:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0101991:	c1 fa 03             	sar    $0x3,%edx
f0101994:	c1 e2 0c             	shl    $0xc,%edx
f0101997:	39 d0                	cmp    %edx,%eax
f0101999:	0f 85 2b 07 00 00    	jne    f01020ca <mem_init+0x10ce>
	assert(pp1->pp_ref == 1);
f010199f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01019a4:	0f 85 39 07 00 00    	jne    f01020e3 <mem_init+0x10e7>
	assert(pp2->pp_ref == 0);
f01019aa:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01019af:	0f 85 47 07 00 00    	jne    f01020fc <mem_init+0x1100>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01019b5:	6a 00                	push   $0x0
f01019b7:	68 00 10 00 00       	push   $0x1000
f01019bc:	53                   	push   %ebx
f01019bd:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019c0:	e8 d0 f5 ff ff       	call   f0100f95 <page_insert>
f01019c5:	83 c4 10             	add    $0x10,%esp
f01019c8:	85 c0                	test   %eax,%eax
f01019ca:	0f 85 45 07 00 00    	jne    f0102115 <mem_init+0x1119>
	assert(pp1->pp_ref);
f01019d0:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01019d5:	0f 84 53 07 00 00    	je     f010212e <mem_init+0x1132>
	assert(pp1->pp_link == NULL);
f01019db:	83 3b 00             	cmpl   $0x0,(%ebx)
f01019de:	0f 85 63 07 00 00    	jne    f0102147 <mem_init+0x114b>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01019e4:	83 ec 08             	sub    $0x8,%esp
f01019e7:	68 00 10 00 00       	push   $0x1000
f01019ec:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01019f2:	e8 59 f5 ff ff       	call   f0100f50 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01019f7:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f01019fc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01019ff:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a04:	e8 41 ef ff ff       	call   f010094a <check_va2pa>
f0101a09:	83 c4 10             	add    $0x10,%esp
f0101a0c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101a0f:	0f 85 4b 07 00 00    	jne    f0102160 <mem_init+0x1164>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101a15:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a1a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a1d:	e8 28 ef ff ff       	call   f010094a <check_va2pa>
f0101a22:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101a25:	0f 85 4e 07 00 00    	jne    f0102179 <mem_init+0x117d>
	assert(pp1->pp_ref == 0);
f0101a2b:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101a30:	0f 85 5c 07 00 00    	jne    f0102192 <mem_init+0x1196>
	assert(pp2->pp_ref == 0);
f0101a36:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101a3b:	0f 85 6a 07 00 00    	jne    f01021ab <mem_init+0x11af>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101a41:	83 ec 0c             	sub    $0xc,%esp
f0101a44:	6a 00                	push   $0x0
f0101a46:	e8 c6 f2 ff ff       	call   f0100d11 <page_alloc>
f0101a4b:	83 c4 10             	add    $0x10,%esp
f0101a4e:	85 c0                	test   %eax,%eax
f0101a50:	0f 84 6e 07 00 00    	je     f01021c4 <mem_init+0x11c8>
f0101a56:	39 c3                	cmp    %eax,%ebx
f0101a58:	0f 85 66 07 00 00    	jne    f01021c4 <mem_init+0x11c8>

	// should be no free memory
	assert(!page_alloc(0));
f0101a5e:	83 ec 0c             	sub    $0xc,%esp
f0101a61:	6a 00                	push   $0x0
f0101a63:	e8 a9 f2 ff ff       	call   f0100d11 <page_alloc>
f0101a68:	83 c4 10             	add    $0x10,%esp
f0101a6b:	85 c0                	test   %eax,%eax
f0101a6d:	0f 85 6a 07 00 00    	jne    f01021dd <mem_init+0x11e1>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a73:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
f0101a79:	8b 11                	mov    (%ecx),%edx
f0101a7b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a81:	89 f8                	mov    %edi,%eax
f0101a83:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0101a89:	c1 f8 03             	sar    $0x3,%eax
f0101a8c:	c1 e0 0c             	shl    $0xc,%eax
f0101a8f:	39 c2                	cmp    %eax,%edx
f0101a91:	0f 85 5f 07 00 00    	jne    f01021f6 <mem_init+0x11fa>
	kern_pgdir[0] = 0;
f0101a97:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101a9d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101aa2:	0f 85 67 07 00 00    	jne    f010220f <mem_init+0x1213>
	pp0->pp_ref = 0;
f0101aa8:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101aae:	83 ec 0c             	sub    $0xc,%esp
f0101ab1:	57                   	push   %edi
f0101ab2:	e8 cc f2 ff ff       	call   f0100d83 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101ab7:	83 c4 0c             	add    $0xc,%esp
f0101aba:	6a 01                	push   $0x1
f0101abc:	68 00 10 40 00       	push   $0x401000
f0101ac1:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101ac7:	e8 17 f3 ff ff       	call   f0100de3 <pgdir_walk>
f0101acc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101acf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101ad2:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101ad7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ada:	8b 50 04             	mov    0x4(%eax),%edx
f0101add:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ae3:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0101ae8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101aeb:	89 d1                	mov    %edx,%ecx
f0101aed:	c1 e9 0c             	shr    $0xc,%ecx
f0101af0:	83 c4 10             	add    $0x10,%esp
f0101af3:	39 c1                	cmp    %eax,%ecx
f0101af5:	0f 83 2d 07 00 00    	jae    f0102228 <mem_init+0x122c>
	assert(ptep == ptep1 + PTX(va));
f0101afb:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0101b01:	39 55 d4             	cmp    %edx,-0x2c(%ebp)
f0101b04:	0f 85 33 07 00 00    	jne    f010223d <mem_init+0x1241>
	kern_pgdir[PDX(va)] = 0;
f0101b0a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101b0d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101b14:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b1a:	89 f8                	mov    %edi,%eax
f0101b1c:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f0101b22:	c1 f8 03             	sar    $0x3,%eax
f0101b25:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b28:	89 c2                	mov    %eax,%edx
f0101b2a:	c1 ea 0c             	shr    $0xc,%edx
f0101b2d:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0101b30:	0f 86 20 07 00 00    	jbe    f0102256 <mem_init+0x125a>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101b36:	83 ec 04             	sub    $0x4,%esp
f0101b39:	68 00 10 00 00       	push   $0x1000
f0101b3e:	68 ff 00 00 00       	push   $0xff
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0101b43:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b48:	50                   	push   %eax
f0101b49:	e8 0f 18 00 00       	call   f010335d <memset>
	page_free(pp0);
f0101b4e:	89 3c 24             	mov    %edi,(%esp)
f0101b51:	e8 2d f2 ff ff       	call   f0100d83 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101b56:	83 c4 0c             	add    $0xc,%esp
f0101b59:	6a 01                	push   $0x1
f0101b5b:	6a 00                	push   $0x0
f0101b5d:	ff 35 48 79 11 f0    	pushl  0xf0117948
f0101b63:	e8 7b f2 ff ff       	call   f0100de3 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b68:	89 fa                	mov    %edi,%edx
f0101b6a:	2b 15 4c 79 11 f0    	sub    0xf011794c,%edx
f0101b70:	c1 fa 03             	sar    $0x3,%edx
f0101b73:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b76:	89 d0                	mov    %edx,%eax
f0101b78:	c1 e8 0c             	shr    $0xc,%eax
f0101b7b:	83 c4 10             	add    $0x10,%esp
f0101b7e:	3b 05 44 79 11 f0    	cmp    0xf0117944,%eax
f0101b84:	0f 83 de 06 00 00    	jae    f0102268 <mem_init+0x126c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0101b8a:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101b90:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101b93:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101b99:	f6 00 01             	testb  $0x1,(%eax)
f0101b9c:	0f 85 d8 06 00 00    	jne    f010227a <mem_init+0x127e>
f0101ba2:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0101ba5:	39 c2                	cmp    %eax,%edx
f0101ba7:	75 f0                	jne    f0101b99 <mem_init+0xb9d>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0101ba9:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101bae:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101bb4:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// give free list back
	page_free_list = fl;
f0101bba:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0101bbd:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101bc2:	83 ec 0c             	sub    $0xc,%esp
f0101bc5:	57                   	push   %edi
f0101bc6:	e8 b8 f1 ff ff       	call   f0100d83 <page_free>
	page_free(pp1);
f0101bcb:	89 1c 24             	mov    %ebx,(%esp)
f0101bce:	e8 b0 f1 ff ff       	call   f0100d83 <page_free>
	page_free(pp2);
f0101bd3:	89 34 24             	mov    %esi,(%esp)
f0101bd6:	e8 a8 f1 ff ff       	call   f0100d83 <page_free>

	cprintf("check_page() succeeded!\n");
f0101bdb:	c7 04 24 3e 47 10 f0 	movl   $0xf010473e,(%esp)
f0101be2:	e8 66 0c 00 00       	call   f010284d <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,PTSIZE,PADDR(pages),PTE_U | PTE_P);
f0101be7:	a1 4c 79 11 f0       	mov    0xf011794c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101bec:	83 c4 10             	add    $0x10,%esp
f0101bef:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101bf4:	0f 86 99 06 00 00    	jbe    f0102293 <mem_init+0x1297>
f0101bfa:	83 ec 08             	sub    $0x8,%esp
f0101bfd:	6a 05                	push   $0x5
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0101bff:	05 00 00 00 10       	add    $0x10000000,%eax
f0101c04:	50                   	push   %eax
f0101c05:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0101c0a:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0101c0f:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101c14:	e8 5c f2 ff ff       	call   f0100e75 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101c19:	83 c4 10             	add    $0x10,%esp
f0101c1c:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f0101c21:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101c26:	0f 86 7c 06 00 00    	jbe    f01022a8 <mem_init+0x12ac>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_W | PTE_P);
f0101c2c:	83 ec 08             	sub    $0x8,%esp
f0101c2f:	6a 03                	push   $0x3
f0101c31:	68 00 d0 10 00       	push   $0x10d000
f0101c36:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0101c3b:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0101c40:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101c45:	e8 2b f2 ff ff       	call   f0100e75 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir,KERNBASE,-KERNBASE,0,PTE_W | PTE_P);
f0101c4a:	83 c4 08             	add    $0x8,%esp
f0101c4d:	6a 03                	push   $0x3
f0101c4f:	6a 00                	push   $0x0
f0101c51:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0101c56:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0101c5b:	a1 48 79 11 f0       	mov    0xf0117948,%eax
f0101c60:	e8 10 f2 ff ff       	call   f0100e75 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0101c65:	8b 35 48 79 11 f0    	mov    0xf0117948,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0101c6b:	a1 44 79 11 f0       	mov    0xf0117944,%eax
f0101c70:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101c73:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0101c7a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101c7f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0101c82:	8b 3d 4c 79 11 f0    	mov    0xf011794c,%edi
f0101c88:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101c8b:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0101c8e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101c93:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101c96:	0f 86 4f 06 00 00    	jbe    f01022eb <mem_init+0x12ef>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0101c9c:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0101ca2:	89 f0                	mov    %esi,%eax
f0101ca4:	e8 a1 ec ff ff       	call   f010094a <check_va2pa>
f0101ca9:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0101cb0:	0f 86 07 06 00 00    	jbe    f01022bd <mem_init+0x12c1>
f0101cb6:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f0101cbd:	39 d0                	cmp    %edx,%eax
f0101cbf:	0f 85 0d 06 00 00    	jne    f01022d2 <mem_init+0x12d6>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0101cc5:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101ccb:	eb c6                	jmp    f0101c93 <mem_init+0xc97>
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
		--nfree;
	assert(nfree == 0);
f0101ccd:	68 67 46 10 f0       	push   $0xf0104667
f0101cd2:	68 ca 44 10 f0       	push   $0xf01044ca
f0101cd7:	68 8e 02 00 00       	push   $0x28e
f0101cdc:	68 a4 44 10 f0       	push   $0xf01044a4
f0101ce1:	e8 93 e3 ff ff       	call   f0100079 <_panic>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101ce6:	68 75 45 10 f0       	push   $0xf0104575
f0101ceb:	68 ca 44 10 f0       	push   $0xf01044ca
f0101cf0:	68 e7 02 00 00       	push   $0x2e7
f0101cf5:	68 a4 44 10 f0       	push   $0xf01044a4
f0101cfa:	e8 7a e3 ff ff       	call   f0100079 <_panic>
	assert((pp1 = page_alloc(0)));
f0101cff:	68 8b 45 10 f0       	push   $0xf010458b
f0101d04:	68 ca 44 10 f0       	push   $0xf01044ca
f0101d09:	68 e8 02 00 00       	push   $0x2e8
f0101d0e:	68 a4 44 10 f0       	push   $0xf01044a4
f0101d13:	e8 61 e3 ff ff       	call   f0100079 <_panic>
	assert((pp2 = page_alloc(0)));
f0101d18:	68 a1 45 10 f0       	push   $0xf01045a1
f0101d1d:	68 ca 44 10 f0       	push   $0xf01044ca
f0101d22:	68 e9 02 00 00       	push   $0x2e9
f0101d27:	68 a4 44 10 f0       	push   $0xf01044a4
f0101d2c:	e8 48 e3 ff ff       	call   f0100079 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101d31:	68 b7 45 10 f0       	push   $0xf01045b7
f0101d36:	68 ca 44 10 f0       	push   $0xf01044ca
f0101d3b:	68 ec 02 00 00       	push   $0x2ec
f0101d40:	68 a4 44 10 f0       	push   $0xf01044a4
f0101d45:	e8 2f e3 ff ff       	call   f0100079 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101d4a:	68 b8 3e 10 f0       	push   $0xf0103eb8
f0101d4f:	68 ca 44 10 f0       	push   $0xf01044ca
f0101d54:	68 ed 02 00 00       	push   $0x2ed
f0101d59:	68 a4 44 10 f0       	push   $0xf01044a4
f0101d5e:	e8 16 e3 ff ff       	call   f0100079 <_panic>
	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;

	// should be no free memory
	assert(!page_alloc(0));
f0101d63:	68 20 46 10 f0       	push   $0xf0104620
f0101d68:	68 ca 44 10 f0       	push   $0xf01044ca
f0101d6d:	68 f4 02 00 00       	push   $0x2f4
f0101d72:	68 a4 44 10 f0       	push   $0xf01044a4
f0101d77:	e8 fd e2 ff ff       	call   f0100079 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101d7c:	68 f8 3e 10 f0       	push   $0xf0103ef8
f0101d81:	68 ca 44 10 f0       	push   $0xf01044ca
f0101d86:	68 f7 02 00 00       	push   $0x2f7
f0101d8b:	68 a4 44 10 f0       	push   $0xf01044a4
f0101d90:	e8 e4 e2 ff ff       	call   f0100079 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101d95:	68 30 3f 10 f0       	push   $0xf0103f30
f0101d9a:	68 ca 44 10 f0       	push   $0xf01044ca
f0101d9f:	68 fa 02 00 00       	push   $0x2fa
f0101da4:	68 a4 44 10 f0       	push   $0xf01044a4
f0101da9:	e8 cb e2 ff ff       	call   f0100079 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101dae:	68 60 3f 10 f0       	push   $0xf0103f60
f0101db3:	68 ca 44 10 f0       	push   $0xf01044ca
f0101db8:	68 fe 02 00 00       	push   $0x2fe
f0101dbd:	68 a4 44 10 f0       	push   $0xf01044a4
f0101dc2:	e8 b2 e2 ff ff       	call   f0100079 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101dc7:	68 90 3f 10 f0       	push   $0xf0103f90
f0101dcc:	68 ca 44 10 f0       	push   $0xf01044ca
f0101dd1:	68 ff 02 00 00       	push   $0x2ff
f0101dd6:	68 a4 44 10 f0       	push   $0xf01044a4
f0101ddb:	e8 99 e2 ff ff       	call   f0100079 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101de0:	68 b8 3f 10 f0       	push   $0xf0103fb8
f0101de5:	68 ca 44 10 f0       	push   $0xf01044ca
f0101dea:	68 00 03 00 00       	push   $0x300
f0101def:	68 a4 44 10 f0       	push   $0xf01044a4
f0101df4:	e8 80 e2 ff ff       	call   f0100079 <_panic>
	assert(pp1->pp_ref == 1);
f0101df9:	68 72 46 10 f0       	push   $0xf0104672
f0101dfe:	68 ca 44 10 f0       	push   $0xf01044ca
f0101e03:	68 01 03 00 00       	push   $0x301
f0101e08:	68 a4 44 10 f0       	push   $0xf01044a4
f0101e0d:	e8 67 e2 ff ff       	call   f0100079 <_panic>
	assert(pp0->pp_ref == 1);
f0101e12:	68 83 46 10 f0       	push   $0xf0104683
f0101e17:	68 ca 44 10 f0       	push   $0xf01044ca
f0101e1c:	68 02 03 00 00       	push   $0x302
f0101e21:	68 a4 44 10 f0       	push   $0xf01044a4
f0101e26:	e8 4e e2 ff ff       	call   f0100079 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e2b:	68 e8 3f 10 f0       	push   $0xf0103fe8
f0101e30:	68 ca 44 10 f0       	push   $0xf01044ca
f0101e35:	68 05 03 00 00       	push   $0x305
f0101e3a:	68 a4 44 10 f0       	push   $0xf01044a4
f0101e3f:	e8 35 e2 ff ff       	call   f0100079 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e44:	68 24 40 10 f0       	push   $0xf0104024
f0101e49:	68 ca 44 10 f0       	push   $0xf01044ca
f0101e4e:	68 06 03 00 00       	push   $0x306
f0101e53:	68 a4 44 10 f0       	push   $0xf01044a4
f0101e58:	e8 1c e2 ff ff       	call   f0100079 <_panic>
	assert(pp2->pp_ref == 1);
f0101e5d:	68 94 46 10 f0       	push   $0xf0104694
f0101e62:	68 ca 44 10 f0       	push   $0xf01044ca
f0101e67:	68 07 03 00 00       	push   $0x307
f0101e6c:	68 a4 44 10 f0       	push   $0xf01044a4
f0101e71:	e8 03 e2 ff ff       	call   f0100079 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e76:	68 20 46 10 f0       	push   $0xf0104620
f0101e7b:	68 ca 44 10 f0       	push   $0xf01044ca
f0101e80:	68 0a 03 00 00       	push   $0x30a
f0101e85:	68 a4 44 10 f0       	push   $0xf01044a4
f0101e8a:	e8 ea e1 ff ff       	call   f0100079 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e8f:	68 e8 3f 10 f0       	push   $0xf0103fe8
f0101e94:	68 ca 44 10 f0       	push   $0xf01044ca
f0101e99:	68 0d 03 00 00       	push   $0x30d
f0101e9e:	68 a4 44 10 f0       	push   $0xf01044a4
f0101ea3:	e8 d1 e1 ff ff       	call   f0100079 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ea8:	68 24 40 10 f0       	push   $0xf0104024
f0101ead:	68 ca 44 10 f0       	push   $0xf01044ca
f0101eb2:	68 0e 03 00 00       	push   $0x30e
f0101eb7:	68 a4 44 10 f0       	push   $0xf01044a4
f0101ebc:	e8 b8 e1 ff ff       	call   f0100079 <_panic>
	assert(pp2->pp_ref == 1);
f0101ec1:	68 94 46 10 f0       	push   $0xf0104694
f0101ec6:	68 ca 44 10 f0       	push   $0xf01044ca
f0101ecb:	68 0f 03 00 00       	push   $0x30f
f0101ed0:	68 a4 44 10 f0       	push   $0xf01044a4
f0101ed5:	e8 9f e1 ff ff       	call   f0100079 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101eda:	68 20 46 10 f0       	push   $0xf0104620
f0101edf:	68 ca 44 10 f0       	push   $0xf01044ca
f0101ee4:	68 13 03 00 00       	push   $0x313
f0101ee9:	68 a4 44 10 f0       	push   $0xf01044a4
f0101eee:	e8 86 e1 ff ff       	call   f0100079 <_panic>

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ef3:	50                   	push   %eax
f0101ef4:	68 08 3d 10 f0       	push   $0xf0103d08
f0101ef9:	68 16 03 00 00       	push   $0x316
f0101efe:	68 a4 44 10 f0       	push   $0xf01044a4
f0101f03:	e8 71 e1 ff ff       	call   f0100079 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101f08:	68 54 40 10 f0       	push   $0xf0104054
f0101f0d:	68 ca 44 10 f0       	push   $0xf01044ca
f0101f12:	68 17 03 00 00       	push   $0x317
f0101f17:	68 a4 44 10 f0       	push   $0xf01044a4
f0101f1c:	e8 58 e1 ff ff       	call   f0100079 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101f21:	68 94 40 10 f0       	push   $0xf0104094
f0101f26:	68 ca 44 10 f0       	push   $0xf01044ca
f0101f2b:	68 1a 03 00 00       	push   $0x31a
f0101f30:	68 a4 44 10 f0       	push   $0xf01044a4
f0101f35:	e8 3f e1 ff ff       	call   f0100079 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f3a:	68 24 40 10 f0       	push   $0xf0104024
f0101f3f:	68 ca 44 10 f0       	push   $0xf01044ca
f0101f44:	68 1b 03 00 00       	push   $0x31b
f0101f49:	68 a4 44 10 f0       	push   $0xf01044a4
f0101f4e:	e8 26 e1 ff ff       	call   f0100079 <_panic>
	assert(pp2->pp_ref == 1);
f0101f53:	68 94 46 10 f0       	push   $0xf0104694
f0101f58:	68 ca 44 10 f0       	push   $0xf01044ca
f0101f5d:	68 1c 03 00 00       	push   $0x31c
f0101f62:	68 a4 44 10 f0       	push   $0xf01044a4
f0101f67:	e8 0d e1 ff ff       	call   f0100079 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101f6c:	68 d4 40 10 f0       	push   $0xf01040d4
f0101f71:	68 ca 44 10 f0       	push   $0xf01044ca
f0101f76:	68 1d 03 00 00       	push   $0x31d
f0101f7b:	68 a4 44 10 f0       	push   $0xf01044a4
f0101f80:	e8 f4 e0 ff ff       	call   f0100079 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101f85:	68 a5 46 10 f0       	push   $0xf01046a5
f0101f8a:	68 ca 44 10 f0       	push   $0xf01044ca
f0101f8f:	68 1e 03 00 00       	push   $0x31e
f0101f94:	68 a4 44 10 f0       	push   $0xf01044a4
f0101f99:	e8 db e0 ff ff       	call   f0100079 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f9e:	68 e8 3f 10 f0       	push   $0xf0103fe8
f0101fa3:	68 ca 44 10 f0       	push   $0xf01044ca
f0101fa8:	68 21 03 00 00       	push   $0x321
f0101fad:	68 a4 44 10 f0       	push   $0xf01044a4
f0101fb2:	e8 c2 e0 ff ff       	call   f0100079 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101fb7:	68 08 41 10 f0       	push   $0xf0104108
f0101fbc:	68 ca 44 10 f0       	push   $0xf01044ca
f0101fc1:	68 22 03 00 00       	push   $0x322
f0101fc6:	68 a4 44 10 f0       	push   $0xf01044a4
f0101fcb:	e8 a9 e0 ff ff       	call   f0100079 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101fd0:	68 3c 41 10 f0       	push   $0xf010413c
f0101fd5:	68 ca 44 10 f0       	push   $0xf01044ca
f0101fda:	68 23 03 00 00       	push   $0x323
f0101fdf:	68 a4 44 10 f0       	push   $0xf01044a4
f0101fe4:	e8 90 e0 ff ff       	call   f0100079 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101fe9:	68 74 41 10 f0       	push   $0xf0104174
f0101fee:	68 ca 44 10 f0       	push   $0xf01044ca
f0101ff3:	68 26 03 00 00       	push   $0x326
f0101ff8:	68 a4 44 10 f0       	push   $0xf01044a4
f0101ffd:	e8 77 e0 ff ff       	call   f0100079 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102002:	68 ac 41 10 f0       	push   $0xf01041ac
f0102007:	68 ca 44 10 f0       	push   $0xf01044ca
f010200c:	68 29 03 00 00       	push   $0x329
f0102011:	68 a4 44 10 f0       	push   $0xf01044a4
f0102016:	e8 5e e0 ff ff       	call   f0100079 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010201b:	68 3c 41 10 f0       	push   $0xf010413c
f0102020:	68 ca 44 10 f0       	push   $0xf01044ca
f0102025:	68 2a 03 00 00       	push   $0x32a
f010202a:	68 a4 44 10 f0       	push   $0xf01044a4
f010202f:	e8 45 e0 ff ff       	call   f0100079 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102034:	68 e8 41 10 f0       	push   $0xf01041e8
f0102039:	68 ca 44 10 f0       	push   $0xf01044ca
f010203e:	68 2d 03 00 00       	push   $0x32d
f0102043:	68 a4 44 10 f0       	push   $0xf01044a4
f0102048:	e8 2c e0 ff ff       	call   f0100079 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010204d:	68 14 42 10 f0       	push   $0xf0104214
f0102052:	68 ca 44 10 f0       	push   $0xf01044ca
f0102057:	68 2e 03 00 00       	push   $0x32e
f010205c:	68 a4 44 10 f0       	push   $0xf01044a4
f0102061:	e8 13 e0 ff ff       	call   f0100079 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102066:	68 bb 46 10 f0       	push   $0xf01046bb
f010206b:	68 ca 44 10 f0       	push   $0xf01044ca
f0102070:	68 30 03 00 00       	push   $0x330
f0102075:	68 a4 44 10 f0       	push   $0xf01044a4
f010207a:	e8 fa df ff ff       	call   f0100079 <_panic>
	assert(pp2->pp_ref == 0);
f010207f:	68 cc 46 10 f0       	push   $0xf01046cc
f0102084:	68 ca 44 10 f0       	push   $0xf01044ca
f0102089:	68 31 03 00 00       	push   $0x331
f010208e:	68 a4 44 10 f0       	push   $0xf01044a4
f0102093:	e8 e1 df ff ff       	call   f0100079 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102098:	68 44 42 10 f0       	push   $0xf0104244
f010209d:	68 ca 44 10 f0       	push   $0xf01044ca
f01020a2:	68 34 03 00 00       	push   $0x334
f01020a7:	68 a4 44 10 f0       	push   $0xf01044a4
f01020ac:	e8 c8 df ff ff       	call   f0100079 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020b1:	68 68 42 10 f0       	push   $0xf0104268
f01020b6:	68 ca 44 10 f0       	push   $0xf01044ca
f01020bb:	68 38 03 00 00       	push   $0x338
f01020c0:	68 a4 44 10 f0       	push   $0xf01044a4
f01020c5:	e8 af df ff ff       	call   f0100079 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020ca:	68 14 42 10 f0       	push   $0xf0104214
f01020cf:	68 ca 44 10 f0       	push   $0xf01044ca
f01020d4:	68 39 03 00 00       	push   $0x339
f01020d9:	68 a4 44 10 f0       	push   $0xf01044a4
f01020de:	e8 96 df ff ff       	call   f0100079 <_panic>
	assert(pp1->pp_ref == 1);
f01020e3:	68 72 46 10 f0       	push   $0xf0104672
f01020e8:	68 ca 44 10 f0       	push   $0xf01044ca
f01020ed:	68 3a 03 00 00       	push   $0x33a
f01020f2:	68 a4 44 10 f0       	push   $0xf01044a4
f01020f7:	e8 7d df ff ff       	call   f0100079 <_panic>
	assert(pp2->pp_ref == 0);
f01020fc:	68 cc 46 10 f0       	push   $0xf01046cc
f0102101:	68 ca 44 10 f0       	push   $0xf01044ca
f0102106:	68 3b 03 00 00       	push   $0x33b
f010210b:	68 a4 44 10 f0       	push   $0xf01044a4
f0102110:	e8 64 df ff ff       	call   f0100079 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102115:	68 8c 42 10 f0       	push   $0xf010428c
f010211a:	68 ca 44 10 f0       	push   $0xf01044ca
f010211f:	68 3e 03 00 00       	push   $0x33e
f0102124:	68 a4 44 10 f0       	push   $0xf01044a4
f0102129:	e8 4b df ff ff       	call   f0100079 <_panic>
	assert(pp1->pp_ref);
f010212e:	68 dd 46 10 f0       	push   $0xf01046dd
f0102133:	68 ca 44 10 f0       	push   $0xf01044ca
f0102138:	68 3f 03 00 00       	push   $0x33f
f010213d:	68 a4 44 10 f0       	push   $0xf01044a4
f0102142:	e8 32 df ff ff       	call   f0100079 <_panic>
	assert(pp1->pp_link == NULL);
f0102147:	68 e9 46 10 f0       	push   $0xf01046e9
f010214c:	68 ca 44 10 f0       	push   $0xf01044ca
f0102151:	68 40 03 00 00       	push   $0x340
f0102156:	68 a4 44 10 f0       	push   $0xf01044a4
f010215b:	e8 19 df ff ff       	call   f0100079 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102160:	68 68 42 10 f0       	push   $0xf0104268
f0102165:	68 ca 44 10 f0       	push   $0xf01044ca
f010216a:	68 44 03 00 00       	push   $0x344
f010216f:	68 a4 44 10 f0       	push   $0xf01044a4
f0102174:	e8 00 df ff ff       	call   f0100079 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102179:	68 c4 42 10 f0       	push   $0xf01042c4
f010217e:	68 ca 44 10 f0       	push   $0xf01044ca
f0102183:	68 45 03 00 00       	push   $0x345
f0102188:	68 a4 44 10 f0       	push   $0xf01044a4
f010218d:	e8 e7 de ff ff       	call   f0100079 <_panic>
	assert(pp1->pp_ref == 0);
f0102192:	68 fe 46 10 f0       	push   $0xf01046fe
f0102197:	68 ca 44 10 f0       	push   $0xf01044ca
f010219c:	68 46 03 00 00       	push   $0x346
f01021a1:	68 a4 44 10 f0       	push   $0xf01044a4
f01021a6:	e8 ce de ff ff       	call   f0100079 <_panic>
	assert(pp2->pp_ref == 0);
f01021ab:	68 cc 46 10 f0       	push   $0xf01046cc
f01021b0:	68 ca 44 10 f0       	push   $0xf01044ca
f01021b5:	68 47 03 00 00       	push   $0x347
f01021ba:	68 a4 44 10 f0       	push   $0xf01044a4
f01021bf:	e8 b5 de ff ff       	call   f0100079 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01021c4:	68 ec 42 10 f0       	push   $0xf01042ec
f01021c9:	68 ca 44 10 f0       	push   $0xf01044ca
f01021ce:	68 4a 03 00 00       	push   $0x34a
f01021d3:	68 a4 44 10 f0       	push   $0xf01044a4
f01021d8:	e8 9c de ff ff       	call   f0100079 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01021dd:	68 20 46 10 f0       	push   $0xf0104620
f01021e2:	68 ca 44 10 f0       	push   $0xf01044ca
f01021e7:	68 4d 03 00 00       	push   $0x34d
f01021ec:	68 a4 44 10 f0       	push   $0xf01044a4
f01021f1:	e8 83 de ff ff       	call   f0100079 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01021f6:	68 90 3f 10 f0       	push   $0xf0103f90
f01021fb:	68 ca 44 10 f0       	push   $0xf01044ca
f0102200:	68 50 03 00 00       	push   $0x350
f0102205:	68 a4 44 10 f0       	push   $0xf01044a4
f010220a:	e8 6a de ff ff       	call   f0100079 <_panic>
	kern_pgdir[0] = 0;
	assert(pp0->pp_ref == 1);
f010220f:	68 83 46 10 f0       	push   $0xf0104683
f0102214:	68 ca 44 10 f0       	push   $0xf01044ca
f0102219:	68 52 03 00 00       	push   $0x352
f010221e:	68 a4 44 10 f0       	push   $0xf01044a4
f0102223:	e8 51 de ff ff       	call   f0100079 <_panic>
f0102228:	52                   	push   %edx
f0102229:	68 08 3d 10 f0       	push   $0xf0103d08
f010222e:	68 59 03 00 00       	push   $0x359
f0102233:	68 a4 44 10 f0       	push   $0xf01044a4
f0102238:	e8 3c de ff ff       	call   f0100079 <_panic>
	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
	assert(ptep == ptep1 + PTX(va));
f010223d:	68 0f 47 10 f0       	push   $0xf010470f
f0102242:	68 ca 44 10 f0       	push   $0xf01044ca
f0102247:	68 5a 03 00 00       	push   $0x35a
f010224c:	68 a4 44 10 f0       	push   $0xf01044a4
f0102251:	e8 23 de ff ff       	call   f0100079 <_panic>
f0102256:	50                   	push   %eax
f0102257:	68 08 3d 10 f0       	push   $0xf0103d08
f010225c:	6a 52                	push   $0x52
f010225e:	68 b0 44 10 f0       	push   $0xf01044b0
f0102263:	e8 11 de ff ff       	call   f0100079 <_panic>
f0102268:	52                   	push   %edx
f0102269:	68 08 3d 10 f0       	push   $0xf0103d08
f010226e:	6a 52                	push   $0x52
f0102270:	68 b0 44 10 f0       	push   $0xf01044b0
f0102275:	e8 ff dd ff ff       	call   f0100079 <_panic>
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010227a:	68 27 47 10 f0       	push   $0xf0104727
f010227f:	68 ca 44 10 f0       	push   $0xf01044ca
f0102284:	68 64 03 00 00       	push   $0x364
f0102289:	68 a4 44 10 f0       	push   $0xf01044a4
f010228e:	e8 e6 dd ff ff       	call   f0100079 <_panic>

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102293:	50                   	push   %eax
f0102294:	68 94 3e 10 f0       	push   $0xf0103e94
f0102299:	68 bd 00 00 00       	push   $0xbd
f010229e:	68 a4 44 10 f0       	push   $0xf01044a4
f01022a3:	e8 d1 dd ff ff       	call   f0100079 <_panic>
f01022a8:	50                   	push   %eax
f01022a9:	68 94 3e 10 f0       	push   $0xf0103e94
f01022ae:	68 c9 00 00 00       	push   $0xc9
f01022b3:	68 a4 44 10 f0       	push   $0xf01044a4
f01022b8:	e8 bc dd ff ff       	call   f0100079 <_panic>
f01022bd:	57                   	push   %edi
f01022be:	68 94 3e 10 f0       	push   $0xf0103e94
f01022c3:	68 a6 02 00 00       	push   $0x2a6
f01022c8:	68 a4 44 10 f0       	push   $0xf01044a4
f01022cd:	e8 a7 dd ff ff       	call   f0100079 <_panic>
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01022d2:	68 10 43 10 f0       	push   $0xf0104310
f01022d7:	68 ca 44 10 f0       	push   $0xf01044ca
f01022dc:	68 a6 02 00 00       	push   $0x2a6
f01022e1:	68 a4 44 10 f0       	push   $0xf01044a4
f01022e6:	e8 8e dd ff ff       	call   f0100079 <_panic>


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01022eb:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01022ee:	c1 e7 0c             	shl    $0xc,%edi
f01022f1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01022f6:	eb 06                	jmp    f01022fe <mem_init+0x1302>
f01022f8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01022fe:	39 fb                	cmp    %edi,%ebx
f0102300:	73 2a                	jae    f010232c <mem_init+0x1330>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102302:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102308:	89 f0                	mov    %esi,%eax
f010230a:	e8 3b e6 ff ff       	call   f010094a <check_va2pa>
f010230f:	39 c3                	cmp    %eax,%ebx
f0102311:	74 e5                	je     f01022f8 <mem_init+0x12fc>
f0102313:	68 44 43 10 f0       	push   $0xf0104344
f0102318:	68 ca 44 10 f0       	push   $0xf01044ca
f010231d:	68 ab 02 00 00       	push   $0x2ab
f0102322:	68 a4 44 10 f0       	push   $0xf01044a4
f0102327:	e8 4d dd ff ff       	call   f0100079 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010232c:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102331:	89 da                	mov    %ebx,%edx
f0102333:	89 f0                	mov    %esi,%eax
f0102335:	e8 10 e6 ff ff       	call   f010094a <check_va2pa>
f010233a:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f0102340:	39 d0                	cmp    %edx,%eax
f0102342:	75 26                	jne    f010236a <mem_init+0x136e>
f0102344:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010234a:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102350:	75 df                	jne    f0102331 <mem_init+0x1335>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102352:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102357:	89 f0                	mov    %esi,%eax
f0102359:	e8 ec e5 ff ff       	call   f010094a <check_va2pa>
f010235e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102361:	75 20                	jne    f0102383 <mem_init+0x1387>
f0102363:	b8 00 00 00 00       	mov    $0x0,%eax
f0102368:	eb 59                	jmp    f01023c3 <mem_init+0x13c7>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010236a:	68 6c 43 10 f0       	push   $0xf010436c
f010236f:	68 ca 44 10 f0       	push   $0xf01044ca
f0102374:	68 af 02 00 00       	push   $0x2af
f0102379:	68 a4 44 10 f0       	push   $0xf01044a4
f010237e:	e8 f6 dc ff ff       	call   f0100079 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102383:	68 b4 43 10 f0       	push   $0xf01043b4
f0102388:	68 ca 44 10 f0       	push   $0xf01044ca
f010238d:	68 b0 02 00 00       	push   $0x2b0
f0102392:	68 a4 44 10 f0       	push   $0xf01044a4
f0102397:	e8 dd dc ff ff       	call   f0100079 <_panic>
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f010239c:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01023a0:	74 47                	je     f01023e9 <mem_init+0x13ed>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01023a2:	40                   	inc    %eax
f01023a3:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f01023a8:	0f 87 93 00 00 00    	ja     f0102441 <mem_init+0x1445>
		switch (i) {
f01023ae:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01023b3:	72 0e                	jb     f01023c3 <mem_init+0x13c7>
f01023b5:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01023ba:	76 e0                	jbe    f010239c <mem_init+0x13a0>
f01023bc:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023c1:	74 d9                	je     f010239c <mem_init+0x13a0>
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01023c3:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01023c8:	77 38                	ja     f0102402 <mem_init+0x1406>
				assert(pgdir[i] & PTE_P);
				assert(pgdir[i] & PTE_W);
			} else
				assert(pgdir[i] == 0);
f01023ca:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f01023ce:	74 d2                	je     f01023a2 <mem_init+0x13a6>
f01023d0:	68 79 47 10 f0       	push   $0xf0104779
f01023d5:	68 ca 44 10 f0       	push   $0xf01044ca
f01023da:	68 bf 02 00 00       	push   $0x2bf
f01023df:	68 a4 44 10 f0       	push   $0xf01044a4
f01023e4:	e8 90 dc ff ff       	call   f0100079 <_panic>
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01023e9:	68 57 47 10 f0       	push   $0xf0104757
f01023ee:	68 ca 44 10 f0       	push   $0xf01044ca
f01023f3:	68 b8 02 00 00       	push   $0x2b8
f01023f8:	68 a4 44 10 f0       	push   $0xf01044a4
f01023fd:	e8 77 dc ff ff       	call   f0100079 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
				assert(pgdir[i] & PTE_P);
f0102402:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102405:	f6 c2 01             	test   $0x1,%dl
f0102408:	74 1e                	je     f0102428 <mem_init+0x142c>
				assert(pgdir[i] & PTE_W);
f010240a:	f6 c2 02             	test   $0x2,%dl
f010240d:	75 93                	jne    f01023a2 <mem_init+0x13a6>
f010240f:	68 68 47 10 f0       	push   $0xf0104768
f0102414:	68 ca 44 10 f0       	push   $0xf01044ca
f0102419:	68 bd 02 00 00       	push   $0x2bd
f010241e:	68 a4 44 10 f0       	push   $0xf01044a4
f0102423:	e8 51 dc ff ff       	call   f0100079 <_panic>
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
				assert(pgdir[i] & PTE_P);
f0102428:	68 57 47 10 f0       	push   $0xf0104757
f010242d:	68 ca 44 10 f0       	push   $0xf01044ca
f0102432:	68 bc 02 00 00       	push   $0x2bc
f0102437:	68 a4 44 10 f0       	push   $0xf01044a4
f010243c:	e8 38 dc ff ff       	call   f0100079 <_panic>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102441:	83 ec 0c             	sub    $0xc,%esp
f0102444:	68 e4 43 10 f0       	push   $0xf01043e4
f0102449:	e8 ff 03 00 00       	call   f010284d <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010244e:	a1 48 79 11 f0       	mov    0xf0117948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102453:	83 c4 10             	add    $0x10,%esp
f0102456:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010245b:	0f 86 fe 01 00 00    	jbe    f010265f <mem_init+0x1663>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102461:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102466:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102469:	b8 00 00 00 00       	mov    $0x0,%eax
f010246e:	e8 38 e5 ff ff       	call   f01009ab <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102473:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102476:	83 e0 f3             	and    $0xfffffff3,%eax
f0102479:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010247e:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102481:	83 ec 0c             	sub    $0xc,%esp
f0102484:	6a 00                	push   $0x0
f0102486:	e8 86 e8 ff ff       	call   f0100d11 <page_alloc>
f010248b:	89 c3                	mov    %eax,%ebx
f010248d:	83 c4 10             	add    $0x10,%esp
f0102490:	85 c0                	test   %eax,%eax
f0102492:	0f 84 dc 01 00 00    	je     f0102674 <mem_init+0x1678>
	assert((pp1 = page_alloc(0)));
f0102498:	83 ec 0c             	sub    $0xc,%esp
f010249b:	6a 00                	push   $0x0
f010249d:	e8 6f e8 ff ff       	call   f0100d11 <page_alloc>
f01024a2:	89 c7                	mov    %eax,%edi
f01024a4:	83 c4 10             	add    $0x10,%esp
f01024a7:	85 c0                	test   %eax,%eax
f01024a9:	0f 84 de 01 00 00    	je     f010268d <mem_init+0x1691>
	assert((pp2 = page_alloc(0)));
f01024af:	83 ec 0c             	sub    $0xc,%esp
f01024b2:	6a 00                	push   $0x0
f01024b4:	e8 58 e8 ff ff       	call   f0100d11 <page_alloc>
f01024b9:	89 c6                	mov    %eax,%esi
f01024bb:	83 c4 10             	add    $0x10,%esp
f01024be:	85 c0                	test   %eax,%eax
f01024c0:	0f 84 e0 01 00 00    	je     f01026a6 <mem_init+0x16aa>
	page_free(pp0);
f01024c6:	83 ec 0c             	sub    $0xc,%esp
f01024c9:	53                   	push   %ebx
f01024ca:	e8 b4 e8 ff ff       	call   f0100d83 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024cf:	89 f8                	mov    %edi,%eax
f01024d1:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f01024d7:	c1 f8 03             	sar    $0x3,%eax
f01024da:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024dd:	89 c2                	mov    %eax,%edx
f01024df:	c1 ea 0c             	shr    $0xc,%edx
f01024e2:	83 c4 10             	add    $0x10,%esp
f01024e5:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f01024eb:	0f 83 ce 01 00 00    	jae    f01026bf <mem_init+0x16c3>
	memset(page2kva(pp1), 1, PGSIZE);
f01024f1:	83 ec 04             	sub    $0x4,%esp
f01024f4:	68 00 10 00 00       	push   $0x1000
f01024f9:	6a 01                	push   $0x1
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f01024fb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102500:	50                   	push   %eax
f0102501:	e8 57 0e 00 00       	call   f010335d <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102506:	89 f0                	mov    %esi,%eax
f0102508:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f010250e:	c1 f8 03             	sar    $0x3,%eax
f0102511:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102514:	89 c2                	mov    %eax,%edx
f0102516:	c1 ea 0c             	shr    $0xc,%edx
f0102519:	83 c4 10             	add    $0x10,%esp
f010251c:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f0102522:	0f 83 a9 01 00 00    	jae    f01026d1 <mem_init+0x16d5>
	memset(page2kva(pp2), 2, PGSIZE);
f0102528:	83 ec 04             	sub    $0x4,%esp
f010252b:	68 00 10 00 00       	push   $0x1000
f0102530:	6a 02                	push   $0x2
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0102532:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102537:	50                   	push   %eax
f0102538:	e8 20 0e 00 00       	call   f010335d <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010253d:	6a 02                	push   $0x2
f010253f:	68 00 10 00 00       	push   $0x1000
f0102544:	57                   	push   %edi
f0102545:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010254b:	e8 45 ea ff ff       	call   f0100f95 <page_insert>
	assert(pp1->pp_ref == 1);
f0102550:	83 c4 20             	add    $0x20,%esp
f0102553:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102558:	0f 85 85 01 00 00    	jne    f01026e3 <mem_init+0x16e7>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010255e:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102565:	01 01 01 
f0102568:	0f 85 8e 01 00 00    	jne    f01026fc <mem_init+0x1700>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010256e:	6a 02                	push   $0x2
f0102570:	68 00 10 00 00       	push   $0x1000
f0102575:	56                   	push   %esi
f0102576:	ff 35 48 79 11 f0    	pushl  0xf0117948
f010257c:	e8 14 ea ff ff       	call   f0100f95 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102581:	83 c4 10             	add    $0x10,%esp
f0102584:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010258b:	02 02 02 
f010258e:	0f 85 81 01 00 00    	jne    f0102715 <mem_init+0x1719>
	assert(pp2->pp_ref == 1);
f0102594:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102599:	0f 85 8f 01 00 00    	jne    f010272e <mem_init+0x1732>
	assert(pp1->pp_ref == 0);
f010259f:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025a4:	0f 85 9d 01 00 00    	jne    f0102747 <mem_init+0x174b>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01025aa:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01025b1:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025b4:	89 f0                	mov    %esi,%eax
f01025b6:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f01025bc:	c1 f8 03             	sar    $0x3,%eax
f01025bf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025c2:	89 c2                	mov    %eax,%edx
f01025c4:	c1 ea 0c             	shr    $0xc,%edx
f01025c7:	3b 15 44 79 11 f0    	cmp    0xf0117944,%edx
f01025cd:	0f 83 8d 01 00 00    	jae    f0102760 <mem_init+0x1764>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01025d3:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01025da:	03 03 03 
f01025dd:	0f 85 8f 01 00 00    	jne    f0102772 <mem_init+0x1776>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025e3:	83 ec 08             	sub    $0x8,%esp
f01025e6:	68 00 10 00 00       	push   $0x1000
f01025eb:	ff 35 48 79 11 f0    	pushl  0xf0117948
f01025f1:	e8 5a e9 ff ff       	call   f0100f50 <page_remove>
	assert(pp2->pp_ref == 0);
f01025f6:	83 c4 10             	add    $0x10,%esp
f01025f9:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025fe:	0f 85 87 01 00 00    	jne    f010278b <mem_init+0x178f>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102604:	8b 0d 48 79 11 f0    	mov    0xf0117948,%ecx
f010260a:	8b 11                	mov    (%ecx),%edx
f010260c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102612:	89 d8                	mov    %ebx,%eax
f0102614:	2b 05 4c 79 11 f0    	sub    0xf011794c,%eax
f010261a:	c1 f8 03             	sar    $0x3,%eax
f010261d:	c1 e0 0c             	shl    $0xc,%eax
f0102620:	39 c2                	cmp    %eax,%edx
f0102622:	0f 85 7c 01 00 00    	jne    f01027a4 <mem_init+0x17a8>
	kern_pgdir[0] = 0;
f0102628:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010262e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102633:	0f 85 84 01 00 00    	jne    f01027bd <mem_init+0x17c1>
	pp0->pp_ref = 0;
f0102639:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f010263f:	83 ec 0c             	sub    $0xc,%esp
f0102642:	53                   	push   %ebx
f0102643:	e8 3b e7 ff ff       	call   f0100d83 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102648:	c7 04 24 78 44 10 f0 	movl   $0xf0104478,(%esp)
f010264f:	e8 f9 01 00 00       	call   f010284d <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102654:	83 c4 10             	add    $0x10,%esp
f0102657:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010265a:	5b                   	pop    %ebx
f010265b:	5e                   	pop    %esi
f010265c:	5f                   	pop    %edi
f010265d:	5d                   	pop    %ebp
f010265e:	c3                   	ret    

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010265f:	50                   	push   %eax
f0102660:	68 94 3e 10 f0       	push   $0xf0103e94
f0102665:	68 de 00 00 00       	push   $0xde
f010266a:	68 a4 44 10 f0       	push   $0xf01044a4
f010266f:	e8 05 da ff ff       	call   f0100079 <_panic>
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102674:	68 75 45 10 f0       	push   $0xf0104575
f0102679:	68 ca 44 10 f0       	push   $0xf01044ca
f010267e:	68 7f 03 00 00       	push   $0x37f
f0102683:	68 a4 44 10 f0       	push   $0xf01044a4
f0102688:	e8 ec d9 ff ff       	call   f0100079 <_panic>
	assert((pp1 = page_alloc(0)));
f010268d:	68 8b 45 10 f0       	push   $0xf010458b
f0102692:	68 ca 44 10 f0       	push   $0xf01044ca
f0102697:	68 80 03 00 00       	push   $0x380
f010269c:	68 a4 44 10 f0       	push   $0xf01044a4
f01026a1:	e8 d3 d9 ff ff       	call   f0100079 <_panic>
	assert((pp2 = page_alloc(0)));
f01026a6:	68 a1 45 10 f0       	push   $0xf01045a1
f01026ab:	68 ca 44 10 f0       	push   $0xf01044ca
f01026b0:	68 81 03 00 00       	push   $0x381
f01026b5:	68 a4 44 10 f0       	push   $0xf01044a4
f01026ba:	e8 ba d9 ff ff       	call   f0100079 <_panic>

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026bf:	50                   	push   %eax
f01026c0:	68 08 3d 10 f0       	push   $0xf0103d08
f01026c5:	6a 52                	push   $0x52
f01026c7:	68 b0 44 10 f0       	push   $0xf01044b0
f01026cc:	e8 a8 d9 ff ff       	call   f0100079 <_panic>
f01026d1:	50                   	push   %eax
f01026d2:	68 08 3d 10 f0       	push   $0xf0103d08
f01026d7:	6a 52                	push   $0x52
f01026d9:	68 b0 44 10 f0       	push   $0xf01044b0
f01026de:	e8 96 d9 ff ff       	call   f0100079 <_panic>
	page_free(pp0);
	memset(page2kva(pp1), 1, PGSIZE);
	memset(page2kva(pp2), 2, PGSIZE);
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
	assert(pp1->pp_ref == 1);
f01026e3:	68 72 46 10 f0       	push   $0xf0104672
f01026e8:	68 ca 44 10 f0       	push   $0xf01044ca
f01026ed:	68 86 03 00 00       	push   $0x386
f01026f2:	68 a4 44 10 f0       	push   $0xf01044a4
f01026f7:	e8 7d d9 ff ff       	call   f0100079 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01026fc:	68 04 44 10 f0       	push   $0xf0104404
f0102701:	68 ca 44 10 f0       	push   $0xf01044ca
f0102706:	68 87 03 00 00       	push   $0x387
f010270b:	68 a4 44 10 f0       	push   $0xf01044a4
f0102710:	e8 64 d9 ff ff       	call   f0100079 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102715:	68 28 44 10 f0       	push   $0xf0104428
f010271a:	68 ca 44 10 f0       	push   $0xf01044ca
f010271f:	68 89 03 00 00       	push   $0x389
f0102724:	68 a4 44 10 f0       	push   $0xf01044a4
f0102729:	e8 4b d9 ff ff       	call   f0100079 <_panic>
	assert(pp2->pp_ref == 1);
f010272e:	68 94 46 10 f0       	push   $0xf0104694
f0102733:	68 ca 44 10 f0       	push   $0xf01044ca
f0102738:	68 8a 03 00 00       	push   $0x38a
f010273d:	68 a4 44 10 f0       	push   $0xf01044a4
f0102742:	e8 32 d9 ff ff       	call   f0100079 <_panic>
	assert(pp1->pp_ref == 0);
f0102747:	68 fe 46 10 f0       	push   $0xf01046fe
f010274c:	68 ca 44 10 f0       	push   $0xf01044ca
f0102751:	68 8b 03 00 00       	push   $0x38b
f0102756:	68 a4 44 10 f0       	push   $0xf01044a4
f010275b:	e8 19 d9 ff ff       	call   f0100079 <_panic>
f0102760:	50                   	push   %eax
f0102761:	68 08 3d 10 f0       	push   $0xf0103d08
f0102766:	6a 52                	push   $0x52
f0102768:	68 b0 44 10 f0       	push   $0xf01044b0
f010276d:	e8 07 d9 ff ff       	call   f0100079 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102772:	68 4c 44 10 f0       	push   $0xf010444c
f0102777:	68 ca 44 10 f0       	push   $0xf01044ca
f010277c:	68 8d 03 00 00       	push   $0x38d
f0102781:	68 a4 44 10 f0       	push   $0xf01044a4
f0102786:	e8 ee d8 ff ff       	call   f0100079 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
	assert(pp2->pp_ref == 0);
f010278b:	68 cc 46 10 f0       	push   $0xf01046cc
f0102790:	68 ca 44 10 f0       	push   $0xf01044ca
f0102795:	68 8f 03 00 00       	push   $0x38f
f010279a:	68 a4 44 10 f0       	push   $0xf01044a4
f010279f:	e8 d5 d8 ff ff       	call   f0100079 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01027a4:	68 90 3f 10 f0       	push   $0xf0103f90
f01027a9:	68 ca 44 10 f0       	push   $0xf01044ca
f01027ae:	68 92 03 00 00       	push   $0x392
f01027b3:	68 a4 44 10 f0       	push   $0xf01044a4
f01027b8:	e8 bc d8 ff ff       	call   f0100079 <_panic>
	kern_pgdir[0] = 0;
	assert(pp0->pp_ref == 1);
f01027bd:	68 83 46 10 f0       	push   $0xf0104683
f01027c2:	68 ca 44 10 f0       	push   $0xf01044ca
f01027c7:	68 94 03 00 00       	push   $0x394
f01027cc:	68 a4 44 10 f0       	push   $0xf01044a4
f01027d1:	e8 a3 d8 ff ff       	call   f0100079 <_panic>

f01027d6 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01027d6:	55                   	push   %ebp
f01027d7:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01027d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027dc:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01027df:	5d                   	pop    %ebp
f01027e0:	c3                   	ret    
f01027e1:	00 00                	add    %al,(%eax)
	...

f01027e4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01027e4:	55                   	push   %ebp
f01027e5:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01027e7:	ba 70 00 00 00       	mov    $0x70,%edx
f01027ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01027ef:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01027f0:	ba 71 00 00 00       	mov    $0x71,%edx
f01027f5:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01027f6:	0f b6 c0             	movzbl %al,%eax
}
f01027f9:	5d                   	pop    %ebp
f01027fa:	c3                   	ret    

f01027fb <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01027fb:	55                   	push   %ebp
f01027fc:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01027fe:	ba 70 00 00 00       	mov    $0x70,%edx
f0102803:	8b 45 08             	mov    0x8(%ebp),%eax
f0102806:	ee                   	out    %al,(%dx)
f0102807:	ba 71 00 00 00       	mov    $0x71,%edx
f010280c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010280f:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102810:	5d                   	pop    %ebp
f0102811:	c3                   	ret    
	...

f0102814 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102814:	55                   	push   %ebp
f0102815:	89 e5                	mov    %esp,%ebp
f0102817:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010281a:	ff 75 08             	pushl  0x8(%ebp)
f010281d:	e8 a1 dd ff ff       	call   f01005c3 <cputchar>
	*cnt++;
}
f0102822:	83 c4 10             	add    $0x10,%esp
f0102825:	c9                   	leave  
f0102826:	c3                   	ret    

f0102827 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102827:	55                   	push   %ebp
f0102828:	89 e5                	mov    %esp,%ebp
f010282a:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010282d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102834:	ff 75 0c             	pushl  0xc(%ebp)
f0102837:	ff 75 08             	pushl  0x8(%ebp)
f010283a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010283d:	50                   	push   %eax
f010283e:	68 14 28 10 f0       	push   $0xf0102814
f0102843:	e8 2e 04 00 00       	call   f0102c76 <vprintfmt>
	return cnt;
}
f0102848:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010284b:	c9                   	leave  
f010284c:	c3                   	ret    

f010284d <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010284d:	55                   	push   %ebp
f010284e:	89 e5                	mov    %esp,%ebp
f0102850:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102853:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102856:	50                   	push   %eax
f0102857:	ff 75 08             	pushl  0x8(%ebp)
f010285a:	e8 c8 ff ff ff       	call   f0102827 <vcprintf>
	va_end(ap);

	return cnt;
}
f010285f:	c9                   	leave  
f0102860:	c3                   	ret    
f0102861:	00 00                	add    %al,(%eax)
	...

f0102864 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102864:	55                   	push   %ebp
f0102865:	89 e5                	mov    %esp,%ebp
f0102867:	57                   	push   %edi
f0102868:	56                   	push   %esi
f0102869:	53                   	push   %ebx
f010286a:	83 ec 14             	sub    $0x14,%esp
f010286d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102870:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102873:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102876:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102879:	8b 1a                	mov    (%edx),%ebx
f010287b:	8b 01                	mov    (%ecx),%eax
f010287d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102880:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0102887:	eb 34                	jmp    f01028bd <stab_binsearch+0x59>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0102889:	48                   	dec    %eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010288a:	39 c3                	cmp    %eax,%ebx
f010288c:	7f 2c                	jg     f01028ba <stab_binsearch+0x56>
f010288e:	0f b6 0a             	movzbl (%edx),%ecx
f0102891:	83 ea 0c             	sub    $0xc,%edx
f0102894:	39 f9                	cmp    %edi,%ecx
f0102896:	75 f1                	jne    f0102889 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102898:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010289b:	01 c2                	add    %eax,%edx
f010289d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01028a0:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01028a4:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01028a7:	76 37                	jbe    f01028e0 <stab_binsearch+0x7c>
			*region_left = m;
f01028a9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01028ac:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01028ae:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01028b1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01028b8:	eb 03                	jmp    f01028bd <stab_binsearch+0x59>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01028ba:	8d 5e 01             	lea    0x1(%esi),%ebx
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01028bd:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01028c0:	7f 48                	jg     f010290a <stab_binsearch+0xa6>
		int true_m = (l + r) / 2, m = true_m;
f01028c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01028c5:	01 d8                	add    %ebx,%eax
f01028c7:	89 c6                	mov    %eax,%esi
f01028c9:	c1 ee 1f             	shr    $0x1f,%esi
f01028cc:	01 c6                	add    %eax,%esi
f01028ce:	d1 fe                	sar    %esi
f01028d0:	8d 04 36             	lea    (%esi,%esi,1),%eax
f01028d3:	01 f0                	add    %esi,%eax
f01028d5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01028d8:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01028dc:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01028de:	eb aa                	jmp    f010288a <stab_binsearch+0x26>
		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01028e0:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01028e3:	73 12                	jae    f01028f7 <stab_binsearch+0x93>
			*region_right = m - 1;
f01028e5:	48                   	dec    %eax
f01028e6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01028e9:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01028ec:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01028ee:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01028f5:	eb c6                	jmp    f01028bd <stab_binsearch+0x59>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01028f7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01028fa:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01028fc:	ff 45 0c             	incl   0xc(%ebp)
f01028ff:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102901:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102908:	eb b3                	jmp    f01028bd <stab_binsearch+0x59>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010290a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010290e:	74 18                	je     f0102928 <stab_binsearch+0xc4>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102910:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102913:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102915:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102918:	8b 0e                	mov    (%esi),%ecx
f010291a:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010291d:	01 c2                	add    %eax,%edx
f010291f:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0102922:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102926:	eb 0e                	jmp    f0102936 <stab_binsearch+0xd2>
			addr++;
		}
	}

	if (!any_matches)
		*region_right = *region_left - 1;
f0102928:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010292b:	8b 00                	mov    (%eax),%eax
f010292d:	48                   	dec    %eax
f010292e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0102931:	89 07                	mov    %eax,(%edi)
f0102933:	eb 14                	jmp    f0102949 <stab_binsearch+0xe5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102935:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102936:	39 c8                	cmp    %ecx,%eax
f0102938:	7e 0a                	jle    f0102944 <stab_binsearch+0xe0>
		     l > *region_left && stabs[l].n_type != type;
f010293a:	0f b6 1a             	movzbl (%edx),%ebx
f010293d:	83 ea 0c             	sub    $0xc,%edx
f0102940:	39 df                	cmp    %ebx,%edi
f0102942:	75 f1                	jne    f0102935 <stab_binsearch+0xd1>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102944:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102947:	89 07                	mov    %eax,(%edi)
	}
}
f0102949:	83 c4 14             	add    $0x14,%esp
f010294c:	5b                   	pop    %ebx
f010294d:	5e                   	pop    %esi
f010294e:	5f                   	pop    %edi
f010294f:	5d                   	pop    %ebp
f0102950:	c3                   	ret    

f0102951 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102951:	55                   	push   %ebp
f0102952:	89 e5                	mov    %esp,%ebp
f0102954:	57                   	push   %edi
f0102955:	56                   	push   %esi
f0102956:	53                   	push   %ebx
f0102957:	83 ec 3c             	sub    $0x3c,%esp
f010295a:	8b 75 08             	mov    0x8(%ebp),%esi
f010295d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102960:	c7 03 87 47 10 f0    	movl   $0xf0104787,(%ebx)
	info->eip_line = 0;
f0102966:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010296d:	c7 43 08 87 47 10 f0 	movl   $0xf0104787,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102974:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010297b:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010297e:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102985:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010298b:	0f 86 3a 01 00 00    	jbe    f0102acb <debuginfo_eip+0x17a>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102991:	b8 c5 ca 10 f0       	mov    $0xf010cac5,%eax
f0102996:	3d 29 ad 10 f0       	cmp    $0xf010ad29,%eax
f010299b:	0f 86 bf 01 00 00    	jbe    f0102b60 <debuginfo_eip+0x20f>
f01029a1:	80 3d c4 ca 10 f0 00 	cmpb   $0x0,0xf010cac4
f01029a8:	0f 85 b9 01 00 00    	jne    f0102b67 <debuginfo_eip+0x216>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01029ae:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01029b5:	ba 28 ad 10 f0       	mov    $0xf010ad28,%edx
f01029ba:	81 ea bc 49 10 f0    	sub    $0xf01049bc,%edx
f01029c0:	c1 fa 02             	sar    $0x2,%edx
f01029c3:	8d 04 92             	lea    (%edx,%edx,4),%eax
f01029c6:	8d 04 82             	lea    (%edx,%eax,4),%eax
f01029c9:	8d 04 82             	lea    (%edx,%eax,4),%eax
f01029cc:	89 c1                	mov    %eax,%ecx
f01029ce:	c1 e1 08             	shl    $0x8,%ecx
f01029d1:	01 c8                	add    %ecx,%eax
f01029d3:	89 c1                	mov    %eax,%ecx
f01029d5:	c1 e1 10             	shl    $0x10,%ecx
f01029d8:	01 c8                	add    %ecx,%eax
f01029da:	01 c0                	add    %eax,%eax
f01029dc:	8d 44 02 ff          	lea    -0x1(%edx,%eax,1),%eax
f01029e0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01029e3:	83 ec 08             	sub    $0x8,%esp
f01029e6:	56                   	push   %esi
f01029e7:	6a 64                	push   $0x64
f01029e9:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01029ec:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01029ef:	b8 bc 49 10 f0       	mov    $0xf01049bc,%eax
f01029f4:	e8 6b fe ff ff       	call   f0102864 <stab_binsearch>
	if (lfile == 0)
f01029f9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01029fc:	83 c4 10             	add    $0x10,%esp
f01029ff:	85 c0                	test   %eax,%eax
f0102a01:	0f 84 67 01 00 00    	je     f0102b6e <debuginfo_eip+0x21d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102a07:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102a0a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102a0d:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102a10:	83 ec 08             	sub    $0x8,%esp
f0102a13:	56                   	push   %esi
f0102a14:	6a 24                	push   $0x24
f0102a16:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102a19:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102a1c:	b8 bc 49 10 f0       	mov    $0xf01049bc,%eax
f0102a21:	e8 3e fe ff ff       	call   f0102864 <stab_binsearch>

	if (lfun <= rfun) {
f0102a26:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102a29:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102a2c:	83 c4 10             	add    $0x10,%esp
f0102a2f:	39 d0                	cmp    %edx,%eax
f0102a31:	0f 8f a8 00 00 00    	jg     f0102adf <debuginfo_eip+0x18e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102a37:	8d 0c 00             	lea    (%eax,%eax,1),%ecx
f0102a3a:	01 c1                	add    %eax,%ecx
f0102a3c:	c1 e1 02             	shl    $0x2,%ecx
f0102a3f:	8d b9 bc 49 10 f0    	lea    -0xfefb644(%ecx),%edi
f0102a45:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102a48:	8b 89 bc 49 10 f0    	mov    -0xfefb644(%ecx),%ecx
f0102a4e:	bf c5 ca 10 f0       	mov    $0xf010cac5,%edi
f0102a53:	81 ef 29 ad 10 f0    	sub    $0xf010ad29,%edi
f0102a59:	39 f9                	cmp    %edi,%ecx
f0102a5b:	73 09                	jae    f0102a66 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102a5d:	81 c1 29 ad 10 f0    	add    $0xf010ad29,%ecx
f0102a63:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102a66:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102a69:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102a6c:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102a6f:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102a71:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102a74:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102a77:	83 ec 08             	sub    $0x8,%esp
f0102a7a:	6a 3a                	push   $0x3a
f0102a7c:	ff 73 08             	pushl  0x8(%ebx)
f0102a7f:	e8 c1 08 00 00       	call   f0103345 <strfind>
f0102a84:	2b 43 08             	sub    0x8(%ebx),%eax
f0102a87:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102a8a:	83 c4 08             	add    $0x8,%esp
f0102a8d:	56                   	push   %esi
f0102a8e:	6a 44                	push   $0x44
f0102a90:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102a93:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102a96:	b8 bc 49 10 f0       	mov    $0xf01049bc,%eax
f0102a9b:	e8 c4 fd ff ff       	call   f0102864 <stab_binsearch>
	if (lline <= rline) {
f0102aa0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102aa3:	83 c4 10             	add    $0x10,%esp
f0102aa6:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0102aa9:	0f 8f c6 00 00 00    	jg     f0102b75 <debuginfo_eip+0x224>
		info->eip_line = stabs[lline].n_desc;
f0102aaf:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0102ab2:	01 d0                	add    %edx,%eax
f0102ab4:	c1 e0 02             	shl    $0x2,%eax
f0102ab7:	0f b7 88 c2 49 10 f0 	movzwl -0xfefb63e(%eax),%ecx
f0102abe:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102ac1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102ac4:	05 c0 49 10 f0       	add    $0xf01049c0,%eax
f0102ac9:	eb 29                	jmp    f0102af4 <debuginfo_eip+0x1a3>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102acb:	83 ec 04             	sub    $0x4,%esp
f0102ace:	68 91 47 10 f0       	push   $0xf0104791
f0102ad3:	6a 7f                	push   $0x7f
f0102ad5:	68 9e 47 10 f0       	push   $0xf010479e
f0102ada:	e8 9a d5 ff ff       	call   f0100079 <_panic>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102adf:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102ae2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ae5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102ae8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102aeb:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102aee:	eb 87                	jmp    f0102a77 <debuginfo_eip+0x126>
f0102af0:	4a                   	dec    %edx
f0102af1:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102af4:	39 d6                	cmp    %edx,%esi
f0102af6:	7f 34                	jg     f0102b2c <debuginfo_eip+0x1db>
	       && stabs[lline].n_type != N_SOL
f0102af8:	8a 08                	mov    (%eax),%cl
f0102afa:	80 f9 84             	cmp    $0x84,%cl
f0102afd:	74 0b                	je     f0102b0a <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102aff:	80 f9 64             	cmp    $0x64,%cl
f0102b02:	75 ec                	jne    f0102af0 <debuginfo_eip+0x19f>
f0102b04:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0102b08:	74 e6                	je     f0102af0 <debuginfo_eip+0x19f>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102b0a:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0102b0d:	01 c2                	add    %eax,%edx
f0102b0f:	8b 14 95 bc 49 10 f0 	mov    -0xfefb644(,%edx,4),%edx
f0102b16:	b8 c5 ca 10 f0       	mov    $0xf010cac5,%eax
f0102b1b:	2d 29 ad 10 f0       	sub    $0xf010ad29,%eax
f0102b20:	39 c2                	cmp    %eax,%edx
f0102b22:	73 08                	jae    f0102b2c <debuginfo_eip+0x1db>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102b24:	81 c2 29 ad 10 f0    	add    $0xf010ad29,%edx
f0102b2a:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102b2c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102b2f:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0102b32:	39 f2                	cmp    %esi,%edx
f0102b34:	7d 46                	jge    f0102b7c <debuginfo_eip+0x22b>
		for (lline = lfun + 1;
f0102b36:	42                   	inc    %edx
f0102b37:	89 d0                	mov    %edx,%eax
f0102b39:	8d 0c 12             	lea    (%edx,%edx,1),%ecx
f0102b3c:	01 ca                	add    %ecx,%edx
f0102b3e:	8d 14 95 c0 49 10 f0 	lea    -0xfefb640(,%edx,4),%edx
f0102b45:	eb 03                	jmp    f0102b4a <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102b47:	ff 43 14             	incl   0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102b4a:	39 c6                	cmp    %eax,%esi
f0102b4c:	7e 3b                	jle    f0102b89 <debuginfo_eip+0x238>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102b4e:	8a 0a                	mov    (%edx),%cl
f0102b50:	40                   	inc    %eax
f0102b51:	83 c2 0c             	add    $0xc,%edx
f0102b54:	80 f9 a0             	cmp    $0xa0,%cl
f0102b57:	74 ee                	je     f0102b47 <debuginfo_eip+0x1f6>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b59:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b5e:	eb 21                	jmp    f0102b81 <debuginfo_eip+0x230>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102b60:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b65:	eb 1a                	jmp    f0102b81 <debuginfo_eip+0x230>
f0102b67:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b6c:	eb 13                	jmp    f0102b81 <debuginfo_eip+0x230>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102b6e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b73:	eb 0c                	jmp    f0102b81 <debuginfo_eip+0x230>

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline <= rline) {
		info->eip_line = stabs[lline].n_desc;
	} else {
		return -1;
f0102b75:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102b7a:	eb 05                	jmp    f0102b81 <debuginfo_eip+0x230>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b7c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102b81:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b84:	5b                   	pop    %ebx
f0102b85:	5e                   	pop    %esi
f0102b86:	5f                   	pop    %edi
f0102b87:	5d                   	pop    %ebp
f0102b88:	c3                   	ret    
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102b89:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b8e:	eb f1                	jmp    f0102b81 <debuginfo_eip+0x230>

f0102b90 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102b90:	55                   	push   %ebp
f0102b91:	89 e5                	mov    %esp,%ebp
f0102b93:	57                   	push   %edi
f0102b94:	56                   	push   %esi
f0102b95:	53                   	push   %ebx
f0102b96:	83 ec 1c             	sub    $0x1c,%esp
f0102b99:	89 c7                	mov    %eax,%edi
f0102b9b:	89 d6                	mov    %edx,%esi
f0102b9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ba0:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102ba3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ba6:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102ba9:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102bac:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102bb1:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102bb4:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102bb7:	39 d3                	cmp    %edx,%ebx
f0102bb9:	72 05                	jb     f0102bc0 <printnum+0x30>
f0102bbb:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102bbe:	77 78                	ja     f0102c38 <printnum+0xa8>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102bc0:	83 ec 0c             	sub    $0xc,%esp
f0102bc3:	ff 75 18             	pushl  0x18(%ebp)
f0102bc6:	8b 45 14             	mov    0x14(%ebp),%eax
f0102bc9:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102bcc:	53                   	push   %ebx
f0102bcd:	ff 75 10             	pushl  0x10(%ebp)
f0102bd0:	83 ec 08             	sub    $0x8,%esp
f0102bd3:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102bd6:	ff 75 e0             	pushl  -0x20(%ebp)
f0102bd9:	ff 75 dc             	pushl  -0x24(%ebp)
f0102bdc:	ff 75 d8             	pushl  -0x28(%ebp)
f0102bdf:	e8 5c 09 00 00       	call   f0103540 <__udivdi3>
f0102be4:	83 c4 18             	add    $0x18,%esp
f0102be7:	52                   	push   %edx
f0102be8:	50                   	push   %eax
f0102be9:	89 f2                	mov    %esi,%edx
f0102beb:	89 f8                	mov    %edi,%eax
f0102bed:	e8 9e ff ff ff       	call   f0102b90 <printnum>
f0102bf2:	83 c4 20             	add    $0x20,%esp
f0102bf5:	eb 11                	jmp    f0102c08 <printnum+0x78>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102bf7:	83 ec 08             	sub    $0x8,%esp
f0102bfa:	56                   	push   %esi
f0102bfb:	ff 75 18             	pushl  0x18(%ebp)
f0102bfe:	ff d7                	call   *%edi
f0102c00:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102c03:	4b                   	dec    %ebx
f0102c04:	85 db                	test   %ebx,%ebx
f0102c06:	7f ef                	jg     f0102bf7 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102c08:	83 ec 08             	sub    $0x8,%esp
f0102c0b:	56                   	push   %esi
f0102c0c:	83 ec 04             	sub    $0x4,%esp
f0102c0f:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102c12:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c15:	ff 75 dc             	pushl  -0x24(%ebp)
f0102c18:	ff 75 d8             	pushl  -0x28(%ebp)
f0102c1b:	e8 30 0a 00 00       	call   f0103650 <__umoddi3>
f0102c20:	83 c4 14             	add    $0x14,%esp
f0102c23:	0f be 80 ac 47 10 f0 	movsbl -0xfefb854(%eax),%eax
f0102c2a:	50                   	push   %eax
f0102c2b:	ff d7                	call   *%edi
}
f0102c2d:	83 c4 10             	add    $0x10,%esp
f0102c30:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c33:	5b                   	pop    %ebx
f0102c34:	5e                   	pop    %esi
f0102c35:	5f                   	pop    %edi
f0102c36:	5d                   	pop    %ebp
f0102c37:	c3                   	ret    
f0102c38:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0102c3b:	eb c6                	jmp    f0102c03 <printnum+0x73>

f0102c3d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102c3d:	55                   	push   %ebp
f0102c3e:	89 e5                	mov    %esp,%ebp
f0102c40:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102c43:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f0102c46:	8b 10                	mov    (%eax),%edx
f0102c48:	3b 50 04             	cmp    0x4(%eax),%edx
f0102c4b:	73 0a                	jae    f0102c57 <sprintputch+0x1a>
		*b->buf++ = ch;
f0102c4d:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102c50:	89 08                	mov    %ecx,(%eax)
f0102c52:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c55:	88 02                	mov    %al,(%edx)
}
f0102c57:	5d                   	pop    %ebp
f0102c58:	c3                   	ret    

f0102c59 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102c59:	55                   	push   %ebp
f0102c5a:	89 e5                	mov    %esp,%ebp
f0102c5c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102c5f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102c62:	50                   	push   %eax
f0102c63:	ff 75 10             	pushl  0x10(%ebp)
f0102c66:	ff 75 0c             	pushl  0xc(%ebp)
f0102c69:	ff 75 08             	pushl  0x8(%ebp)
f0102c6c:	e8 05 00 00 00       	call   f0102c76 <vprintfmt>
	va_end(ap);
}
f0102c71:	83 c4 10             	add    $0x10,%esp
f0102c74:	c9                   	leave  
f0102c75:	c3                   	ret    

f0102c76 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102c76:	55                   	push   %ebp
f0102c77:	89 e5                	mov    %esp,%ebp
f0102c79:	57                   	push   %edi
f0102c7a:	56                   	push   %esi
f0102c7b:	53                   	push   %ebx
f0102c7c:	83 ec 2c             	sub    $0x2c,%esp
f0102c7f:	8b 75 08             	mov    0x8(%ebp),%esi
f0102c82:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102c85:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102c88:	e9 79 03 00 00       	jmp    f0103006 <vprintfmt+0x390>
f0102c8d:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102c91:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102c98:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c9f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102ca6:	b9 00 00 00 00       	mov    $0x0,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cab:	8d 47 01             	lea    0x1(%edi),%eax
f0102cae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102cb1:	8a 17                	mov    (%edi),%dl
f0102cb3:	8d 42 dd             	lea    -0x23(%edx),%eax
f0102cb6:	3c 55                	cmp    $0x55,%al
f0102cb8:	0f 87 c9 03 00 00    	ja     f0103087 <vprintfmt+0x411>
f0102cbe:	0f b6 c0             	movzbl %al,%eax
f0102cc1:	ff 24 85 38 48 10 f0 	jmp    *-0xfefb7c8(,%eax,4)
f0102cc8:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102ccb:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0102ccf:	eb da                	jmp    f0102cab <vprintfmt+0x35>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cd1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102cd4:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102cd8:	eb d1                	jmp    f0102cab <vprintfmt+0x35>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102cda:	0f b6 d2             	movzbl %dl,%edx
f0102cdd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ce0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ce5:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102ce8:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102ceb:	01 c0                	add    %eax,%eax
f0102ced:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
				ch = *fmt;
f0102cf1:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102cf4:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102cf7:	83 f9 09             	cmp    $0x9,%ecx
f0102cfa:	77 52                	ja     f0102d4e <vprintfmt+0xd8>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102cfc:	47                   	inc    %edi
				precision = precision * 10 + ch - '0';
f0102cfd:	eb e9                	jmp    f0102ce8 <vprintfmt+0x72>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102cff:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d02:	8b 00                	mov    (%eax),%eax
f0102d04:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102d07:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d0a:	8d 40 04             	lea    0x4(%eax),%eax
f0102d0d:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d10:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0102d13:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d17:	79 92                	jns    f0102cab <vprintfmt+0x35>
				width = precision, precision = -1;
f0102d19:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102d1c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102d1f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102d26:	eb 83                	jmp    f0102cab <vprintfmt+0x35>
f0102d28:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102d2c:	78 08                	js     f0102d36 <vprintfmt+0xc0>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d2e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d31:	e9 75 ff ff ff       	jmp    f0102cab <vprintfmt+0x35>
f0102d36:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102d3d:	eb ef                	jmp    f0102d2e <vprintfmt+0xb8>
f0102d3f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102d42:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102d49:	e9 5d ff ff ff       	jmp    f0102cab <vprintfmt+0x35>
f0102d4e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102d51:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102d54:	eb bd                	jmp    f0102d13 <vprintfmt+0x9d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102d56:	41                   	inc    %ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d57:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102d5a:	e9 4c ff ff ff       	jmp    f0102cab <vprintfmt+0x35>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102d5f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d62:	8d 78 04             	lea    0x4(%eax),%edi
f0102d65:	83 ec 08             	sub    $0x8,%esp
f0102d68:	53                   	push   %ebx
f0102d69:	ff 30                	pushl  (%eax)
f0102d6b:	ff d6                	call   *%esi
			break;
f0102d6d:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102d70:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0102d73:	e9 8b 02 00 00       	jmp    f0103003 <vprintfmt+0x38d>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102d78:	8b 45 14             	mov    0x14(%ebp),%eax
f0102d7b:	8d 78 04             	lea    0x4(%eax),%edi
f0102d7e:	8b 00                	mov    (%eax),%eax
f0102d80:	85 c0                	test   %eax,%eax
f0102d82:	78 2a                	js     f0102dae <vprintfmt+0x138>
f0102d84:	89 c2                	mov    %eax,%edx
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102d86:	83 f8 06             	cmp    $0x6,%eax
f0102d89:	7f 27                	jg     f0102db2 <vprintfmt+0x13c>
f0102d8b:	8b 04 85 90 49 10 f0 	mov    -0xfefb670(,%eax,4),%eax
f0102d92:	85 c0                	test   %eax,%eax
f0102d94:	74 1c                	je     f0102db2 <vprintfmt+0x13c>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0102d96:	50                   	push   %eax
f0102d97:	68 dc 44 10 f0       	push   $0xf01044dc
f0102d9c:	53                   	push   %ebx
f0102d9d:	56                   	push   %esi
f0102d9e:	e8 b6 fe ff ff       	call   f0102c59 <printfmt>
f0102da3:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102da6:	89 7d 14             	mov    %edi,0x14(%ebp)
f0102da9:	e9 55 02 00 00       	jmp    f0103003 <vprintfmt+0x38d>
f0102dae:	f7 d8                	neg    %eax
f0102db0:	eb d2                	jmp    f0102d84 <vprintfmt+0x10e>
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102db2:	52                   	push   %edx
f0102db3:	68 c4 47 10 f0       	push   $0xf01047c4
f0102db8:	53                   	push   %ebx
f0102db9:	56                   	push   %esi
f0102dba:	e8 9a fe ff ff       	call   f0102c59 <printfmt>
f0102dbf:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102dc2:	89 7d 14             	mov    %edi,0x14(%ebp)
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102dc5:	e9 39 02 00 00       	jmp    f0103003 <vprintfmt+0x38d>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102dca:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dcd:	83 c0 04             	add    $0x4,%eax
f0102dd0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102dd3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dd6:	8b 38                	mov    (%eax),%edi
f0102dd8:	85 ff                	test   %edi,%edi
f0102dda:	74 39                	je     f0102e15 <vprintfmt+0x19f>
				p = "(null)";
			if (width > 0 && padc != '-')
f0102ddc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102de0:	0f 8e a9 00 00 00    	jle    f0102e8f <vprintfmt+0x219>
f0102de6:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102dea:	0f 84 a7 00 00 00    	je     f0102e97 <vprintfmt+0x221>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102df0:	83 ec 08             	sub    $0x8,%esp
f0102df3:	ff 75 d0             	pushl  -0x30(%ebp)
f0102df6:	57                   	push   %edi
f0102df7:	e8 1e 04 00 00       	call   f010321a <strnlen>
f0102dfc:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102dff:	29 c1                	sub    %eax,%ecx
f0102e01:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102e04:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102e07:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102e0b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102e0e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102e11:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e13:	eb 14                	jmp    f0102e29 <vprintfmt+0x1b3>
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
f0102e15:	bf bd 47 10 f0       	mov    $0xf01047bd,%edi
f0102e1a:	eb c0                	jmp    f0102ddc <vprintfmt+0x166>
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
f0102e1c:	83 ec 08             	sub    $0x8,%esp
f0102e1f:	53                   	push   %ebx
f0102e20:	ff 75 e0             	pushl  -0x20(%ebp)
f0102e23:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e25:	4f                   	dec    %edi
f0102e26:	83 c4 10             	add    $0x10,%esp
f0102e29:	85 ff                	test   %edi,%edi
f0102e2b:	7f ef                	jg     f0102e1c <vprintfmt+0x1a6>
f0102e2d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102e30:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102e33:	89 c8                	mov    %ecx,%eax
f0102e35:	85 c9                	test   %ecx,%ecx
f0102e37:	78 10                	js     f0102e49 <vprintfmt+0x1d3>
f0102e39:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102e3c:	29 c1                	sub    %eax,%ecx
f0102e3e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102e41:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e44:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e47:	eb 15                	jmp    f0102e5e <vprintfmt+0x1e8>
f0102e49:	b8 00 00 00 00       	mov    $0x0,%eax
f0102e4e:	eb e9                	jmp    f0102e39 <vprintfmt+0x1c3>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
f0102e50:	83 ec 08             	sub    $0x8,%esp
f0102e53:	53                   	push   %ebx
f0102e54:	52                   	push   %edx
f0102e55:	ff 55 08             	call   *0x8(%ebp)
f0102e58:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102e5b:	ff 4d e0             	decl   -0x20(%ebp)
f0102e5e:	47                   	inc    %edi
f0102e5f:	8a 47 ff             	mov    -0x1(%edi),%al
f0102e62:	0f be d0             	movsbl %al,%edx
f0102e65:	85 d2                	test   %edx,%edx
f0102e67:	74 59                	je     f0102ec2 <vprintfmt+0x24c>
f0102e69:	85 f6                	test   %esi,%esi
f0102e6b:	78 03                	js     f0102e70 <vprintfmt+0x1fa>
f0102e6d:	4e                   	dec    %esi
f0102e6e:	78 2f                	js     f0102e9f <vprintfmt+0x229>
				if (altflag && (ch < ' ' || ch > '~'))
f0102e70:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102e74:	74 da                	je     f0102e50 <vprintfmt+0x1da>
f0102e76:	0f be c0             	movsbl %al,%eax
f0102e79:	83 e8 20             	sub    $0x20,%eax
f0102e7c:	83 f8 5e             	cmp    $0x5e,%eax
f0102e7f:	76 cf                	jbe    f0102e50 <vprintfmt+0x1da>
					putch('?', putdat);
f0102e81:	83 ec 08             	sub    $0x8,%esp
f0102e84:	53                   	push   %ebx
f0102e85:	6a 3f                	push   $0x3f
f0102e87:	ff 55 08             	call   *0x8(%ebp)
f0102e8a:	83 c4 10             	add    $0x10,%esp
f0102e8d:	eb cc                	jmp    f0102e5b <vprintfmt+0x1e5>
f0102e8f:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e92:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e95:	eb c7                	jmp    f0102e5e <vprintfmt+0x1e8>
f0102e97:	89 75 08             	mov    %esi,0x8(%ebp)
f0102e9a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102e9d:	eb bf                	jmp    f0102e5e <vprintfmt+0x1e8>
f0102e9f:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ea2:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0102ea5:	eb 0c                	jmp    f0102eb3 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102ea7:	83 ec 08             	sub    $0x8,%esp
f0102eaa:	53                   	push   %ebx
f0102eab:	6a 20                	push   $0x20
f0102ead:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102eaf:	4f                   	dec    %edi
f0102eb0:	83 c4 10             	add    $0x10,%esp
f0102eb3:	85 ff                	test   %edi,%edi
f0102eb5:	7f f0                	jg     f0102ea7 <vprintfmt+0x231>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102eb7:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102eba:	89 45 14             	mov    %eax,0x14(%ebp)
f0102ebd:	e9 41 01 00 00       	jmp    f0103003 <vprintfmt+0x38d>
f0102ec2:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0102ec5:	8b 75 08             	mov    0x8(%ebp),%esi
f0102ec8:	eb e9                	jmp    f0102eb3 <vprintfmt+0x23d>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102eca:	83 f9 01             	cmp    $0x1,%ecx
f0102ecd:	7f 1f                	jg     f0102eee <vprintfmt+0x278>
		return va_arg(*ap, long long);
	else if (lflag)
f0102ecf:	85 c9                	test   %ecx,%ecx
f0102ed1:	75 48                	jne    f0102f1b <vprintfmt+0x2a5>
		return va_arg(*ap, long);
	else
		return va_arg(*ap, int);
f0102ed3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ed6:	8b 00                	mov    (%eax),%eax
f0102ed8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102edb:	89 c1                	mov    %eax,%ecx
f0102edd:	c1 f9 1f             	sar    $0x1f,%ecx
f0102ee0:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102ee3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ee6:	8d 40 04             	lea    0x4(%eax),%eax
f0102ee9:	89 45 14             	mov    %eax,0x14(%ebp)
f0102eec:	eb 17                	jmp    f0102f05 <vprintfmt+0x28f>
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, long long);
f0102eee:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ef1:	8b 50 04             	mov    0x4(%eax),%edx
f0102ef4:	8b 00                	mov    (%eax),%eax
f0102ef6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102ef9:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102efc:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eff:	8d 40 08             	lea    0x8(%eax),%eax
f0102f02:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102f05:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102f08:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
f0102f0b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102f0f:	78 25                	js     f0102f36 <vprintfmt+0x2c0>
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102f11:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102f16:	e9 ce 00 00 00       	jmp    f0102fe9 <vprintfmt+0x373>
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, long long);
	else if (lflag)
		return va_arg(*ap, long);
f0102f1b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f1e:	8b 00                	mov    (%eax),%eax
f0102f20:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f23:	89 c1                	mov    %eax,%ecx
f0102f25:	c1 f9 1f             	sar    $0x1f,%ecx
f0102f28:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102f2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f2e:	8d 40 04             	lea    0x4(%eax),%eax
f0102f31:	89 45 14             	mov    %eax,0x14(%ebp)
f0102f34:	eb cf                	jmp    f0102f05 <vprintfmt+0x28f>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
f0102f36:	83 ec 08             	sub    $0x8,%esp
f0102f39:	53                   	push   %ebx
f0102f3a:	6a 2d                	push   $0x2d
f0102f3c:	ff d6                	call   *%esi
				num = -(long long) num;
f0102f3e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102f41:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102f44:	f7 da                	neg    %edx
f0102f46:	83 d1 00             	adc    $0x0,%ecx
f0102f49:	f7 d9                	neg    %ecx
f0102f4b:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102f4e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102f53:	e9 91 00 00 00       	jmp    f0102fe9 <vprintfmt+0x373>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102f58:	83 f9 01             	cmp    $0x1,%ecx
f0102f5b:	7f 1b                	jg     f0102f78 <vprintfmt+0x302>
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0102f5d:	85 c9                	test   %ecx,%ecx
f0102f5f:	75 2c                	jne    f0102f8d <vprintfmt+0x317>
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0102f61:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f64:	8b 10                	mov    (%eax),%edx
f0102f66:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f6b:	8d 40 04             	lea    0x4(%eax),%eax
f0102f6e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102f71:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102f76:	eb 71                	jmp    f0102fe9 <vprintfmt+0x373>
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
f0102f78:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f7b:	8b 10                	mov    (%eax),%edx
f0102f7d:	8b 48 04             	mov    0x4(%eax),%ecx
f0102f80:	8d 40 08             	lea    0x8(%eax),%eax
f0102f83:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102f86:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102f8b:	eb 5c                	jmp    f0102fe9 <vprintfmt+0x373>
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
f0102f8d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f90:	8b 10                	mov    (%eax),%edx
f0102f92:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102f97:	8d 40 04             	lea    0x4(%eax),%eax
f0102f9a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0102f9d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102fa2:	eb 45                	jmp    f0102fe9 <vprintfmt+0x373>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0102fa4:	83 ec 08             	sub    $0x8,%esp
f0102fa7:	53                   	push   %ebx
f0102fa8:	6a 58                	push   $0x58
f0102faa:	ff d6                	call   *%esi
			putch('X', putdat);
f0102fac:	83 c4 08             	add    $0x8,%esp
f0102faf:	53                   	push   %ebx
f0102fb0:	6a 58                	push   $0x58
f0102fb2:	ff d6                	call   *%esi
			putch('X', putdat);
f0102fb4:	83 c4 08             	add    $0x8,%esp
f0102fb7:	53                   	push   %ebx
f0102fb8:	6a 58                	push   $0x58
f0102fba:	ff d6                	call   *%esi
			break;
f0102fbc:	83 c4 10             	add    $0x10,%esp
f0102fbf:	eb 42                	jmp    f0103003 <vprintfmt+0x38d>

		// pointer
		case 'p':
			putch('0', putdat);
f0102fc1:	83 ec 08             	sub    $0x8,%esp
f0102fc4:	53                   	push   %ebx
f0102fc5:	6a 30                	push   $0x30
f0102fc7:	ff d6                	call   *%esi
			putch('x', putdat);
f0102fc9:	83 c4 08             	add    $0x8,%esp
f0102fcc:	53                   	push   %ebx
f0102fcd:	6a 78                	push   $0x78
f0102fcf:	ff d6                	call   *%esi
			num = (unsigned long long)
f0102fd1:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fd4:	8b 10                	mov    (%eax),%edx
f0102fd6:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102fdb:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102fde:	8d 40 04             	lea    0x4(%eax),%eax
f0102fe1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0102fe4:	b8 10 00 00 00       	mov    $0x10,%eax
		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102fe9:	83 ec 0c             	sub    $0xc,%esp
f0102fec:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102ff0:	57                   	push   %edi
f0102ff1:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ff4:	50                   	push   %eax
f0102ff5:	51                   	push   %ecx
f0102ff6:	52                   	push   %edx
f0102ff7:	89 da                	mov    %ebx,%edx
f0102ff9:	89 f0                	mov    %esi,%eax
f0102ffb:	e8 90 fb ff ff       	call   f0102b90 <printnum>
			break;
f0103000:	83 c4 20             	add    $0x20,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103003:	8b 7d e4             	mov    -0x1c(%ebp),%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103006:	47                   	inc    %edi
f0103007:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f010300b:	83 f8 25             	cmp    $0x25,%eax
f010300e:	0f 84 79 fc ff ff    	je     f0102c8d <vprintfmt+0x17>
			if (ch == '\0')
f0103014:	85 c0                	test   %eax,%eax
f0103016:	0f 84 89 00 00 00    	je     f01030a5 <vprintfmt+0x42f>
				return;
			putch(ch, putdat);
f010301c:	83 ec 08             	sub    $0x8,%esp
f010301f:	53                   	push   %ebx
f0103020:	50                   	push   %eax
f0103021:	ff d6                	call   *%esi
f0103023:	83 c4 10             	add    $0x10,%esp
f0103026:	eb de                	jmp    f0103006 <vprintfmt+0x390>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103028:	83 f9 01             	cmp    $0x1,%ecx
f010302b:	7f 1b                	jg     f0103048 <vprintfmt+0x3d2>
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f010302d:	85 c9                	test   %ecx,%ecx
f010302f:	75 2c                	jne    f010305d <vprintfmt+0x3e7>
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103031:	8b 45 14             	mov    0x14(%ebp),%eax
f0103034:	8b 10                	mov    (%eax),%edx
f0103036:	b9 00 00 00 00       	mov    $0x0,%ecx
f010303b:	8d 40 04             	lea    0x4(%eax),%eax
f010303e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103041:	b8 10 00 00 00       	mov    $0x10,%eax
f0103046:	eb a1                	jmp    f0102fe9 <vprintfmt+0x373>
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
f0103048:	8b 45 14             	mov    0x14(%ebp),%eax
f010304b:	8b 10                	mov    (%eax),%edx
f010304d:	8b 48 04             	mov    0x4(%eax),%ecx
f0103050:	8d 40 08             	lea    0x8(%eax),%eax
f0103053:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103056:	b8 10 00 00 00       	mov    $0x10,%eax
f010305b:	eb 8c                	jmp    f0102fe9 <vprintfmt+0x373>
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
f010305d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103060:	8b 10                	mov    (%eax),%edx
f0103062:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103067:	8d 40 04             	lea    0x4(%eax),%eax
f010306a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010306d:	b8 10 00 00 00       	mov    $0x10,%eax
f0103072:	e9 72 ff ff ff       	jmp    f0102fe9 <vprintfmt+0x373>
			printnum(putch, putdat, num, base, width, padc);
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103077:	83 ec 08             	sub    $0x8,%esp
f010307a:	53                   	push   %ebx
f010307b:	6a 25                	push   $0x25
f010307d:	ff d6                	call   *%esi
			break;
f010307f:	83 c4 10             	add    $0x10,%esp
f0103082:	e9 7c ff ff ff       	jmp    f0103003 <vprintfmt+0x38d>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103087:	83 ec 08             	sub    $0x8,%esp
f010308a:	53                   	push   %ebx
f010308b:	6a 25                	push   $0x25
f010308d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010308f:	83 c4 10             	add    $0x10,%esp
f0103092:	89 f8                	mov    %edi,%eax
f0103094:	eb 01                	jmp    f0103097 <vprintfmt+0x421>
f0103096:	48                   	dec    %eax
f0103097:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f010309b:	75 f9                	jne    f0103096 <vprintfmt+0x420>
f010309d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01030a0:	e9 5e ff ff ff       	jmp    f0103003 <vprintfmt+0x38d>
				/* do nothing */;
			break;
		}
	}
}
f01030a5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01030a8:	5b                   	pop    %ebx
f01030a9:	5e                   	pop    %esi
f01030aa:	5f                   	pop    %edi
f01030ab:	5d                   	pop    %ebp
f01030ac:	c3                   	ret    

f01030ad <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01030ad:	55                   	push   %ebp
f01030ae:	89 e5                	mov    %esp,%ebp
f01030b0:	83 ec 18             	sub    $0x18,%esp
f01030b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01030b6:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01030b9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01030bc:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01030c0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01030c3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01030ca:	85 c0                	test   %eax,%eax
f01030cc:	74 26                	je     f01030f4 <vsnprintf+0x47>
f01030ce:	85 d2                	test   %edx,%edx
f01030d0:	7e 29                	jle    f01030fb <vsnprintf+0x4e>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01030d2:	ff 75 14             	pushl  0x14(%ebp)
f01030d5:	ff 75 10             	pushl  0x10(%ebp)
f01030d8:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01030db:	50                   	push   %eax
f01030dc:	68 3d 2c 10 f0       	push   $0xf0102c3d
f01030e1:	e8 90 fb ff ff       	call   f0102c76 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01030e6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01030e9:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01030ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01030ef:	83 c4 10             	add    $0x10,%esp
}
f01030f2:	c9                   	leave  
f01030f3:	c3                   	ret    
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01030f4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01030f9:	eb f7                	jmp    f01030f2 <vsnprintf+0x45>
f01030fb:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103100:	eb f0                	jmp    f01030f2 <vsnprintf+0x45>

f0103102 <snprintf>:
	return b.cnt;
}

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103102:	55                   	push   %ebp
f0103103:	89 e5                	mov    %esp,%ebp
f0103105:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103108:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010310b:	50                   	push   %eax
f010310c:	ff 75 10             	pushl  0x10(%ebp)
f010310f:	ff 75 0c             	pushl  0xc(%ebp)
f0103112:	ff 75 08             	pushl  0x8(%ebp)
f0103115:	e8 93 ff ff ff       	call   f01030ad <vsnprintf>
	va_end(ap);

	return rc;
}
f010311a:	c9                   	leave  
f010311b:	c3                   	ret    

f010311c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010311c:	55                   	push   %ebp
f010311d:	89 e5                	mov    %esp,%ebp
f010311f:	57                   	push   %edi
f0103120:	56                   	push   %esi
f0103121:	53                   	push   %ebx
f0103122:	83 ec 0c             	sub    $0xc,%esp
f0103125:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103128:	85 c0                	test   %eax,%eax
f010312a:	74 11                	je     f010313d <readline+0x21>
		cprintf("%s", prompt);
f010312c:	83 ec 08             	sub    $0x8,%esp
f010312f:	50                   	push   %eax
f0103130:	68 dc 44 10 f0       	push   $0xf01044dc
f0103135:	e8 13 f7 ff ff       	call   f010284d <cprintf>
f010313a:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010313d:	83 ec 0c             	sub    $0xc,%esp
f0103140:	6a 00                	push   $0x0
f0103142:	e8 9d d4 ff ff       	call   f01005e4 <iscons>
f0103147:	89 c7                	mov    %eax,%edi
f0103149:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010314c:	be 00 00 00 00       	mov    $0x0,%esi
f0103151:	eb 6f                	jmp    f01031c2 <readline+0xa6>
	echoing = iscons(0);
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103153:	83 ec 08             	sub    $0x8,%esp
f0103156:	50                   	push   %eax
f0103157:	68 ac 49 10 f0       	push   $0xf01049ac
f010315c:	e8 ec f6 ff ff       	call   f010284d <cprintf>
			return NULL;
f0103161:	83 c4 10             	add    $0x10,%esp
f0103164:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103169:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010316c:	5b                   	pop    %ebx
f010316d:	5e                   	pop    %esi
f010316e:	5f                   	pop    %edi
f010316f:	5d                   	pop    %ebp
f0103170:	c3                   	ret    
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
			if (echoing)
				cputchar('\b');
f0103171:	83 ec 0c             	sub    $0xc,%esp
f0103174:	6a 08                	push   $0x8
f0103176:	e8 48 d4 ff ff       	call   f01005c3 <cputchar>
f010317b:	83 c4 10             	add    $0x10,%esp
f010317e:	eb 41                	jmp    f01031c1 <readline+0xa5>
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
f0103180:	83 ec 0c             	sub    $0xc,%esp
f0103183:	53                   	push   %ebx
f0103184:	e8 3a d4 ff ff       	call   f01005c3 <cputchar>
f0103189:	83 c4 10             	add    $0x10,%esp
f010318c:	eb 5a                	jmp    f01031e8 <readline+0xcc>
			buf[i++] = c;
		} else if (c == '\n' || c == '\r') {
f010318e:	83 fb 0a             	cmp    $0xa,%ebx
f0103191:	74 05                	je     f0103198 <readline+0x7c>
f0103193:	83 fb 0d             	cmp    $0xd,%ebx
f0103196:	75 2a                	jne    f01031c2 <readline+0xa6>
			if (echoing)
f0103198:	85 ff                	test   %edi,%edi
f010319a:	75 0e                	jne    f01031aa <readline+0x8e>
				cputchar('\n');
			buf[i] = 0;
f010319c:	c6 86 40 75 11 f0 00 	movb   $0x0,-0xfee8ac0(%esi)
			return buf;
f01031a3:	b8 40 75 11 f0       	mov    $0xf0117540,%eax
f01031a8:	eb bf                	jmp    f0103169 <readline+0x4d>
			if (echoing)
				cputchar(c);
			buf[i++] = c;
		} else if (c == '\n' || c == '\r') {
			if (echoing)
				cputchar('\n');
f01031aa:	83 ec 0c             	sub    $0xc,%esp
f01031ad:	6a 0a                	push   $0xa
f01031af:	e8 0f d4 ff ff       	call   f01005c3 <cputchar>
f01031b4:	83 c4 10             	add    $0x10,%esp
f01031b7:	eb e3                	jmp    f010319c <readline+0x80>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01031b9:	85 f6                	test   %esi,%esi
f01031bb:	7e 3c                	jle    f01031f9 <readline+0xdd>
			if (echoing)
f01031bd:	85 ff                	test   %edi,%edi
f01031bf:	75 b0                	jne    f0103171 <readline+0x55>
				cputchar('\b');
			i--;
f01031c1:	4e                   	dec    %esi
		cprintf("%s", prompt);

	i = 0;
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01031c2:	e8 0c d4 ff ff       	call   f01005d3 <getchar>
f01031c7:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01031c9:	85 c0                	test   %eax,%eax
f01031cb:	78 86                	js     f0103153 <readline+0x37>
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01031cd:	83 f8 08             	cmp    $0x8,%eax
f01031d0:	74 21                	je     f01031f3 <readline+0xd7>
f01031d2:	83 f8 7f             	cmp    $0x7f,%eax
f01031d5:	74 e2                	je     f01031b9 <readline+0x9d>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f01031d7:	83 f8 1f             	cmp    $0x1f,%eax
f01031da:	7e b2                	jle    f010318e <readline+0x72>
f01031dc:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01031e2:	7f aa                	jg     f010318e <readline+0x72>
			if (echoing)
f01031e4:	85 ff                	test   %edi,%edi
f01031e6:	75 98                	jne    f0103180 <readline+0x64>
				cputchar(c);
			buf[i++] = c;
f01031e8:	88 9e 40 75 11 f0    	mov    %bl,-0xfee8ac0(%esi)
f01031ee:	8d 76 01             	lea    0x1(%esi),%esi
f01031f1:	eb cf                	jmp    f01031c2 <readline+0xa6>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01031f3:	85 f6                	test   %esi,%esi
f01031f5:	7f c6                	jg     f01031bd <readline+0xa1>
f01031f7:	eb c9                	jmp    f01031c2 <readline+0xa6>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f01031f9:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01031ff:	7e e3                	jle    f01031e4 <readline+0xc8>
f0103201:	eb bf                	jmp    f01031c2 <readline+0xa6>
	...

f0103204 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103204:	55                   	push   %ebp
f0103205:	89 e5                	mov    %esp,%ebp
f0103207:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010320a:	b8 00 00 00 00       	mov    $0x0,%eax
f010320f:	eb 01                	jmp    f0103212 <strlen+0xe>
		n++;
f0103211:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103212:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103216:	75 f9                	jne    f0103211 <strlen+0xd>
		n++;
	return n;
}
f0103218:	5d                   	pop    %ebp
f0103219:	c3                   	ret    

f010321a <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010321a:	55                   	push   %ebp
f010321b:	89 e5                	mov    %esp,%ebp
f010321d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103220:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103223:	b8 00 00 00 00       	mov    $0x0,%eax
f0103228:	eb 01                	jmp    f010322b <strnlen+0x11>
		n++;
f010322a:	40                   	inc    %eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010322b:	39 d0                	cmp    %edx,%eax
f010322d:	74 06                	je     f0103235 <strnlen+0x1b>
f010322f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103233:	75 f5                	jne    f010322a <strnlen+0x10>
		n++;
	return n;
}
f0103235:	5d                   	pop    %ebp
f0103236:	c3                   	ret    

f0103237 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103237:	55                   	push   %ebp
f0103238:	89 e5                	mov    %esp,%ebp
f010323a:	53                   	push   %ebx
f010323b:	8b 45 08             	mov    0x8(%ebp),%eax
f010323e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103241:	89 c2                	mov    %eax,%edx
f0103243:	42                   	inc    %edx
f0103244:	41                   	inc    %ecx
f0103245:	8a 59 ff             	mov    -0x1(%ecx),%bl
f0103248:	88 5a ff             	mov    %bl,-0x1(%edx)
f010324b:	84 db                	test   %bl,%bl
f010324d:	75 f4                	jne    f0103243 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010324f:	5b                   	pop    %ebx
f0103250:	5d                   	pop    %ebp
f0103251:	c3                   	ret    

f0103252 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103252:	55                   	push   %ebp
f0103253:	89 e5                	mov    %esp,%ebp
f0103255:	53                   	push   %ebx
f0103256:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103259:	53                   	push   %ebx
f010325a:	e8 a5 ff ff ff       	call   f0103204 <strlen>
f010325f:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103262:	ff 75 0c             	pushl  0xc(%ebp)
f0103265:	01 d8                	add    %ebx,%eax
f0103267:	50                   	push   %eax
f0103268:	e8 ca ff ff ff       	call   f0103237 <strcpy>
	return dst;
}
f010326d:	89 d8                	mov    %ebx,%eax
f010326f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103272:	c9                   	leave  
f0103273:	c3                   	ret    

f0103274 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103274:	55                   	push   %ebp
f0103275:	89 e5                	mov    %esp,%ebp
f0103277:	56                   	push   %esi
f0103278:	53                   	push   %ebx
f0103279:	8b 75 08             	mov    0x8(%ebp),%esi
f010327c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010327f:	89 f3                	mov    %esi,%ebx
f0103281:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103284:	89 f2                	mov    %esi,%edx
f0103286:	eb 0c                	jmp    f0103294 <strncpy+0x20>
		*dst++ = *src;
f0103288:	42                   	inc    %edx
f0103289:	8a 01                	mov    (%ecx),%al
f010328b:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010328e:	80 39 01             	cmpb   $0x1,(%ecx)
f0103291:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103294:	39 da                	cmp    %ebx,%edx
f0103296:	75 f0                	jne    f0103288 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103298:	89 f0                	mov    %esi,%eax
f010329a:	5b                   	pop    %ebx
f010329b:	5e                   	pop    %esi
f010329c:	5d                   	pop    %ebp
f010329d:	c3                   	ret    

f010329e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010329e:	55                   	push   %ebp
f010329f:	89 e5                	mov    %esp,%ebp
f01032a1:	56                   	push   %esi
f01032a2:	53                   	push   %ebx
f01032a3:	8b 75 08             	mov    0x8(%ebp),%esi
f01032a6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032a9:	8b 45 10             	mov    0x10(%ebp),%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01032ac:	85 c0                	test   %eax,%eax
f01032ae:	74 20                	je     f01032d0 <strlcpy+0x32>
f01032b0:	8d 5c 06 ff          	lea    -0x1(%esi,%eax,1),%ebx
f01032b4:	89 f0                	mov    %esi,%eax
f01032b6:	eb 05                	jmp    f01032bd <strlcpy+0x1f>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01032b8:	40                   	inc    %eax
f01032b9:	42                   	inc    %edx
f01032ba:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01032bd:	39 d8                	cmp    %ebx,%eax
f01032bf:	74 06                	je     f01032c7 <strlcpy+0x29>
f01032c1:	8a 0a                	mov    (%edx),%cl
f01032c3:	84 c9                	test   %cl,%cl
f01032c5:	75 f1                	jne    f01032b8 <strlcpy+0x1a>
			*dst++ = *src++;
		*dst = '\0';
f01032c7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01032ca:	29 f0                	sub    %esi,%eax
}
f01032cc:	5b                   	pop    %ebx
f01032cd:	5e                   	pop    %esi
f01032ce:	5d                   	pop    %ebp
f01032cf:	c3                   	ret    
f01032d0:	89 f0                	mov    %esi,%eax
f01032d2:	eb f6                	jmp    f01032ca <strlcpy+0x2c>

f01032d4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01032d4:	55                   	push   %ebp
f01032d5:	89 e5                	mov    %esp,%ebp
f01032d7:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01032da:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01032dd:	eb 02                	jmp    f01032e1 <strcmp+0xd>
		p++, q++;
f01032df:	41                   	inc    %ecx
f01032e0:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01032e1:	8a 01                	mov    (%ecx),%al
f01032e3:	84 c0                	test   %al,%al
f01032e5:	74 04                	je     f01032eb <strcmp+0x17>
f01032e7:	3a 02                	cmp    (%edx),%al
f01032e9:	74 f4                	je     f01032df <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01032eb:	0f b6 c0             	movzbl %al,%eax
f01032ee:	0f b6 12             	movzbl (%edx),%edx
f01032f1:	29 d0                	sub    %edx,%eax
}
f01032f3:	5d                   	pop    %ebp
f01032f4:	c3                   	ret    

f01032f5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01032f5:	55                   	push   %ebp
f01032f6:	89 e5                	mov    %esp,%ebp
f01032f8:	53                   	push   %ebx
f01032f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01032fc:	8b 55 0c             	mov    0xc(%ebp),%edx
f01032ff:	89 c3                	mov    %eax,%ebx
f0103301:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103304:	eb 02                	jmp    f0103308 <strncmp+0x13>
		n--, p++, q++;
f0103306:	40                   	inc    %eax
f0103307:	42                   	inc    %edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103308:	39 d8                	cmp    %ebx,%eax
f010330a:	74 15                	je     f0103321 <strncmp+0x2c>
f010330c:	8a 08                	mov    (%eax),%cl
f010330e:	84 c9                	test   %cl,%cl
f0103310:	74 04                	je     f0103316 <strncmp+0x21>
f0103312:	3a 0a                	cmp    (%edx),%cl
f0103314:	74 f0                	je     f0103306 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103316:	0f b6 00             	movzbl (%eax),%eax
f0103319:	0f b6 12             	movzbl (%edx),%edx
f010331c:	29 d0                	sub    %edx,%eax
}
f010331e:	5b                   	pop    %ebx
f010331f:	5d                   	pop    %ebp
f0103320:	c3                   	ret    
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103321:	b8 00 00 00 00       	mov    $0x0,%eax
f0103326:	eb f6                	jmp    f010331e <strncmp+0x29>

f0103328 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103328:	55                   	push   %ebp
f0103329:	89 e5                	mov    %esp,%ebp
f010332b:	8b 45 08             	mov    0x8(%ebp),%eax
f010332e:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f0103331:	8a 10                	mov    (%eax),%dl
f0103333:	84 d2                	test   %dl,%dl
f0103335:	74 07                	je     f010333e <strchr+0x16>
		if (*s == c)
f0103337:	38 ca                	cmp    %cl,%dl
f0103339:	74 08                	je     f0103343 <strchr+0x1b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010333b:	40                   	inc    %eax
f010333c:	eb f3                	jmp    f0103331 <strchr+0x9>
		if (*s == c)
			return (char *) s;
	return 0;
f010333e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103343:	5d                   	pop    %ebp
f0103344:	c3                   	ret    

f0103345 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103345:	55                   	push   %ebp
f0103346:	89 e5                	mov    %esp,%ebp
f0103348:	8b 45 08             	mov    0x8(%ebp),%eax
f010334b:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010334e:	8a 10                	mov    (%eax),%dl
f0103350:	84 d2                	test   %dl,%dl
f0103352:	74 07                	je     f010335b <strfind+0x16>
		if (*s == c)
f0103354:	38 ca                	cmp    %cl,%dl
f0103356:	74 03                	je     f010335b <strfind+0x16>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103358:	40                   	inc    %eax
f0103359:	eb f3                	jmp    f010334e <strfind+0x9>
		if (*s == c)
			break;
	return (char *) s;
}
f010335b:	5d                   	pop    %ebp
f010335c:	c3                   	ret    

f010335d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010335d:	55                   	push   %ebp
f010335e:	89 e5                	mov    %esp,%ebp
f0103360:	57                   	push   %edi
f0103361:	56                   	push   %esi
f0103362:	53                   	push   %ebx
f0103363:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103366:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103369:	85 c9                	test   %ecx,%ecx
f010336b:	74 13                	je     f0103380 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010336d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103373:	75 05                	jne    f010337a <memset+0x1d>
f0103375:	f6 c1 03             	test   $0x3,%cl
f0103378:	74 0d                	je     f0103387 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010337a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010337d:	fc                   	cld    
f010337e:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103380:	89 f8                	mov    %edi,%eax
f0103382:	5b                   	pop    %ebx
f0103383:	5e                   	pop    %esi
f0103384:	5f                   	pop    %edi
f0103385:	5d                   	pop    %ebp
f0103386:	c3                   	ret    
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
f0103387:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010338b:	89 d3                	mov    %edx,%ebx
f010338d:	c1 e3 08             	shl    $0x8,%ebx
f0103390:	89 d0                	mov    %edx,%eax
f0103392:	c1 e0 18             	shl    $0x18,%eax
f0103395:	89 d6                	mov    %edx,%esi
f0103397:	c1 e6 10             	shl    $0x10,%esi
f010339a:	09 f0                	or     %esi,%eax
f010339c:	09 c2                	or     %eax,%edx
f010339e:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01033a0:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01033a3:	89 d0                	mov    %edx,%eax
f01033a5:	fc                   	cld    
f01033a6:	f3 ab                	rep stos %eax,%es:(%edi)
f01033a8:	eb d6                	jmp    f0103380 <memset+0x23>

f01033aa <memmove>:
	return v;
}

void *
memmove(void *dst, const void *src, size_t n)
{
f01033aa:	55                   	push   %ebp
f01033ab:	89 e5                	mov    %esp,%ebp
f01033ad:	57                   	push   %edi
f01033ae:	56                   	push   %esi
f01033af:	8b 45 08             	mov    0x8(%ebp),%eax
f01033b2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01033b5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01033b8:	39 c6                	cmp    %eax,%esi
f01033ba:	73 33                	jae    f01033ef <memmove+0x45>
f01033bc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01033bf:	39 d0                	cmp    %edx,%eax
f01033c1:	73 2c                	jae    f01033ef <memmove+0x45>
		s += n;
		d += n;
f01033c3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01033c6:	89 d6                	mov    %edx,%esi
f01033c8:	09 fe                	or     %edi,%esi
f01033ca:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01033d0:	75 13                	jne    f01033e5 <memmove+0x3b>
f01033d2:	f6 c1 03             	test   $0x3,%cl
f01033d5:	75 0e                	jne    f01033e5 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01033d7:	83 ef 04             	sub    $0x4,%edi
f01033da:	8d 72 fc             	lea    -0x4(%edx),%esi
f01033dd:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01033e0:	fd                   	std    
f01033e1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01033e3:	eb 07                	jmp    f01033ec <memmove+0x42>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01033e5:	4f                   	dec    %edi
f01033e6:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01033e9:	fd                   	std    
f01033ea:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01033ec:	fc                   	cld    
f01033ed:	eb 13                	jmp    f0103402 <memmove+0x58>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01033ef:	89 f2                	mov    %esi,%edx
f01033f1:	09 c2                	or     %eax,%edx
f01033f3:	f6 c2 03             	test   $0x3,%dl
f01033f6:	75 05                	jne    f01033fd <memmove+0x53>
f01033f8:	f6 c1 03             	test   $0x3,%cl
f01033fb:	74 09                	je     f0103406 <memmove+0x5c>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01033fd:	89 c7                	mov    %eax,%edi
f01033ff:	fc                   	cld    
f0103400:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103402:	5e                   	pop    %esi
f0103403:	5f                   	pop    %edi
f0103404:	5d                   	pop    %ebp
f0103405:	c3                   	ret    
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103406:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103409:	89 c7                	mov    %eax,%edi
f010340b:	fc                   	cld    
f010340c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010340e:	eb f2                	jmp    f0103402 <memmove+0x58>

f0103410 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103410:	55                   	push   %ebp
f0103411:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103413:	ff 75 10             	pushl  0x10(%ebp)
f0103416:	ff 75 0c             	pushl  0xc(%ebp)
f0103419:	ff 75 08             	pushl  0x8(%ebp)
f010341c:	e8 89 ff ff ff       	call   f01033aa <memmove>
}
f0103421:	c9                   	leave  
f0103422:	c3                   	ret    

f0103423 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103423:	55                   	push   %ebp
f0103424:	89 e5                	mov    %esp,%ebp
f0103426:	56                   	push   %esi
f0103427:	53                   	push   %ebx
f0103428:	8b 45 08             	mov    0x8(%ebp),%eax
f010342b:	89 c6                	mov    %eax,%esi
f010342d:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;
f0103430:	8b 55 0c             	mov    0xc(%ebp),%edx

	while (n-- > 0) {
f0103433:	39 f0                	cmp    %esi,%eax
f0103435:	74 16                	je     f010344d <memcmp+0x2a>
		if (*s1 != *s2)
f0103437:	8a 08                	mov    (%eax),%cl
f0103439:	8a 1a                	mov    (%edx),%bl
f010343b:	38 d9                	cmp    %bl,%cl
f010343d:	75 04                	jne    f0103443 <memcmp+0x20>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010343f:	40                   	inc    %eax
f0103440:	42                   	inc    %edx
f0103441:	eb f0                	jmp    f0103433 <memcmp+0x10>
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
f0103443:	0f b6 c1             	movzbl %cl,%eax
f0103446:	0f b6 db             	movzbl %bl,%ebx
f0103449:	29 d8                	sub    %ebx,%eax
f010344b:	eb 05                	jmp    f0103452 <memcmp+0x2f>
		s1++, s2++;
	}

	return 0;
f010344d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103452:	5b                   	pop    %ebx
f0103453:	5e                   	pop    %esi
f0103454:	5d                   	pop    %ebp
f0103455:	c3                   	ret    

f0103456 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103456:	55                   	push   %ebp
f0103457:	89 e5                	mov    %esp,%ebp
f0103459:	8b 45 08             	mov    0x8(%ebp),%eax
f010345c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010345f:	89 c2                	mov    %eax,%edx
f0103461:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103464:	39 d0                	cmp    %edx,%eax
f0103466:	73 07                	jae    f010346f <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103468:	38 08                	cmp    %cl,(%eax)
f010346a:	74 03                	je     f010346f <memfind+0x19>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010346c:	40                   	inc    %eax
f010346d:	eb f5                	jmp    f0103464 <memfind+0xe>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010346f:	5d                   	pop    %ebp
f0103470:	c3                   	ret    

f0103471 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103471:	55                   	push   %ebp
f0103472:	89 e5                	mov    %esp,%ebp
f0103474:	57                   	push   %edi
f0103475:	56                   	push   %esi
f0103476:	53                   	push   %ebx
f0103477:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010347a:	eb 01                	jmp    f010347d <strtol+0xc>
		s++;
f010347c:	41                   	inc    %ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010347d:	8a 01                	mov    (%ecx),%al
f010347f:	3c 20                	cmp    $0x20,%al
f0103481:	74 f9                	je     f010347c <strtol+0xb>
f0103483:	3c 09                	cmp    $0x9,%al
f0103485:	74 f5                	je     f010347c <strtol+0xb>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103487:	3c 2b                	cmp    $0x2b,%al
f0103489:	74 2b                	je     f01034b6 <strtol+0x45>
		s++;
	else if (*s == '-')
f010348b:	3c 2d                	cmp    $0x2d,%al
f010348d:	74 2f                	je     f01034be <strtol+0x4d>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010348f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103494:	f7 45 10 ef ff ff ff 	testl  $0xffffffef,0x10(%ebp)
f010349b:	75 12                	jne    f01034af <strtol+0x3e>
f010349d:	80 39 30             	cmpb   $0x30,(%ecx)
f01034a0:	74 24                	je     f01034c6 <strtol+0x55>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01034a2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01034a6:	75 07                	jne    f01034af <strtol+0x3e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01034a8:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)
f01034af:	b8 00 00 00 00       	mov    $0x0,%eax
f01034b4:	eb 4e                	jmp    f0103504 <strtol+0x93>
	while (*s == ' ' || *s == '\t')
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
f01034b6:	41                   	inc    %ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01034b7:	bf 00 00 00 00       	mov    $0x0,%edi
f01034bc:	eb d6                	jmp    f0103494 <strtol+0x23>

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
		s++, neg = 1;
f01034be:	41                   	inc    %ecx
f01034bf:	bf 01 00 00 00       	mov    $0x1,%edi
f01034c4:	eb ce                	jmp    f0103494 <strtol+0x23>

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01034c6:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01034ca:	74 10                	je     f01034dc <strtol+0x6b>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01034cc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01034d0:	75 dd                	jne    f01034af <strtol+0x3e>
		s++, base = 8;
f01034d2:	41                   	inc    %ecx
f01034d3:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f01034da:	eb d3                	jmp    f01034af <strtol+0x3e>
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
f01034dc:	83 c1 02             	add    $0x2,%ecx
f01034df:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f01034e6:	eb c7                	jmp    f01034af <strtol+0x3e>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01034e8:	8d 72 9f             	lea    -0x61(%edx),%esi
f01034eb:	89 f3                	mov    %esi,%ebx
f01034ed:	80 fb 19             	cmp    $0x19,%bl
f01034f0:	77 24                	ja     f0103516 <strtol+0xa5>
			dig = *s - 'a' + 10;
f01034f2:	0f be d2             	movsbl %dl,%edx
f01034f5:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01034f8:	3b 55 10             	cmp    0x10(%ebp),%edx
f01034fb:	7d 2b                	jge    f0103528 <strtol+0xb7>
			break;
		s++, val = (val * base) + dig;
f01034fd:	41                   	inc    %ecx
f01034fe:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103502:	01 d0                	add    %edx,%eax

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103504:	8a 11                	mov    (%ecx),%dl
f0103506:	8d 5a d0             	lea    -0x30(%edx),%ebx
f0103509:	80 fb 09             	cmp    $0x9,%bl
f010350c:	77 da                	ja     f01034e8 <strtol+0x77>
			dig = *s - '0';
f010350e:	0f be d2             	movsbl %dl,%edx
f0103511:	83 ea 30             	sub    $0x30,%edx
f0103514:	eb e2                	jmp    f01034f8 <strtol+0x87>
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103516:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103519:	89 f3                	mov    %esi,%ebx
f010351b:	80 fb 19             	cmp    $0x19,%bl
f010351e:	77 08                	ja     f0103528 <strtol+0xb7>
			dig = *s - 'A' + 10;
f0103520:	0f be d2             	movsbl %dl,%edx
f0103523:	83 ea 37             	sub    $0x37,%edx
f0103526:	eb d0                	jmp    f01034f8 <strtol+0x87>
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103528:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010352c:	74 05                	je     f0103533 <strtol+0xc2>
		*endptr = (char *) s;
f010352e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103531:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0103533:	85 ff                	test   %edi,%edi
f0103535:	74 02                	je     f0103539 <strtol+0xc8>
f0103537:	f7 d8                	neg    %eax
}
f0103539:	5b                   	pop    %ebx
f010353a:	5e                   	pop    %esi
f010353b:	5f                   	pop    %edi
f010353c:	5d                   	pop    %ebp
f010353d:	c3                   	ret    
	...

f0103540 <__udivdi3>:
f0103540:	55                   	push   %ebp
f0103541:	57                   	push   %edi
f0103542:	56                   	push   %esi
f0103543:	53                   	push   %ebx
f0103544:	83 ec 1c             	sub    $0x1c,%esp
f0103547:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010354b:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f010354f:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103553:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103557:	89 ca                	mov    %ecx,%edx
f0103559:	89 f8                	mov    %edi,%eax
f010355b:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010355f:	85 f6                	test   %esi,%esi
f0103561:	75 2d                	jne    f0103590 <__udivdi3+0x50>
f0103563:	39 cf                	cmp    %ecx,%edi
f0103565:	77 65                	ja     f01035cc <__udivdi3+0x8c>
f0103567:	89 fd                	mov    %edi,%ebp
f0103569:	85 ff                	test   %edi,%edi
f010356b:	75 0b                	jne    f0103578 <__udivdi3+0x38>
f010356d:	b8 01 00 00 00       	mov    $0x1,%eax
f0103572:	31 d2                	xor    %edx,%edx
f0103574:	f7 f7                	div    %edi
f0103576:	89 c5                	mov    %eax,%ebp
f0103578:	31 d2                	xor    %edx,%edx
f010357a:	89 c8                	mov    %ecx,%eax
f010357c:	f7 f5                	div    %ebp
f010357e:	89 c1                	mov    %eax,%ecx
f0103580:	89 d8                	mov    %ebx,%eax
f0103582:	f7 f5                	div    %ebp
f0103584:	89 cf                	mov    %ecx,%edi
f0103586:	89 fa                	mov    %edi,%edx
f0103588:	83 c4 1c             	add    $0x1c,%esp
f010358b:	5b                   	pop    %ebx
f010358c:	5e                   	pop    %esi
f010358d:	5f                   	pop    %edi
f010358e:	5d                   	pop    %ebp
f010358f:	c3                   	ret    
f0103590:	39 ce                	cmp    %ecx,%esi
f0103592:	77 28                	ja     f01035bc <__udivdi3+0x7c>
f0103594:	0f bd fe             	bsr    %esi,%edi
f0103597:	83 f7 1f             	xor    $0x1f,%edi
f010359a:	75 40                	jne    f01035dc <__udivdi3+0x9c>
f010359c:	39 ce                	cmp    %ecx,%esi
f010359e:	72 0a                	jb     f01035aa <__udivdi3+0x6a>
f01035a0:	3b 44 24 04          	cmp    0x4(%esp),%eax
f01035a4:	0f 87 9e 00 00 00    	ja     f0103648 <__udivdi3+0x108>
f01035aa:	b8 01 00 00 00       	mov    $0x1,%eax
f01035af:	89 fa                	mov    %edi,%edx
f01035b1:	83 c4 1c             	add    $0x1c,%esp
f01035b4:	5b                   	pop    %ebx
f01035b5:	5e                   	pop    %esi
f01035b6:	5f                   	pop    %edi
f01035b7:	5d                   	pop    %ebp
f01035b8:	c3                   	ret    
f01035b9:	8d 76 00             	lea    0x0(%esi),%esi
f01035bc:	31 ff                	xor    %edi,%edi
f01035be:	31 c0                	xor    %eax,%eax
f01035c0:	89 fa                	mov    %edi,%edx
f01035c2:	83 c4 1c             	add    $0x1c,%esp
f01035c5:	5b                   	pop    %ebx
f01035c6:	5e                   	pop    %esi
f01035c7:	5f                   	pop    %edi
f01035c8:	5d                   	pop    %ebp
f01035c9:	c3                   	ret    
f01035ca:	66 90                	xchg   %ax,%ax
f01035cc:	89 d8                	mov    %ebx,%eax
f01035ce:	f7 f7                	div    %edi
f01035d0:	31 ff                	xor    %edi,%edi
f01035d2:	89 fa                	mov    %edi,%edx
f01035d4:	83 c4 1c             	add    $0x1c,%esp
f01035d7:	5b                   	pop    %ebx
f01035d8:	5e                   	pop    %esi
f01035d9:	5f                   	pop    %edi
f01035da:	5d                   	pop    %ebp
f01035db:	c3                   	ret    
f01035dc:	bd 20 00 00 00       	mov    $0x20,%ebp
f01035e1:	29 fd                	sub    %edi,%ebp
f01035e3:	89 f9                	mov    %edi,%ecx
f01035e5:	d3 e6                	shl    %cl,%esi
f01035e7:	89 c3                	mov    %eax,%ebx
f01035e9:	89 e9                	mov    %ebp,%ecx
f01035eb:	d3 eb                	shr    %cl,%ebx
f01035ed:	89 d9                	mov    %ebx,%ecx
f01035ef:	09 f1                	or     %esi,%ecx
f01035f1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01035f5:	89 f9                	mov    %edi,%ecx
f01035f7:	d3 e0                	shl    %cl,%eax
f01035f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035fd:	89 d6                	mov    %edx,%esi
f01035ff:	89 e9                	mov    %ebp,%ecx
f0103601:	d3 ee                	shr    %cl,%esi
f0103603:	89 f9                	mov    %edi,%ecx
f0103605:	d3 e2                	shl    %cl,%edx
f0103607:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010360b:	89 e9                	mov    %ebp,%ecx
f010360d:	d3 eb                	shr    %cl,%ebx
f010360f:	09 da                	or     %ebx,%edx
f0103611:	89 d0                	mov    %edx,%eax
f0103613:	89 f2                	mov    %esi,%edx
f0103615:	f7 74 24 08          	divl   0x8(%esp)
f0103619:	89 d6                	mov    %edx,%esi
f010361b:	89 c3                	mov    %eax,%ebx
f010361d:	f7 64 24 0c          	mull   0xc(%esp)
f0103621:	39 d6                	cmp    %edx,%esi
f0103623:	72 17                	jb     f010363c <__udivdi3+0xfc>
f0103625:	74 09                	je     f0103630 <__udivdi3+0xf0>
f0103627:	89 d8                	mov    %ebx,%eax
f0103629:	31 ff                	xor    %edi,%edi
f010362b:	e9 56 ff ff ff       	jmp    f0103586 <__udivdi3+0x46>
f0103630:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103634:	89 f9                	mov    %edi,%ecx
f0103636:	d3 e2                	shl    %cl,%edx
f0103638:	39 c2                	cmp    %eax,%edx
f010363a:	73 eb                	jae    f0103627 <__udivdi3+0xe7>
f010363c:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010363f:	31 ff                	xor    %edi,%edi
f0103641:	e9 40 ff ff ff       	jmp    f0103586 <__udivdi3+0x46>
f0103646:	66 90                	xchg   %ax,%ax
f0103648:	31 c0                	xor    %eax,%eax
f010364a:	e9 37 ff ff ff       	jmp    f0103586 <__udivdi3+0x46>
	...

f0103650 <__umoddi3>:
f0103650:	55                   	push   %ebp
f0103651:	57                   	push   %edi
f0103652:	56                   	push   %esi
f0103653:	53                   	push   %ebx
f0103654:	83 ec 1c             	sub    $0x1c,%esp
f0103657:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010365b:	8b 74 24 34          	mov    0x34(%esp),%esi
f010365f:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0103663:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0103667:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010366b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010366f:	89 3c 24             	mov    %edi,(%esp)
f0103672:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103676:	89 f2                	mov    %esi,%edx
f0103678:	85 c0                	test   %eax,%eax
f010367a:	75 18                	jne    f0103694 <__umoddi3+0x44>
f010367c:	39 f7                	cmp    %esi,%edi
f010367e:	0f 86 a0 00 00 00    	jbe    f0103724 <__umoddi3+0xd4>
f0103684:	89 c8                	mov    %ecx,%eax
f0103686:	f7 f7                	div    %edi
f0103688:	89 d0                	mov    %edx,%eax
f010368a:	31 d2                	xor    %edx,%edx
f010368c:	83 c4 1c             	add    $0x1c,%esp
f010368f:	5b                   	pop    %ebx
f0103690:	5e                   	pop    %esi
f0103691:	5f                   	pop    %edi
f0103692:	5d                   	pop    %ebp
f0103693:	c3                   	ret    
f0103694:	89 f3                	mov    %esi,%ebx
f0103696:	39 f0                	cmp    %esi,%eax
f0103698:	0f 87 a6 00 00 00    	ja     f0103744 <__umoddi3+0xf4>
f010369e:	0f bd e8             	bsr    %eax,%ebp
f01036a1:	83 f5 1f             	xor    $0x1f,%ebp
f01036a4:	0f 84 a6 00 00 00    	je     f0103750 <__umoddi3+0x100>
f01036aa:	bf 20 00 00 00       	mov    $0x20,%edi
f01036af:	29 ef                	sub    %ebp,%edi
f01036b1:	89 e9                	mov    %ebp,%ecx
f01036b3:	d3 e0                	shl    %cl,%eax
f01036b5:	8b 34 24             	mov    (%esp),%esi
f01036b8:	89 f2                	mov    %esi,%edx
f01036ba:	89 f9                	mov    %edi,%ecx
f01036bc:	d3 ea                	shr    %cl,%edx
f01036be:	09 c2                	or     %eax,%edx
f01036c0:	89 14 24             	mov    %edx,(%esp)
f01036c3:	89 f2                	mov    %esi,%edx
f01036c5:	89 e9                	mov    %ebp,%ecx
f01036c7:	d3 e2                	shl    %cl,%edx
f01036c9:	89 54 24 04          	mov    %edx,0x4(%esp)
f01036cd:	89 de                	mov    %ebx,%esi
f01036cf:	89 f9                	mov    %edi,%ecx
f01036d1:	d3 ee                	shr    %cl,%esi
f01036d3:	89 e9                	mov    %ebp,%ecx
f01036d5:	d3 e3                	shl    %cl,%ebx
f01036d7:	8b 54 24 08          	mov    0x8(%esp),%edx
f01036db:	89 d0                	mov    %edx,%eax
f01036dd:	89 f9                	mov    %edi,%ecx
f01036df:	d3 e8                	shr    %cl,%eax
f01036e1:	09 d8                	or     %ebx,%eax
f01036e3:	89 d3                	mov    %edx,%ebx
f01036e5:	89 e9                	mov    %ebp,%ecx
f01036e7:	d3 e3                	shl    %cl,%ebx
f01036e9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01036ed:	89 f2                	mov    %esi,%edx
f01036ef:	f7 34 24             	divl   (%esp)
f01036f2:	89 d6                	mov    %edx,%esi
f01036f4:	f7 64 24 04          	mull   0x4(%esp)
f01036f8:	89 c3                	mov    %eax,%ebx
f01036fa:	89 d1                	mov    %edx,%ecx
f01036fc:	39 d6                	cmp    %edx,%esi
f01036fe:	72 7c                	jb     f010377c <__umoddi3+0x12c>
f0103700:	74 72                	je     f0103774 <__umoddi3+0x124>
f0103702:	8b 54 24 08          	mov    0x8(%esp),%edx
f0103706:	29 da                	sub    %ebx,%edx
f0103708:	19 ce                	sbb    %ecx,%esi
f010370a:	89 f0                	mov    %esi,%eax
f010370c:	89 f9                	mov    %edi,%ecx
f010370e:	d3 e0                	shl    %cl,%eax
f0103710:	89 e9                	mov    %ebp,%ecx
f0103712:	d3 ea                	shr    %cl,%edx
f0103714:	09 d0                	or     %edx,%eax
f0103716:	89 e9                	mov    %ebp,%ecx
f0103718:	d3 ee                	shr    %cl,%esi
f010371a:	89 f2                	mov    %esi,%edx
f010371c:	83 c4 1c             	add    $0x1c,%esp
f010371f:	5b                   	pop    %ebx
f0103720:	5e                   	pop    %esi
f0103721:	5f                   	pop    %edi
f0103722:	5d                   	pop    %ebp
f0103723:	c3                   	ret    
f0103724:	89 fd                	mov    %edi,%ebp
f0103726:	85 ff                	test   %edi,%edi
f0103728:	75 0b                	jne    f0103735 <__umoddi3+0xe5>
f010372a:	b8 01 00 00 00       	mov    $0x1,%eax
f010372f:	31 d2                	xor    %edx,%edx
f0103731:	f7 f7                	div    %edi
f0103733:	89 c5                	mov    %eax,%ebp
f0103735:	89 f0                	mov    %esi,%eax
f0103737:	31 d2                	xor    %edx,%edx
f0103739:	f7 f5                	div    %ebp
f010373b:	89 c8                	mov    %ecx,%eax
f010373d:	f7 f5                	div    %ebp
f010373f:	e9 44 ff ff ff       	jmp    f0103688 <__umoddi3+0x38>
f0103744:	89 c8                	mov    %ecx,%eax
f0103746:	89 f2                	mov    %esi,%edx
f0103748:	83 c4 1c             	add    $0x1c,%esp
f010374b:	5b                   	pop    %ebx
f010374c:	5e                   	pop    %esi
f010374d:	5f                   	pop    %edi
f010374e:	5d                   	pop    %ebp
f010374f:	c3                   	ret    
f0103750:	39 f0                	cmp    %esi,%eax
f0103752:	72 05                	jb     f0103759 <__umoddi3+0x109>
f0103754:	39 0c 24             	cmp    %ecx,(%esp)
f0103757:	77 0c                	ja     f0103765 <__umoddi3+0x115>
f0103759:	89 f2                	mov    %esi,%edx
f010375b:	29 f9                	sub    %edi,%ecx
f010375d:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0103761:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103765:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103769:	83 c4 1c             	add    $0x1c,%esp
f010376c:	5b                   	pop    %ebx
f010376d:	5e                   	pop    %esi
f010376e:	5f                   	pop    %edi
f010376f:	5d                   	pop    %ebp
f0103770:	c3                   	ret    
f0103771:	8d 76 00             	lea    0x0(%esi),%esi
f0103774:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103778:	73 88                	jae    f0103702 <__umoddi3+0xb2>
f010377a:	66 90                	xchg   %ax,%ax
f010377c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103780:	1b 14 24             	sbb    (%esp),%edx
f0103783:	89 d1                	mov    %edx,%ecx
f0103785:	89 c3                	mov    %eax,%ebx
f0103787:	e9 76 ff ff ff       	jmp    f0103702 <__umoddi3+0xb2>

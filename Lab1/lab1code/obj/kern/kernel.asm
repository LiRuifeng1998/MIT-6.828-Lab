
obj/kern/kernel：     文件格式 elf32-i386


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
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 a0 1a 10 f0 	movl   $0xf0101aa0,(%esp)
f0100055:	e8 77 09 00 00       	call   f01009d1 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 ff 06 00 00       	call   f0100786 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 bc 1a 10 f0 	movl   $0xf0101abc,(%esp)
f0100092:	e8 3a 09 00 00       	call   f01009d1 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 0a 15 00 00       	call   f01015cf <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 d7 1a 10 f0 	movl   $0xf0101ad7,(%esp)
f01000d9:	e8 f3 08 00 00       	call   f01009d1 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 44 07 00 00       	call   f010083a <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 f2 1a 10 f0 	movl   $0xf0101af2,(%esp)
f010012c:	e8 a0 08 00 00       	call   f01009d1 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 61 08 00 00       	call   f010099e <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 2e 1b 10 f0 	movl   $0xf0101b2e,(%esp)
f0100144:	e8 88 08 00 00       	call   f01009d1 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 e5 06 00 00       	call   f010083a <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 0a 1b 10 f0 	movl   $0xf0101b0a,(%esp)
f0100176:	e8 56 08 00 00       	call   f01009d1 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 14 08 00 00       	call   f010099e <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 2e 1b 10 f0 	movl   $0xf0101b2e,(%esp)
f0100191:	e8 3b 08 00 00       	call   f01009d1 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 44 25 11 f0    	mov    %ecx,0xf0112544
f01001d9:	88 90 40 23 11 f0    	mov    %dl,-0xfeedcc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 44 25 11 f0 00 	movl   $0x0,0xf0112544
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
f010020e:	b2 60                	mov    $0x60,%dl
f0100210:	ec                   	in     (%dx),%al
f0100211:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100213:	3c e0                	cmp    $0xe0,%al
f0100215:	75 0d                	jne    f0100224 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100217:	83 0d 20 23 11 f0 40 	orl    $0x40,0xf0112320
		return 0;
f010021e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100223:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100224:	55                   	push   %ebp
f0100225:	89 e5                	mov    %esp,%ebp
f0100227:	53                   	push   %ebx
f0100228:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010022b:	84 c0                	test   %al,%al
f010022d:	79 37                	jns    f0100266 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022f:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f0100235:	89 cb                	mov    %ecx,%ebx
f0100237:	83 e3 40             	and    $0x40,%ebx
f010023a:	83 e0 7f             	and    $0x7f,%eax
f010023d:	85 db                	test   %ebx,%ebx
f010023f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100242:	0f b6 d2             	movzbl %dl,%edx
f0100245:	0f b6 82 80 1c 10 f0 	movzbl -0xfefe380(%edx),%eax
f010024c:	83 c8 40             	or     $0x40,%eax
f010024f:	0f b6 c0             	movzbl %al,%eax
f0100252:	f7 d0                	not    %eax
f0100254:	21 c1                	and    %eax,%ecx
f0100256:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
		return 0;
f010025c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100261:	e9 9d 00 00 00       	jmp    f0100303 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100266:	8b 0d 20 23 11 f0    	mov    0xf0112320,%ecx
f010026c:	f6 c1 40             	test   $0x40,%cl
f010026f:	74 0e                	je     f010027f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100271:	83 c8 80             	or     $0xffffff80,%eax
f0100274:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100276:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100279:	89 0d 20 23 11 f0    	mov    %ecx,0xf0112320
	}

	shift |= shiftcode[data];
f010027f:	0f b6 d2             	movzbl %dl,%edx
f0100282:	0f b6 82 80 1c 10 f0 	movzbl -0xfefe380(%edx),%eax
f0100289:	0b 05 20 23 11 f0    	or     0xf0112320,%eax
	shift ^= togglecode[data];
f010028f:	0f b6 8a 80 1b 10 f0 	movzbl -0xfefe480(%edx),%ecx
f0100296:	31 c8                	xor    %ecx,%eax
f0100298:	a3 20 23 11 f0       	mov    %eax,0xf0112320

	c = charcode[shift & (CTL | SHIFT)][data];
f010029d:	89 c1                	mov    %eax,%ecx
f010029f:	83 e1 03             	and    $0x3,%ecx
f01002a2:	8b 0c 8d 60 1b 10 f0 	mov    -0xfefe4a0(,%ecx,4),%ecx
f01002a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b0:	a8 08                	test   $0x8,%al
f01002b2:	74 1b                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b4:	89 da                	mov    %ebx,%edx
f01002b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002b9:	83 f9 19             	cmp    $0x19,%ecx
f01002bc:	77 05                	ja     f01002c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01002be:	83 eb 20             	sub    $0x20,%ebx
f01002c1:	eb 0c                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002c9:	83 fa 19             	cmp    $0x19,%edx
f01002cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 29                	jne    f0100303 <kbd_proc_data+0x103>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 21                	jne    f0100303 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 24 1b 10 f0 	movl   $0xf0101b24,(%esp)
f01002e9:	e8 e3 06 00 00       	call   f01009d1 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 06                	jmp    f0100303 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100303:	83 c4 14             	add    $0x14,%esp
f0100306:	5b                   	pop    %ebx
f0100307:	5d                   	pop    %ebp
f0100308:	c3                   	ret    

f0100309 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100309:	55                   	push   %ebp
f010030a:	89 e5                	mov    %esp,%ebp
f010030c:	57                   	push   %edi
f010030d:	56                   	push   %esi
f010030e:	53                   	push   %ebx
f010030f:	83 ec 1c             	sub    $0x1c,%esp
f0100312:	89 c7                	mov    %eax,%edi

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100314:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100319:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 21                	jne    f010033f <cons_putc+0x36>
f010031e:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100323:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100328:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032d:	89 ca                	mov    %ecx,%edx
f010032f:	ec                   	in     (%dx),%al
f0100330:	ec                   	in     (%dx),%al
f0100331:	ec                   	in     (%dx),%al
f0100332:	ec                   	in     (%dx),%al
f0100333:	89 f2                	mov    %esi,%edx
f0100335:	ec                   	in     (%dx),%al
f0100336:	a8 20                	test   $0x20,%al
f0100338:	75 05                	jne    f010033f <cons_putc+0x36>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010033a:	83 eb 01             	sub    $0x1,%ebx
f010033d:	75 ee                	jne    f010032d <cons_putc+0x24>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f010033f:	89 f8                	mov    %edi,%eax
f0100341:	0f b6 c0             	movzbl %al,%eax
f0100344:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100347:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010034c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010034d:	b2 79                	mov    $0x79,%dl
f010034f:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100350:	84 c0                	test   %al,%al
f0100352:	78 21                	js     f0100375 <cons_putc+0x6c>
f0100354:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100359:	b9 84 00 00 00       	mov    $0x84,%ecx
f010035e:	be 79 03 00 00       	mov    $0x379,%esi
f0100363:	89 ca                	mov    %ecx,%edx
f0100365:	ec                   	in     (%dx),%al
f0100366:	ec                   	in     (%dx),%al
f0100367:	ec                   	in     (%dx),%al
f0100368:	ec                   	in     (%dx),%al
f0100369:	89 f2                	mov    %esi,%edx
f010036b:	ec                   	in     (%dx),%al
f010036c:	84 c0                	test   %al,%al
f010036e:	78 05                	js     f0100375 <cons_putc+0x6c>
f0100370:	83 eb 01             	sub    $0x1,%ebx
f0100373:	75 ee                	jne    f0100363 <cons_putc+0x5a>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100375:	ba 78 03 00 00       	mov    $0x378,%edx
f010037a:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010037e:	ee                   	out    %al,(%dx)
f010037f:	b2 7a                	mov    $0x7a,%dl
f0100381:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100386:	ee                   	out    %al,(%dx)
f0100387:	b8 08 00 00 00       	mov    $0x8,%eax
f010038c:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010038d:	89 fa                	mov    %edi,%edx
f010038f:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100395:	89 f8                	mov    %edi,%eax
f0100397:	80 cc 07             	or     $0x7,%ah
f010039a:	85 d2                	test   %edx,%edx
f010039c:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010039f:	89 f8                	mov    %edi,%eax
f01003a1:	0f b6 c0             	movzbl %al,%eax
f01003a4:	83 f8 09             	cmp    $0x9,%eax
f01003a7:	74 79                	je     f0100422 <cons_putc+0x119>
f01003a9:	83 f8 09             	cmp    $0x9,%eax
f01003ac:	7f 0a                	jg     f01003b8 <cons_putc+0xaf>
f01003ae:	83 f8 08             	cmp    $0x8,%eax
f01003b1:	74 19                	je     f01003cc <cons_putc+0xc3>
f01003b3:	e9 9e 00 00 00       	jmp    f0100456 <cons_putc+0x14d>
f01003b8:	83 f8 0a             	cmp    $0xa,%eax
f01003bb:	90                   	nop
f01003bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01003c0:	74 3a                	je     f01003fc <cons_putc+0xf3>
f01003c2:	83 f8 0d             	cmp    $0xd,%eax
f01003c5:	74 3d                	je     f0100404 <cons_putc+0xfb>
f01003c7:	e9 8a 00 00 00       	jmp    f0100456 <cons_putc+0x14d>
	case '\b':
		if (crt_pos > 0) {
f01003cc:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003d3:	66 85 c0             	test   %ax,%ax
f01003d6:	0f 84 e5 00 00 00    	je     f01004c1 <cons_putc+0x1b8>
			crt_pos--;
f01003dc:	83 e8 01             	sub    $0x1,%eax
f01003df:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003e5:	0f b7 c0             	movzwl %ax,%eax
f01003e8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003ed:	83 cf 20             	or     $0x20,%edi
f01003f0:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f01003f6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003fa:	eb 78                	jmp    f0100474 <cons_putc+0x16b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003fc:	66 83 05 48 25 11 f0 	addw   $0x50,0xf0112548
f0100403:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100404:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f010040b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100411:	c1 e8 16             	shr    $0x16,%eax
f0100414:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100417:	c1 e0 04             	shl    $0x4,%eax
f010041a:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
f0100420:	eb 52                	jmp    f0100474 <cons_putc+0x16b>
		break;
	case '\t':
		cons_putc(' ');
f0100422:	b8 20 00 00 00       	mov    $0x20,%eax
f0100427:	e8 dd fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010042c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100431:	e8 d3 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100436:	b8 20 00 00 00       	mov    $0x20,%eax
f010043b:	e8 c9 fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f0100440:	b8 20 00 00 00       	mov    $0x20,%eax
f0100445:	e8 bf fe ff ff       	call   f0100309 <cons_putc>
		cons_putc(' ');
f010044a:	b8 20 00 00 00       	mov    $0x20,%eax
f010044f:	e8 b5 fe ff ff       	call   f0100309 <cons_putc>
f0100454:	eb 1e                	jmp    f0100474 <cons_putc+0x16b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100456:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f010045d:	8d 50 01             	lea    0x1(%eax),%edx
f0100460:	66 89 15 48 25 11 f0 	mov    %dx,0xf0112548
f0100467:	0f b7 c0             	movzwl %ax,%eax
f010046a:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100470:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100474:	66 81 3d 48 25 11 f0 	cmpw   $0x7cf,0xf0112548
f010047b:	cf 07 
f010047d:	76 42                	jbe    f01004c1 <cons_putc+0x1b8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010047f:	a1 4c 25 11 f0       	mov    0xf011254c,%eax
f0100484:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010048b:	00 
f010048c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100492:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100496:	89 04 24             	mov    %eax,(%esp)
f0100499:	e8 7e 11 00 00       	call   f010161c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010049e:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004a4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004a9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004af:	83 c0 01             	add    $0x1,%eax
f01004b2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004b7:	75 f0                	jne    f01004a9 <cons_putc+0x1a0>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004b9:	66 83 2d 48 25 11 f0 	subw   $0x50,0xf0112548
f01004c0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004c1:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01004c7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004cc:	89 ca                	mov    %ecx,%edx
f01004ce:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004cf:	0f b7 1d 48 25 11 f0 	movzwl 0xf0112548,%ebx
f01004d6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004d9:	89 d8                	mov    %ebx,%eax
f01004db:	66 c1 e8 08          	shr    $0x8,%ax
f01004df:	89 f2                	mov    %esi,%edx
f01004e1:	ee                   	out    %al,(%dx)
f01004e2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004e7:	89 ca                	mov    %ecx,%edx
f01004e9:	ee                   	out    %al,(%dx)
f01004ea:	89 d8                	mov    %ebx,%eax
f01004ec:	89 f2                	mov    %esi,%edx
f01004ee:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ef:	83 c4 1c             	add    $0x1c,%esp
f01004f2:	5b                   	pop    %ebx
f01004f3:	5e                   	pop    %esi
f01004f4:	5f                   	pop    %edi
f01004f5:	5d                   	pop    %ebp
f01004f6:	c3                   	ret    

f01004f7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f7:	83 3d 54 25 11 f0 00 	cmpl   $0x0,0xf0112554
f01004fe:	74 11                	je     f0100511 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100500:	55                   	push   %ebp
f0100501:	89 e5                	mov    %esp,%ebp
f0100503:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100506:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f010050b:	e8 ac fc ff ff       	call   f01001bc <cons_intr>
}
f0100510:	c9                   	leave  
f0100511:	f3 c3                	repz ret 

f0100513 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100513:	55                   	push   %ebp
f0100514:	89 e5                	mov    %esp,%ebp
f0100516:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100519:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010051e:	e8 99 fc ff ff       	call   f01001bc <cons_intr>
}
f0100523:	c9                   	leave  
f0100524:	c3                   	ret    

f0100525 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100525:	55                   	push   %ebp
f0100526:	89 e5                	mov    %esp,%ebp
f0100528:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010052b:	e8 c7 ff ff ff       	call   f01004f7 <serial_intr>
	kbd_intr();
f0100530:	e8 de ff ff ff       	call   f0100513 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100535:	a1 40 25 11 f0       	mov    0xf0112540,%eax
f010053a:	3b 05 44 25 11 f0    	cmp    0xf0112544,%eax
f0100540:	74 26                	je     f0100568 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100542:	8d 50 01             	lea    0x1(%eax),%edx
f0100545:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f010054b:	0f b6 88 40 23 11 f0 	movzbl -0xfeedcc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100552:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100554:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055a:	75 11                	jne    f010056d <cons_getc+0x48>
			cons.rpos = 0;
f010055c:	c7 05 40 25 11 f0 00 	movl   $0x0,0xf0112540
f0100563:	00 00 00 
f0100566:	eb 05                	jmp    f010056d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100568:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010056d:	c9                   	leave  
f010056e:	c3                   	ret    

f010056f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056f:	55                   	push   %ebp
f0100570:	89 e5                	mov    %esp,%ebp
f0100572:	57                   	push   %edi
f0100573:	56                   	push   %esi
f0100574:	53                   	push   %ebx
f0100575:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100578:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100586:	5a a5 
	if (*cp != 0xA55A) {
f0100588:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100593:	74 11                	je     f01005a6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100595:	c7 05 50 25 11 f0 b4 	movl   $0x3b4,0xf0112550
f010059c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005a4:	eb 16                	jmp    f01005bc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005ad:	c7 05 50 25 11 f0 d4 	movl   $0x3d4,0xf0112550
f01005b4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005bc:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01005c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c7:	89 ca                	mov    %ecx,%edx
f01005c9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ca:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cd:	89 da                	mov    %ebx,%edx
f01005cf:	ec                   	in     (%dx),%al
f01005d0:	0f b6 f0             	movzbl %al,%esi
f01005d3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005db:	89 ca                	mov    %ecx,%edx
f01005dd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005de:	89 da                	mov    %ebx,%edx
f01005e0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005e1:	89 3d 4c 25 11 f0    	mov    %edi,0xf011254c
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e7:	0f b6 d8             	movzbl %al,%ebx
f01005ea:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005ec:	66 89 35 48 25 11 f0 	mov    %si,0xf0112548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fd:	89 f2                	mov    %esi,%edx
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	b2 fb                	mov    $0xfb,%dl
f0100602:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100607:	ee                   	out    %al,(%dx)
f0100608:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010060d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100612:	89 da                	mov    %ebx,%edx
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 f9                	mov    $0xf9,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 fb                	mov    $0xfb,%dl
f010061f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 fc                	mov    $0xfc,%dl
f0100627:	b8 00 00 00 00       	mov    $0x0,%eax
f010062c:	ee                   	out    %al,(%dx)
f010062d:	b2 f9                	mov    $0xf9,%dl
f010062f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100634:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100635:	b2 fd                	mov    $0xfd,%dl
f0100637:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100638:	3c ff                	cmp    $0xff,%al
f010063a:	0f 95 c1             	setne  %cl
f010063d:	0f b6 c9             	movzbl %cl,%ecx
f0100640:	89 0d 54 25 11 f0    	mov    %ecx,0xf0112554
f0100646:	89 f2                	mov    %esi,%edx
f0100648:	ec                   	in     (%dx),%al
f0100649:	89 da                	mov    %ebx,%edx
f010064b:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010064c:	85 c9                	test   %ecx,%ecx
f010064e:	75 0c                	jne    f010065c <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f0100650:	c7 04 24 30 1b 10 f0 	movl   $0xf0101b30,(%esp)
f0100657:	e8 75 03 00 00       	call   f01009d1 <cprintf>
}
f010065c:	83 c4 1c             	add    $0x1c,%esp
f010065f:	5b                   	pop    %ebx
f0100660:	5e                   	pop    %esi
f0100661:	5f                   	pop    %edi
f0100662:	5d                   	pop    %ebp
f0100663:	c3                   	ret    

f0100664 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100664:	55                   	push   %ebp
f0100665:	89 e5                	mov    %esp,%ebp
f0100667:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010066a:	8b 45 08             	mov    0x8(%ebp),%eax
f010066d:	e8 97 fc ff ff       	call   f0100309 <cons_putc>
}
f0100672:	c9                   	leave  
f0100673:	c3                   	ret    

f0100674 <getchar>:

int
getchar(void)
{
f0100674:	55                   	push   %ebp
f0100675:	89 e5                	mov    %esp,%ebp
f0100677:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010067a:	e8 a6 fe ff ff       	call   f0100525 <cons_getc>
f010067f:	85 c0                	test   %eax,%eax
f0100681:	74 f7                	je     f010067a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100683:	c9                   	leave  
f0100684:	c3                   	ret    

f0100685 <iscons>:

int
iscons(int fdnum)
{
f0100685:	55                   	push   %ebp
f0100686:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100688:	b8 01 00 00 00       	mov    $0x1,%eax
f010068d:	5d                   	pop    %ebp
f010068e:	c3                   	ret    
f010068f:	90                   	nop

f0100690 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100696:	c7 44 24 08 80 1d 10 	movl   $0xf0101d80,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 9e 1d 10 	movl   $0xf0101d9e,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 a3 1d 10 f0 	movl   $0xf0101da3,(%esp)
f01006ad:	e8 1f 03 00 00       	call   f01009d1 <cprintf>
f01006b2:	c7 44 24 08 38 1e 10 	movl   $0xf0101e38,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 ac 1d 10 	movl   $0xf0101dac,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 a3 1d 10 f0 	movl   $0xf0101da3,(%esp)
f01006c9:	e8 03 03 00 00       	call   f01009d1 <cprintf>
	return 0;
}
f01006ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d3:	c9                   	leave  
f01006d4:	c3                   	ret    

f01006d5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006d5:	55                   	push   %ebp
f01006d6:	89 e5                	mov    %esp,%ebp
f01006d8:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006db:	c7 04 24 b5 1d 10 f0 	movl   $0xf0101db5,(%esp)
f01006e2:	e8 ea 02 00 00       	call   f01009d1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ee:	00 
f01006ef:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006f6:	f0 
f01006f7:	c7 04 24 60 1e 10 f0 	movl   $0xf0101e60,(%esp)
f01006fe:	e8 ce 02 00 00       	call   f01009d1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100703:	c7 44 24 08 97 1a 10 	movl   $0x101a97,0x8(%esp)
f010070a:	00 
f010070b:	c7 44 24 04 97 1a 10 	movl   $0xf0101a97,0x4(%esp)
f0100712:	f0 
f0100713:	c7 04 24 84 1e 10 f0 	movl   $0xf0101e84,(%esp)
f010071a:	e8 b2 02 00 00       	call   f01009d1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010071f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100726:	00 
f0100727:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010072e:	f0 
f010072f:	c7 04 24 a8 1e 10 f0 	movl   $0xf0101ea8,(%esp)
f0100736:	e8 96 02 00 00       	call   f01009d1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010073b:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f0100742:	00 
f0100743:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f010074a:	f0 
f010074b:	c7 04 24 cc 1e 10 f0 	movl   $0xf0101ecc,(%esp)
f0100752:	e8 7a 02 00 00       	call   f01009d1 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100757:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f010075c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100761:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100767:	85 c0                	test   %eax,%eax
f0100769:	0f 48 c2             	cmovs  %edx,%eax
f010076c:	c1 f8 0a             	sar    $0xa,%eax
f010076f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100773:	c7 04 24 f0 1e 10 f0 	movl   $0xf0101ef0,(%esp)
f010077a:	e8 52 02 00 00       	call   f01009d1 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010077f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100784:	c9                   	leave  
f0100785:	c3                   	ret    

f0100786 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100786:	55                   	push   %ebp
f0100787:	89 e5                	mov    %esp,%ebp
f0100789:	57                   	push   %edi
f010078a:	56                   	push   %esi
f010078b:	53                   	push   %ebx
f010078c:	83 ec 4c             	sub    $0x4c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010078f:	89 e8                	mov    %ebp,%eax
	// Your code here.
	int i;
	uint32_t eip;
	uint32_t* ebp = (uint32_t *)read_ebp();
f0100791:	89 c6                	mov    %eax,%esi

	while (ebp) {
f0100793:	85 c0                	test   %eax,%eax
f0100795:	0f 84 92 00 00 00    	je     f010082d <mon_backtrace+0xa7>
		eip = *(ebp + 1);
f010079b:	8b 46 04             	mov    0x4(%esi),%eax
f010079e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		cprintf("ebp %x eip %x args", ebp, eip);
f01007a1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007a5:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007a9:	c7 04 24 ce 1d 10 f0 	movl   $0xf0101dce,(%esp)
f01007b0:	e8 1c 02 00 00       	call   f01009d1 <cprintf>
		uint32_t *args = ebp + 2;
f01007b5:	8d 5e 08             	lea    0x8(%esi),%ebx
f01007b8:	8d 7e 1c             	lea    0x1c(%esi),%edi
		for (i = 0; i < 5; i++) {
			uint32_t argi = args[i];
			cprintf(" %08x ", argi);
f01007bb:	8b 03                	mov    (%ebx),%eax
f01007bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007c1:	c7 04 24 e1 1d 10 f0 	movl   $0xf0101de1,(%esp)
f01007c8:	e8 04 02 00 00       	call   f01009d1 <cprintf>
f01007cd:	83 c3 04             	add    $0x4,%ebx

	while (ebp) {
		eip = *(ebp + 1);
		cprintf("ebp %x eip %x args", ebp, eip);
		uint32_t *args = ebp + 2;
		for (i = 0; i < 5; i++) {
f01007d0:	39 fb                	cmp    %edi,%ebx
f01007d2:	75 e7                	jne    f01007bb <mon_backtrace+0x35>
			uint32_t argi = args[i];
			cprintf(" %08x ", argi);
		}
		cprintf("\n");
f01007d4:	c7 04 24 2e 1b 10 f0 	movl   $0xf0101b2e,(%esp)
f01007db:	e8 f1 01 00 00       	call   f01009d1 <cprintf>
		ebp = (uint32_t *) *ebp;
f01007e0:	8b 36                	mov    (%esi),%esi
		struct Eipdebuginfo debug_info;
		debuginfo_eip(eip, &debug_info);
f01007e2:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007e5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e9:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01007ec:	89 3c 24             	mov    %edi,(%esp)
f01007ef:	e8 d9 02 00 00       	call   f0100acd <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n",
f01007f4:	89 f8                	mov    %edi,%eax
f01007f6:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01007f9:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007fd:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100800:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100804:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100807:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010080b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010080e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100812:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100815:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100819:	c7 04 24 e8 1d 10 f0 	movl   $0xf0101de8,(%esp)
f0100820:	e8 ac 01 00 00       	call   f01009d1 <cprintf>
	// Your code here.
	int i;
	uint32_t eip;
	uint32_t* ebp = (uint32_t *)read_ebp();

	while (ebp) {
f0100825:	85 f6                	test   %esi,%esi
f0100827:	0f 85 6e ff ff ff    	jne    f010079b <mon_backtrace+0x15>
		cprintf("\t%s:%d: %.*s+%d\n",
			debug_info.eip_file, debug_info.eip_line, debug_info.eip_fn_namelen,
			debug_info.eip_fn_name, eip - debug_info.eip_fn_addr);
	}
	return 0;
}
f010082d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100832:	83 c4 4c             	add    $0x4c,%esp
f0100835:	5b                   	pop    %ebx
f0100836:	5e                   	pop    %esi
f0100837:	5f                   	pop    %edi
f0100838:	5d                   	pop    %ebp
f0100839:	c3                   	ret    

f010083a <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010083a:	55                   	push   %ebp
f010083b:	89 e5                	mov    %esp,%ebp
f010083d:	57                   	push   %edi
f010083e:	56                   	push   %esi
f010083f:	53                   	push   %ebx
f0100840:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100843:	c7 04 24 1c 1f 10 f0 	movl   $0xf0101f1c,(%esp)
f010084a:	e8 82 01 00 00       	call   f01009d1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010084f:	c7 04 24 40 1f 10 f0 	movl   $0xf0101f40,(%esp)
f0100856:	e8 76 01 00 00       	call   f01009d1 <cprintf>


	while (1) {
		buf = readline("K> ");
f010085b:	c7 04 24 f9 1d 10 f0 	movl   $0xf0101df9,(%esp)
f0100862:	e8 b9 0a 00 00       	call   f0101320 <readline>
f0100867:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100869:	85 c0                	test   %eax,%eax
f010086b:	74 ee                	je     f010085b <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010086d:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100874:	be 00 00 00 00       	mov    $0x0,%esi
f0100879:	eb 0a                	jmp    f0100885 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010087b:	c6 03 00             	movb   $0x0,(%ebx)
f010087e:	89 f7                	mov    %esi,%edi
f0100880:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100883:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100885:	0f b6 03             	movzbl (%ebx),%eax
f0100888:	84 c0                	test   %al,%al
f010088a:	74 6a                	je     f01008f6 <monitor+0xbc>
f010088c:	0f be c0             	movsbl %al,%eax
f010088f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100893:	c7 04 24 fd 1d 10 f0 	movl   $0xf0101dfd,(%esp)
f010089a:	e8 cf 0c 00 00       	call   f010156e <strchr>
f010089f:	85 c0                	test   %eax,%eax
f01008a1:	75 d8                	jne    f010087b <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008a3:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008a6:	74 4e                	je     f01008f6 <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008a8:	83 fe 0f             	cmp    $0xf,%esi
f01008ab:	75 16                	jne    f01008c3 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008ad:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008b4:	00 
f01008b5:	c7 04 24 02 1e 10 f0 	movl   $0xf0101e02,(%esp)
f01008bc:	e8 10 01 00 00       	call   f01009d1 <cprintf>
f01008c1:	eb 98                	jmp    f010085b <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008c3:	8d 7e 01             	lea    0x1(%esi),%edi
f01008c6:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f01008ca:	0f b6 03             	movzbl (%ebx),%eax
f01008cd:	84 c0                	test   %al,%al
f01008cf:	75 0c                	jne    f01008dd <monitor+0xa3>
f01008d1:	eb b0                	jmp    f0100883 <monitor+0x49>
			buf++;
f01008d3:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d6:	0f b6 03             	movzbl (%ebx),%eax
f01008d9:	84 c0                	test   %al,%al
f01008db:	74 a6                	je     f0100883 <monitor+0x49>
f01008dd:	0f be c0             	movsbl %al,%eax
f01008e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e4:	c7 04 24 fd 1d 10 f0 	movl   $0xf0101dfd,(%esp)
f01008eb:	e8 7e 0c 00 00       	call   f010156e <strchr>
f01008f0:	85 c0                	test   %eax,%eax
f01008f2:	74 df                	je     f01008d3 <monitor+0x99>
f01008f4:	eb 8d                	jmp    f0100883 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f01008f6:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008fd:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008fe:	85 f6                	test   %esi,%esi
f0100900:	0f 84 55 ff ff ff    	je     f010085b <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100906:	c7 44 24 04 9e 1d 10 	movl   $0xf0101d9e,0x4(%esp)
f010090d:	f0 
f010090e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100911:	89 04 24             	mov    %eax,(%esp)
f0100914:	e8 d1 0b 00 00       	call   f01014ea <strcmp>
f0100919:	85 c0                	test   %eax,%eax
f010091b:	74 1b                	je     f0100938 <monitor+0xfe>
f010091d:	c7 44 24 04 ac 1d 10 	movl   $0xf0101dac,0x4(%esp)
f0100924:	f0 
f0100925:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100928:	89 04 24             	mov    %eax,(%esp)
f010092b:	e8 ba 0b 00 00       	call   f01014ea <strcmp>
f0100930:	85 c0                	test   %eax,%eax
f0100932:	75 2f                	jne    f0100963 <monitor+0x129>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100934:	b0 01                	mov    $0x1,%al
f0100936:	eb 05                	jmp    f010093d <monitor+0x103>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100938:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f010093d:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100940:	01 d0                	add    %edx,%eax
f0100942:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100945:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100949:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010094c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100950:	89 34 24             	mov    %esi,(%esp)
f0100953:	ff 14 85 70 1f 10 f0 	call   *-0xfefe090(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010095a:	85 c0                	test   %eax,%eax
f010095c:	78 1d                	js     f010097b <monitor+0x141>
f010095e:	e9 f8 fe ff ff       	jmp    f010085b <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100963:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100966:	89 44 24 04          	mov    %eax,0x4(%esp)
f010096a:	c7 04 24 1f 1e 10 f0 	movl   $0xf0101e1f,(%esp)
f0100971:	e8 5b 00 00 00       	call   f01009d1 <cprintf>
f0100976:	e9 e0 fe ff ff       	jmp    f010085b <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010097b:	83 c4 5c             	add    $0x5c,%esp
f010097e:	5b                   	pop    %ebx
f010097f:	5e                   	pop    %esi
f0100980:	5f                   	pop    %edi
f0100981:	5d                   	pop    %ebp
f0100982:	c3                   	ret    

f0100983 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100983:	55                   	push   %ebp
f0100984:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100986:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100989:	5d                   	pop    %ebp
f010098a:	c3                   	ret    

f010098b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010098b:	55                   	push   %ebp
f010098c:	89 e5                	mov    %esp,%ebp
f010098e:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100991:	8b 45 08             	mov    0x8(%ebp),%eax
f0100994:	89 04 24             	mov    %eax,(%esp)
f0100997:	e8 c8 fc ff ff       	call   f0100664 <cputchar>
	*cnt++;
}
f010099c:	c9                   	leave  
f010099d:	c3                   	ret    

f010099e <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010099e:	55                   	push   %ebp
f010099f:	89 e5                	mov    %esp,%ebp
f01009a1:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009a4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009ab:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009ae:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01009b5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009b9:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009c0:	c7 04 24 8b 09 10 f0 	movl   $0xf010098b,(%esp)
f01009c7:	e8 e8 04 00 00       	call   f0100eb4 <vprintfmt>
	return cnt;
}
f01009cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009cf:	c9                   	leave  
f01009d0:	c3                   	ret    

f01009d1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009d1:	55                   	push   %ebp
f01009d2:	89 e5                	mov    %esp,%ebp
f01009d4:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009d7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009da:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009de:	8b 45 08             	mov    0x8(%ebp),%eax
f01009e1:	89 04 24             	mov    %eax,(%esp)
f01009e4:	e8 b5 ff ff ff       	call   f010099e <vcprintf>
	va_end(ap);

	return cnt;
}
f01009e9:	c9                   	leave  
f01009ea:	c3                   	ret    
f01009eb:	66 90                	xchg   %ax,%ax
f01009ed:	66 90                	xchg   %ax,%ax
f01009ef:	90                   	nop

f01009f0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009f0:	55                   	push   %ebp
f01009f1:	89 e5                	mov    %esp,%ebp
f01009f3:	57                   	push   %edi
f01009f4:	56                   	push   %esi
f01009f5:	53                   	push   %ebx
f01009f6:	83 ec 10             	sub    $0x10,%esp
f01009f9:	89 c6                	mov    %eax,%esi
f01009fb:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009fe:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a01:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a04:	8b 1a                	mov    (%edx),%ebx
f0100a06:	8b 01                	mov    (%ecx),%eax
f0100a08:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a0b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100a12:	eb 77                	jmp    f0100a8b <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a14:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a17:	01 d8                	add    %ebx,%eax
f0100a19:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a1e:	99                   	cltd   
f0100a1f:	f7 f9                	idiv   %ecx
f0100a21:	89 c1                	mov    %eax,%ecx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a23:	eb 01                	jmp    f0100a26 <stab_binsearch+0x36>
			m--;
f0100a25:	49                   	dec    %ecx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a26:	39 d9                	cmp    %ebx,%ecx
f0100a28:	7c 1d                	jl     f0100a47 <stab_binsearch+0x57>
f0100a2a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a2d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a32:	39 fa                	cmp    %edi,%edx
f0100a34:	75 ef                	jne    f0100a25 <stab_binsearch+0x35>
f0100a36:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a39:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a3c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a40:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a43:	73 18                	jae    f0100a5d <stab_binsearch+0x6d>
f0100a45:	eb 05                	jmp    f0100a4c <stab_binsearch+0x5c>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a47:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a4a:	eb 3f                	jmp    f0100a8b <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a4c:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a4f:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a51:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a54:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a5b:	eb 2e                	jmp    f0100a8b <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a5d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a60:	73 15                	jae    f0100a77 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a62:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a65:	48                   	dec    %eax
f0100a66:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a69:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a6c:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a6e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a75:	eb 14                	jmp    f0100a8b <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a77:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a7a:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a7d:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100a7f:	ff 45 0c             	incl   0xc(%ebp)
f0100a82:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a84:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100a8b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a8e:	7e 84                	jle    f0100a14 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a90:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a94:	75 0d                	jne    f0100aa3 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a96:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a99:	8b 00                	mov    (%eax),%eax
f0100a9b:	48                   	dec    %eax
f0100a9c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a9f:	89 07                	mov    %eax,(%edi)
f0100aa1:	eb 22                	jmp    f0100ac5 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aa3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100aa6:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100aa8:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100aab:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aad:	eb 01                	jmp    f0100ab0 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100aaf:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ab0:	39 c1                	cmp    %eax,%ecx
f0100ab2:	7d 0c                	jge    f0100ac0 <stab_binsearch+0xd0>
f0100ab4:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100ab7:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100abc:	39 fa                	cmp    %edi,%edx
f0100abe:	75 ef                	jne    f0100aaf <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ac0:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100ac3:	89 07                	mov    %eax,(%edi)
	}
}
f0100ac5:	83 c4 10             	add    $0x10,%esp
f0100ac8:	5b                   	pop    %ebx
f0100ac9:	5e                   	pop    %esi
f0100aca:	5f                   	pop    %edi
f0100acb:	5d                   	pop    %ebp
f0100acc:	c3                   	ret    

f0100acd <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100acd:	55                   	push   %ebp
f0100ace:	89 e5                	mov    %esp,%ebp
f0100ad0:	57                   	push   %edi
f0100ad1:	56                   	push   %esi
f0100ad2:	53                   	push   %ebx
f0100ad3:	83 ec 3c             	sub    $0x3c,%esp
f0100ad6:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ad9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100adc:	c7 03 80 1f 10 f0    	movl   $0xf0101f80,(%ebx)
	info->eip_line = 0;
f0100ae2:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ae9:	c7 43 08 80 1f 10 f0 	movl   $0xf0101f80,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100af0:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100af7:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100afa:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b01:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b07:	76 12                	jbe    f0100b1b <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b09:	b8 2f 75 10 f0       	mov    $0xf010752f,%eax
f0100b0e:	3d 9d 5b 10 f0       	cmp    $0xf0105b9d,%eax
f0100b13:	0f 86 e9 01 00 00    	jbe    f0100d02 <debuginfo_eip+0x235>
f0100b19:	eb 1c                	jmp    f0100b37 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b1b:	c7 44 24 08 8a 1f 10 	movl   $0xf0101f8a,0x8(%esp)
f0100b22:	f0 
f0100b23:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b2a:	00 
f0100b2b:	c7 04 24 97 1f 10 f0 	movl   $0xf0101f97,(%esp)
f0100b32:	e8 c1 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b37:	80 3d 2e 75 10 f0 00 	cmpb   $0x0,0xf010752e
f0100b3e:	0f 85 c5 01 00 00    	jne    f0100d09 <debuginfo_eip+0x23c>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b44:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b4b:	b8 9c 5b 10 f0       	mov    $0xf0105b9c,%eax
f0100b50:	2d b8 21 10 f0       	sub    $0xf01021b8,%eax
f0100b55:	c1 f8 02             	sar    $0x2,%eax
f0100b58:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b5e:	83 e8 01             	sub    $0x1,%eax
f0100b61:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b64:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b68:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b6f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b72:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b75:	b8 b8 21 10 f0       	mov    $0xf01021b8,%eax
f0100b7a:	e8 71 fe ff ff       	call   f01009f0 <stab_binsearch>
	if (lfile == 0)
f0100b7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b82:	85 c0                	test   %eax,%eax
f0100b84:	0f 84 86 01 00 00    	je     f0100d10 <debuginfo_eip+0x243>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b8a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b8d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b90:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b93:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b97:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b9e:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ba1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ba4:	b8 b8 21 10 f0       	mov    $0xf01021b8,%eax
f0100ba9:	e8 42 fe ff ff       	call   f01009f0 <stab_binsearch>

	if (lfun <= rfun) {
f0100bae:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bb1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100bb4:	39 d0                	cmp    %edx,%eax
f0100bb6:	7f 3d                	jg     f0100bf5 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bb8:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100bbb:	8d b9 b8 21 10 f0    	lea    -0xfefde48(%ecx),%edi
f0100bc1:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bc4:	8b 89 b8 21 10 f0    	mov    -0xfefde48(%ecx),%ecx
f0100bca:	bf 2f 75 10 f0       	mov    $0xf010752f,%edi
f0100bcf:	81 ef 9d 5b 10 f0    	sub    $0xf0105b9d,%edi
f0100bd5:	39 f9                	cmp    %edi,%ecx
f0100bd7:	73 09                	jae    f0100be2 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bd9:	81 c1 9d 5b 10 f0    	add    $0xf0105b9d,%ecx
f0100bdf:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100be2:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100be5:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100be8:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100beb:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bed:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bf0:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100bf3:	eb 0f                	jmp    f0100c04 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bf5:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bf8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bfb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bfe:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c01:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c04:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c0b:	00 
f0100c0c:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c0f:	89 04 24             	mov    %eax,(%esp)
f0100c12:	e8 8d 09 00 00       	call   f01015a4 <strfind>
f0100c17:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c1a:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c1d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c21:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c28:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c2b:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c2e:	b8 b8 21 10 f0       	mov    $0xf01021b8,%eax
f0100c33:	e8 b8 fd ff ff       	call   f01009f0 <stab_binsearch>
	if (lline <= rline) {
f0100c38:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100c3b:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0100c3e:	0f 8f d3 00 00 00    	jg     f0100d17 <debuginfo_eip+0x24a>
    		info->eip_line = stabs[rline].n_desc;
f0100c44:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c47:	0f b7 80 be 21 10 f0 	movzwl -0xfefde42(%eax),%eax
f0100c4e:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c51:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100c54:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c57:	39 f2                	cmp    %esi,%edx
f0100c59:	7c 5c                	jl     f0100cb7 <debuginfo_eip+0x1ea>
	       && stabs[lline].n_type != N_SOL
f0100c5b:	6b c2 0c             	imul   $0xc,%edx,%eax
f0100c5e:	8d b8 b8 21 10 f0    	lea    -0xfefde48(%eax),%edi
f0100c64:	0f b6 4f 04          	movzbl 0x4(%edi),%ecx
f0100c68:	80 f9 84             	cmp    $0x84,%cl
f0100c6b:	74 2b                	je     f0100c98 <debuginfo_eip+0x1cb>
f0100c6d:	05 ac 21 10 f0       	add    $0xf01021ac,%eax
f0100c72:	eb 15                	jmp    f0100c89 <debuginfo_eip+0x1bc>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c74:	83 ea 01             	sub    $0x1,%edx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c77:	39 f2                	cmp    %esi,%edx
f0100c79:	7c 3c                	jl     f0100cb7 <debuginfo_eip+0x1ea>
	       && stabs[lline].n_type != N_SOL
f0100c7b:	89 c7                	mov    %eax,%edi
f0100c7d:	83 e8 0c             	sub    $0xc,%eax
f0100c80:	0f b6 48 10          	movzbl 0x10(%eax),%ecx
f0100c84:	80 f9 84             	cmp    $0x84,%cl
f0100c87:	74 0f                	je     f0100c98 <debuginfo_eip+0x1cb>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c89:	80 f9 64             	cmp    $0x64,%cl
f0100c8c:	75 e6                	jne    f0100c74 <debuginfo_eip+0x1a7>
f0100c8e:	83 7f 08 00          	cmpl   $0x0,0x8(%edi)
f0100c92:	74 e0                	je     f0100c74 <debuginfo_eip+0x1a7>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c94:	39 d6                	cmp    %edx,%esi
f0100c96:	7f 1f                	jg     f0100cb7 <debuginfo_eip+0x1ea>
f0100c98:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100c9b:	8b 82 b8 21 10 f0    	mov    -0xfefde48(%edx),%eax
f0100ca1:	ba 2f 75 10 f0       	mov    $0xf010752f,%edx
f0100ca6:	81 ea 9d 5b 10 f0    	sub    $0xf0105b9d,%edx
f0100cac:	39 d0                	cmp    %edx,%eax
f0100cae:	73 07                	jae    f0100cb7 <debuginfo_eip+0x1ea>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cb0:	05 9d 5b 10 f0       	add    $0xf0105b9d,%eax
f0100cb5:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cb7:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100cba:	8b 55 d8             	mov    -0x28(%ebp),%edx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100cbd:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cc2:	39 d6                	cmp    %edx,%esi
f0100cc4:	7d 72                	jge    f0100d38 <debuginfo_eip+0x26b>
		for (lline = lfun + 1;
f0100cc6:	8d 46 01             	lea    0x1(%esi),%eax
f0100cc9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100ccc:	39 c2                	cmp    %eax,%edx
f0100cce:	7e 4e                	jle    f0100d1e <debuginfo_eip+0x251>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cd0:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100cd3:	80 b9 bc 21 10 f0 a0 	cmpb   $0xa0,-0xfefde44(%ecx)
f0100cda:	75 49                	jne    f0100d25 <debuginfo_eip+0x258>
f0100cdc:	8d 46 02             	lea    0x2(%esi),%eax
f0100cdf:	81 c1 ac 21 10 f0    	add    $0xf01021ac,%ecx
f0100ce5:	89 d7                	mov    %edx,%edi
		     lline++)
			info->eip_fn_narg++;
f0100ce7:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100ceb:	39 f8                	cmp    %edi,%eax
f0100ced:	74 3d                	je     f0100d2c <debuginfo_eip+0x25f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cef:	0f b6 71 1c          	movzbl 0x1c(%ecx),%esi
f0100cf3:	83 c0 01             	add    $0x1,%eax
f0100cf6:	83 c1 0c             	add    $0xc,%ecx
f0100cf9:	89 f2                	mov    %esi,%edx
f0100cfb:	80 fa a0             	cmp    $0xa0,%dl
f0100cfe:	74 e7                	je     f0100ce7 <debuginfo_eip+0x21a>
f0100d00:	eb 31                	jmp    f0100d33 <debuginfo_eip+0x266>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d07:	eb 2f                	jmp    f0100d38 <debuginfo_eip+0x26b>
f0100d09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d0e:	eb 28                	jmp    f0100d38 <debuginfo_eip+0x26b>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d10:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d15:	eb 21                	jmp    f0100d38 <debuginfo_eip+0x26b>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if (lline <= rline) {
    		info->eip_line = stabs[rline].n_desc;
	} else {
  	  return -1;
f0100d17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d1c:	eb 1a                	jmp    f0100d38 <debuginfo_eip+0x26b>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100d1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d23:	eb 13                	jmp    f0100d38 <debuginfo_eip+0x26b>
f0100d25:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d2a:	eb 0c                	jmp    f0100d38 <debuginfo_eip+0x26b>
f0100d2c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d31:	eb 05                	jmp    f0100d38 <debuginfo_eip+0x26b>
f0100d33:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d38:	83 c4 3c             	add    $0x3c,%esp
f0100d3b:	5b                   	pop    %ebx
f0100d3c:	5e                   	pop    %esi
f0100d3d:	5f                   	pop    %edi
f0100d3e:	5d                   	pop    %ebp
f0100d3f:	c3                   	ret    

f0100d40 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d40:	55                   	push   %ebp
f0100d41:	89 e5                	mov    %esp,%ebp
f0100d43:	57                   	push   %edi
f0100d44:	56                   	push   %esi
f0100d45:	53                   	push   %ebx
f0100d46:	83 ec 3c             	sub    $0x3c,%esp
f0100d49:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d4c:	89 d7                	mov    %edx,%edi
f0100d4e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d51:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d54:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100d57:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100d5a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d5d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d62:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d65:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d68:	39 f1                	cmp    %esi,%ecx
f0100d6a:	72 14                	jb     f0100d80 <printnum+0x40>
f0100d6c:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d6f:	76 0f                	jbe    f0100d80 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d71:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d74:	8d 70 ff             	lea    -0x1(%eax),%esi
f0100d77:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100d7a:	85 f6                	test   %esi,%esi
f0100d7c:	7f 60                	jg     f0100dde <printnum+0x9e>
f0100d7e:	eb 72                	jmp    f0100df2 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d80:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d83:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d87:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0100d8a:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100d8d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100d91:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d95:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d99:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d9d:	89 c3                	mov    %eax,%ebx
f0100d9f:	89 d6                	mov    %edx,%esi
f0100da1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100da4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100da7:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100dab:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100daf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100db2:	89 04 24             	mov    %eax,(%esp)
f0100db5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100db8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dbc:	e8 4f 0a 00 00       	call   f0101810 <__udivdi3>
f0100dc1:	89 d9                	mov    %ebx,%ecx
f0100dc3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100dc7:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100dcb:	89 04 24             	mov    %eax,(%esp)
f0100dce:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100dd2:	89 fa                	mov    %edi,%edx
f0100dd4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dd7:	e8 64 ff ff ff       	call   f0100d40 <printnum>
f0100ddc:	eb 14                	jmp    f0100df2 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dde:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100de2:	8b 45 18             	mov    0x18(%ebp),%eax
f0100de5:	89 04 24             	mov    %eax,(%esp)
f0100de8:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100dea:	83 ee 01             	sub    $0x1,%esi
f0100ded:	75 ef                	jne    f0100dde <printnum+0x9e>
f0100def:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100df2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100df6:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100dfa:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100dfd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e00:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e04:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100e08:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e0b:	89 04 24             	mov    %eax,(%esp)
f0100e0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e11:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e15:	e8 26 0b 00 00       	call   f0101940 <__umoddi3>
f0100e1a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e1e:	0f be 80 a5 1f 10 f0 	movsbl -0xfefe05b(%eax),%eax
f0100e25:	89 04 24             	mov    %eax,(%esp)
f0100e28:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e2b:	ff d0                	call   *%eax
}
f0100e2d:	83 c4 3c             	add    $0x3c,%esp
f0100e30:	5b                   	pop    %ebx
f0100e31:	5e                   	pop    %esi
f0100e32:	5f                   	pop    %edi
f0100e33:	5d                   	pop    %ebp
f0100e34:	c3                   	ret    

f0100e35 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e35:	55                   	push   %ebp
f0100e36:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e38:	83 fa 01             	cmp    $0x1,%edx
f0100e3b:	7e 0e                	jle    f0100e4b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e3d:	8b 10                	mov    (%eax),%edx
f0100e3f:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e42:	89 08                	mov    %ecx,(%eax)
f0100e44:	8b 02                	mov    (%edx),%eax
f0100e46:	8b 52 04             	mov    0x4(%edx),%edx
f0100e49:	eb 22                	jmp    f0100e6d <getuint+0x38>
	else if (lflag)
f0100e4b:	85 d2                	test   %edx,%edx
f0100e4d:	74 10                	je     f0100e5f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e4f:	8b 10                	mov    (%eax),%edx
f0100e51:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e54:	89 08                	mov    %ecx,(%eax)
f0100e56:	8b 02                	mov    (%edx),%eax
f0100e58:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e5d:	eb 0e                	jmp    f0100e6d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e5f:	8b 10                	mov    (%eax),%edx
f0100e61:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e64:	89 08                	mov    %ecx,(%eax)
f0100e66:	8b 02                	mov    (%edx),%eax
f0100e68:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e6d:	5d                   	pop    %ebp
f0100e6e:	c3                   	ret    

f0100e6f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e6f:	55                   	push   %ebp
f0100e70:	89 e5                	mov    %esp,%ebp
f0100e72:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e75:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e79:	8b 10                	mov    (%eax),%edx
f0100e7b:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e7e:	73 0a                	jae    f0100e8a <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e80:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e83:	89 08                	mov    %ecx,(%eax)
f0100e85:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e88:	88 02                	mov    %al,(%edx)
}
f0100e8a:	5d                   	pop    %ebp
f0100e8b:	c3                   	ret    

f0100e8c <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e8c:	55                   	push   %ebp
f0100e8d:	89 e5                	mov    %esp,%ebp
f0100e8f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e92:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e95:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e99:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e9c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ea0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ea3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ea7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eaa:	89 04 24             	mov    %eax,(%esp)
f0100ead:	e8 02 00 00 00       	call   f0100eb4 <vprintfmt>
	va_end(ap);
}
f0100eb2:	c9                   	leave  
f0100eb3:	c3                   	ret    

f0100eb4 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100eb4:	55                   	push   %ebp
f0100eb5:	89 e5                	mov    %esp,%ebp
f0100eb7:	57                   	push   %edi
f0100eb8:	56                   	push   %esi
f0100eb9:	53                   	push   %ebx
f0100eba:	83 ec 3c             	sub    $0x3c,%esp
f0100ebd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100ec0:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100ec3:	eb 18                	jmp    f0100edd <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100ec5:	85 c0                	test   %eax,%eax
f0100ec7:	0f 84 c3 03 00 00    	je     f0101290 <vprintfmt+0x3dc>
				return;
			putch(ch, putdat);
f0100ecd:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ed1:	89 04 24             	mov    %eax,(%esp)
f0100ed4:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ed7:	89 f3                	mov    %esi,%ebx
f0100ed9:	eb 02                	jmp    f0100edd <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100edb:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100edd:	8d 73 01             	lea    0x1(%ebx),%esi
f0100ee0:	0f b6 03             	movzbl (%ebx),%eax
f0100ee3:	83 f8 25             	cmp    $0x25,%eax
f0100ee6:	75 dd                	jne    f0100ec5 <vprintfmt+0x11>
f0100ee8:	c6 45 e3 20          	movb   $0x20,-0x1d(%ebp)
f0100eec:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100ef3:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100efa:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100f01:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f06:	eb 1d                	jmp    f0100f25 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f08:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f0a:	c6 45 e3 2d          	movb   $0x2d,-0x1d(%ebp)
f0100f0e:	eb 15                	jmp    f0100f25 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f10:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f12:	c6 45 e3 30          	movb   $0x30,-0x1d(%ebp)
f0100f16:	eb 0d                	jmp    f0100f25 <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f18:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f1b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f1e:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f25:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100f28:	0f b6 06             	movzbl (%esi),%eax
f0100f2b:	0f b6 c8             	movzbl %al,%ecx
f0100f2e:	83 e8 23             	sub    $0x23,%eax
f0100f31:	3c 55                	cmp    $0x55,%al
f0100f33:	0f 87 2f 03 00 00    	ja     f0101268 <vprintfmt+0x3b4>
f0100f39:	0f b6 c0             	movzbl %al,%eax
f0100f3c:	ff 24 85 34 20 10 f0 	jmp    *-0xfefdfcc(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f43:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0100f46:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				ch = *fmt;
f0100f49:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100f4d:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100f50:	83 f9 09             	cmp    $0x9,%ecx
f0100f53:	77 50                	ja     f0100fa5 <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f55:	89 de                	mov    %ebx,%esi
f0100f57:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f5a:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100f5d:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f60:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f64:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f67:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f6a:	83 fb 09             	cmp    $0x9,%ebx
f0100f6d:	76 eb                	jbe    f0100f5a <vprintfmt+0xa6>
f0100f6f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100f72:	eb 33                	jmp    f0100fa7 <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f74:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f77:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f7a:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f7d:	8b 00                	mov    (%eax),%eax
f0100f7f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f82:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f84:	eb 21                	jmp    f0100fa7 <vprintfmt+0xf3>
f0100f86:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f89:	85 c9                	test   %ecx,%ecx
f0100f8b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f90:	0f 49 c1             	cmovns %ecx,%eax
f0100f93:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f96:	89 de                	mov    %ebx,%esi
f0100f98:	eb 8b                	jmp    f0100f25 <vprintfmt+0x71>
f0100f9a:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f9c:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100fa3:	eb 80                	jmp    f0100f25 <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa5:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100fa7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100fab:	0f 89 74 ff ff ff    	jns    f0100f25 <vprintfmt+0x71>
f0100fb1:	e9 62 ff ff ff       	jmp    f0100f18 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fb6:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fb9:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100fbb:	e9 65 ff ff ff       	jmp    f0100f25 <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fc0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fc3:	8d 50 04             	lea    0x4(%eax),%edx
f0100fc6:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fc9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fcd:	8b 00                	mov    (%eax),%eax
f0100fcf:	89 04 24             	mov    %eax,(%esp)
f0100fd2:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100fd5:	e9 03 ff ff ff       	jmp    f0100edd <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fda:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fdd:	8d 50 04             	lea    0x4(%eax),%edx
f0100fe0:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fe3:	8b 00                	mov    (%eax),%eax
f0100fe5:	99                   	cltd   
f0100fe6:	31 d0                	xor    %edx,%eax
f0100fe8:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fea:	83 f8 06             	cmp    $0x6,%eax
f0100fed:	7f 0b                	jg     f0100ffa <vprintfmt+0x146>
f0100fef:	8b 14 85 8c 21 10 f0 	mov    -0xfefde74(,%eax,4),%edx
f0100ff6:	85 d2                	test   %edx,%edx
f0100ff8:	75 20                	jne    f010101a <vprintfmt+0x166>
				printfmt(putch, putdat, "error %d", err);
f0100ffa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ffe:	c7 44 24 08 bd 1f 10 	movl   $0xf0101fbd,0x8(%esp)
f0101005:	f0 
f0101006:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010100a:	8b 45 08             	mov    0x8(%ebp),%eax
f010100d:	89 04 24             	mov    %eax,(%esp)
f0101010:	e8 77 fe ff ff       	call   f0100e8c <printfmt>
f0101015:	e9 c3 fe ff ff       	jmp    f0100edd <vprintfmt+0x29>
			else
				printfmt(putch, putdat, "%s", p);
f010101a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010101e:	c7 44 24 08 c6 1f 10 	movl   $0xf0101fc6,0x8(%esp)
f0101025:	f0 
f0101026:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010102a:	8b 45 08             	mov    0x8(%ebp),%eax
f010102d:	89 04 24             	mov    %eax,(%esp)
f0101030:	e8 57 fe ff ff       	call   f0100e8c <printfmt>
f0101035:	e9 a3 fe ff ff       	jmp    f0100edd <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010103a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010103d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101040:	8b 45 14             	mov    0x14(%ebp),%eax
f0101043:	8d 50 04             	lea    0x4(%eax),%edx
f0101046:	89 55 14             	mov    %edx,0x14(%ebp)
f0101049:	8b 00                	mov    (%eax),%eax
				p = "(null)";
f010104b:	85 c0                	test   %eax,%eax
f010104d:	ba b6 1f 10 f0       	mov    $0xf0101fb6,%edx
f0101052:	0f 45 d0             	cmovne %eax,%edx
f0101055:	89 55 d0             	mov    %edx,-0x30(%ebp)
			if (width > 0 && padc != '-')
f0101058:	80 7d e3 2d          	cmpb   $0x2d,-0x1d(%ebp)
f010105c:	74 04                	je     f0101062 <vprintfmt+0x1ae>
f010105e:	85 f6                	test   %esi,%esi
f0101060:	7f 19                	jg     f010107b <vprintfmt+0x1c7>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101062:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101065:	8d 70 01             	lea    0x1(%eax),%esi
f0101068:	0f b6 10             	movzbl (%eax),%edx
f010106b:	0f be c2             	movsbl %dl,%eax
f010106e:	85 c0                	test   %eax,%eax
f0101070:	0f 85 95 00 00 00    	jne    f010110b <vprintfmt+0x257>
f0101076:	e9 85 00 00 00       	jmp    f0101100 <vprintfmt+0x24c>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010107b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010107f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101082:	89 04 24             	mov    %eax,(%esp)
f0101085:	e8 88 03 00 00       	call   f0101412 <strnlen>
f010108a:	29 c6                	sub    %eax,%esi
f010108c:	89 f0                	mov    %esi,%eax
f010108e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101091:	85 f6                	test   %esi,%esi
f0101093:	7e cd                	jle    f0101062 <vprintfmt+0x1ae>
					putch(padc, putdat);
f0101095:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0101099:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010109c:	89 c3                	mov    %eax,%ebx
f010109e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010a2:	89 34 24             	mov    %esi,(%esp)
f01010a5:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010a8:	83 eb 01             	sub    $0x1,%ebx
f01010ab:	75 f1                	jne    f010109e <vprintfmt+0x1ea>
f01010ad:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01010b0:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01010b3:	eb ad                	jmp    f0101062 <vprintfmt+0x1ae>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010b5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01010b9:	74 1e                	je     f01010d9 <vprintfmt+0x225>
f01010bb:	0f be d2             	movsbl %dl,%edx
f01010be:	83 ea 20             	sub    $0x20,%edx
f01010c1:	83 fa 5e             	cmp    $0x5e,%edx
f01010c4:	76 13                	jbe    f01010d9 <vprintfmt+0x225>
					putch('?', putdat);
f01010c6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010cd:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01010d4:	ff 55 08             	call   *0x8(%ebp)
f01010d7:	eb 0d                	jmp    f01010e6 <vprintfmt+0x232>
				else
					putch(ch, putdat);
f01010d9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01010dc:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01010e0:	89 04 24             	mov    %eax,(%esp)
f01010e3:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010e6:	83 ef 01             	sub    $0x1,%edi
f01010e9:	83 c6 01             	add    $0x1,%esi
f01010ec:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01010f0:	0f be c2             	movsbl %dl,%eax
f01010f3:	85 c0                	test   %eax,%eax
f01010f5:	75 20                	jne    f0101117 <vprintfmt+0x263>
f01010f7:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01010fa:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010fd:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101100:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101104:	7f 25                	jg     f010112b <vprintfmt+0x277>
f0101106:	e9 d2 fd ff ff       	jmp    f0100edd <vprintfmt+0x29>
f010110b:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010110e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101111:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101114:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101117:	85 db                	test   %ebx,%ebx
f0101119:	78 9a                	js     f01010b5 <vprintfmt+0x201>
f010111b:	83 eb 01             	sub    $0x1,%ebx
f010111e:	79 95                	jns    f01010b5 <vprintfmt+0x201>
f0101120:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f0101123:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101126:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101129:	eb d5                	jmp    f0101100 <vprintfmt+0x24c>
f010112b:	8b 75 08             	mov    0x8(%ebp),%esi
f010112e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101131:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101134:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101138:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010113f:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101141:	83 eb 01             	sub    $0x1,%ebx
f0101144:	75 ee                	jne    f0101134 <vprintfmt+0x280>
f0101146:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0101149:	e9 8f fd ff ff       	jmp    f0100edd <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010114e:	83 fa 01             	cmp    $0x1,%edx
f0101151:	7e 16                	jle    f0101169 <vprintfmt+0x2b5>
		return va_arg(*ap, long long);
f0101153:	8b 45 14             	mov    0x14(%ebp),%eax
f0101156:	8d 50 08             	lea    0x8(%eax),%edx
f0101159:	89 55 14             	mov    %edx,0x14(%ebp)
f010115c:	8b 50 04             	mov    0x4(%eax),%edx
f010115f:	8b 00                	mov    (%eax),%eax
f0101161:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101164:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101167:	eb 32                	jmp    f010119b <vprintfmt+0x2e7>
	else if (lflag)
f0101169:	85 d2                	test   %edx,%edx
f010116b:	74 18                	je     f0101185 <vprintfmt+0x2d1>
		return va_arg(*ap, long);
f010116d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101170:	8d 50 04             	lea    0x4(%eax),%edx
f0101173:	89 55 14             	mov    %edx,0x14(%ebp)
f0101176:	8b 30                	mov    (%eax),%esi
f0101178:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010117b:	89 f0                	mov    %esi,%eax
f010117d:	c1 f8 1f             	sar    $0x1f,%eax
f0101180:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101183:	eb 16                	jmp    f010119b <vprintfmt+0x2e7>
	else
		return va_arg(*ap, int);
f0101185:	8b 45 14             	mov    0x14(%ebp),%eax
f0101188:	8d 50 04             	lea    0x4(%eax),%edx
f010118b:	89 55 14             	mov    %edx,0x14(%ebp)
f010118e:	8b 30                	mov    (%eax),%esi
f0101190:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0101193:	89 f0                	mov    %esi,%eax
f0101195:	c1 f8 1f             	sar    $0x1f,%eax
f0101198:	89 45 dc             	mov    %eax,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010119b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010119e:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01011a1:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01011a6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01011aa:	0f 89 80 00 00 00    	jns    f0101230 <vprintfmt+0x37c>
				putch('-', putdat);
f01011b0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011b4:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01011bb:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01011be:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01011c1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01011c4:	f7 d8                	neg    %eax
f01011c6:	83 d2 00             	adc    $0x0,%edx
f01011c9:	f7 da                	neg    %edx
			}
			base = 10;
f01011cb:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01011d0:	eb 5e                	jmp    f0101230 <vprintfmt+0x37c>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01011d2:	8d 45 14             	lea    0x14(%ebp),%eax
f01011d5:	e8 5b fc ff ff       	call   f0100e35 <getuint>
			base = 10;
f01011da:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01011df:	eb 4f                	jmp    f0101230 <vprintfmt+0x37c>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f01011e1:	8d 45 14             	lea    0x14(%ebp),%eax
f01011e4:	e8 4c fc ff ff       	call   f0100e35 <getuint>
			base = 8;
f01011e9:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01011ee:	eb 40                	jmp    f0101230 <vprintfmt+0x37c>


		// pointer
		case 'p':
			putch('0', putdat);
f01011f0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011f4:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011fb:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011fe:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101202:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101209:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010120c:	8b 45 14             	mov    0x14(%ebp),%eax
f010120f:	8d 50 04             	lea    0x4(%eax),%edx
f0101212:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101215:	8b 00                	mov    (%eax),%eax
f0101217:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010121c:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101221:	eb 0d                	jmp    f0101230 <vprintfmt+0x37c>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101223:	8d 45 14             	lea    0x14(%ebp),%eax
f0101226:	e8 0a fc ff ff       	call   f0100e35 <getuint>
			base = 16;
f010122b:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101230:	0f be 75 e3          	movsbl -0x1d(%ebp),%esi
f0101234:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101238:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010123b:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010123f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101243:	89 04 24             	mov    %eax,(%esp)
f0101246:	89 54 24 04          	mov    %edx,0x4(%esp)
f010124a:	89 fa                	mov    %edi,%edx
f010124c:	8b 45 08             	mov    0x8(%ebp),%eax
f010124f:	e8 ec fa ff ff       	call   f0100d40 <printnum>
			break;
f0101254:	e9 84 fc ff ff       	jmp    f0100edd <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101259:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010125d:	89 0c 24             	mov    %ecx,(%esp)
f0101260:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101263:	e9 75 fc ff ff       	jmp    f0100edd <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101268:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010126c:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101273:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101276:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010127a:	0f 84 5b fc ff ff    	je     f0100edb <vprintfmt+0x27>
f0101280:	89 f3                	mov    %esi,%ebx
f0101282:	83 eb 01             	sub    $0x1,%ebx
f0101285:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101289:	75 f7                	jne    f0101282 <vprintfmt+0x3ce>
f010128b:	e9 4d fc ff ff       	jmp    f0100edd <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
f0101290:	83 c4 3c             	add    $0x3c,%esp
f0101293:	5b                   	pop    %ebx
f0101294:	5e                   	pop    %esi
f0101295:	5f                   	pop    %edi
f0101296:	5d                   	pop    %ebp
f0101297:	c3                   	ret    

f0101298 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101298:	55                   	push   %ebp
f0101299:	89 e5                	mov    %esp,%ebp
f010129b:	83 ec 28             	sub    $0x28,%esp
f010129e:	8b 45 08             	mov    0x8(%ebp),%eax
f01012a1:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012a4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012a7:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01012ab:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01012ae:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01012b5:	85 c0                	test   %eax,%eax
f01012b7:	74 30                	je     f01012e9 <vsnprintf+0x51>
f01012b9:	85 d2                	test   %edx,%edx
f01012bb:	7e 2c                	jle    f01012e9 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01012bd:	8b 45 14             	mov    0x14(%ebp),%eax
f01012c0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012c4:	8b 45 10             	mov    0x10(%ebp),%eax
f01012c7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012cb:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01012ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012d2:	c7 04 24 6f 0e 10 f0 	movl   $0xf0100e6f,(%esp)
f01012d9:	e8 d6 fb ff ff       	call   f0100eb4 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012de:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012e1:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012e7:	eb 05                	jmp    f01012ee <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012e9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012ee:	c9                   	leave  
f01012ef:	c3                   	ret    

f01012f0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012f0:	55                   	push   %ebp
f01012f1:	89 e5                	mov    %esp,%ebp
f01012f3:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012f6:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012fd:	8b 45 10             	mov    0x10(%ebp),%eax
f0101300:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101304:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101307:	89 44 24 04          	mov    %eax,0x4(%esp)
f010130b:	8b 45 08             	mov    0x8(%ebp),%eax
f010130e:	89 04 24             	mov    %eax,(%esp)
f0101311:	e8 82 ff ff ff       	call   f0101298 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101316:	c9                   	leave  
f0101317:	c3                   	ret    
f0101318:	66 90                	xchg   %ax,%ax
f010131a:	66 90                	xchg   %ax,%ax
f010131c:	66 90                	xchg   %ax,%ax
f010131e:	66 90                	xchg   %ax,%ax

f0101320 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101320:	55                   	push   %ebp
f0101321:	89 e5                	mov    %esp,%ebp
f0101323:	57                   	push   %edi
f0101324:	56                   	push   %esi
f0101325:	53                   	push   %ebx
f0101326:	83 ec 1c             	sub    $0x1c,%esp
f0101329:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010132c:	85 c0                	test   %eax,%eax
f010132e:	74 10                	je     f0101340 <readline+0x20>
		cprintf("%s", prompt);
f0101330:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101334:	c7 04 24 c6 1f 10 f0 	movl   $0xf0101fc6,(%esp)
f010133b:	e8 91 f6 ff ff       	call   f01009d1 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101340:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101347:	e8 39 f3 ff ff       	call   f0100685 <iscons>
f010134c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010134e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101353:	e8 1c f3 ff ff       	call   f0100674 <getchar>
f0101358:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010135a:	85 c0                	test   %eax,%eax
f010135c:	79 17                	jns    f0101375 <readline+0x55>
			cprintf("read error: %e\n", c);
f010135e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101362:	c7 04 24 a8 21 10 f0 	movl   $0xf01021a8,(%esp)
f0101369:	e8 63 f6 ff ff       	call   f01009d1 <cprintf>
			return NULL;
f010136e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101373:	eb 6d                	jmp    f01013e2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101375:	83 f8 7f             	cmp    $0x7f,%eax
f0101378:	74 05                	je     f010137f <readline+0x5f>
f010137a:	83 f8 08             	cmp    $0x8,%eax
f010137d:	75 19                	jne    f0101398 <readline+0x78>
f010137f:	85 f6                	test   %esi,%esi
f0101381:	7e 15                	jle    f0101398 <readline+0x78>
			if (echoing)
f0101383:	85 ff                	test   %edi,%edi
f0101385:	74 0c                	je     f0101393 <readline+0x73>
				cputchar('\b');
f0101387:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010138e:	e8 d1 f2 ff ff       	call   f0100664 <cputchar>
			i--;
f0101393:	83 ee 01             	sub    $0x1,%esi
f0101396:	eb bb                	jmp    f0101353 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101398:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010139e:	7f 1c                	jg     f01013bc <readline+0x9c>
f01013a0:	83 fb 1f             	cmp    $0x1f,%ebx
f01013a3:	7e 17                	jle    f01013bc <readline+0x9c>
			if (echoing)
f01013a5:	85 ff                	test   %edi,%edi
f01013a7:	74 08                	je     f01013b1 <readline+0x91>
				cputchar(c);
f01013a9:	89 1c 24             	mov    %ebx,(%esp)
f01013ac:	e8 b3 f2 ff ff       	call   f0100664 <cputchar>
			buf[i++] = c;
f01013b1:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f01013b7:	8d 76 01             	lea    0x1(%esi),%esi
f01013ba:	eb 97                	jmp    f0101353 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01013bc:	83 fb 0d             	cmp    $0xd,%ebx
f01013bf:	74 05                	je     f01013c6 <readline+0xa6>
f01013c1:	83 fb 0a             	cmp    $0xa,%ebx
f01013c4:	75 8d                	jne    f0101353 <readline+0x33>
			if (echoing)
f01013c6:	85 ff                	test   %edi,%edi
f01013c8:	74 0c                	je     f01013d6 <readline+0xb6>
				cputchar('\n');
f01013ca:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01013d1:	e8 8e f2 ff ff       	call   f0100664 <cputchar>
			buf[i] = 0;
f01013d6:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f01013dd:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f01013e2:	83 c4 1c             	add    $0x1c,%esp
f01013e5:	5b                   	pop    %ebx
f01013e6:	5e                   	pop    %esi
f01013e7:	5f                   	pop    %edi
f01013e8:	5d                   	pop    %ebp
f01013e9:	c3                   	ret    
f01013ea:	66 90                	xchg   %ax,%ax
f01013ec:	66 90                	xchg   %ax,%ax
f01013ee:	66 90                	xchg   %ax,%ax

f01013f0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013f0:	55                   	push   %ebp
f01013f1:	89 e5                	mov    %esp,%ebp
f01013f3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013f6:	80 3a 00             	cmpb   $0x0,(%edx)
f01013f9:	74 10                	je     f010140b <strlen+0x1b>
f01013fb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101400:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101403:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101407:	75 f7                	jne    f0101400 <strlen+0x10>
f0101409:	eb 05                	jmp    f0101410 <strlen+0x20>
f010140b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101410:	5d                   	pop    %ebp
f0101411:	c3                   	ret    

f0101412 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101412:	55                   	push   %ebp
f0101413:	89 e5                	mov    %esp,%ebp
f0101415:	53                   	push   %ebx
f0101416:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101419:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010141c:	85 c9                	test   %ecx,%ecx
f010141e:	74 1c                	je     f010143c <strnlen+0x2a>
f0101420:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101423:	74 1e                	je     f0101443 <strnlen+0x31>
f0101425:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010142a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010142c:	39 ca                	cmp    %ecx,%edx
f010142e:	74 18                	je     f0101448 <strnlen+0x36>
f0101430:	83 c2 01             	add    $0x1,%edx
f0101433:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101438:	75 f0                	jne    f010142a <strnlen+0x18>
f010143a:	eb 0c                	jmp    f0101448 <strnlen+0x36>
f010143c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101441:	eb 05                	jmp    f0101448 <strnlen+0x36>
f0101443:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101448:	5b                   	pop    %ebx
f0101449:	5d                   	pop    %ebp
f010144a:	c3                   	ret    

f010144b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010144b:	55                   	push   %ebp
f010144c:	89 e5                	mov    %esp,%ebp
f010144e:	53                   	push   %ebx
f010144f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101452:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101455:	89 c2                	mov    %eax,%edx
f0101457:	83 c2 01             	add    $0x1,%edx
f010145a:	83 c1 01             	add    $0x1,%ecx
f010145d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101461:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101464:	84 db                	test   %bl,%bl
f0101466:	75 ef                	jne    f0101457 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101468:	5b                   	pop    %ebx
f0101469:	5d                   	pop    %ebp
f010146a:	c3                   	ret    

f010146b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010146b:	55                   	push   %ebp
f010146c:	89 e5                	mov    %esp,%ebp
f010146e:	56                   	push   %esi
f010146f:	53                   	push   %ebx
f0101470:	8b 75 08             	mov    0x8(%ebp),%esi
f0101473:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101476:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101479:	85 db                	test   %ebx,%ebx
f010147b:	74 17                	je     f0101494 <strncpy+0x29>
f010147d:	01 f3                	add    %esi,%ebx
f010147f:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f0101481:	83 c1 01             	add    $0x1,%ecx
f0101484:	0f b6 02             	movzbl (%edx),%eax
f0101487:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010148a:	80 3a 01             	cmpb   $0x1,(%edx)
f010148d:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101490:	39 d9                	cmp    %ebx,%ecx
f0101492:	75 ed                	jne    f0101481 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101494:	89 f0                	mov    %esi,%eax
f0101496:	5b                   	pop    %ebx
f0101497:	5e                   	pop    %esi
f0101498:	5d                   	pop    %ebp
f0101499:	c3                   	ret    

f010149a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010149a:	55                   	push   %ebp
f010149b:	89 e5                	mov    %esp,%ebp
f010149d:	57                   	push   %edi
f010149e:	56                   	push   %esi
f010149f:	53                   	push   %ebx
f01014a0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01014a3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01014a6:	8b 75 10             	mov    0x10(%ebp),%esi
f01014a9:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01014ab:	85 f6                	test   %esi,%esi
f01014ad:	74 34                	je     f01014e3 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f01014af:	83 fe 01             	cmp    $0x1,%esi
f01014b2:	74 26                	je     f01014da <strlcpy+0x40>
f01014b4:	0f b6 0b             	movzbl (%ebx),%ecx
f01014b7:	84 c9                	test   %cl,%cl
f01014b9:	74 23                	je     f01014de <strlcpy+0x44>
f01014bb:	83 ee 02             	sub    $0x2,%esi
f01014be:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f01014c3:	83 c0 01             	add    $0x1,%eax
f01014c6:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01014c9:	39 f2                	cmp    %esi,%edx
f01014cb:	74 13                	je     f01014e0 <strlcpy+0x46>
f01014cd:	83 c2 01             	add    $0x1,%edx
f01014d0:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01014d4:	84 c9                	test   %cl,%cl
f01014d6:	75 eb                	jne    f01014c3 <strlcpy+0x29>
f01014d8:	eb 06                	jmp    f01014e0 <strlcpy+0x46>
f01014da:	89 f8                	mov    %edi,%eax
f01014dc:	eb 02                	jmp    f01014e0 <strlcpy+0x46>
f01014de:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01014e0:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01014e3:	29 f8                	sub    %edi,%eax
}
f01014e5:	5b                   	pop    %ebx
f01014e6:	5e                   	pop    %esi
f01014e7:	5f                   	pop    %edi
f01014e8:	5d                   	pop    %ebp
f01014e9:	c3                   	ret    

f01014ea <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014ea:	55                   	push   %ebp
f01014eb:	89 e5                	mov    %esp,%ebp
f01014ed:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014f0:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014f3:	0f b6 01             	movzbl (%ecx),%eax
f01014f6:	84 c0                	test   %al,%al
f01014f8:	74 15                	je     f010150f <strcmp+0x25>
f01014fa:	3a 02                	cmp    (%edx),%al
f01014fc:	75 11                	jne    f010150f <strcmp+0x25>
		p++, q++;
f01014fe:	83 c1 01             	add    $0x1,%ecx
f0101501:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101504:	0f b6 01             	movzbl (%ecx),%eax
f0101507:	84 c0                	test   %al,%al
f0101509:	74 04                	je     f010150f <strcmp+0x25>
f010150b:	3a 02                	cmp    (%edx),%al
f010150d:	74 ef                	je     f01014fe <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010150f:	0f b6 c0             	movzbl %al,%eax
f0101512:	0f b6 12             	movzbl (%edx),%edx
f0101515:	29 d0                	sub    %edx,%eax
}
f0101517:	5d                   	pop    %ebp
f0101518:	c3                   	ret    

f0101519 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101519:	55                   	push   %ebp
f010151a:	89 e5                	mov    %esp,%ebp
f010151c:	56                   	push   %esi
f010151d:	53                   	push   %ebx
f010151e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101521:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101524:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0101527:	85 f6                	test   %esi,%esi
f0101529:	74 29                	je     f0101554 <strncmp+0x3b>
f010152b:	0f b6 03             	movzbl (%ebx),%eax
f010152e:	84 c0                	test   %al,%al
f0101530:	74 30                	je     f0101562 <strncmp+0x49>
f0101532:	3a 02                	cmp    (%edx),%al
f0101534:	75 2c                	jne    f0101562 <strncmp+0x49>
f0101536:	8d 43 01             	lea    0x1(%ebx),%eax
f0101539:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f010153b:	89 c3                	mov    %eax,%ebx
f010153d:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101540:	39 f0                	cmp    %esi,%eax
f0101542:	74 17                	je     f010155b <strncmp+0x42>
f0101544:	0f b6 08             	movzbl (%eax),%ecx
f0101547:	84 c9                	test   %cl,%cl
f0101549:	74 17                	je     f0101562 <strncmp+0x49>
f010154b:	83 c0 01             	add    $0x1,%eax
f010154e:	3a 0a                	cmp    (%edx),%cl
f0101550:	74 e9                	je     f010153b <strncmp+0x22>
f0101552:	eb 0e                	jmp    f0101562 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101554:	b8 00 00 00 00       	mov    $0x0,%eax
f0101559:	eb 0f                	jmp    f010156a <strncmp+0x51>
f010155b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101560:	eb 08                	jmp    f010156a <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101562:	0f b6 03             	movzbl (%ebx),%eax
f0101565:	0f b6 12             	movzbl (%edx),%edx
f0101568:	29 d0                	sub    %edx,%eax
}
f010156a:	5b                   	pop    %ebx
f010156b:	5e                   	pop    %esi
f010156c:	5d                   	pop    %ebp
f010156d:	c3                   	ret    

f010156e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010156e:	55                   	push   %ebp
f010156f:	89 e5                	mov    %esp,%ebp
f0101571:	53                   	push   %ebx
f0101572:	8b 45 08             	mov    0x8(%ebp),%eax
f0101575:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101578:	0f b6 18             	movzbl (%eax),%ebx
f010157b:	84 db                	test   %bl,%bl
f010157d:	74 1d                	je     f010159c <strchr+0x2e>
f010157f:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101581:	38 d3                	cmp    %dl,%bl
f0101583:	75 06                	jne    f010158b <strchr+0x1d>
f0101585:	eb 1a                	jmp    f01015a1 <strchr+0x33>
f0101587:	38 ca                	cmp    %cl,%dl
f0101589:	74 16                	je     f01015a1 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010158b:	83 c0 01             	add    $0x1,%eax
f010158e:	0f b6 10             	movzbl (%eax),%edx
f0101591:	84 d2                	test   %dl,%dl
f0101593:	75 f2                	jne    f0101587 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0101595:	b8 00 00 00 00       	mov    $0x0,%eax
f010159a:	eb 05                	jmp    f01015a1 <strchr+0x33>
f010159c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015a1:	5b                   	pop    %ebx
f01015a2:	5d                   	pop    %ebp
f01015a3:	c3                   	ret    

f01015a4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015a4:	55                   	push   %ebp
f01015a5:	89 e5                	mov    %esp,%ebp
f01015a7:	53                   	push   %ebx
f01015a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01015ab:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01015ae:	0f b6 18             	movzbl (%eax),%ebx
f01015b1:	84 db                	test   %bl,%bl
f01015b3:	74 17                	je     f01015cc <strfind+0x28>
f01015b5:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01015b7:	38 d3                	cmp    %dl,%bl
f01015b9:	75 07                	jne    f01015c2 <strfind+0x1e>
f01015bb:	eb 0f                	jmp    f01015cc <strfind+0x28>
f01015bd:	38 ca                	cmp    %cl,%dl
f01015bf:	90                   	nop
f01015c0:	74 0a                	je     f01015cc <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01015c2:	83 c0 01             	add    $0x1,%eax
f01015c5:	0f b6 10             	movzbl (%eax),%edx
f01015c8:	84 d2                	test   %dl,%dl
f01015ca:	75 f1                	jne    f01015bd <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f01015cc:	5b                   	pop    %ebx
f01015cd:	5d                   	pop    %ebp
f01015ce:	c3                   	ret    

f01015cf <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015cf:	55                   	push   %ebp
f01015d0:	89 e5                	mov    %esp,%ebp
f01015d2:	57                   	push   %edi
f01015d3:	56                   	push   %esi
f01015d4:	53                   	push   %ebx
f01015d5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015d8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015db:	85 c9                	test   %ecx,%ecx
f01015dd:	74 36                	je     f0101615 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015df:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015e5:	75 28                	jne    f010160f <memset+0x40>
f01015e7:	f6 c1 03             	test   $0x3,%cl
f01015ea:	75 23                	jne    f010160f <memset+0x40>
		c &= 0xFF;
f01015ec:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015f0:	89 d3                	mov    %edx,%ebx
f01015f2:	c1 e3 08             	shl    $0x8,%ebx
f01015f5:	89 d6                	mov    %edx,%esi
f01015f7:	c1 e6 18             	shl    $0x18,%esi
f01015fa:	89 d0                	mov    %edx,%eax
f01015fc:	c1 e0 10             	shl    $0x10,%eax
f01015ff:	09 f0                	or     %esi,%eax
f0101601:	09 c2                	or     %eax,%edx
f0101603:	89 d0                	mov    %edx,%eax
f0101605:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101607:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010160a:	fc                   	cld    
f010160b:	f3 ab                	rep stos %eax,%es:(%edi)
f010160d:	eb 06                	jmp    f0101615 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010160f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101612:	fc                   	cld    
f0101613:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101615:	89 f8                	mov    %edi,%eax
f0101617:	5b                   	pop    %ebx
f0101618:	5e                   	pop    %esi
f0101619:	5f                   	pop    %edi
f010161a:	5d                   	pop    %ebp
f010161b:	c3                   	ret    

f010161c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010161c:	55                   	push   %ebp
f010161d:	89 e5                	mov    %esp,%ebp
f010161f:	57                   	push   %edi
f0101620:	56                   	push   %esi
f0101621:	8b 45 08             	mov    0x8(%ebp),%eax
f0101624:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101627:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010162a:	39 c6                	cmp    %eax,%esi
f010162c:	73 35                	jae    f0101663 <memmove+0x47>
f010162e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101631:	39 d0                	cmp    %edx,%eax
f0101633:	73 2e                	jae    f0101663 <memmove+0x47>
		s += n;
		d += n;
f0101635:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101638:	89 d6                	mov    %edx,%esi
f010163a:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010163c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101642:	75 13                	jne    f0101657 <memmove+0x3b>
f0101644:	f6 c1 03             	test   $0x3,%cl
f0101647:	75 0e                	jne    f0101657 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101649:	83 ef 04             	sub    $0x4,%edi
f010164c:	8d 72 fc             	lea    -0x4(%edx),%esi
f010164f:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101652:	fd                   	std    
f0101653:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101655:	eb 09                	jmp    f0101660 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101657:	83 ef 01             	sub    $0x1,%edi
f010165a:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010165d:	fd                   	std    
f010165e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101660:	fc                   	cld    
f0101661:	eb 1d                	jmp    f0101680 <memmove+0x64>
f0101663:	89 f2                	mov    %esi,%edx
f0101665:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101667:	f6 c2 03             	test   $0x3,%dl
f010166a:	75 0f                	jne    f010167b <memmove+0x5f>
f010166c:	f6 c1 03             	test   $0x3,%cl
f010166f:	75 0a                	jne    f010167b <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101671:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101674:	89 c7                	mov    %eax,%edi
f0101676:	fc                   	cld    
f0101677:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101679:	eb 05                	jmp    f0101680 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010167b:	89 c7                	mov    %eax,%edi
f010167d:	fc                   	cld    
f010167e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101680:	5e                   	pop    %esi
f0101681:	5f                   	pop    %edi
f0101682:	5d                   	pop    %ebp
f0101683:	c3                   	ret    

f0101684 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0101684:	55                   	push   %ebp
f0101685:	89 e5                	mov    %esp,%ebp
f0101687:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010168a:	8b 45 10             	mov    0x10(%ebp),%eax
f010168d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101691:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101694:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101698:	8b 45 08             	mov    0x8(%ebp),%eax
f010169b:	89 04 24             	mov    %eax,(%esp)
f010169e:	e8 79 ff ff ff       	call   f010161c <memmove>
}
f01016a3:	c9                   	leave  
f01016a4:	c3                   	ret    

f01016a5 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01016a5:	55                   	push   %ebp
f01016a6:	89 e5                	mov    %esp,%ebp
f01016a8:	57                   	push   %edi
f01016a9:	56                   	push   %esi
f01016aa:	53                   	push   %ebx
f01016ab:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01016ae:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016b1:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016b4:	8d 78 ff             	lea    -0x1(%eax),%edi
f01016b7:	85 c0                	test   %eax,%eax
f01016b9:	74 36                	je     f01016f1 <memcmp+0x4c>
		if (*s1 != *s2)
f01016bb:	0f b6 03             	movzbl (%ebx),%eax
f01016be:	0f b6 0e             	movzbl (%esi),%ecx
f01016c1:	ba 00 00 00 00       	mov    $0x0,%edx
f01016c6:	38 c8                	cmp    %cl,%al
f01016c8:	74 1c                	je     f01016e6 <memcmp+0x41>
f01016ca:	eb 10                	jmp    f01016dc <memcmp+0x37>
f01016cc:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01016d1:	83 c2 01             	add    $0x1,%edx
f01016d4:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01016d8:	38 c8                	cmp    %cl,%al
f01016da:	74 0a                	je     f01016e6 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f01016dc:	0f b6 c0             	movzbl %al,%eax
f01016df:	0f b6 c9             	movzbl %cl,%ecx
f01016e2:	29 c8                	sub    %ecx,%eax
f01016e4:	eb 10                	jmp    f01016f6 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016e6:	39 fa                	cmp    %edi,%edx
f01016e8:	75 e2                	jne    f01016cc <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01016ef:	eb 05                	jmp    f01016f6 <memcmp+0x51>
f01016f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016f6:	5b                   	pop    %ebx
f01016f7:	5e                   	pop    %esi
f01016f8:	5f                   	pop    %edi
f01016f9:	5d                   	pop    %ebp
f01016fa:	c3                   	ret    

f01016fb <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016fb:	55                   	push   %ebp
f01016fc:	89 e5                	mov    %esp,%ebp
f01016fe:	53                   	push   %ebx
f01016ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0101702:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0101705:	89 c2                	mov    %eax,%edx
f0101707:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010170a:	39 d0                	cmp    %edx,%eax
f010170c:	73 14                	jae    f0101722 <memfind+0x27>
		if (*(const unsigned char *) s == (unsigned char) c)
f010170e:	89 d9                	mov    %ebx,%ecx
f0101710:	38 18                	cmp    %bl,(%eax)
f0101712:	75 06                	jne    f010171a <memfind+0x1f>
f0101714:	eb 0c                	jmp    f0101722 <memfind+0x27>
f0101716:	38 08                	cmp    %cl,(%eax)
f0101718:	74 08                	je     f0101722 <memfind+0x27>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010171a:	83 c0 01             	add    $0x1,%eax
f010171d:	39 d0                	cmp    %edx,%eax
f010171f:	90                   	nop
f0101720:	75 f4                	jne    f0101716 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101722:	5b                   	pop    %ebx
f0101723:	5d                   	pop    %ebp
f0101724:	c3                   	ret    

f0101725 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101725:	55                   	push   %ebp
f0101726:	89 e5                	mov    %esp,%ebp
f0101728:	57                   	push   %edi
f0101729:	56                   	push   %esi
f010172a:	53                   	push   %ebx
f010172b:	8b 55 08             	mov    0x8(%ebp),%edx
f010172e:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101731:	0f b6 0a             	movzbl (%edx),%ecx
f0101734:	80 f9 09             	cmp    $0x9,%cl
f0101737:	74 05                	je     f010173e <strtol+0x19>
f0101739:	80 f9 20             	cmp    $0x20,%cl
f010173c:	75 10                	jne    f010174e <strtol+0x29>
		s++;
f010173e:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101741:	0f b6 0a             	movzbl (%edx),%ecx
f0101744:	80 f9 09             	cmp    $0x9,%cl
f0101747:	74 f5                	je     f010173e <strtol+0x19>
f0101749:	80 f9 20             	cmp    $0x20,%cl
f010174c:	74 f0                	je     f010173e <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f010174e:	80 f9 2b             	cmp    $0x2b,%cl
f0101751:	75 0a                	jne    f010175d <strtol+0x38>
		s++;
f0101753:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101756:	bf 00 00 00 00       	mov    $0x0,%edi
f010175b:	eb 11                	jmp    f010176e <strtol+0x49>
f010175d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101762:	80 f9 2d             	cmp    $0x2d,%cl
f0101765:	75 07                	jne    f010176e <strtol+0x49>
		s++, neg = 1;
f0101767:	83 c2 01             	add    $0x1,%edx
f010176a:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010176e:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101773:	75 15                	jne    f010178a <strtol+0x65>
f0101775:	80 3a 30             	cmpb   $0x30,(%edx)
f0101778:	75 10                	jne    f010178a <strtol+0x65>
f010177a:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010177e:	75 0a                	jne    f010178a <strtol+0x65>
		s += 2, base = 16;
f0101780:	83 c2 02             	add    $0x2,%edx
f0101783:	b8 10 00 00 00       	mov    $0x10,%eax
f0101788:	eb 10                	jmp    f010179a <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f010178a:	85 c0                	test   %eax,%eax
f010178c:	75 0c                	jne    f010179a <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010178e:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101790:	80 3a 30             	cmpb   $0x30,(%edx)
f0101793:	75 05                	jne    f010179a <strtol+0x75>
		s++, base = 8;
f0101795:	83 c2 01             	add    $0x1,%edx
f0101798:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010179a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010179f:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01017a2:	0f b6 0a             	movzbl (%edx),%ecx
f01017a5:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01017a8:	89 f0                	mov    %esi,%eax
f01017aa:	3c 09                	cmp    $0x9,%al
f01017ac:	77 08                	ja     f01017b6 <strtol+0x91>
			dig = *s - '0';
f01017ae:	0f be c9             	movsbl %cl,%ecx
f01017b1:	83 e9 30             	sub    $0x30,%ecx
f01017b4:	eb 20                	jmp    f01017d6 <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f01017b6:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01017b9:	89 f0                	mov    %esi,%eax
f01017bb:	3c 19                	cmp    $0x19,%al
f01017bd:	77 08                	ja     f01017c7 <strtol+0xa2>
			dig = *s - 'a' + 10;
f01017bf:	0f be c9             	movsbl %cl,%ecx
f01017c2:	83 e9 57             	sub    $0x57,%ecx
f01017c5:	eb 0f                	jmp    f01017d6 <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f01017c7:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01017ca:	89 f0                	mov    %esi,%eax
f01017cc:	3c 19                	cmp    $0x19,%al
f01017ce:	77 16                	ja     f01017e6 <strtol+0xc1>
			dig = *s - 'A' + 10;
f01017d0:	0f be c9             	movsbl %cl,%ecx
f01017d3:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01017d6:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01017d9:	7d 0f                	jge    f01017ea <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01017db:	83 c2 01             	add    $0x1,%edx
f01017de:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01017e2:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01017e4:	eb bc                	jmp    f01017a2 <strtol+0x7d>
f01017e6:	89 d8                	mov    %ebx,%eax
f01017e8:	eb 02                	jmp    f01017ec <strtol+0xc7>
f01017ea:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01017ec:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017f0:	74 05                	je     f01017f7 <strtol+0xd2>
		*endptr = (char *) s;
f01017f2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017f5:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01017f7:	f7 d8                	neg    %eax
f01017f9:	85 ff                	test   %edi,%edi
f01017fb:	0f 44 c3             	cmove  %ebx,%eax
}
f01017fe:	5b                   	pop    %ebx
f01017ff:	5e                   	pop    %esi
f0101800:	5f                   	pop    %edi
f0101801:	5d                   	pop    %ebp
f0101802:	c3                   	ret    
f0101803:	66 90                	xchg   %ax,%ax
f0101805:	66 90                	xchg   %ax,%ax
f0101807:	66 90                	xchg   %ax,%ax
f0101809:	66 90                	xchg   %ax,%ax
f010180b:	66 90                	xchg   %ax,%ax
f010180d:	66 90                	xchg   %ax,%ax
f010180f:	90                   	nop

f0101810 <__udivdi3>:
f0101810:	55                   	push   %ebp
f0101811:	57                   	push   %edi
f0101812:	56                   	push   %esi
f0101813:	83 ec 0c             	sub    $0xc,%esp
f0101816:	8b 44 24 28          	mov    0x28(%esp),%eax
f010181a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010181e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101822:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101826:	85 c0                	test   %eax,%eax
f0101828:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010182c:	89 ea                	mov    %ebp,%edx
f010182e:	89 0c 24             	mov    %ecx,(%esp)
f0101831:	75 2d                	jne    f0101860 <__udivdi3+0x50>
f0101833:	39 e9                	cmp    %ebp,%ecx
f0101835:	77 61                	ja     f0101898 <__udivdi3+0x88>
f0101837:	85 c9                	test   %ecx,%ecx
f0101839:	89 ce                	mov    %ecx,%esi
f010183b:	75 0b                	jne    f0101848 <__udivdi3+0x38>
f010183d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101842:	31 d2                	xor    %edx,%edx
f0101844:	f7 f1                	div    %ecx
f0101846:	89 c6                	mov    %eax,%esi
f0101848:	31 d2                	xor    %edx,%edx
f010184a:	89 e8                	mov    %ebp,%eax
f010184c:	f7 f6                	div    %esi
f010184e:	89 c5                	mov    %eax,%ebp
f0101850:	89 f8                	mov    %edi,%eax
f0101852:	f7 f6                	div    %esi
f0101854:	89 ea                	mov    %ebp,%edx
f0101856:	83 c4 0c             	add    $0xc,%esp
f0101859:	5e                   	pop    %esi
f010185a:	5f                   	pop    %edi
f010185b:	5d                   	pop    %ebp
f010185c:	c3                   	ret    
f010185d:	8d 76 00             	lea    0x0(%esi),%esi
f0101860:	39 e8                	cmp    %ebp,%eax
f0101862:	77 24                	ja     f0101888 <__udivdi3+0x78>
f0101864:	0f bd e8             	bsr    %eax,%ebp
f0101867:	83 f5 1f             	xor    $0x1f,%ebp
f010186a:	75 3c                	jne    f01018a8 <__udivdi3+0x98>
f010186c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101870:	39 34 24             	cmp    %esi,(%esp)
f0101873:	0f 86 9f 00 00 00    	jbe    f0101918 <__udivdi3+0x108>
f0101879:	39 d0                	cmp    %edx,%eax
f010187b:	0f 82 97 00 00 00    	jb     f0101918 <__udivdi3+0x108>
f0101881:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101888:	31 d2                	xor    %edx,%edx
f010188a:	31 c0                	xor    %eax,%eax
f010188c:	83 c4 0c             	add    $0xc,%esp
f010188f:	5e                   	pop    %esi
f0101890:	5f                   	pop    %edi
f0101891:	5d                   	pop    %ebp
f0101892:	c3                   	ret    
f0101893:	90                   	nop
f0101894:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101898:	89 f8                	mov    %edi,%eax
f010189a:	f7 f1                	div    %ecx
f010189c:	31 d2                	xor    %edx,%edx
f010189e:	83 c4 0c             	add    $0xc,%esp
f01018a1:	5e                   	pop    %esi
f01018a2:	5f                   	pop    %edi
f01018a3:	5d                   	pop    %ebp
f01018a4:	c3                   	ret    
f01018a5:	8d 76 00             	lea    0x0(%esi),%esi
f01018a8:	89 e9                	mov    %ebp,%ecx
f01018aa:	8b 3c 24             	mov    (%esp),%edi
f01018ad:	d3 e0                	shl    %cl,%eax
f01018af:	89 c6                	mov    %eax,%esi
f01018b1:	b8 20 00 00 00       	mov    $0x20,%eax
f01018b6:	29 e8                	sub    %ebp,%eax
f01018b8:	89 c1                	mov    %eax,%ecx
f01018ba:	d3 ef                	shr    %cl,%edi
f01018bc:	89 e9                	mov    %ebp,%ecx
f01018be:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01018c2:	8b 3c 24             	mov    (%esp),%edi
f01018c5:	09 74 24 08          	or     %esi,0x8(%esp)
f01018c9:	89 d6                	mov    %edx,%esi
f01018cb:	d3 e7                	shl    %cl,%edi
f01018cd:	89 c1                	mov    %eax,%ecx
f01018cf:	89 3c 24             	mov    %edi,(%esp)
f01018d2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01018d6:	d3 ee                	shr    %cl,%esi
f01018d8:	89 e9                	mov    %ebp,%ecx
f01018da:	d3 e2                	shl    %cl,%edx
f01018dc:	89 c1                	mov    %eax,%ecx
f01018de:	d3 ef                	shr    %cl,%edi
f01018e0:	09 d7                	or     %edx,%edi
f01018e2:	89 f2                	mov    %esi,%edx
f01018e4:	89 f8                	mov    %edi,%eax
f01018e6:	f7 74 24 08          	divl   0x8(%esp)
f01018ea:	89 d6                	mov    %edx,%esi
f01018ec:	89 c7                	mov    %eax,%edi
f01018ee:	f7 24 24             	mull   (%esp)
f01018f1:	39 d6                	cmp    %edx,%esi
f01018f3:	89 14 24             	mov    %edx,(%esp)
f01018f6:	72 30                	jb     f0101928 <__udivdi3+0x118>
f01018f8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01018fc:	89 e9                	mov    %ebp,%ecx
f01018fe:	d3 e2                	shl    %cl,%edx
f0101900:	39 c2                	cmp    %eax,%edx
f0101902:	73 05                	jae    f0101909 <__udivdi3+0xf9>
f0101904:	3b 34 24             	cmp    (%esp),%esi
f0101907:	74 1f                	je     f0101928 <__udivdi3+0x118>
f0101909:	89 f8                	mov    %edi,%eax
f010190b:	31 d2                	xor    %edx,%edx
f010190d:	e9 7a ff ff ff       	jmp    f010188c <__udivdi3+0x7c>
f0101912:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101918:	31 d2                	xor    %edx,%edx
f010191a:	b8 01 00 00 00       	mov    $0x1,%eax
f010191f:	e9 68 ff ff ff       	jmp    f010188c <__udivdi3+0x7c>
f0101924:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101928:	8d 47 ff             	lea    -0x1(%edi),%eax
f010192b:	31 d2                	xor    %edx,%edx
f010192d:	83 c4 0c             	add    $0xc,%esp
f0101930:	5e                   	pop    %esi
f0101931:	5f                   	pop    %edi
f0101932:	5d                   	pop    %ebp
f0101933:	c3                   	ret    
f0101934:	66 90                	xchg   %ax,%ax
f0101936:	66 90                	xchg   %ax,%ax
f0101938:	66 90                	xchg   %ax,%ax
f010193a:	66 90                	xchg   %ax,%ax
f010193c:	66 90                	xchg   %ax,%ax
f010193e:	66 90                	xchg   %ax,%ax

f0101940 <__umoddi3>:
f0101940:	55                   	push   %ebp
f0101941:	57                   	push   %edi
f0101942:	56                   	push   %esi
f0101943:	83 ec 14             	sub    $0x14,%esp
f0101946:	8b 44 24 28          	mov    0x28(%esp),%eax
f010194a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010194e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101952:	89 c7                	mov    %eax,%edi
f0101954:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101958:	8b 44 24 30          	mov    0x30(%esp),%eax
f010195c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101960:	89 34 24             	mov    %esi,(%esp)
f0101963:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101967:	85 c0                	test   %eax,%eax
f0101969:	89 c2                	mov    %eax,%edx
f010196b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010196f:	75 17                	jne    f0101988 <__umoddi3+0x48>
f0101971:	39 fe                	cmp    %edi,%esi
f0101973:	76 4b                	jbe    f01019c0 <__umoddi3+0x80>
f0101975:	89 c8                	mov    %ecx,%eax
f0101977:	89 fa                	mov    %edi,%edx
f0101979:	f7 f6                	div    %esi
f010197b:	89 d0                	mov    %edx,%eax
f010197d:	31 d2                	xor    %edx,%edx
f010197f:	83 c4 14             	add    $0x14,%esp
f0101982:	5e                   	pop    %esi
f0101983:	5f                   	pop    %edi
f0101984:	5d                   	pop    %ebp
f0101985:	c3                   	ret    
f0101986:	66 90                	xchg   %ax,%ax
f0101988:	39 f8                	cmp    %edi,%eax
f010198a:	77 54                	ja     f01019e0 <__umoddi3+0xa0>
f010198c:	0f bd e8             	bsr    %eax,%ebp
f010198f:	83 f5 1f             	xor    $0x1f,%ebp
f0101992:	75 5c                	jne    f01019f0 <__umoddi3+0xb0>
f0101994:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101998:	39 3c 24             	cmp    %edi,(%esp)
f010199b:	0f 87 e7 00 00 00    	ja     f0101a88 <__umoddi3+0x148>
f01019a1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01019a5:	29 f1                	sub    %esi,%ecx
f01019a7:	19 c7                	sbb    %eax,%edi
f01019a9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01019ad:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01019b1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01019b5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01019b9:	83 c4 14             	add    $0x14,%esp
f01019bc:	5e                   	pop    %esi
f01019bd:	5f                   	pop    %edi
f01019be:	5d                   	pop    %ebp
f01019bf:	c3                   	ret    
f01019c0:	85 f6                	test   %esi,%esi
f01019c2:	89 f5                	mov    %esi,%ebp
f01019c4:	75 0b                	jne    f01019d1 <__umoddi3+0x91>
f01019c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01019cb:	31 d2                	xor    %edx,%edx
f01019cd:	f7 f6                	div    %esi
f01019cf:	89 c5                	mov    %eax,%ebp
f01019d1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01019d5:	31 d2                	xor    %edx,%edx
f01019d7:	f7 f5                	div    %ebp
f01019d9:	89 c8                	mov    %ecx,%eax
f01019db:	f7 f5                	div    %ebp
f01019dd:	eb 9c                	jmp    f010197b <__umoddi3+0x3b>
f01019df:	90                   	nop
f01019e0:	89 c8                	mov    %ecx,%eax
f01019e2:	89 fa                	mov    %edi,%edx
f01019e4:	83 c4 14             	add    $0x14,%esp
f01019e7:	5e                   	pop    %esi
f01019e8:	5f                   	pop    %edi
f01019e9:	5d                   	pop    %ebp
f01019ea:	c3                   	ret    
f01019eb:	90                   	nop
f01019ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019f0:	8b 04 24             	mov    (%esp),%eax
f01019f3:	be 20 00 00 00       	mov    $0x20,%esi
f01019f8:	89 e9                	mov    %ebp,%ecx
f01019fa:	29 ee                	sub    %ebp,%esi
f01019fc:	d3 e2                	shl    %cl,%edx
f01019fe:	89 f1                	mov    %esi,%ecx
f0101a00:	d3 e8                	shr    %cl,%eax
f0101a02:	89 e9                	mov    %ebp,%ecx
f0101a04:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a08:	8b 04 24             	mov    (%esp),%eax
f0101a0b:	09 54 24 04          	or     %edx,0x4(%esp)
f0101a0f:	89 fa                	mov    %edi,%edx
f0101a11:	d3 e0                	shl    %cl,%eax
f0101a13:	89 f1                	mov    %esi,%ecx
f0101a15:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a19:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101a1d:	d3 ea                	shr    %cl,%edx
f0101a1f:	89 e9                	mov    %ebp,%ecx
f0101a21:	d3 e7                	shl    %cl,%edi
f0101a23:	89 f1                	mov    %esi,%ecx
f0101a25:	d3 e8                	shr    %cl,%eax
f0101a27:	89 e9                	mov    %ebp,%ecx
f0101a29:	09 f8                	or     %edi,%eax
f0101a2b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0101a2f:	f7 74 24 04          	divl   0x4(%esp)
f0101a33:	d3 e7                	shl    %cl,%edi
f0101a35:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a39:	89 d7                	mov    %edx,%edi
f0101a3b:	f7 64 24 08          	mull   0x8(%esp)
f0101a3f:	39 d7                	cmp    %edx,%edi
f0101a41:	89 c1                	mov    %eax,%ecx
f0101a43:	89 14 24             	mov    %edx,(%esp)
f0101a46:	72 2c                	jb     f0101a74 <__umoddi3+0x134>
f0101a48:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0101a4c:	72 22                	jb     f0101a70 <__umoddi3+0x130>
f0101a4e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101a52:	29 c8                	sub    %ecx,%eax
f0101a54:	19 d7                	sbb    %edx,%edi
f0101a56:	89 e9                	mov    %ebp,%ecx
f0101a58:	89 fa                	mov    %edi,%edx
f0101a5a:	d3 e8                	shr    %cl,%eax
f0101a5c:	89 f1                	mov    %esi,%ecx
f0101a5e:	d3 e2                	shl    %cl,%edx
f0101a60:	89 e9                	mov    %ebp,%ecx
f0101a62:	d3 ef                	shr    %cl,%edi
f0101a64:	09 d0                	or     %edx,%eax
f0101a66:	89 fa                	mov    %edi,%edx
f0101a68:	83 c4 14             	add    $0x14,%esp
f0101a6b:	5e                   	pop    %esi
f0101a6c:	5f                   	pop    %edi
f0101a6d:	5d                   	pop    %ebp
f0101a6e:	c3                   	ret    
f0101a6f:	90                   	nop
f0101a70:	39 d7                	cmp    %edx,%edi
f0101a72:	75 da                	jne    f0101a4e <__umoddi3+0x10e>
f0101a74:	8b 14 24             	mov    (%esp),%edx
f0101a77:	89 c1                	mov    %eax,%ecx
f0101a79:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0101a7d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101a81:	eb cb                	jmp    f0101a4e <__umoddi3+0x10e>
f0101a83:	90                   	nop
f0101a84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a88:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101a8c:	0f 82 0f ff ff ff    	jb     f01019a1 <__umoddi3+0x61>
f0101a92:	e9 1a ff ff ff       	jmp    f01019b1 <__umoddi3+0x71>

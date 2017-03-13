// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/pmap.h>
#include <kern/trap.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "backtrace", "Display the backtrace till boot", mon_backtrace},
	{ "showmappings", "Display page mappings", showmappings},
	{ "stmp", "set Page Permissions", stmp},
	{ "dumpmem", "Dump memory", dumpmem},
	{"si","single step through the code",singlestep},
	{"cexec","contine execution",continueexec}
};

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int mon_backtrace(int argc, char **argv, struct Trapframe *tf) {
	int i;
	uint32_t *ebp = (uint32_t *)read_ebp();
	uint32_t eip = ebp[1];
	struct Eipdebuginfo eip_info;
	cprintf("Stack backtrace:\n");
	while(ebp) {
		cprintf("ebp %08x eip %08x args ",ebp,eip);
		for (i = 2; i < 7;i++) {
			cprintf("%08x ",ebp[i]);
		}
		cprintf("\n");
		debuginfo_eip(eip, &eip_info);
		cprintf("\t%s:%d: %.*s+%d\n",eip_info.eip_file,eip_info.eip_line,eip_info.eip_fn_namelen,eip_info.eip_fn_name,eip-eip_info.eip_fn_addr);
		ebp = (uint32_t *)(ebp[0]);
		eip = ebp[1];
	}
	return 0;
}

uint32_t xtoi(char* buf) {
    uint32_t res = 0;
    buf += 2; //0x...
    while (*buf) {
        if (*buf >= 'a') {
			*buf = *buf-'a'+'0'+10;//aha
		}
        res = res*16 + *buf - '0';
        ++buf;
    }
    return res;
}

int showmappings(int argc, char *argv[],struct Trapframe *tf) {
	if (argc <= 2) {
		cprintf("Usage:\n showmappings <start in hex - 0xabcdef> <end in hex - 0xfedcba>\n");
		return 0;
	}
	uint32_t start_addr = xtoi(argv[1]), end_addr = xtoi(argv[2]);
	cprintf("Beginning:\t%x,\tEnding:\t%x\n",start_addr,end_addr);
	while(start_addr <= end_addr) {
		pte_t *pte = pgdir_walk(kern_pgdir,(void *)start_addr,0);
		if (!pte) {
			cprintf("No Physical page mapped at %x\n",start_addr);
		} else {
			cprintf("Page at %x: ",start_addr);
			cprintf("PTE_P: %d, PTE_W: %d, PTE_U: %d\n", *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);
		}
		start_addr += PGSIZE;
	}
	return 0;
}

int stmp(int argc,char *argv[],struct Trapframe *tf) {
	if (argc <= 2) {
		cprintf("Usage:\n stmp <pageaddr> <P|U|W|0> <1|0>\n");
		return 0;
	}
	int addr = xtoi(argv[1]); int perm = 0;
	pte_t *pte = pgdir_walk(kern_pgdir, (void *)addr, 0);
	cprintf("%x original Permissions: ",addr);
	cprintf("PTE_P: %d, PTE_W: %d, PTE_U: %d\n", *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);
	switch(argv[2][0]) {
		case 'P':	perm = PTE_P;
					break;

		case 'W':	perm = PTE_W;
					break;

		case 'U':	perm = PTE_U;
					break;

		case '0':	perm = 0;
					break;

		default:	cprintf("Usage:\n stmp <pageaddr> <P|U|W|0> <1|0>\n");
					return 0;
	}
	if (argv[2][0] != '0') {
		if (argv[3][0] == '1'){
			*pte = *pte | perm;
		} else {
			*pte = *pte & ~perm;
		}
	} else {
		*pte = *pte & 0xFFFFF000;
	}
	cprintf("%x new permissions: ",addr);
	cprintf("PTE_P: %d, PTE_W: %d, PTE_U: %d\n", *pte&PTE_P, *pte&PTE_W, *pte&PTE_U);
	return 0;
}

int dumpmem(int argc,char *argv[],struct Trapframe *tf) {
	if (argc <= 3) {
		cprintf("Usage:\n dumpmem <start addr in hex> <end in hex> <v|p>\n");
		return 0;
	}
	void *start = (void *)xtoi(argv[1]);
	void *end = (void *)xtoi(argv[2]);
	for (;start<=end;start++) {
		if (argv[3][0] == 'v') {
			cprintf("%x: %x\n",start, *(char *)start);
		} else if (argv[3][0] == 'p'){
			cprintf("%x: %x\n",start, *(char *)KADDR((physaddr_t)start));
		} else {
			cprintf("Usage:\n dumpmem <start addr in hex> <end in hex> <v|p>\n");
		}
	}
	return 0;
}

int singlestep(int argc,char *argv[],struct Trapframe *tf) {
	tf->tf_eflags = tf->tf_eflags | FL_TF;
	return -1;
}

int continueexec(int argc,char *argv[],struct Trapframe *tf) {
	tf->tf_eflags = tf->tf_eflags & ~FL_TF;
	return -1;
}

/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");

	if (tf != NULL)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}

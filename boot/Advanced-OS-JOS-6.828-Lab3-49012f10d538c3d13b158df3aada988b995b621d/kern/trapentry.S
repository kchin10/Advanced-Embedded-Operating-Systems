/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
 TRAPHANDLER_NOEC(divide_error, 0)       //Divide error
 TRAPHANDLER_NOEC(debug_execption, 1)       //Debug exceptions
 TRAPHANDLER_NOEC(breakpoint, 3)       //Breakpoint
 TRAPHANDLER_NOEC(overflow, 4)       //Overflow
 TRAPHANDLER_NOEC(bounds_check, 5)       //Bounds check
 TRAPHANDLER_NOEC(invalid_opcode, 6)       //Invalid Opcode
 TRAPHANDLER_NOEC(copro_not_avail, 7)       //Coprocessor not available
 TRAPHANDLER(sys_err, 8)            //System error
 TRAPHANDLER_NOEC(copro_seg_overrun, 9)       //Coprocessor Segment Overrun
 TRAPHANDLER(invalid_tss, 10)          //Invalid TSS
 TRAPHANDLER(seg_not_present, 11)          //Segment not present
 TRAPHANDLER(stack_exception, 12)          //Stack exception
 TRAPHANDLER(general_prot_fault, 13)          //General protection fault
 TRAPHANDLER(page_fault, 14)          //Page fault
 TRAPHANDLER_NOEC(copro_err, 16)     //Coprocessor error

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
    pushl %ds
    pushl %es
    pushal
    movl $GD_KD,%ax
    movw %eax,%ds
    movw %eax,%es
    pushl %esp
    call trap

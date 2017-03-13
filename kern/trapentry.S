/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


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
 TRAPHANDLER_NOEC(divide_error, T_DIVIDE)           //Divide error
 TRAPHANDLER_NOEC(debug_exception, T_DEBUG)         //Debug exceptions
 TRAPHANDLER_NOEC(nmi_exception, T_NMI)             //Non maskable interrupt
 TRAPHANDLER_NOEC(breakpoint_exception, T_BRKPT)    //Breakpoint
 TRAPHANDLER_NOEC(overflow_exception, T_OFLOW)      //Overflow
 TRAPHANDLER_NOEC(bounds_check, T_BOUND)            //Bounds check
 TRAPHANDLER_NOEC(invalid_opcode, T_ILLOP)          //Invalid Opcode
 TRAPHANDLER_NOEC(copro_not_avail, T_DEVICE)        //Coprocessor not available
 TRAPHANDLER(sys_err, T_DBLFLT)                     //System error
 //TRAPHANDLER_NOEC(copro_seg_overrun, T_COPROC)    //Coprocessor Segment Overrun
 TRAPHANDLER(invalid_tss, T_TSS)                    //Invalid TSS
 TRAPHANDLER(seg_not_present, T_SEGNP)              //Segment not present
 TRAPHANDLER(stack_exception, T_STACK)              //Stack exception
 TRAPHANDLER(general_prot_fault, T_GPFLT)           //General protection fault
 TRAPHANDLER(page_fault, T_PGFLT)                   //Page fault
 TRAPHANDLER_NOEC(copro_err, T_FPERR)               //Coprocessor error
 TRAPHANDLER(align_err, T_ALIGN)                    //Alignment error
 TRAPHANDLER_NOEC(mchk_err, T_MCHK)                 //Machine check error
 TRAPHANDLER_NOEC(simd_err, T_SIMDERR)              //SIMD floating point err
 TRAPHANDLER_NOEC(sys_call,T_SYSCALL)               //System Call


.data;
.globl funcs;
funcs:
    .long divide_error;
    .long debug_exception;
    .long nmi_exception;
    .long breakpoint_exception;
    .long overflow_exception;
    .long bounds_check;
    .long invalid_opcode;
    .long copro_not_avail;
    .long sys_err;
    .long invalid_tss;
    .long seg_not_present;
    .long stack_exception;
    .long general_prot_fault;
    .long page_fault;
    .long copro_err;
    .long align_err;
    .long mchk_err;
    .long simd_err;
    .long sys_call;
/*
 * Lab 3: Your code here for _alltraps
 */
 .text;
_alltraps:
    pushl %ds
    pushl %es
    pushal
    movl $GD_KD,%ax
    movw %eax,%ds
    movw %eax,%es
    pushl %esp
    call trap

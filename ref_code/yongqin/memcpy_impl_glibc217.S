/* Copyright (C) 2006, 2009 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   Contributed by MontaVista Software, Inc. (written by Nicolas Pitre)

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library.  If not, see
   <http://www.gnu.org/licenses/>.  */

#define memcpy ad_memcpy_glibc217

#  define cfi_startproc			.cfi_startproc
#  define cfi_endproc			.cfi_endproc
#  define cfi_def_cfa(reg, off)		.cfi_def_cfa reg, off
#  define cfi_def_cfa_register(reg)	.cfi_def_cfa_register reg
#  define cfi_def_cfa_offset(off)	.cfi_def_cfa_offset off
#  define cfi_adjust_cfa_offset(off)	.cfi_adjust_cfa_offset off
#  define cfi_offset(reg, off)		.cfi_offset reg, off
#  define cfi_rel_offset(reg, off)	.cfi_rel_offset reg, off
#  define cfi_register(r1, r2)		.cfi_register r1, r2
#  define cfi_return_column(reg)	.cfi_return_column reg
#  define cfi_restore(reg)		.cfi_restore reg
#  define cfi_same_value(reg)		.cfi_same_value reg
#  define cfi_undefined(reg)		.cfi_undefined reg
#  define cfi_remember_state		.cfi_remember_state
#  define cfi_restore_state		.cfi_restore_state
#  define cfi_window_save		.cfi_window_save
#  define cfi_personality(enc, exp)	.cfi_personality enc, exp
#  define cfi_lsda(enc, exp)		.cfi_lsda enc, exp

/* Define an entry point visible from C.  */
#define C_LABEL(name)  name:

#define	ENTRY(name)							      \
  .global name;								      \
  .type name, %function;						      \
  .align 4;								      \
  C_LABEL(name)								      \
  .cfi_sections .debug_frame;						      \
  cfi_startproc;

#undef	END
#define END(name)							      \
  cfi_endproc;

/*
 * Data preload for architectures that support it (ARM V5TE and above)
 */
#if (!defined (__ARM_ARCH_2__) && !defined (__ARM_ARCH_3__) \
     && !defined (__ARM_ARCH_3M__) && !defined (__ARM_ARCH_4__) \
     && !defined (__ARM_ARCH_4T__) && !defined (__ARM_ARCH_5__) \
     && !defined (__ARM_ARCH_5T__))
#define PLD(code...)    code
#else
#define PLD(code...)
#endif

/*
 * This can be used to enable code to cacheline align the source pointer.
 * Experiments on tested architectures (StrongARM and XScale) didn't show
 * this a worthwhile thing to do.  That might be different in the future.
 */
//#define CALGN(code...)        code
#define CALGN(code...)

/*
 * Endian independent macros for shifting bytes within registers.
 */
#ifndef __ARMEB__
#define pull            lsr
#define push            lsl
#else
#define pull            lsl
#define push            lsr
#endif

		.text

/* Prototype: void *memcpy(void *dest, const void *src, size_t n); */

ENTRY(memcpy)

		stmfd	sp!, {r0, r4, lr}
		cfi_adjust_cfa_offset (12)
		cfi_rel_offset (r4, 4)
		cfi_rel_offset (lr, 8)

		cfi_remember_state

		subs	r2, r2, #4
		blt	8f
		ands	ip, r0, #3
	PLD(	pld	[r1, #0]		)
		bne	9f
		ands	ip, r1, #3
		bne	10f

1:		subs	r2, r2, #(28)
		stmfd	sp!, {r5 - r8}
		cfi_adjust_cfa_offset (16)
		cfi_rel_offset (r5, 0)
		cfi_rel_offset (r6, 4)
		cfi_rel_offset (r7, 8)
		cfi_rel_offset (r8, 12)
		blt	5f

	CALGN(	ands	ip, r1, #31		)
	CALGN(	rsb	r3, ip, #32		)
	CALGN(	sbcnes	r4, r3, r2		)  @ C is always set here
	CALGN(	bcs	2f			)
	CALGN(	adr	r4, 6f			)
	CALGN(	subs	r2, r2, r3		)  @ C gets set
	CALGN(	add	pc, r4, ip		)

	PLD(	pld	[r1, #0]		)
2:	PLD(	subs	r2, r2, #96		)
	PLD(	pld	[r1, #28]		)
	PLD(	blt	4f			)
	PLD(	pld	[r1, #60]		)
	PLD(	pld	[r1, #92]		)

3:	PLD(	pld	[r1, #124]		)
4:		ldmia	r1!, {r3, r4, r5, r6, r7, r8, ip, lr}
		subs	r2, r2, #32
		stmia	r0!, {r3, r4, r5, r6, r7, r8, ip, lr}
		bge	3b
	PLD(	cmn	r2, #96			)
	PLD(	bge	4b			)

5:		ands	ip, r2, #28
		rsb	ip, ip, #32
		addne	pc, pc, ip		@ C is always clear here
		b	7f
6:		nop
		ldr	r3, [r1], #4
		ldr	r4, [r1], #4
		ldr	r5, [r1], #4
		ldr	r6, [r1], #4
		ldr	r7, [r1], #4
		ldr	r8, [r1], #4
		ldr	lr, [r1], #4

		add	pc, pc, ip
		nop
		nop
		str	r3, [r0], #4
		str	r4, [r0], #4
		str	r5, [r0], #4
		str	r6, [r0], #4
		str	r7, [r0], #4
		str	r8, [r0], #4
		str	lr, [r0], #4

	CALGN(	bcs	2b			)

7:		ldmfd	sp!, {r5 - r8}
		cfi_adjust_cfa_offset (-16)
		cfi_restore (r5)
		cfi_restore (r6)
		cfi_restore (r7)
		cfi_restore (r8)

8:		movs	r2, r2, lsl #31
		ldrneb	r3, [r1], #1
		ldrcsb	r4, [r1], #1
		ldrcsb	ip, [r1]
		strneb	r3, [r0], #1
		strcsb	r4, [r0], #1
		strcsb	ip, [r0]

#if defined (__ARM_ARCH_4T__) && defined(__THUMB_INTERWORK__)
		ldmfd	sp!, {r0, r4, lr}
		cfi_adjust_cfa_offset (-12)
		cfi_restore (r4)
		cfi_restore (lr)
		bx      lr
#else
		ldmfd	sp!, {r0, r4, pc}
#endif

		cfi_restore_state

9:		rsb	ip, ip, #4
		cmp	ip, #2
		ldrgtb	r3, [r1], #1
		ldrgeb	r4, [r1], #1
		ldrb	lr, [r1], #1
		strgtb	r3, [r0], #1
		strgeb	r4, [r0], #1
		subs	r2, r2, ip
		strb	lr, [r0], #1
		blt	8b
		ands	ip, r1, #3
		beq	1b

10:		bic	r1, r1, #3
		cmp	ip, #2
		ldr	lr, [r1], #4
		beq	17f
		bgt	18f


		.macro	forward_copy_shift pull push

		subs	r2, r2, #28
		blt	14f

	CALGN(	ands	ip, r1, #31		)
	CALGN(	rsb	ip, ip, #32		)
	CALGN(	sbcnes	r4, ip, r2		)  @ C is always set here
	CALGN(	subcc	r2, r2, ip		)
	CALGN(	bcc	15f			)

11:		stmfd	sp!, {r5 - r9}
		cfi_adjust_cfa_offset (20)
		cfi_rel_offset (r5, 0)
		cfi_rel_offset (r6, 4)
		cfi_rel_offset (r7, 8)
		cfi_rel_offset (r8, 12)
		cfi_rel_offset (r9, 16)

	PLD(	pld	[r1, #0]		)
	PLD(	subs	r2, r2, #96		)
	PLD(	pld	[r1, #28]		)
	PLD(	blt	13f			)
	PLD(	pld	[r1, #60]		)
	PLD(	pld	[r1, #92]		)

12:	PLD(	pld	[r1, #124]		)
13:		ldmia	r1!, {r4, r5, r6, r7}
		mov	r3, lr, pull #\pull
		subs	r2, r2, #32
		ldmia	r1!, {r8, r9, ip, lr}
		orr	r3, r3, r4, push #\push
		mov	r4, r4, pull #\pull
		orr	r4, r4, r5, push #\push
		mov	r5, r5, pull #\pull
		orr	r5, r5, r6, push #\push
		mov	r6, r6, pull #\pull
		orr	r6, r6, r7, push #\push
		mov	r7, r7, pull #\pull
		orr	r7, r7, r8, push #\push
		mov	r8, r8, pull #\pull
		orr	r8, r8, r9, push #\push
		mov	r9, r9, pull #\pull
		orr	r9, r9, ip, push #\push
		mov	ip, ip, pull #\pull
		orr	ip, ip, lr, push #\push
		stmia	r0!, {r3, r4, r5, r6, r7, r8, r9, ip}
		bge	12b
	PLD(	cmn	r2, #96			)
	PLD(	bge	13b			)

		ldmfd	sp!, {r5 - r9}
		cfi_adjust_cfa_offset (-20)
		cfi_restore (r5)
		cfi_restore (r6)
		cfi_restore (r7)
		cfi_restore (r8)
		cfi_restore (r9)

14:		ands	ip, r2, #28
		beq	16f

15:		mov	r3, lr, pull #\pull
		ldr	lr, [r1], #4
		subs	ip, ip, #4
		orr	r3, r3, lr, push #\push
		str	r3, [r0], #4
		bgt	15b
	CALGN(	cmp	r2, #0			)
	CALGN(	bge	11b			)

16:		sub	r1, r1, #(\push / 8)
		b	8b

		.endm


		forward_copy_shift	pull=8	push=24

17:		forward_copy_shift	pull=16	push=16

18:		forward_copy_shift	pull=24	push=8

END(memcpy)

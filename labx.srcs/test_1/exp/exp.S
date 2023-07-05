_begin:
	li      a0, 0x114514
    csrw    sstatus, a0
	csrr	a0, sstatus
    addi    a0, a0, 1
    csrw	sstatus, a0
    csrr	a1, sepc
    addi    a1, a1, 2
    csrw	sepc, a1
    addi	a2, x0, 3
    csrw	scause, a2
	csrr	a3, stval
    addi    a3, a3, 4
    csrw	stval, a3
    li		a4, 0x68
    addi	a5, x0, 0
    sd		a4, 0(a5)
    ld		a0, 0(a5)
    csrw	stvec, a0
    ecall
    
_loop:
	addi	s0, s0, 1
    addi	s0, s0, 2
    addi	s0, s0, 3
    addi	s0, s0, 4
    addi	s0, s0, 6
    jal		_loop
    
_func:						#0x68
	addi	s1, x0, 1
    addi	s1, s1, 2
    addi	s1, s1, 3
    addi	s1, s1, 4
    addi	s1, s1, 5
    sret
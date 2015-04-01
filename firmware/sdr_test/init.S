	.extern __data_start
	.extern __data_load
	.extern _edata

	.global _board_init_data

_board_init_data:
	l.movhi	r3,hi(__data_load)
	l.ori	r3,r3,lo(__data_load)

	l.movhi	r4,hi(__data_start)
	l.ori	r4,r4,lo(__data_start)

	l.movhi	r5,hi(_edata)
	l.ori	r5,r5,lo(_edata)

.Lcopy:
	l.lwz	r6,0(r3)
	l.sw	0(r4),r6

	l.addi	r4,r4,4
	l.sfltu	r4,r5
	l.bf	.Lcopy
	l.addi	r3,r3,4

	l.jr	r9
	l.nop

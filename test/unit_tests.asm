!to "unit_tests.prg", cbm
!cpu 6510

!src "../vendor/c64unit/cross-assemblers/acme/core2000.asm"

!convtab scr ;scr konvertiert zu C64 Bildschirmzeichen.

!source "../src/macros.asm"

; Init
+c64unit

+examineTest testSumToAccumulator

; If this point is reached, there were no assertion fails
+c64unitExit


testSumToAccumulator
	; Run function
	ldx #5
	ldy #6
	
	jsr sumToAccumulator
	
	; Assertion
	pha
	+assertEqualToA 11
	pla
	+assertNotEqualToA 0
rts

sumToAccumulator
	clc
	sty sumToAccumulatorAdd+1
	txa
sumToAccumulatorAdd
	adc #0
rts

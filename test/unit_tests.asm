!to "unit_tests.prg", cbm
!cpu 6510

!src "../vendor/c64unit/cross-assemblers/acme/core4000.asm"

!convtab scr ;scr konvertiert zu C64 Bildschirmzeichen.

unittest=1
!source "../src/macros.asm"

; Init
+c64unit

+examineTest test_delay_saves_A
+examineTest test_pop_count
+examineTest test_pop_count_keeps_Y_intact
+examineTest test_mirror_test_ram_eror_1
+examineTest test_mirror_test_ram_eror_2
+examineTest test_mirror_test_error_1
+examineTest test_mirror_test_error_2
+examineTest test_mirror_test_error_3

; If this point is reached, there were no assertion fails
+c64unitExit

!zone {
.m
    !scr "test_delay_saves_A"
.me
test_delay_saves_A
	
	lda #$55
	
	+delay 3
	
	; Assertion
	+assertEqualToA $55, .m, .me
rts
}

!zone {
.m
    !scr "test pop count"
.me
test_pop_count:
	lda #$00
	+pop_count
	+assertEqualToA 0, .m, .me
	
	lda #$55
	+pop_count
	+assertEqualToA 4, .m, .me
	
	lda #$80
	+pop_count
	+assertEqualToA 1, .m, .me
	
	lda #$01
	+pop_count
	+assertEqualToA 1, .m, .me
	
	lda #$AA
	+pop_count
	+assertEqualToA 4, .m, .me
	
	lda #$FF
	+pop_count
	+assertEqualToA 8, .m, .me
rts
}

!zone {
.m
    !scr "test_pop_count_keeps_Y_intact"
.me
test_pop_count_keeps_Y_intact
	ldy #$37
	
	lda #$55
	+pop_count
	
	+assertEqualToY $37, .m, .me
rts
}

unittest_fuck_ram_1:
	jsr $FCE2
	rts
unittest_fuck_ram_2:
	jsr $FCE2
	rts

!macro test_mirror_test_ram_eror .fuck_value, .m, .me {
	lda #<.fuck_ram_1
	sta unittest_fuck_ram_1 + 1
	lda #>.fuck_ram_1
	sta unittest_fuck_ram_1 + 2

	lda #<.fuck_ram_2
	sta unittest_fuck_ram_2 + 1
	lda #>.fuck_ram_2
	sta unittest_fuck_ram_2 + 2
	
	+mirror_test $CFFF, 12, .error_jmp, .fucked_jmp, .ram_error_jmp

.error_jmp:	
.fucked_jmp:
	; test failed
	lda #33
	+assertEqualToA 44 ,.m, .me
	rts

.ram_error_jmp:
	; this error should have been detected, $01 is mask of bad RAMS
	+assertEqualToA .fuck_value ,.m, .me
	rts

.fuck_ram_1:
	rts

.fuck_ram_2:
	pha

	lda #.fuck_value
	sta $CFFF

	pla
	rts
}

!zone {
.m
    !scr "test_mirror_test_ram_eror_1"
.me
test_mirror_test_ram_eror_1:
	+test_mirror_test_ram_eror $01 ,.m, .me
}

!zone {
.m
    !scr "test_mirror_test_ram_eror_2"
.me
test_mirror_test_ram_eror_2:
	+test_mirror_test_ram_eror $A2 ,.m, .me
}

!macro test_mirror_test_error .fuck_value, .fuck_addr_line, .m, .me {
	lda #<.fuck_ram_1
	sta unittest_fuck_ram_1 + 1
	lda #>.fuck_ram_1
	sta unittest_fuck_ram_1 + 2

	lda #<.fuck_ram_2
	sta unittest_fuck_ram_2 + 1
	lda #>.fuck_ram_2
	sta unittest_fuck_ram_2 + 2
	
	.tst_addr = $CFFF
	.fuck_trigger = .tst_addr  XOR (1 << (.fuck_addr_line))

	; when the test writes $FF here we fuck up the read result
	lda #$00
	sta .fuck_trigger
	
	+mirror_test .tst_addr, 12, .error_jmp, .fucked_jmp, .ram_error_jmp

.ram_error_jmp:
.fucked_jmp:
	; test failed
	lda #33
	+assertEqualToA 44 ,.m, .me
	rts

.error_jmp:	
	; this error should have been detected, $01 is mask of bad RAMS
	+assertEqualToX .fuck_addr_line + 10 ,.m, .me
	rts

.fuck_ram_1:
	rts

.fuck_ram_2:
	pha

	lda #$00
	cmp .fuck_trigger
	beq +
	
	lda #.fuck_value
	sta .tst_addr

+   
	pla
	rts
}

!zone {
.m
    !scr "test_mirror_test_error_1"
.me
test_mirror_test_error_1:
	+test_mirror_test_error $AA, 0 ,.m, .me
}

!zone {
.m
    !scr "test_mirror_test_error_2"
.me
test_mirror_test_error_2:
	+test_mirror_test_error $55, 11 ,.m, .me
}

!zone {
.m
    !scr "test_mirror_test_error_3"
.me
test_mirror_test_error_3:
	+test_mirror_test_error $F0, 8 ,.m, .me
}
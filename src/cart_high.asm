!to "cart_high.bin",plain

!convtab scr ;scr konvertiert zu C64 Bildschirmzeichen.

unittest=0
!source "macros.asm"

* =  $E000

		+init
		+init_vic  vic_data_ultimax
		+init_cias

		+sid_init

		lda #17
		sta $d404   ;wellenform, ton an 1
		
		+copy_font font_data_ultimax, $800
		+clear_screen
		+print $400, welcome_text
		
		+delay 0
		sty $d404 ;ton aus 1
		
		lda #17
		sta $d40B   ;wellenform, ton an 2
		+delay 0
		sty $d40B ;ton aus 2

		sta $d412   ;wellenform, ton an 3
		+delay 0
		sty $d40B ;ton aus 3

		+mirror_test $fff, 12, addr_error, ram_test_flash_ram

		jmp mirror_test_finished

addr_error:
		+flash_x
		jmp	print_screen_start
		
mirror_test_finished:
		+tone_880
		+delay 0
		+delay 0
		+delay 0
		+delay 0

		+tone_440

;RAM test from dead test cartridge starts here

		LDX	#$15 ; X is bit pattern iterator
		LDY	#0   ; Y is write loop counter

ram_write_lp:
		LDA	ram_test_patterns,X
		STA	$100,Y
		STA	$200,Y
		STA	$300,Y
		STA	$400,Y
		STA	$500,Y
		STA	$600,Y
		STA	$700,Y
		STA	$800,Y
		STA	$900,Y
		STA	$A00,Y
		STA	$B00,Y
		STA	$C00,Y
		STA	$D00,Y
		STA	$E00,Y
		STA	$F00,Y
		INY
		BNE	ram_write_lp
		
		TXA ; save bit pattern iterator
		
		LDX	#0
		LDY	#0
ram_wait_lp:
		DEY
		BNE	ram_wait_lp
		DEX
		BNE	ram_wait_lp
		
		TAX ; restore bit pattern iterator

ram_read_lp:
		LDA	$100,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$200,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$300,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$400,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$500,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$600,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$700,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$800,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$900,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$A00,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$B00,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$C00,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$D00,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$E00,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		LDA	$F00,Y
		CMP	ram_test_patterns,X
		BNE	ram_test_fail
		INY
		BEQ	ram_read_lp_finished
		JMP	ram_read_lp
; ---------------------------------------------------------------------------

ram_test_fail: ; we need to have this trampoline or short jump would be out of range
		JMP	ram_test_fail_1
; ---------------------------------------------------------------------------

ram_read_lp_finished:
		DEX             ; next bit pattern
		BMI	ram_test_done

		+tone_880

		JMP	ram_write_lp
; ---------------------------------------------------------------------------

ram_test_done:
		JMP	print_screen_start

ram_test_fail_1:				; test failed, read value in A 
		EOR	ram_test_patterns,X ; A now holds a mask of failed bits

ram_test_flash_ram:
		+flash_failed_rams
		
; ---------------------------------------------------------------------------
print_screen_start:
		+clear_screen
		+copy_font font_data_ultimax, $800


!macro pchrs .page {
		ldx #0
		ldy #0
.pchrs:
		txa
		sta .page,x
		
		ldx #40
.pchrs_dly:
		dey
		bne .pchrs_dly
		dex
		bne .pchrs_dly
		
		tax
		
		lda $DC01
		and #$10
		beq pchrs_space_pressed
		
		inx
		bne .pchrs
}

		+pchrs $400
		+pchrs $500
		+pchrs $600
		+pchrs $700



pchrs_space_pressed:

ellp:
		jmp $8009 ; 8k cart code start
		JMP print_screen_start

 * = $FC00

font_data_ultimax:
		!binary "font.bin"

vic_data_ultimax:
	+vic_register_data

welcome_text:
	!text "tixivs ultimate dead test v0.1 - ultimax"
	!byte 0
	
ram_test_patterns:		
		!byte $00, $55, $AA, $FF, $01, $02, $04, $08, $10, $20, $40, $80
		!byte $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F, $00, $05

* = $FFFA
	!byte $00, $e0, $00, $e0, $00, $e0


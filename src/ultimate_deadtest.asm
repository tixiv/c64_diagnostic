; File will be a 16k binary. It has two 8k parts:
; The first 8k is the advanced diagnostic that runs in 16k cartridge mode.
; It is mapped to $8000 in that moment.
; The second 8k are the deadtest that runs in ultimax mode and is mapped at $E000.

!to "ultimate_deadtest.bin",plain

!convtab scr ;scr konvertiert zu C64 Bildschirmzeichen.

!source "macros.asm"

; *************************** CODE for Cart-mode Starts here *******************************************************

* = $C000   ;actually this will be at $8000
	!word $8009 ; vector
	!word $8009 ; vector
	!byte $C3, $C2, $CD, $38, $30; cbm80
	
* = $C009

!pseudopc $8009 {
cart_code_start:
		lda $DF00  ; trigger io read 2 (switches banker out of ultimax mode on tixiv's special cartridge)
		lda #$86
		sta $DE02  ; set easflash to 8k mode, LED on
		
		+init
		+init_vic  vic_data_cart
		+init_cias

		+sid_init

		lda #17
		sta $d404   ;wellenform, ton an 1
		
		+copy_font font_data_cart, $800
		+clear_screen
		+print $400, welcome_text_cart
		
		+delay 0
		sty $d404 ;ton aus 1
		
		lda #17
		sta $d40B   ;wellenform, ton an 2
		+delay 0
		sty $d40B ;ton aus 2

		sta $d412   ;wellenform, ton an 3
		+delay 0
		sty $d40B ;ton aus 3
		+delay 0

		; FIXME: implement blinking out RAM chips for RAM errors
		+mirror_test $7FFF, 16, mirror_error, mirror_error, mirror_error

		; TODO: do full RAM test
		
		+tone_880
		+delay 0
		jmp wt1

mirror_error:
		+flash_x

wt1:
		+copy_font font_data_cart, $0800
		+copy_font font_data_cart, $4800
		+copy_font font_data_cart, $8800
		+copy_font font_data_cart, $C800

		+clear_screen $0400
		+clear_screen $4400
		+clear_screen $8400
		+clear_screen $C400
		
		+print $0400, text_page_0400
		+print $4400, text_page_4400
		+print $8400, text_page_8400
		+print $C400, text_page_C400
		
		+print $0400 + 1000, text_if_visible_va6_or_7_bad
		+print $4400 + 1000, text_if_visible_va6_or_7_bad
		+print $8400 + 1000, text_if_visible_va6_or_7_bad
		+print $C400 + 1000, text_if_visible_va6_or_7_bad
		
vlp:
		;videobank 0 selektieren
		lda #3
		sta $dd00 ; daten ausgang port a
		sta $dd02 ; datenrichtung port A		

		+print $4400 + 80, text_va14_stuck_high
		+print $C400 + 80, text_va14_stuck_high
				
		+print $8400 + 120, text_va15_stuck_high
		+print $C400 + 120, text_va15_stuck_high

		+delay 0
		+delay 0

		+print $4400 + 80, text_empty ;va14 stuck high löschen
		+print $C400 + 80, text_empty ;va14 stuck high löschen

		;videobank 1 selektieren
		lda #2
		sta $dd00 ; daten ausgang port a

		+print $0400 + 80, text_va14_stuck_low
		+print $8400 + 80, text_va14_stuck_low

		+delay 0
		+delay 0

		+print $8400 + 120, text_empty ;va15 stuck high löschen
		+print $C400 + 120, text_empty ;va15 stuck high löschen

		;videobank 3 selektieren
		lda #0
		sta $dd00 ; daten ausgang port a
		
		+print $0400 + 120, text_va15_stuck_low
		+print $4400 + 120, text_va15_stuck_low
		
		+delay 0
		+delay 0

		+print $0400 + 80, text_empty ;va14 stuck low löschen
		+print $8400 + 80, text_empty ;va14 stuck low löschen

		;videobank 2 selektieren
		lda #1
		sta $dd00 ; daten ausgang port a

		+print $4400 + 80, text_va14_stuck_high
		+print $C400 + 80, text_va14_stuck_high

		+delay 0
		+delay 0

		+print $0400 + 120, text_empty ;va15 stuck low löschen
		+print $4400 + 120, text_empty ;va15 stuck low löschen



		;videobank 0 selektieren
		lda #3
		sta $dd00 ; daten ausgang port a

		+print $8400 + 120, text_va15_stuck_high
		+print $C400 + 120, text_va15_stuck_high

		
		+print $0400 + 160, text_kernal_rom_test
		+tone_440
		
		lda #$00
		ldx #$00
kernal_tst_lp:
		!for .bank, 0, 31 {
			eor $E000 + (.bank) * $100, x
		}
		clc
		rol
		adc #$00
		inx
		bne kernal_tst_lp
		
		cmp #$08
		bne kernal_test_failed
		
		+print_in_color $400, 4*40 + 20, COLOR_GREEN, text_ok
		+tone_880
		jmp kernal_test_end

kernal_test_failed:

		+print_in_color $0400, 180, COLOR_RED ,text_fail
		+tone_220
		
kernal_test_end:
		+delay 0
		
		
		+print $0400 + 200, text_basic_rom_test
		+tone_440

		lda #$00
		ldx #$00
basic_tst_lp:
		!for .bank, 0, 31 {
			eor $A000 + (.bank) * $100, x
		}
		clc
		rol
		adc #$00
		inx
		bne basic_tst_lp
		
		cmp #$95
		bne basic_test_failed
		
		+print_in_color $400, 5*40 + 20, COLOR_GREEN, text_ok
		+tone_880
		jmp basic_test_end

basic_test_failed:

		+print_in_color $0400, 5*40 + 20, COLOR_RED ,text_fail
		+tone_220
		
basic_test_end:
		+delay 0
		+delay 0
		+delay 0
		+delay 0
		
		
		jmp cart_code_start
	
font_data_cart:
	!binary "font.bin"

vic_data_cart:
	+vic_register_data

welcome_text_cart:
	!text "tixivs ultimate dead test v0.1 - cart"
	!byte 0	

text_page_0400: !text "PAGE 0400"
	!byte 0	
text_page_4400: !text "PAGE 4400"
	!byte 0	
text_page_8400: !text "PAGE 8400"
	!byte 0	
text_page_C400: !text "PAGE C400"
	!byte 0	
text_va14_stuck_high: !text "VA14 STUCK HIGH"
	!byte 0	
text_va15_stuck_high: !text "VA15 STUCK HIGH"
	!byte 0	
text_va14_stuck_low: !text "VA14 STUCK LOW"
	!byte 0	
text_va15_stuck_low: !text "VA15 STUCK LOW"
	!byte 0	
text_empty: !text "               "
	!byte 0	
text_if_visible_va6_or_7_bad: !text "if visible va6 or 7 bad"
	!byte 0
text_kernal_rom_test: !text "kernal rom test"
	!byte 0
text_basic_rom_test: !text "basic  rom test"
	!byte 0
text_ok: !text "ok"
	!byte 0
text_fail: !text "fail"
	!byte 0


}


* =  $E000


; =============== S U B	R O U T	I N E =======================================

; Attributes: noreturn

sub_E000:


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

		+mirror_test $fff, 12, tstlp_error, tstlp_error_ram_fucked, ram_test_fail_from_mirror_test

		jmp tstlp_finished

tstlp_error:
		+flash_x

		JMP	print_screen_start
		
tstlp_finished:
		+tone_880
		+delay 0
		+delay 0
		+delay 0
		+delay 0

		+tone_440
tstlp_error_ram_fucked:

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

ram_test_fail_from_mirror_test:
		TAX ; X register holds failed bits
				
		AND	#$01 ;       bit 0 defective ?
		BNE	bit_0_error
		jmp check_bit_1
bit_0_error:
		+flash 8
; ---------------------------------------------------------------------------

check_bit_1:
		TXA
		AND	#$02 ;       bit 1 defective ?
		BNE	bit_1_error
		jmp check_bit_2
bit_1_error:
		+flash 7
; ---------------------------------------------------------------------------

check_bit_2:
		TXA
		AND	#$04 ;       bit 2 defective ?
		BNE	bit_2_error
		jmp check_bit_3
bit_2_error:
		+flash 6
; ---------------------------------------------------------------------------

check_bit_3:
		TXA
		AND	#$08 ;       bit 3 defective ?
		BNE	bit_3_error
		jmp check_bit_4
bit_3_error:
		+flash 5
; ---------------------------------------------------------------------------

check_bit_4:
		TXA
		AND	#$10 ;       bit 4 defective ?
		BNE	bit_4_error
		jmp check_bit_5
bit_4_error:
		+flash 4
; ---------------------------------------------------------------------------

check_bit_5:
		TXA
		AND	#$20 ;       bit 5 defective ?
		BNE	bit_5_error
		jmp check_bit_6
bit_5_error:
		+flash 3
; ---------------------------------------------------------------------------

check_bit_6:
		TXA
		AND	#$40 ;       bit 6 defective ?
		BNE	bit_6_error
		jmp check_bit_7
bit_6_error:
		+flash 2
; ---------------------------------------------------------------------------

check_bit_7:
		TXA
		AND	#$80 ;       bit 7 defective ?
		BEQ	bit_7_okay
		+flash 1
bit_7_okay:
		jmp print_screen_start
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
		jmp cart_code_start
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


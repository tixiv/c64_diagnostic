!to "cart_low.bin",plain

!convtab scr ;scr konvertiert zu C64 Bildschirmzeichen.

unittest=0
!source "macros.asm"
!source "crc32.asm"

; *************************** CODE for Cart-mode Starts here *******************************************************

* = $8000
	!word $8009 ; vector
	!word $8009 ; vector
	!byte $C3, $C2, $CD, $38, $30; cbm80
	
* = $8009

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

		+mirror_test $7FFF, 16, addr_error, ram_test_fail
		
		+tone_880
		+delay 0
		+delay 0
		+delay 0
		+delay 0
		
		+ram_test $1000, ram_test_fail
		
		jmp ram_test_finished
		
ram_test_fail:
		+flash_failed_rams
		jmp cart_code_start

addr_error:
		+flash_x
		jmp cart_code_start

ram_test_finished:
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
		
		; this one allways passed when we get to here
		+print $0400 + 3*40, text_ram_test_0_1000
		+print_in_color $400, 3*40 + 20, COLOR_GREEN, text_ok

; -------------- CRC init --------------------------------------------
CRC = $6 ; zeropage
		jsr crc32_init
		
; -------------- Kernal test -----------------------------------------		
		+print $0400 + 4*40, text_kernal_rom_test
		+tone_440
				
		+crc32 CRC, $e000, 32

		ldy #$03
-		lda CRC,y
		cmp expected_crc_kernal_901227_03,y
		bne test_02_kernal
		dey
		bpl -
		jmp kernal_test_ok

test_02_kernal:
		ldy #$03
-		lda CRC,y
		cmp expected_crc_kernal_901227_02,y
		bne test_01_kernal
		dey
		bpl -
		jmp kernal_test_ok
		
test_01_kernal:
		ldy #$03
-		lda CRC,y
		cmp expected_crc_kernal_901227_01,y
		bne kernal_test_failed
		dey
		bpl -

kernal_test_ok:
		+print_in_color $400, 4*40 + 20, COLOR_GREEN, text_ok
		+tone_880
		jmp kernal_test_end

expected_crc_kernal_901227_03:
		!byte $c7, $e7 ,$e3 ,$db
expected_crc_kernal_901227_02:
		!byte $b3, $87 ,$c6 ,$a5
expected_crc_kernal_901227_01:
		!byte $fa, $82 ,$e7 ,$dc
		
kernal_test_failed:
		+print_in_color $0400, 180, COLOR_RED ,text_fail
		+tone_220
		
kernal_test_end:
		+delay 0

; -------------- Basic test -----------------------------------------		
		+print $0400 + 5*40, text_basic_rom_test
		+tone_440
		
		+crc32 CRC, $a000, 32

		ldy #$03
-		lda CRC,y
		cmp expected_crc_basic_901226_01,y
		bne basic_test_failed
		dey
		bpl -

		+print_in_color $400, 5*40 + 20, COLOR_GREEN, text_ok
		+tone_880
		jmp basic_test_end

expected_crc_basic_901226_01:
		!byte $17, $d1, $33, $f8		

basic_test_failed:

		+print_in_color $0400, 5*40 + 20, COLOR_RED ,text_fail
		+tone_220
		
basic_test_end:
		+delay 0
		
; -------------- Char ROM test --------------------------------------		
		+print $0400 + 6*40, text_char_rom_test
		+tone_440
		
		lda #$03
		sta $01  ; map in char ROM instead of IO
		
		+crc32 CRC, $d000, 16

		lda #$07
		sta $01  ; map IO back in
		
		ldy #$03
-		lda CRC,y
		cmp expected_crc_char_901225_01,y
		bne char_test_failed
		dey
		bpl -

		+print_in_color $400, 6*40 + 20, COLOR_GREEN, text_ok
		+tone_880
		jmp char_test_end

expected_crc_char_901225_01:
		!byte $ee, $72, $42, $ec		

char_test_failed:

		+print_in_color $0400, 6*40 + 20, COLOR_RED ,text_fail
		+tone_220
		
char_test_end:
		+delay 0

; -------------- RAM test $1000-$FFFF ----------------------------------

	+print $0400 + 7*40, text_ram_test_1000_FFFF

	; copy RAM test to $200
	ldy #$00
-	lda ram_test_start,y
	sta $200,Y
	iny
	bne -
	
	jsr $200
	
	cmp #$00
	beq +
	jmp ram_test_fail
+
	+print_in_color $400, 7*40 + 20, COLOR_GREEN, text_ok

	+delay 0
	+delay 0
	+delay 0
	+delay 0
	
	jmp cart_code_start

ram_test_start:
!pseudopc $200 {
	;RAM test from $1000 to $FFFF
	ldx	#$13 ; X is bit pattern iterator

.ram_test_lp:
	ldy #$0
	sty $1  ; map 64k RAM

	lda #$10
	sta .sta_hb ; fix self modyfying code
	sta .lda_hb ; fix self modyfying code
	
.ram_write_lp:
	lda	.ram_test_patterns,X

	ldy	#0
.sta_hb = * + 2
-	sta $1000,Y
	iny
	BNE -
	
	lda #$ff
	cmp .sta_hb ; last page finished ?
	beq .ram_read_lp

	inc .sta_hb ; inc page
	jmp .ram_write_lp
	
.ram_read_lp:
	ldy	#0
.lda_hb = * + 2
-	lda $1000,Y
	CMP	.ram_test_patterns, X
	BNE .ram_test_fail_internal
	iny
	BNE -
	
	lda #$ff
	cmp .lda_hb ; last page finished ?
	beq +

	inc .lda_hb ; inc page
	jmp .ram_read_lp

+	ldy #$7
	sty $1  ; restore normal memory layout
	
	lda #$00        ; 0 result in case we are finished
	DEX             ; next bit pattern
	BMI	.ram_test_done

	+tone_880

	JMP	.ram_test_lp
	
.ram_test_fail_internal:        ; test failed, read value in A 
	ldy #$7
	sty $1  ; restore normal memory layout

	eor	.ram_test_patterns, X   ; A now holds a mask of failed bits

.ram_test_done:
	rts
; ---------------------------------------------------------------------------
.ram_test_patterns:		
	!byte $00, $55, $AA, $FF, $01, $02, $04, $08, $10, $20, $40, $80
	!byte $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F
	
}
		
+crc32_impl CRC, $C000

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
text_basic_rom_test:  !text "basic  rom test"
	!byte 0
text_char_rom_test:   !text "char   rom test"
	!byte 0
text_ram_test_0_1000: !text "ram test 0-FFF"
	!byte 0
text_ram_test_1000_FFFF: !text "ram test 1000-FFFF"
	!byte 0
text_ok: !text "ok"
	!byte 0
text_fail: !text "fail"
	!byte 0

	* = $9FFF
	!byte 0

!to "cart_low.bin",plain

!convtab scr ;scr konvertiert zu C64 Bildschirmzeichen.

unittest=0
!source "macros.asm"

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

		+mirror_test $7FFF, 16, addr_error, ram_error
		
		+tone_880
		+delay 0
		jmp wt1
		
ram_error:
		+flash_failed_rams
		jmp wt1

addr_error:
		+flash_x

wt1:
		; TODO: do full RAM test


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

	* = $9FFF
	!byte 0

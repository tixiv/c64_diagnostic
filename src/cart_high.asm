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

		+mirror_test $fff, 12, addr_error, ram_test_fail

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

		+ram_test $1000, ram_test_fail
		
		JMP	print_screen_start

ram_test_fail:
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

* = $FFFA
	!byte $00, $e0, $00, $e0, $00, $e0


COLOR_RED = 2
COLOR_GREEN = 5

; delay for some time given as parameter.
; keps state of A
!macro delay .time {
		ldx #.time
		ldy #0
.lp:	
		dey
		bne .lp
		dex
		bne .lp
}

!macro clear_screen {
		LDX	#0
.clrscr:
		LDA	#$20 ; ' '      ; clear screen
		STA	$400,X
		STA	$500,X
		STA	$600,X
		STA	$700,X
		LDA	#6		; init color ram
		STA	$D800,X
		STA	$D900,X
		STA	$DA00,X
		STA	$DB00,X
		INX
		BNE	.clrscr
}

!macro clear_screen .addr{
		LDX	#0
.clrscr:
		LDA	#$20 ; ' '      ; clear screen
		STA	.addr + $000,X
		STA	.addr + $100,X
		STA	.addr + $200,X
		STA	.addr + $300,X
		INX
		BNE	.clrscr
}


!macro copy_font .from, .to {
		LDX #$00
.fclp1:
		lda .from,X
		sta .to+$000,X
		sta .to+$200,X
		sta .to+$400,X
		sta .to+$600,X

		lda .from + $100,X
		sta .to+$100,X
		sta .to+$300,X
		sta .to+$500,X
		sta .to+$700,X

		INX
		BNE .fclp1
}


!macro init_vic .vic_data {
		LDX	#$2F
.lp:
		LDA	.vic_data-1,X
		STA	$CFFF,X
		DEX
		BNE	.lp
}

!macro init_cias {
		lda #$7f ;tastaturzeile mit leertaste auf 0
		sta $DC00
		lda #$ff
		sta $DC02 ;tastaturzeilen auf ausgang
		
		;timer nullen
		LDX	#4
.lp:
		lda #0
		STA	$DC07,X
		STA	$DD07,X
		DEX
		BNE	.lp

		;timer starten
		LDA	#8
		STA	$DC0F
		STA	$DD0F
		LDA	#$48
		STA	$DC0E
		LDA	#8
		STA	$DD0E
}

!macro sid_init {
		lda #15
		sta $d418   ;lautstärke
		lda #16+9
		sta $d405   ;anschlag
		sta $d40C   ;anschlag
		sta $d413   ;anschlag
		lda #0*16+5 
		sta $d406   ;halten und ausklingen
		sta $d40D   ;halten und ausklingen
		sta $d414   ;halten und ausklingen
		lda #29
		sta $d401   ;fh
		sta $d408   ;fh
		sta $d40F   ;fh
		lda #69
		sta $d400   ;fl
		sta $d407   ;fl
		sta $d40E   ;fl

		lda #0
		sta $d404 ;ton aus 1
		sta $d40B ;ton aus 2
		sta $d412 ;ton aus 3
}

!macro tone_880 {
		;stimme 1 auf höhere frequenz
		lda #00
		sta $d404   ;ton aus 1
		lda #58
		sta $d401   ;fh
		lda #138
		sta $d400   ;fl
		lda #17
		sta $d404   ;wellenform, ton an 1
}

!macro tone_440 {
		;stimme 1 auf höhere frequenz
		lda #00
		sta $d404   ;ton aus 1
		lda #29
		sta $d401   ;fh
		lda #60
		sta $d400   ;fl
		lda #17
		sta $d404   ;wellenform, ton an 1
}

!macro tone_220 {
		lda #00
		sta $d404   ;ton aus 1
		;stimme 1 auf niedrige frequenz 
		lda #14
		sta $d401   ;fh
		lda #162
		sta $d400   ;fl
		lda #17
		sta $d404   ;wellenform, ton an 1
}

; the value of X is preserved.
!macro flash_begin {
	lda	#0
	sta $D020 	; set black

	lda #easyflash_mode
	sta $DE02 ;easyflash LED off

	txa
	+delay 0
	+delay 0
	+delay 0
	+delay 0
	tax
}

; flash one time
; the value of X is preserved.
!macro flash {
	lda	#1
	sta	$D020 ;set white

	lda #easyflash_mode + $80
	sta $DE02 ;easyflash LED on

	+tone_220	
	
	txa
	
	+delay $7f
	
	ldx	#0
	stx $D020 ; set black

	ldx #easyflash_mode
	stx $DE02 ;easyflash LED off
	
	+delay $7f
	+delay 0

	tax
}

; flash X times
!macro flash_x {
	+flash_begin
	
.flash_x_lp:
	+flash
	
	dex
	bne .flash_x_lp
}

; A register must hold mask of failed bits.
; The mapping of bit (ram chip) to flashes is taken 
; from original deadtest cartridge.
; Bit 7 set -> 1 flash
; Bit 6 set -> 2 flashes
; Bit 5 set -> 3 flashes
; Bit 4 set -> 4 flashes
; Bit 3 set -> 5 flashes
; Bit 2 set -> 6 flashes
; Bit 1 set -> 7 flashes
; Bit 0 set -> 8 flashes
!macro flash_failed_rams {
.start:
			; A register needs to hold failed bits
		TAX ; X register holds failed bits now
		bne begin_flash ; some bits defective? begin flashing
		
		jmp .done ; no more failed bits
		
begin_flash:
		+flash_begin
		
	!for .i, 7, 0 {
		+flash
		TXA
		AND	#(1<<.i)  ; bit .i defective ?
		beq +         ; no: flash again
		
		TXA           ; yes
		AND #((1<<.i) XOR $FF) ; clear it
		jmp .start    ; and check rest of bits		
+
	}

.done:
}

!macro wrtlp .target, .value {
		ldy #$00
.wrtlp_1 = *
		lda #.value
		sta .target
		iny
		bne .wrtlp_1
}

; returns pop count of A in A.
; Y register is kept in tact.
!macro pop_count {
	ldx #$00
	!for .i, 0, 7 {
		ror	
		bcc +
		inx
+:
	}
	txa
}

!macro tstlp .target, .value, .addr_error_jmp, .errorcode, .ram_error_jmp {
		ldy #$00
.tstlp_1:
		lda #.value
		cmp .target
		beq .tstlp_wt
		
		eor .target    ; A holds mask of failed bits
		tay            ; save it in Y
		+pop_count
		
		clc
		cmp #4         ; up to 3 defective bits ?
		bcc .ram_error ; probably we have bad RAM address line(s) and not multiplexer failure
		
		ldx #.errorcode ; 4 or more: probably addres multiplexer defective or Addres line stuck
		tya
		jmp .addr_error_jmp
.ram_error:
		ldx #.errorcode
		tya            ; restore mask of failed bits
		jmp .ram_error_jmp		
		
.tstlp_wt:
		iny
		bne .tstlp_1
}

!macro mirror_test .tst_adr, .num_bits, .addr_error_jmp, .ram_error_jmp {
		;init last ram location 256 times
		+wrtlp .tst_adr, $00
		
		!if unittest {
			jsr unittest_fuck_ram_1
		}
		
		;test 256 times if value is valid
		+tstlp .tst_adr, $00, .ram_error_jmp, 9, .ram_error_jmp ; 9 blinks means ram fucked 
		
		;set different value to each possible mirror ram location
		;and test if original value was changed
	!for .bit, 0, .num_bits-1 {
			+wrtlp .tst_adr  XOR (1 << (.bit)), $FF
			
			!if unittest {
				jsr unittest_fuck_ram_2
			}
			
			+tstlp .tst_adr, $00, .addr_error_jmp, .bit+10, .ram_error_jmp ;A0 = 10 blinks .... A15 = 25 blinks
	}
}

!macro init {
		SEI
		LDX	#$FF
		TXS
		CLD
		LDA	#$E7
		STA	$01
		LDA	#$37
		STA	$00
}

!macro print .addr, .string {
		ldx #$ff
.lp:
		inx
		lda .string,x
		beq .done
		sta .addr,x
		jmp .lp
.done:
}

!macro print_in_color .screen, .screen_pos, .color, .string {
		ldx #$ff
.lp:
		inx
		lda .string,x
		beq .done
		sta .screen + .screen_pos,x
		lda #.color
		sta $D800 + .screen_pos,x
		jmp .lp
.done:
}

!macro ram_test .size, .ram_test_fail {
	;RAM test from dead test cartridge starts here
	LDX	#$13 ; X is bit pattern iterator
	LDY	#0   ; Y is write loop counter

.ram_test_lp:
.ram_write_lp:
	LDA	.ram_test_patterns,X

	!for .i, 0, (.size / $100)-1 {
		!if .i = 0 {
			STA	$100 * .i + 2, Y ; don't overwrite 6510 IO port
		} else {
			STA	$100 * .i, Y
		}
	}

	INY
	BEQ +
	jmp .ram_write_lp
	
+
	TXA ; save bit pattern iterator
	+delay 0
	TAX ; restore bit pattern iterator

.ram_read_lp:

	!for .j, 0, (.size / $1000)-1 {
		!for .i, 0, 7 {
			!if .j = 0 AND .i = 0 {
				LDA	$1000 * .j + 2, Y
			} else {
				LDA	$1000 * .j + $100 * .i, Y
			}
			
			CMP	.ram_test_patterns, X
			BNE	+
		}
		jmp ++
+
-
		jmp .ram_test_fail_internal ; local trampoline
++		
		!for .i, 8, 15 {
			LDA	$1000 * .j + $100 * .i, Y
			CMP	.ram_test_patterns, X
			BNE	-
		}
	}

	INY
	BEQ	.ram_read_lp_finished
	JMP	.ram_read_lp
; ---------------------------------------------------------------------------

.ram_test_fail_internal:        ; test failed, read value in A 
	EOR	.ram_test_patterns, X   ; A now holds a mask of failed bits

	JMP	.ram_test_fail
; ---------------------------------------------------------------------------

.ram_read_lp_finished:
	DEX             ; next bit pattern
	BMI	.ram_test_done

	+tone_880

	JMP	.ram_test_lp

.ram_test_patterns:		
	!byte $00, $55, $AA, $FF, $01, $02, $04, $08, $10, $20, $40, $80
	!byte $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F
	
.ram_test_done:
}

!macro vic_register_data {
	!byte $00, $00, $00, $00, $00, $00, $00, $00
	!byte $00, $00, $00, $00, $00, $00, $00, $00
	!byte $00, $1B, $00, $00, $00, $00, $08, $00
	!byte $12, $00, $00, $00, $00, $00, $00, $00
	!byte $03, $01, $00, $00, $00, $00, $00, $00
}

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

!macro cia_test .base_addr {
		lda #$00
		sta .base_addr + 2 ; port a input
		sta .base_addr + 3 ; port b input
		sta .base_addr     ; port a would write 0s
		sta .base_addr + 1 ; port b would write 0s
		
		+delay 2
		
		lda 
		
		
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

!macro flash_x {
		; set black
		lda	#0
		sta $D020
		
		txa
		
		+delay 0
		+delay 0
		+delay 0
		+delay 0
		
		tax
		
.flash_x_lp:           ;set white
		LDA	#1
		STA	$D020

		+tone_220
		
		TXA
		
		+delay $7f
		
		; set black
		ldx	#0
		stx $D020
		
		+delay $7f
		+delay 0
		
		TAX
		DEX
		BNE .flash_x_lp
}

; flash .times times. Unrolled loop.
; the value of X is preserved.
!macro flash .times {
	lda	#0
	sta $D020 	; set black
	
	txa
	+delay 0
	+delay 0
	+delay 0
	+delay 0
		
	!for .i, 1, .times {
		ldx	#1
		stx	$D020 ;set white

		tax
		+tone_220		
		txa
		
		+delay $7f
		
		; set black
		ldx	#0
		stx $D020
		
		+delay $7f
		+delay 0
	}

	tax
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

!macro tstlp .target, .value, .errorjmp, .errorcode, .ram_error_jmp {
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
		jmp .errorjmp
.ram_error:
		ldx #.errorcode
		tya            ; restore mask of failed bits
		jmp .ram_error_jmp		
		
.tstlp_wt:
		iny
		bne .tstlp_1
}

!macro mirror_test .tst_adr, .num_bits, .error_jmp, .fucked_jmp, .ram_error_jmp {
		;init last ram location 256 times
		+wrtlp .tst_adr, $00
		
		!if unittest {
			jsr unittest_fuck_ram_1
		}
		
		;test 256 times if value is valid
		+tstlp .tst_adr, $00, .fucked_jmp, 9, .ram_error_jmp ; 9 blinks means ram fucked 
		
		;set different value to each possible mirror ram location
		;and test if original value was changed
	!for .bit, 0, .num_bits-1 {
			+wrtlp .tst_adr  XOR (1 << (.bit)), $FF
			
			!if unittest {
				jsr unittest_fuck_ram_2
			}
			
			+tstlp .tst_adr, $00, .error_jmp, .bit+10, .ram_error_jmp ;A0 = 10 blinks .... A15 = 25 blinks
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

!macro vic_register_data {
	!byte $00, $00, $00, $00, $00, $00, $00, $00
	!byte $00, $00, $00, $00, $00, $00, $00, $00
	!byte $00, $1B, $00, $00, $00, $00, $08, $00
	!byte $12, $00, $00, $00, $00, $00, $00, $00
	!byte $03, $01, $00, $00, $00, $00, $00, $00
}

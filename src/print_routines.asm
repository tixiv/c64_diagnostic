
CURSOR_POS_ZP = $10
STRING_P_ZP = $12


!macro set_cursor .line, .column {
	.address = $400 + .line*40 + .column
	lda #<.address
	sta CURSOR_POS_ZP
	lda #>.address
	sta CURSOR_POS_ZP+1
}

; print a null terminated string at X:Y to current cursor position
print_string:
	sty STRING_P_ZP
	stx STRING_P_ZP+1
	ldy #$00
-	lda (STRING_P_ZP), Y
	beq +
	sta (CURSOR_POS_ZP), Y
	iny
	jmp -
+	tya
	clc
	adc CURSOR_POS_ZP
	sta CURSOR_POS_ZP
	bcc +
	inc CURSOR_POS_ZP+1
+	rts


!zone {
; print a hex digit in A and increment cursor position
; X register is kept intact
.print_hex_digit:
	cmp #$0A
	bmi +
	clc
	adc #('A' - ('9'+1))
+	clc
	adc #('0')
	ldy #$00
	sta (CURSOR_POS_ZP),y
	inc CURSOR_POS_ZP
	bne +
	inc CURSOR_POS_ZP+1
+	rts	

; print A as two places hex to current cursor position
print_hex:
	tax
	lsr
	lsr
	lsr
	lsr
	jsr .print_hex_digit
	txa
	and #$0f
	jsr .print_hex_digit
	rts	
}
	

	
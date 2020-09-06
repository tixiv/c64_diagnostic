
all: ultimate_deadtest.crt cart_low.bin


cart_low.bin: ultimate_deadtest.bin
	dd if=ultimate_deadtest.bin bs=8192 skip=0 count=1 of=cart_low.bin

cart_high.bin: ultimate_deadtest.bin
	dd if=ultimate_deadtest.bin bs=8192 skip=1 count=1 of=cart_high.bin

ultimate_deadtest.crt: crt_header cart_high.bin
	cat crt_header > ultimate_deadtest.crt
	cat cart_high.bin >> ultimate_deadtest.crt

ultimate_deadtest.bin: ultimate_deadtest.asm
	acme ultimate_deadtest.asm
	
:PHONY clean
clean:
	rm -f cart_low.bin cart_high.bin ultimate_deadtest.crt ultimate_deadtest.bin

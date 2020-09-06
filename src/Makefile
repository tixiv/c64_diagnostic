
all: cart_low.bin cart_high.bin ultimate_deadtest.crt ultimate_diagnostic.crt easyflash.crt


cart_low.bin: ultimate_deadtest.bin
	dd if=ultimate_deadtest.bin bs=8192 skip=0 count=1 of=cart_low.bin

cart_high.bin: ultimate_deadtest.bin
	dd if=ultimate_deadtest.bin bs=8192 skip=1 count=1 of=cart_high.bin

ultimate_deadtest.crt: crt_header_ultimax cart_high.bin
	cat crt_header_ultimax > ultimate_deadtest.crt
	cat cart_high.bin >> ultimate_deadtest.crt

ultimate_diagnostic.crt: crt_header_8k ultimate_deadtest.bin
	cat crt_header_8k > ultimate_diagnostic.crt
	cat ultimate_deadtest.bin >> ultimate_diagnostic.crt

easyflash.crt: crt_header_easyflash chip_header_easyflash cart_low.bin cart_high.bin
	cat crt_header_easyflash   > easyflash.crt
	cat cart_low.bin          >> easyflash.crt
	cat chip_header_easyflash >> easyflash.crt
	cat cart_high.bin         >> easyflash.crt

ultimate_deadtest.bin: ultimate_deadtest.asm
	acme ultimate_deadtest.asm
	
:PHONY clean
clean:
	rm -f ultimate_deadtest.bin cart_low.bin cart_high.bin ultimate_deadtest.crt ultimate_diagnostic.crt easyflash.crt

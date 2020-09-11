
all: cart_low.bin cart_high.bin ultimate_deadtest.crt


cart_low.bin: cart_low.asm macros.asm
	acme cart_low.asm

cart_high.bin: cart_high.asm macros.asm
	acme cart_high.asm

ultimate_deadtest.crt: crt_header_easyflash chip_header_easyflash cart_low.bin cart_high.bin
	cat crt_header_easyflash   > ultimate_deadtest.crt
	cat cart_low.bin          >> ultimate_deadtest.crt
	cat chip_header_easyflash >> ultimate_deadtest.crt
	cat cart_high.bin         >> ultimate_deadtest.crt

:PHONY clean
clean:
	rm -f cart_low.bin cart_high.bin ultimate_deadtest.crt

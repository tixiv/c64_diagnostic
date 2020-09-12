
all: cart_low.bin cart_high.bin tixivs_diagnostic.crt


cart_low.bin: cart_low.asm macros.asm
	acme cart_low.asm

cart_high.bin: cart_high.asm macros.asm
	acme cart_high.asm

tixivs_diagnostic.crt: crt_header_easyflash chip_header_easyflash cart_low.bin cart_high.bin
	cat crt_header_easyflash   > tixivs_diagnostic.crt
	cat cart_low.bin          >> tixivs_diagnostic.crt
	cat chip_header_easyflash >> tixivs_diagnostic.crt
	cat cart_high.bin         >> tixivs_diagnostic.crt

:PHONY clean
clean:
	rm -f cart_low.bin cart_high.bin tixivs_diagnostic.crt

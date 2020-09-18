
all: unit_tests.prg

unit_tests.prg: unit_tests.asm ../src/macros.asm ../src/crc32.asm ../src/print_routines.asm
	acme -l unit_tests.sym unit_tests.asm 
	
:PHONY clean
clean:
	rm -f ultimate_deadtest.bin cart_low.bin cart_high.bin ultimate_deadtest.crt unit_tests.prg

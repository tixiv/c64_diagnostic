
all: unit_tests.prg

unit_tests.prg: unit_tests.asm ../src/macros.asm
	acme unit_tests.asm
	
:PHONY clean
clean:
	rm -f ultimate_deadtest.bin cart_low.bin cart_high.bin ultimate_deadtest.crt unit_tests.prg

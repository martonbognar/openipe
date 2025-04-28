NAME            = ipe-hello
OBJECTS         = main.o output/generated_table.o output/generated_stubs.o

AS              = msp430-as
CC              = msp430-gcc
CFLAGS          = -Wall -g -mcpu=430 -mmpy=none -D__MSP430F149__ -I$(shell msp430-gcc -print-file-name="include")
LDFLAGS         = -L$(shell msp430-gcc -print-file-name="") -T pmem.x

all: ${NAME}.elf

${NAME}.elf: ${OBJECTS}
	../framework/linker.py $(LDFLAGS) -o $@ ${OBJECTS}

clean:
	rm -f *.o *.elf *.ihex pmem.* output/*.o

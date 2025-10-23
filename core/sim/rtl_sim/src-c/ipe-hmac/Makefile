NAME            = ipe-hmac
OBJECTS         = untrusted.o generated_ipe.o output/generated_table.o output/generated_stubs.o

CC              = msp430-gcc
AS              = msp430-as
CFLAGS          = -Wall -std=gnu99 -g -mcpu=430 -mmpy=none -D__MSP430F149__ -I$(shell msp430-gcc -print-file-name="include")
LDFLAGS         = -L$(shell msp430-gcc -print-file-name="") -T pmem.x

all: ${NAME}.elf

${NAME}.elf: ${OBJECTS}
	../framework/linker.py $(LDFLAGS) -o $@ ${OBJECTS}

ipe.o: ipe.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f *.o *.elf *.ihex pmem.* output/*.o

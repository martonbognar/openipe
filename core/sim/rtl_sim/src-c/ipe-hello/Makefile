OPENIPE        = ../framework
CC              = $(OPENIPE)/compiler.py
LD              = $(OPENIPE)/linker.py

NAME            = ipe-hello
SOURCES         = $(shell ls *.c)
OBJECTS         = $(SOURCES:.c=.o)

INCLUDE         = -I$(OPENIPE) -I$(shell msp430-gcc -print-file-name="include")
CFLAGS          = -Wall -std=gnu99 -g -mcpu=430 -mmpy=none -D__MSP430F149__
LDFLAGS         = -L$(shell msp430-gcc -print-file-name="") -T pmem.x

all: $(NAME).elf

$(NAME).elf: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@ 

%.o : %.c
	$(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@

clean:
	rm -f *.o *.elf *.ihex pmem.* output/*.o

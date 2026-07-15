include ../Makefile.include

NAME            = customTLS
SOURCES         = $(shell ls *.c) ../customTLS/bigint.c
OBJECTS         = $(SOURCES:.c=.o)

CFLAGS			+= -Os


all: $(NAME).elf

$(NAME).elf: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@ 

%.o : %.c
	$(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@

clean:
	rm -f *.o *.elf *.ihex pmem.* output/*.o

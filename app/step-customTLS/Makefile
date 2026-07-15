include ../Makefile.include

NAME            = step-customTLS
SOURCES         = $(shell ls *.c) ../customTLS/bigint.c
OBJECTS         = $(SOURCES:.c=.o)

CFLAGS			+= -Os
LDFLAGS 		+= --dumb-memory-stub --ipe-step --nb-step 15

all: $(NAME).elf

$(NAME).elf: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@ 

%.o : %.c
	$(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@

clean:
	rm -f *.o *.elf *.ihex pmem.* output/*.o

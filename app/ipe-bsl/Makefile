include ../Makefile.include

NAME            = ipe-bsl
SOURCES         = $(shell ls *.c)
OBJECTS         = $(SOURCES:.c=.o)

CFLAGS			+= -fomit-frame-pointer

all: $(NAME).elf

$(NAME).elf: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@ 

%.o : %.c
	$(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@

clean:
	rm -f *.o *.elf *.ihex pmem.* output/*.o

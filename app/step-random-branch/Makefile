include ../Makefile.include

NAME            = step-random-branch
SOURCES         = $(shell ls *.c)
OBJECTS         = $(SOURCES:.c=.o)

CFLAGS			+= -fomit-frame-pointer
LDFLAGS			+= --ipe-step --init-latency 0x27 --nb-step 873

all: $(NAME).elf

$(NAME).elf: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@ 

%.o : %.c
	$(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@

clean:
	rm -f *.o *.elf *.ihex pmem.* output/*.o

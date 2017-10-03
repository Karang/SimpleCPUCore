AS_ARM = arm-linux-gnueabi-as
LD_ARM = arm-linux-gnueabi-ld
OBJ_DUMP_ARM = arm-linux-gnueabi-objdump
CC = /usr/bin/arm-linux-gnu-gcc
CFLAGS = -march=armv2a -mno-thumb-interwork -Wall
LD_FLAGS = -Bstatic -fix-v4bx

all: strlen pgcd test leds.hex

pgcd: pgcd.o
	${LD_ARM} ${LD_FLAGS} -T sections.lds -o pgcd pgcd.o

pgcd.o: pgcd.s
	${AS_ARM} -c pgcd.s -o pgcd.o
	
leds: leds.o
	${LD_ARM} ${LD_FLAGS} -T sections.lds -o leds leds.o
	
leds.o: leds.s
	${AS_ARM} -c leds.s -o leds.o
	
leds.hex: leds
	arm-linux-gnueabi-objcopy -O ihex leds leds.hex 

strlen: strlen.o start.o
	${LD_ARM} ${LD_FLAGS} -T sections.lds -o strlen strlen.o start.o

pgcd.hex: pgcd.o
	$(OBJ_DUMP_ARM) -d -S pgcd.o > pgcd.hex

strlen.hex: strlen
	$(OBJ_DUMP_ARM) -d -S strlen > strlen.hex

strlen.o: strlen.c
	${CC} ${CFLAGS} -g -c strlen.c -o strlen.o

start.o: start.s
	${AS_ARM} -c start.s -o start.o

test.o: test.c
	${CC} ${CFLAGS} -g -c test.c -o test.o

test: test.o start.o
	${LD_ARM} ${LD_FLAGS} -T sections.lds -o test test.o start.o

test.hex: test
	$(OBJ_DUMP_ARM) -d -S test > test.hex
	
mtrans.o: mtrans.s
	${AS_ARM} -c mtrans.s -o mtrans.o

mtrans: mtrans.o
	${LD_ARM} ${LD_FLAGS} -T sections.lds -o mtrans mtrans.o
	
mtrans.hex: mtrans
	$(OBJ_DUMP_ARM) -d -S mtrans > mtrans.hex

clean:
	rm -f pgcd strlen *.o strlen.hex pgcd.hex mtrans.hex mtrans

SOURCES := $(shell find $(SOURCEDIR) -name '*.asm')
LIBS := 

game: game.o
	gcc -static game.o -o game.out
	
game.o: $(SOURCES)
	nasm -f elf64 -l game.lst -o game.o src/main.asm
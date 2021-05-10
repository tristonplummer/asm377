game: game.o
	gcc -static game.o -lpthread -o game.out

game.o:
	nasm -f elf64 -l game.lst -g -o game.o src/main.asm

clean:
	rm *.o

game: game.o
	gcc -static game.o -o game.out
	
game.o:
	nasm -f elf64 -l game.lst -o game.o src/main.asm
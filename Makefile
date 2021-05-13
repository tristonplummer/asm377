LIBS := -lpthread -lssl -lcrypto

game: game.o
	gcc game.o $(LIBS) -no-pie -o game

game.o:
	nasm -f elf64 -l game.lst -g -o game.o src/main.asm

clean:
	rm *.o

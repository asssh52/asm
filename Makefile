
start: printf.o
	ld printf.o -o main

printf.o: printf.s
	nasm -f elf64 printf.s

clean:
	rm a.out *.o

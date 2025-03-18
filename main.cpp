#include <stdio.h>
#include <stdlib.h>

extern "C" int meowprint(char* str, ...);

int main(){
    char * meow = "meowmeow\n";
    //meowprint(0, "meow", 0, 2, 3, 4, 5, 6, 7, 8, 9);
    meowprint("meow\n%d\n %h \n%c\n, %s 52 52 52\n %b %o %o\n", 0, 256, 100, meow, 5, 16, 24, 8, 9);

    return 0;
}

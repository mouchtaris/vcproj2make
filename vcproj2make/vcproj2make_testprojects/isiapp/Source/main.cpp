#include <stdio.h>
#include "isi/f.h"
#include "isi/g.h"

#define CSTR(SOMETHING) ""#SOMETHING

int main(int argc, char *argv[]) {

    const int finp = 5;
    const int ginp = 5;
    printf("Hello. This is a test project. I hope"
            " it works.\n\n\n"
            "Albus Dumbledore Productions\n1286\nVERSION: " ISIAPP_VERSION "\n\n\n"
            "isidll\n"
            "------\n"
            "f(x) = x + %d\n"
            "    f(%d) = %d + %d    <=>\n"
            "    f(%d) = %d\n"
            "\n"
            "\n"
            "isistatic\n"
            "---------\n"
            "g(x) = f(x) * %d      <=>\n"
            "g(x) = (x + %d) * %d   <=>\n"
            "g(x) = %dx + %d\n"
            "    g(%d) = %d*%d + %d    <=>\n"
            "    g(%d) = %d   + %d    <=>\n"
            "    g(%d) = %d\n"
            "\n"
            "\n",
            // f(x)
            isi::fadj(), finp, finp, isi::fadj(), finp, isi::f(5),
            // g(x)
            isi::gmul(),
            isi::fadj(), isi::gmul(),
            isi::gmul(), isi::fadj() * isi::gmul(),
            ginp, isi::gmul(), ginp, isi::fadj() * isi::gmul(),
            ginp, isi::gmul() * ginp, isi::fadj() * isi::gmul(),
            ginp, isi::g(ginp)
    );

    return 0;
}
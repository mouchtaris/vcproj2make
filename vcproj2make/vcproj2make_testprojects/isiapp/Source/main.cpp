#include <stdio.h>
#include "isi/f.h"
#include "isi/g.h"

int main(int argc, char *argv[]) {

    printf("Hello. This is a test project. I hope"
            " it works.\n\n\n"
            "isidll\n"
            "------\n"
            "f(x) = x + 2\n"
            "    f(5) = %d + 2    <=>\n"
            "    f(5) = %d\n"
            "\n"
            "\n"
            "isistatic\n"
            "---------\n"
            "g(x) = f(x) * 2      <=>\n"
            "g(x) = (x + 2) * 2   <=>\n"
            "g(x) = 2x + 4\n"
            "    g(5) = 2*%d + 4    <=>\n"
            "    g(5) = %d   + 4    <=>\n"
            "    g(5) = %d\n"
            "\n"
            "\n",
            5, isi::f(5),
            5, 2*5, isi::g(5)
    );

    return 0;
}
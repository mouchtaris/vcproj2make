#include <stdio.h>
//
#include "isi/f.h"
#include "isi/g.h"
#include "main3.h"
#include "main4.h"
//
#include "isi/lambda.h"
//
#include <fstream>
#include <iostream>
//
#include <assert.h>
#include <list>
#include <algorithm>
//
#define RUN_MAIN 4

#define CSTR(SOMETHING) ""#SOMETHING
#define IASSERT(EXPR)   assert(EXPR)
struct arrlenvalidator {
    template <typename T, const size_t N>
    size_t operator()(size_t const length_to_test, T (&carr)[N]) const throw() {
        IASSERT( length_to_test == N );
        IASSERT( sizeof(carr)/sizeof(carr[0]) == N );
        return N;
    }
};
#define _ARRLENV(CARR)                            \
   arrlenvalidator()(                           \
                sizeof(CARR)/sizeof(CARR[0]),   \
                CARR)
#define _ARRLEN(CARR) (sizeof(CARR)/sizeof(CARR[0]))
#define ARRLEN(CARR) _ARRLENV(CARR)


class B;
class A {
public:
	A(void) {}
	//A(B const&){puts("A(B&)");}
};
class B {
public:
	operator A (void) const throw () { puts("B::A()"); return A(); }
};
static int main2 (int argc, char *argv[]) {
	(void) argc;
	(void) argv;
	A::A(B::B());
	A a; B b;
	a = (A)b;
	a = A(b);
	static_cast<A>(b);
	return 0;
}

struct vuf_t {
    char d[262144]; // 512KiB
    std::streamsize read;
};
struct vuf_printer {
    void operator ()(vuf_t const& vuf) const throw() {
        for (std::streamsize i = 0; i < vuf.read; ++i) {
            const char c = vuf.d[i];
            printf("%c(%0#x), ", c, c);
        }
    }
};
static int main1(int argc, char *argv[]) throw() {
    if (argc > 1) {
        std::ifstream fin(argv[1], std::ios::in|std::ios::binary);
        if (fin) {
            std::list<vuf_t> vufs;
            while (fin) {
                vufs.push_back(vuf_t());
                vuf_t& vuf = vufs.back();
                fin.read(vuf.d, ARRLEN(vuf.d));
                vuf.read = fin.gcount();
            }
            fin.close();
            std::for_each(vufs.begin(), vufs.end(), vuf_printer());
        }
        else
            std::cerr << "Could not open file " <<
                        argv[1] << " for reading" <<
                        std::endl;
    }
    else {
        std::cerr << "Not enough arguments. Required input "
                    "file name." << std::endl;
        for (int i = 0; i < argc; ++i)
            std::cerr << "arg" << i << ": " << argv[i] <<
                        std::endl;
    }
    return 0;
}

static int main0(int argc, char *argv[]) throw() {
    (void) argc;
    (void) argv;

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

int main(int argc, char* argv[]) {
    static int (*mains[])(int, char*[]) = {main0, main1, main2, main3, main4};
    return (*mains[RUN_MAIN])(argc, argv);
}
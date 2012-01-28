#include "isi/g.h"
//
#include "isi/f.h"

namespace isi {

    int g(int x) throw() {
        return f(x) * ISISTATIC_G_MUL;
    }

    int gmul(void) throw() {
        return ISISTATIC_G_MUL;
    }
} // namespace isi

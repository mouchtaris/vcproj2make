#include "isi/f.h"

namespace isi {

    int f(int x) throw() {
        return x + ISIDLL_F_ADJ;
    }

    int fadj(void) throw() {
        return ISIDLL_F_ADJ;
    }

} // namespace isi
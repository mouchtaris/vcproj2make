#include "isi/g.h"
//
#include "isi/f.h"

namespace isi {

    int g(int x) throw() {
        return f(x) * 2;
    }

} // namespace isi

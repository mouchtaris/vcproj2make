#include "isi/dll.h"

namespace isi {

    // f(x) = x + ISIDLL_F_ADJ
    ISI_FUNC int f(int) throw();
    ISI_FUNC int fadj(void) throw();

} // namespace isi
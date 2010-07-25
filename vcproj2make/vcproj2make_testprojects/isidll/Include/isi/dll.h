#ifndef __ISI__DLL__H__
#define __ISI__DLL__H__

#ifdef _MSC_VER
#   ifdef ISIDLL_VS_EXPORTS
#       define ISI_API  __declspec(dllexport)
#   else
#       define ISI_API  __declspec(dllimport)
#   endif
#else
#   define ISI_API
#endif

#define ISI_CLASS   class       ISI_API
#define ISI_STRUCT  struct      ISI_API
#define ISI_FUNC    extern      ISI_API
#define ISI_CFUNC   extern  "C" ISI_API
#define ISI_VAR     extern      ISI_API

#endif // __ISI__DLL__H__

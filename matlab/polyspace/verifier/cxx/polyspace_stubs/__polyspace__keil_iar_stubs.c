/* Copyright 1999-2024 The MathWorks, Inc. */

#if (defined(__PST_KEIL_COMPILER__) && !defined(__PST_NO_KEIL_STUBS__))

#define PST_STUB_KEIL_DEF(ret, func, args) ret func args

#define PST_STUB_C_DEF(func_return,func_name,func_args) func_return func_name func_args


/* Optimized stubs for the standard Keil library */

#if defined(__polyspace_xmalloc) && !defined(__polyspace_no_xmalloc)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_xmalloc)
#pragma POLYSPACE_INLINE_CHECKS "xmalloc"
#endif /* !NO_CHECKS_INLINING */
#undef xmalloc
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(xmalloc, 1)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_1
#define RETURN(x) RETURN_CUSTOM_TYPE(xmalloc, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_1
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, void*, xmalloc, unsigned long, size, NO_VARARGS, )
{
        RETURN(malloc(size));
}
PST_STUB_C_DEF_END
#define __polyspace_no_xmalloc
#endif


#if defined(__polyspace_xrealloc) && !defined(__polyspace_no_xrealloc)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_xrealloc)
#pragma POLYSPACE_INLINE_CHECKS "xrealloc"
#endif /* !NO_CHECKS_INLINING */
#undef xrealloc
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(xrealloc, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(xrealloc, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, void*, xrealloc, void*, p, unsigned long, size, NO_VARARGS, )
{
        RETURN(realloc(p, size));
}
PST_STUB_C_DEF_END
#define __polyspace_no_xrealloc
#endif


#if defined(__polyspace_xcalloc) && !defined(__polyspace_no_xcalloc)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_xcalloc)
#pragma POLYSPACE_INLINE_CHECKS "xcalloc"
#endif /* !NO_CHECKS_INLINING */
#undef xcalloc
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(xcalloc, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(xcalloc, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, void*, xcalloc, unsigned long, size, unsigned long, len, NO_VARARGS, )
{
        RETURN(xcalloc(size, len));
}
PST_STUB_C_DEF_END
#define __polyspace_no_xcalloc
#endif


#if defined(__polyspace_xfree) && !defined(__polyspace_no_xfree)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_xfree)
#pragma POLYSPACE_INLINE_CHECKS "xfree"
#endif /* !NO_CHECKS_INLINING */
#undef xfree
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(xfree, 1)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_1
#define RETURN(x) RETURN_CUSTOM_TYPE(xfree, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_1
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, void, xfree, void*, p, NO_VARARGS, )
{
        free(p);
}
PST_STUB_C_DEF_END
#define __polyspace_no_xfree
#endif


//fmemcmp
#if defined(__polyspace_fmemcmp) && !defined(__polyspace_no_fmemcmp)
#if defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fmemcmp)
#pragma POLYSPACE_INLINE_CHECKS "fmemcmp"
#endif /* !NO_CHECKS_INLINING */
#undef fmemcmp
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fmemcmp, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(fmemcmp, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_C_DEF, int, fmemcmp,  void *, s1, void *, s2, unsigned int, n, NO_VARARGS, __PST_THROW) {
    RETURN(memcmp(s1, s2, n));
}
PST_STUB_C_DEF_END
#pragma POLYSPACE_POLYMORPHIC "fmemcmp"
#endif
#define __polyspace_no_fmemcmp
#endif /* __polyspace_fmemcmp */


//hmemcmp
#if defined(__polyspace_hmemcmp) && !defined(__polyspace_no_hmemcmp)
#if defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_hmemcmp)
#pragma POLYSPACE_INLINE_CHECKS "hmemcmp"
#endif /* !NO_CHECKS_INLINING */
#undef hmemcmp
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(hmemcmp, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(hmemcmp, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_C_DEF, int, hmemcmp,  void *, s1, void *, s2, unsigned int, n, NO_VARARGS, __PST_THROW) {
    RETURN(memcmp(s1, s2, n));
}
PST_STUB_C_DEF_END
#pragma POLYSPACE_POLYMORPHIC "hmemcmp"
#endif
#define __polyspace_no_hmemcmp
#endif /* __polyspace_hmemcmp */


//xmemcmp
#if defined(__polyspace_xmemcmp) && !defined(__polyspace_no_xmemcmp)
#if defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_xmemcmp)
#pragma POLYSPACE_INLINE_CHECKS "xmemcmp"
#endif /* !NO_CHECKS_INLINING */
#undef xmemcmp
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(xmemcmp, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(xmemcmp, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_C_DEF, int, xmemcmp,  void *, s1, void *, s2, unsigned long, n, NO_VARARGS, __PST_THROW) {
    RETURN(memcmp(s1, s2, (unsigned int)n));
}
PST_STUB_C_DEF_END
#pragma POLYSPACE_POLYMORPHIC "xmemcmp"
#endif
#define __polyspace_no_xmemcmp
#endif /* __polyspace_xmemcmp */


#if ((defined(__polyspace_fmemcpy) && !defined(__polyspace_no_fmemcpy)) || \
     (defined(__polyspace_fmemmove) && !defined(__polyspace_no_fmemmove)))
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fmemcpy)
#pragma POLYSPACE_INLINE_CHECKS "fmemcpy"
#endif /* !NO_CHECKS_INLINING */
#undef fmemcpy
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fmemcpy, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(fmemcpy, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, void*, fmemcpy, void*, s1, void*, s2, unsigned int, n, NO_VARARGS, ) {
  RETURN(memcpy(s1, s2, n));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fmemcpy
#endif


#if defined(__polyspace_hmemcpy) && !defined(__polyspace_no_hmemcpy)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_hmemcpy)
#pragma POLYSPACE_INLINE_CHECKS "hmemcpy"
#endif /* !NO_CHECKS_INLINING */
#undef hmemcpy
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(hmemcpy, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(hmemcpy, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, void*, hmemcpy, void*, s1, void*, s2, unsigned int, n, NO_VARARGS, ) {
  RETURN(memcpy(s1, s2, n));
}
PST_STUB_C_DEF_END
#define __polyspace_no_hmemcpy
#endif


#if defined(__polyspace_xmemcpy) && !defined(__polyspace_no_xmemcpy)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_xmemcpy)
#pragma POLYSPACE_INLINE_CHECKS "xmemcpy"
#endif /* !NO_CHECKS_INLINING */
#undef xmemcpy
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(xmemcpy, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(xmemcpy, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, void*, xmemcpy, void*, s1, void*, s2, unsigned long, n, NO_VARARGS, ) {
  RETURN(memcpy(s1, s2, n));
}
PST_STUB_C_DEF_END
#define __polyspace_no_xmemcpy
#endif


#if defined(__polyspace_fstrcpy) && !defined(__polyspace_no_fstrcpy)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fstrcpy)
#pragma POLYSPACE_INLINE_CHECKS "fstrcpy"
#endif /* !NO_CHECKS_INLINING */
#undef fstrcpy
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fstrcpy, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(fstrcpy, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, signed char*, fstrcpy, signed char*, s1, signed char*, s2, NO_VARARGS, ) {
  RETURN(strcpy(s1, s2));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fstrcpy
#endif


#if defined(__polyspace_hstrcpy) && !defined(__polyspace_no_hstrcpy)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_hstrcpy)
#pragma POLYSPACE_INLINE_CHECKS "hstrcpy"
#endif /* !NO_CHECKS_INLINING */
#undef hstrcpy
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(hstrcpy, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(hstrcpy, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, signed char*, hstrcpy, signed char*, s1, signed char, *s2, NO_VARARGS, ) {
  RETURN(strcpy(s1, s2));
}
PST_STUB_C_DEF_END
#define __polyspace_no_hstrcpy
#endif


#if defined(__polyspace_xstrcpy) && !defined(__polyspace_no_xstrcpy)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_xstrcpy)
#pragma POLYSPACE_INLINE_CHECKS "xstrcpy"
#endif /* !NO_CHECKS_INLINING */
#undef xstrcpy
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(xstrcpy, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(xstrcpy, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, signed char*, xstrcpy, signed char*, s1, signed char*, s2, NO_VARARGS, ) {
  RETURN(strcpy(s1, s2));
}
PST_STUB_C_DEF_END
#define __polyspace_no_xstrcpy
#endif


#if defined(__polyspace_fstrcmp) && !defined(__polyspace_no_fstrcmp)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fstrcmp)
#pragma POLYSPACE_INLINE_CHECKS "fstrcmp"
#endif /* !NO_CHECKS_INLINING */
#undef fstrcmp
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fstrcmp, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(fstrcmp, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, int, fstrcmp, signed char*, s1, signed char*, s2, NO_VARARGS, ) {
  RETURN(strcmp(s1, s2));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fstrcmp
#endif


#if defined(__polyspace_hstrcmp) && !defined(__polyspace_no_hstrcmp)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_hstrcmp)
#pragma POLYSPACE_INLINE_CHECKS "hstrcmp"
#endif /* !NO_CHECKS_INLINING */
#undef hstrcmp
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(hstrcmp, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(hstrcmp, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, int, hstrcmp, signed char*, s1, signed char*, s2, NO_VARARGS, ) {
  RETURN(strcmp(s1, s2));
}
PST_STUB_C_DEF_END
#define __polyspace_no_hstrcmp
#endif


#if defined(__polyspace_xstrcmp) && !defined(__polyspace_no_xstrcmp)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_xstrcmp)
#pragma POLYSPACE_INLINE_CHECKS "xstrcmp"
#endif /* !NO_CHECKS_INLINING */
#undef xstrcmp
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(xstrcmp, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(xstrcmp, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, int, xstrcmp, signed char*, s1, signed char*, s2, NO_VARARGS, ) {
  RETURN(strcmp(s1, s2));
}
PST_STUB_C_DEF_END
#define __polyspace_no_xstrcmp
#endif


#if defined(__polyspace_fstrlen) && !defined(__polyspace_no_fstrlen)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fstrlen)
#pragma POLYSPACE_INLINE_CHECKS "fstrlen"
#endif /* !NO_CHECKS_INLINING */
#undef fstrlen
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fstrlen, 1)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_1
#define RETURN(x) RETURN_CUSTOM_TYPE(fstrlen, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_1
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, size_t, fstrlen, signed char*, s, NO_VARARGS, ) {
  RETURN(strlen(s));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fstrlen
#endif


#if defined(__polyspace_fmemset) && !defined(__polyspace_no_fmemset)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fmemset)
#pragma POLYSPACE_INLINE_CHECKS "fmemset"
#endif /* !NO_CHECKS_INLINING */
#undef fmemset
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fmemset, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(fmemset, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, void*, fmemset, void*, s, signed char, c, unsigned int, n, NO_VARARGS, ) {
  RETURN(memset(s, c, n));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fmemset
#endif


#if defined(__polyspace_xmemset) && !defined(__polyspace_no_xmemset)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_xmemset)
#pragma POLYSPACE_INLINE_CHECKS "xmemset"
#endif /* !NO_CHECKS_INLINING */
#undef xmemset
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(xmemset, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(xmemset, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, void*, xmemset, void*, s, signed char, c, unsigned long, n, NO_VARARGS, ) {
  RETURN(memset(s, c, n));
}
PST_STUB_C_DEF_END
#define __polyspace_no_xmemset
#endif


#if defined(__polyspace_fmemmove) && !defined(__polyspace_no_fmemmove)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fmemmove)
#pragma POLYSPACE_INLINE_CHECKS "fmemmove"
#endif /* !NO_CHECKS_INLINING */
#undef fmemmove
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fmemmove, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(fmemmove, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, void*, fmemmove, void*, s1, void*, s2, unsigned int, n, NO_VARARGS, ) {
  RETURN(memmove(s1, s2, n));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fmemmove
#endif


#if defined(__polyspace_xmemmove) && !defined(__polyspace_no_xmemmove)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_xmemmove)
#pragma POLYSPACE_INLINE_CHECKS "xmemmove"
#endif /* !NO_CHECKS_INLINING */
#undef xmemmove
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(xmemmove, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(xmemmove, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, void*, xmemmove, void*, s1, void*, s2, unsigned long, n, NO_VARARGS, ) {
  RETURN(memmove(s1, s2, n));
}
PST_STUB_C_DEF_END
#define __polyspace_no_xmemmove
#endif


#if defined(__polyspace_fstrncpy) && !defined(__polyspace_no_fstrncpy)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fstrncpy)
#pragma POLYSPACE_INLINE_CHECKS "fstrncpy"
#endif /* !NO_CHECKS_INLINING */
#undef fstrncpy
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fstrncpy, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(fstrncpy, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, signed char*, fstrncpy, signed char*, s1, signed char*, s2, unsigned int, n, NO_VARARGS, ) {
  RETURN(strncpy(s1, s2, n));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fstrncpy
#endif


#if defined(__polyspace_fstrcat) && !defined(__polyspace_no_fstrcat)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fstrcat)
#pragma POLYSPACE_INLINE_CHECKS "fstrcat"
#endif /* !NO_CHECKS_INLINING */
#undef fstrcat
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fstrcat, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(fstrcat, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, signed char*, fstrcat, signed char*, s1, signed char*, s2, NO_VARARGS, ) {
  RETURN(strcat(s1, s2));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fstrcat
#endif


#if defined(__polyspace_fstrncat) && !defined(__polyspace_no_fstrncat)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fstrncat)
#pragma POLYSPACE_INLINE_CHECKS "fstrncat"
#endif /* !NO_CHECKS_INLINING */
#undef fstrncat
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fstrncat, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(fstrncat, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, signed char*, fstrncat, signed char*, s1, signed char*, s2, unsigned int, n, NO_VARARGS, ) {
  RETURN(strncat(s1, s2, n));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fstrncat
#endif


#if defined(__polyspace_fstrncmp) && !defined(__polyspace_no_fstrncmp)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fstrncmp)
#pragma POLYSPACE_INLINE_CHECKS "fstrncmp"
#endif /* !NO_CHECKS_INLINING */
#undef fstrncmp
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fstrncmp, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(fstrncmp, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, int, fstrncmp, signed char*, s1, signed char*, s2, unsigned int, n, NO_VARARGS, ) {
  RETURN(strncmp(s1, s2, n));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fstrncmp
#endif


#if defined(__polyspace_fmemchr) && !defined(__polyspace_no_fmemchr)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fmemchr)
#pragma POLYSPACE_INLINE_CHECKS "fmemchr"
#endif /* !NO_CHECKS_INLINING */
#undef fmemchr
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fmemchr, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(fmemchr, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, void*, fmemchr, void*, s, signed int, c, unsigned int, n, NO_VARARGS, ) {
  RETURN(memchr(s, c, n));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fmemchr
#endif


#if defined(__polyspace_xmemchr) && !defined(__polyspace_no_xmemchr)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_xmemchr)
#pragma POLYSPACE_INLINE_CHECKS "xmemchr"
#endif /* !NO_CHECKS_INLINING */
#undef xmemchr
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(xmemchr, 3)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_3
#define RETURN(x) RETURN_CUSTOM_TYPE(xmemchr, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_3
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, void*, xmemchr, void*, s, signed int, c, unsigned long, n, NO_VARARGS, ) {
  RETURN(memchr(s, c, n));
}
PST_STUB_C_DEF_END
#define __polyspace_no_xmemchr
#endif


#if defined(__polyspace_fstrchr) && !defined(__polyspace_no_fstrchr)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fstrchr)
#pragma POLYSPACE_INLINE_CHECKS "fstrchr"
#endif /* !NO_CHECKS_INLINING */
#undef fstrchr
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fstrchr, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(fstrchr, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, signed char*, fstrchr, signed char*, s, signed char, c, NO_VARARGS, ) {
  RETURN(strchr(s, c));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fstrchr
#endif


//fstrcspn
#if defined(__polyspace_fstrcspn) && !defined(__polyspace_no_fstrcspn)
#if defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fstrcspn)
#pragma POLYSPACE_INLINE_CHECKS "fstrcspn"
#endif /* !NO_CHECKS_INLINING */
#undef fstrcspn
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fstrcspn, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(fstrcspn, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_C_DEF, int, fstrcspn, signed char *, s1, signed char *, s2, NO_VARARGS, __PST_THROW)
{
  RETURN(strcspn(s1, s2));
}
PST_STUB_C_DEF_END
#pragma POLYSPACE_POLYMORPHIC "fstrcspn"
#endif
#define __polyspace_no_fstrcspn
#endif /* __polyspace_fstrcspn */


#if defined(__polyspace_fstrpbrk) && !defined(__polyspace_no_fstrpbrk)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fstrpbrk)
#pragma POLYSPACE_INLINE_CHECKS "fstrpbrk"
#endif /* !NO_CHECKS_INLINING */
#undef fstrpbrk
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fstrpbrk, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(fstrpbrk, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, signed char*, fstrpbrk, signed char*, s1, signed char*, s2, NO_VARARGS, ) {
  RETURN(strpbrk(s1, s2));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fstrpbrk
#endif


#if defined(__polyspace_fstrrchr) && !defined(__polyspace_no_fstrrchr)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fstrrchr)
#pragma POLYSPACE_INLINE_CHECKS "fstrrchr"
#endif /* !NO_CHECKS_INLINING */
#undef fstrrchr
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fstrrchr, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(fstrrchr, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_KEIL_DEF, signed char*, fstrrchr, signed char*, s, signed char, c, NO_VARARGS, ) {
  RETURN(strrchr(s, c));
}
PST_STUB_C_DEF_END
#define __polyspace_no_fstrrchr
#endif


//fstrspn
#if defined(__polyspace_fstrspn) && !defined(__polyspace_no_fstrspn)
#if defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined_fstrspn)
#pragma POLYSPACE_INLINE_CHECKS "fstrspn"
#endif /* !NO_CHECKS_INLINING */
#undef fstrspn
#undef PST_STUB_C_DEF_BEGIN
#undef RETURN
#if CUSTOM_STUB_TYPE(fstrspn, 2)
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_CUSTOM_TYPE_2
#define RETURN(x) RETURN_CUSTOM_TYPE(fstrspn, x)
#else
#define PST_STUB_C_DEF_BEGIN PST_STUB_C_STD_TYPE_2
#define RETURN(x) return (x)
#endif
PST_STUB_C_DEF_BEGIN(PST_STUB_C_DEF, int, fstrspn, signed char *, s1, signed char *, s2, NO_VARARGS, __PST_THROW) {
  RETURN(strspn(s1, s2));
}
PST_STUB_C_DEF_END
#pragma POLYSPACE_POLYMORPHIC "fstrspn"
#endif
#define __polyspace_no_fstrspn
#endif /* __polyspace_fstrspn */


#endif /* defined(__PST_KEIL_COMPILER__) && !defined(__PST_NO_KEIL_STUBS__) */

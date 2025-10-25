/* Copyright 2017-2021 The MathWorks, Inc. */
/* Support for complex runtime */
#ifndef NO_POLYSPACE_COMPLEX
/* List of routines EDG uses to lower complex:
Command used:
grep \"__c99 matlab/polyspace/src/shared/cxx_front_end_kernel/edg/src/lower_c99.c | awk  -F  "\"" ' { print $2 }'  | sort -u
   __c99_cdouble_to_cfloat
   __c99_cdouble_to_clong_double
   __c99_cdouble_to_double
   __c99_cdouble_to_idouble
   __c99_cfloat_to_cdouble
   __c99_cfloat_to_clong_double
   __c99_cfloat_to_float
   __c99_cfloat_to_ifloat
   __c99_clong_double_to_cdouble
   __c99_clong_double_to_cfloat
   __c99_clong_double_to_ilong_double
   __c99_clong_double_to_long_double
   __c99_complex_double_add
   __c99_complex_double_conj
   __c99_complex_double_divide
   __c99_complex_double_eq
   __c99_complex_double_multiply
   __c99_complex_double_ne
   __c99_complex_double_negate
   __c99_complex_double_subtract
   __c99_complex_float_add
   __c99_complex_float_conj
   __c99_complex_float_divide
   __c99_complex_float_eq
   __c99_complex_float_multiply
   __c99_complex_float_ne
   __c99_complex_float_negate
   __c99_complex_float_subtract
   __c99_complex_long_double_add
   __c99_complex_long_double_conj
   __c99_complex_long_double_divide
   __c99_complex_long_double_eq
   __c99_complex_long_double_multiply
   __c99_complex_long_double_ne
   __c99_complex_long_double_negate
   __c99_complex_long_double_subtract
   __c99_double_to_cdouble
   __c99_float_to_cfloat
   __c99_idouble_to_cdouble
   __c99_ifloat_to_cfloat
   __c99_ilong_double_to_clong_double
   __c99_long_double_to_clong_double
*/
#if defined(__polyspace___c99_complex_double_add) || defined(__polyspace___c99_complex_double_conj) || defined(__polyspace___c99_complex_double_divide) || defined(__polyspace___c99_complex_double_eq) || defined(__polyspace___c99_complex_double_multiply) || defined(__polyspace___c99_complex_double_ne) || defined(__polyspace___c99_complex_double_negate) || defined(__polyspace___c99_complex_double_subtract) || defined(__polyspace___c99_cdouble_to_cfloat) || defined(__polyspace___c99_cdouble_to_clong_double) || defined(__polyspace___c99_cdouble_to_double) || defined(__polyspace___c99_cdouble_to_idouble) || defined(__polyspace___c99_cfloat_to_cdouble) || defined(__polyspace___c99_clong_double_to_cdouble) || defined(__polyspace___c99_double_to_cdouble) || defined(__polyspace___c99_idouble_to_cdouble)
struct _Complex_double { double _Vals[2]; };
#endif

#if defined(__polyspace___c99_complex_float_add) || defined(__polyspace___c99_complex_float_conj) || defined(__polyspace___c99_complex_float_divide) || defined(__polyspace___c99_complex_float_eq) || defined(__polyspace___c99_complex_float_multiply) || defined(__polyspace___c99_complex_float_ne) || defined(__polyspace___c99_complex_float_negate) || defined(__polyspace___c99_complex_float_subtract) || defined(__polyspace___c99_cdouble_to_cfloat) || defined(__polyspace___c99_cfloat_to_cdouble) || defined(__polyspace___c99_cfloat_to_clong_double) || defined(__polyspace___c99_cfloat_to_float) || defined(__polyspace___c99_cfloat_to_ifloat) || defined(__polyspace___c99_clong_double_to_cfloat) || defined(__polyspace___c99_float_to_cfloat) || defined(__polyspace___c99_ifloat_to_cfloat)
struct _Complex_float { float _Vals[2]; };
#endif

#if defined(__polyspace___c99_complex_long_double_add) || defined(__polyspace___c99_complex_long_double_conj) || defined(__polyspace___c99_complex_long_double_divide) || defined(__polyspace___c99_complex_long_double_eq) || defined(__polyspace___c99_complex_long_double_multiply) || defined(__polyspace___c99_complex_long_double_ne) || defined(__polyspace___c99_complex_long_double_negate) || defined(__polyspace___c99_complex_long_double_subtract) || defined(__polyspace___c99_cdouble_to_clong_double) || defined(__polyspace___c99_cfloat_to_clong_double) || defined(__polyspace___c99_clong_double_to_cdouble) || defined(__polyspace___c99_clong_double_to_cfloat) || defined(__polyspace___c99_clong_double_to_ilong_double) || defined(__polyspace___c99_clong_double_to_long_double) || defined(__polyspace___c99_ilong_double_to_clong_double) || defined(__polyspace___c99_long_double_to_clong_double)
struct _Complex_long_double { long double _Vals[2]; };
#endif

#if defined(__polyspace___c99_cdouble_to_double) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_cdouble_to_double)
#pragma POLYSPACE_INLINE_CHECKS "__c99_cdouble_to_double"
#endif /* !NO_CHECKS_INLINING */
double __c99_cdouble_to_double(struct _Complex_double c) {
  return c._Vals[0];
}
#endif /*  __polyspace___c99_cdouble_to_double */

#if defined(__polyspace_creal) && defined(__PST_POLYSPACE_MODE)
double creal(struct _Complex_double c) {
  return c._Vals[0];
}
#endif /*  __polyspace_creal */
#if defined(__polyspace_crealf) && defined(__PST_POLYSPACE_MODE)
float crealf(struct _Complex_float c) {
  return c._Vals[0];
}
#endif /*  __polyspace_crealf */
#if defined(__polyspace_creall) && defined(__PST_POLYSPACE_MODE)
long double creall(struct _Complex_long_double c) {
  return c._Vals[0];
}
#endif /*  __polyspace_creall */

#if defined(__polyspace_cimag) && defined(__PST_POLYSPACE_MODE)
double cimag(struct _Complex_double c) {
  return c._Vals[1];
}
#endif /*  __polyspace_cimag */
#if defined(__polyspace_cimagf) && defined(__PST_POLYSPACE_MODE)
float cimagf(struct _Complex_float c) {
  return c._Vals[1];
}
#endif /*  __polyspace_cimagf */
#if defined(__polyspace_cimagl) && defined(__PST_POLYSPACE_MODE)
long double cimagl(struct _Complex_long_double c) {
  return c._Vals[1];
}
#endif /*  __polyspace_cimagl */

#if defined(__polyspace___c99_clong_double_to_long_double) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_clong_double_to_long_double)
#pragma POLYSPACE_INLINE_CHECKS "__c99_clong_double_to_long_double"
#endif /* !NO_CHECKS_INLINING */
long double __c99_clong_double_to_long_double(struct _Complex_long_double c) {
  return c._Vals[0];
}
#endif /*  __polyspace___c99_clong_double_to_long_double */

#if defined(__polyspace___c99_cfloat_to_float) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_cfloat_to_float)
#pragma POLYSPACE_INLINE_CHECKS "__c99_cfloat_to_float"
#endif /* !NO_CHECKS_INLINING */
float __c99_cfloat_to_float(struct _Complex_float c) {
  return c._Vals[0];
}
#endif /*  __polyspace___c99_cfloat_to_float */

#if defined(__polyspace___c99_cdouble_to_idouble) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_cdouble_to_idouble)
#pragma POLYSPACE_INLINE_CHECKS "__c99_cdouble_to_idouble"
#endif /* !NO_CHECKS_INLINING */
double __c99_cdouble_to_idouble(struct _Complex_double c) {
  return c._Vals[1];
}
#endif /*  __polyspace___c99_cdouble_to_idouble */

#if defined(__polyspace___c99_clong_double_to_ilong_double) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_clong_double_to_ilong_double)
#pragma POLYSPACE_INLINE_CHECKS "__c99_clong_double_to_ilong_double"
#endif /* !NO_CHECKS_INLINING */
long double __c99_clong_double_to_ilong_double(struct _Complex_long_double c) {
  return c._Vals[1];
}
#endif /*  __polyspace___c99_clong_double_to_ilong_double */

#if defined(__polyspace___c99_cfloat_to_ifloat) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_cfloat_to_ifloat)
#pragma POLYSPACE_INLINE_CHECKS "__c99_cfloat_to_ifloat"
#endif /* !NO_CHECKS_INLINING */
float __c99_cfloat_to_ifloat(struct _Complex_float c) {
  return c._Vals[1];
}
#endif /*  __polyspace___c99_cfloat_to_ifloat */

#if defined(__polyspace___c99_cdouble_to_clong_double) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_cdouble_to_clong_double)
#pragma POLYSPACE_INLINE_CHECKS "__c99_cdouble_to_clong_double"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_long_double __c99_cdouble_to_clong_double(struct _Complex_double c) {
  struct _Complex_long_double cl;
  cl._Vals[0] = c._Vals[0];
  cl._Vals[1] = c._Vals[1];
  return cl;
}
#endif /*  __polyspace___c99_cdouble_to_clong_double */

#if defined(__polyspace___c99_cdouble_to_cfloat) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_cdouble_to_cfloat)
#pragma POLYSPACE_INLINE_CHECKS "__c99_cdouble_to_cfloat"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_float __c99_cdouble_to_cfloat(struct _Complex_double c) {
  struct _Complex_float cl;
  cl._Vals[0] = c._Vals[0];
  cl._Vals[1] = c._Vals[1];
  return cl;
}
#endif /*  __polyspace___c99_cdouble_to_cfloat */

#if defined(__polyspace___c99_clong_double_to_cfloat) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_clong_double_to_cfloat)
#pragma POLYSPACE_INLINE_CHECKS "__c99_clong_double_to_cfloat"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_float __c99_clong_double_to_cfloat(struct _Complex_long_double c) {
  struct _Complex_float cl;
  cl._Vals[0] = c._Vals[0];
  cl._Vals[1] = c._Vals[1];
  return cl;
}
#endif /*  __polyspace___c99_clong_double_to_cfloat */

#if defined(__polyspace___c99_clong_double_to_cdouble) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_clong_double_to_cdouble)
#pragma POLYSPACE_INLINE_CHECKS "__c99_clong_double_to_cdouble"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_double __c99_clong_double_to_cdouble(struct _Complex_long_double c) {
  struct _Complex_double cl;
  cl._Vals[0] = c._Vals[0];
  cl._Vals[1] = c._Vals[1];
  return cl;
}
#endif /*  __polyspace___c99_clong_double_to_cdouble */

#if defined(__polyspace___c99_cfloat_to_cdouble) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_cfloat_to_cdouble)
#pragma POLYSPACE_INLINE_CHECKS "__c99_cfloat_to_cdouble"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_double __c99_cfloat_to_cdouble(struct _Complex_float c) {
  struct _Complex_double cl;
  cl._Vals[0] = c._Vals[0];
  cl._Vals[1] = c._Vals[1];
  return cl;
}
#endif /*  __polyspace___c99_cfloat_to_cdouble */

#if defined(__polyspace___c99_cfloat_to_clong_double) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_cfloat_to_clong_double)
#pragma POLYSPACE_INLINE_CHECKS "__c99_cfloat_to_clong_double"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_long_double __c99_cfloat_to_clong_double(struct _Complex_float c) {
  struct _Complex_long_double cl;
  cl._Vals[0] = c._Vals[0];
  cl._Vals[1] = c._Vals[1];
  return cl;
}
#endif /*  __polyspace___c99_cfloat_to_clong_double */

#if defined(__polyspace___c99_complex_double_add) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_double_add)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_double_add"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_double __c99_complex_double_add(struct _Complex_double c1, struct _Complex_double c2) {
  struct _Complex_double cadd;
  cadd._Vals[0] = c1._Vals[0] + c2._Vals[0];
  cadd._Vals[1] = c1._Vals[1] + c2._Vals[1];
  return cadd;
}
#endif /*  __polyspace___c99_complex_double_add */

#if defined(__polyspace___c99_complex_double_divide) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_double_divide)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_double_divide"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_double __c99_complex_double_divide(struct _Complex_double c1, struct _Complex_double c2) {
  struct _Complex_double cdivide;
  double q = c2._Vals[0]*c2._Vals[0] + c2._Vals[1]*c2._Vals[1];
  /* divisor must not be null */
#pragma polyspace_value_info STD_LIB_value_type("VALUE") "second argument (divisor)"
#pragma Inspection_Point q
_Pragma("polyspace_value_info");
#pragma polyspace_check_info STD_LIB_type("PS_INTERNAL_FLOAT_STD_LIB") arg_green_orange_red_message("Complex division:divisor", "is not", "may be", "is", " equal to zero")
  ASSERT_IS_VALID_CONDITION(q != 0.0);
#pragma polyspace_check_info
  cdivide._Vals[0] = (c1._Vals[0]*c2._Vals[0] + c1._Vals[1]*c2._Vals[1])/q;
  cdivide._Vals[1] = (c1._Vals[1]*c2._Vals[0] - c1._Vals[0]*c2._Vals[1])/q;
  return cdivide;
}

#endif /*  __polyspace___c99_complex_double_divide */

#if defined(__polyspace___c99_complex_double_multiply) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_double_multiply)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_double_multiply"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_double __c99_complex_double_multiply(struct _Complex_double c1, struct _Complex_double c2) {
  struct _Complex_double cmultiply;
  cmultiply._Vals[0] = c1._Vals[0] * c2._Vals[0] - c1._Vals[1] * c2._Vals[1];
  cmultiply._Vals[1] = c1._Vals[0] * c2._Vals[1] + c1._Vals[1] * c2._Vals[0];
  return cmultiply;
}
#endif /*  __polyspace___c99_complex_double_multiply */

#if defined(__polyspace___c99_complex_double_subtract) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_double_subtract)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_double_subtract"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_double __c99_complex_double_subtract(struct _Complex_double c1, struct _Complex_double c2) {
  struct _Complex_double csubtract;
  csubtract._Vals[0] = c1._Vals[0] - c2._Vals[0];
  csubtract._Vals[1] = c1._Vals[1] - c2._Vals[1];
  return csubtract;
}
#endif /*  __polyspace___c99_complex_double_subtract */

#if defined(__polyspace___c99_complex_double_negate) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_double_negate)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_double_negate"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_double __c99_complex_double_negate(struct _Complex_double c1) {
  struct _Complex_double cnegate;
  cnegate._Vals[0] = -c1._Vals[0];
  cnegate._Vals[1] = -c1._Vals[1];
  return cnegate;
}
#endif /*  __polyspace___c99_complex_double_negate */

#if defined(__polyspace___c99_complex_double_conj) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_double_conj)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_double_conj"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_double __c99_complex_double_conj(struct _Complex_double c1) {
  struct _Complex_double cconj;
  cconj._Vals[0] = c1._Vals[0];
  cconj._Vals[1] = -c1._Vals[1];
  return cconj;
}
#endif /*  __polyspace___c99_complex_double_conj */

#if defined(__polyspace_conj) && defined(__PST_POLYSPACE_MODE)
struct _Complex_double conj(struct _Complex_double c1) {
  struct _Complex_double cconj;
  cconj._Vals[0] = c1._Vals[0];
  cconj._Vals[1] = -c1._Vals[1];
  return cconj;
}
#endif /*  __polyspace_conj */

#if defined(__polyspace___c99_complex_double_ne) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_double_ne)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_double_ne"
#endif /* !NO_CHECKS_INLINING */
int __c99_complex_double_ne(struct _Complex_double c1, struct _Complex_double c2) {
  return !(c1._Vals[0] == c2._Vals[0] && c1._Vals[1] == c2._Vals[1]);
}
#endif /*  __polyspace___c99_complex_double_eq */

#if defined(__polyspace___c99_complex_double_eq) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_double_eq)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_double_eq"
#endif /* !NO_CHECKS_INLINING */
int __c99_complex_double_eq(struct _Complex_double c1, struct _Complex_double c2) {
  return (c1._Vals[0] == c2._Vals[0] && c1._Vals[1] == c2._Vals[1]);
}
#endif /*  __polyspace___c99_complex_double_eq */

#if defined(__polyspace___c99_complex_long_double_add) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_long_double_add)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_long_double_add"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_long_double __c99_complex_long_double_add(struct _Complex_long_double c1, struct _Complex_long_double c2) {
  struct _Complex_long_double cadd;
  cadd._Vals[0] = c1._Vals[0] + c2._Vals[0];
  cadd._Vals[1] = c1._Vals[1] + c2._Vals[1];
  return cadd;
}
#endif /*  __polyspace___c99_complex_long_double_add */

#if defined(__polyspace___c99_complex_long_double_divide) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_long_double_divide)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_long_double_divide"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_long_double __c99_complex_long_double_divide(struct _Complex_long_double c1, struct _Complex_long_double c2) {
  struct _Complex_long_double cdivide;
  long double q = c2._Vals[0]*c2._Vals[0] + c2._Vals[1]*c2._Vals[1];
  /* divisor must not be null */
#pragma polyspace_value_info STD_LIB_value_type("VALUE") "second argument (divisor)"
#pragma Inspection_Point q
_Pragma("polyspace_value_info");
#pragma polyspace_check_info STD_LIB_type("PS_INTERNAL_FLOAT_STD_LIB") arg_green_orange_red_message("Complex division:divisor", "is not", "may be", "is", " equal to zero")
  ASSERT_IS_VALID_CONDITION(q != 0.0);
#pragma polyspace_check_info
  cdivide._Vals[0] = (c1._Vals[0]*c2._Vals[0] + c1._Vals[1]*c2._Vals[1])/q;
  cdivide._Vals[1] = (c1._Vals[1]*c2._Vals[0] - c1._Vals[0]*c2._Vals[1])/q;
  return cdivide;
}
#endif /*  __polyspace___c99_complex_long_double_divide */

#if defined(__polyspace___c99_complex_long_double_multiply) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_long_double_multiply)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_long_double_multiply"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_long_double __c99_complex_long_double_multiply(struct _Complex_long_double c1, struct _Complex_long_double c2) {
  struct _Complex_long_double cmultiply;
  cmultiply._Vals[0] = c1._Vals[0] * c2._Vals[0] - c1._Vals[1] * c2._Vals[1];
  cmultiply._Vals[1] = c1._Vals[0] * c2._Vals[1] + c1._Vals[1] * c2._Vals[0];
  return cmultiply;
}
#endif /*  __polyspace___c99_complex_long_double_multiply */

#if defined(__polyspace___c99_complex_long_double_subtract) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_long_double_subtract)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_long_double_subtract"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_long_double __c99_complex_long_double_subtract(struct _Complex_long_double c1, struct _Complex_long_double c2) {
  struct _Complex_long_double csubtract;
  csubtract._Vals[0] = c1._Vals[0] - c2._Vals[0];
  csubtract._Vals[1] = c1._Vals[1] - c2._Vals[1];
  return csubtract;
}
#endif /*  __polyspace___c99_complex_long_double_subtract */

#if defined(__polyspace___c99_complex_long_double_negate) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_long_double_negate)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_long_double_negate"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_long_double __c99_complex_long_double_negate(struct _Complex_long_double c1) {
  struct _Complex_long_double cnegate;
  cnegate._Vals[0] = -c1._Vals[0];
  cnegate._Vals[1] = -c1._Vals[1];
  return cnegate;
}
#endif /*  __polyspace___c99_complex_long_double_negate */

#if defined(__polyspace___c99_complex_long_double_conj) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_long_double_conj)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_long_double_conj"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_long_double __c99_complex_long_double_conj(struct _Complex_long_double c1) {
  struct _Complex_long_double cconj;
  cconj._Vals[0] = c1._Vals[0];
  cconj._Vals[1] = -c1._Vals[1];
  return cconj;
}
#endif /*  __polyspace___c99_complex_long_double_conj */

#if defined(__polyspace_conjl) && defined(__PST_POLYSPACE_MODE)
struct _Complex_long_double conjl(struct _Complex_long_double c1) {
  struct _Complex_long_double cconj;
  cconj._Vals[0] = c1._Vals[0];
  cconj._Vals[1] = -c1._Vals[1];
  return cconj;
}
#endif /*  __polyspace_conjl */

#if defined(__polyspace___c99_complex_long_double_ne) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_long_double_ne)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_long_double_ne"
#endif /* !NO_CHECKS_INLINING */
int __c99_complex_long_double_ne(struct _Complex_long_double c1, struct _Complex_long_double c2) {
  return !(c1._Vals[0] == c2._Vals[0] && c1._Vals[1] == c2._Vals[1]);
}
#endif /*  __polyspace___c99_complex_long_double_eq */

#if defined(__polyspace___c99_complex_long_double_eq) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_long_double_eq)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_long_double_eq"
#endif /* !NO_CHECKS_INLINING */
int __c99_complex_long_double_eq(struct _Complex_long_double c1, struct _Complex_long_double c2) {
  return (c1._Vals[0] == c2._Vals[0] && c1._Vals[1] == c2._Vals[1]);
}
#endif /*  __polyspace___c99_complex_long_double_eq */

#if defined(__polyspace___c99_complex_float_add) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_float_add)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_float_add"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_float __c99_complex_float_add(struct _Complex_float c1, struct _Complex_float c2) {
  struct _Complex_float cadd;
  cadd._Vals[0] = c1._Vals[0] + c2._Vals[0];
  cadd._Vals[1] = c1._Vals[1] + c2._Vals[1];
  return cadd;
}
#endif /*  __polyspace___c99_complex_float_add */

#if defined(__polyspace___c99_complex_float_divide) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_float_divide)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_float_divide"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_float __c99_complex_float_divide(struct _Complex_float c1, struct _Complex_float c2) {
  struct _Complex_float cdivide;
  float q = c2._Vals[0]*c2._Vals[0] + c2._Vals[1]*c2._Vals[1];
  /* divisor must not be null */
#pragma polyspace_value_info STD_LIB_value_type("VALUE") "second argument (divisor)"
#pragma Inspection_Point q
_Pragma("polyspace_value_info");
#pragma polyspace_check_info STD_LIB_type("PS_INTERNAL_FLOAT_STD_LIB") arg_green_orange_red_message("Complex division:divisor", "is not", "may be", "is", " equal to zero")
  ASSERT_IS_VALID_CONDITION(q != 0.0);
#pragma polyspace_check_info
  cdivide._Vals[0] = (c1._Vals[0]*c2._Vals[0] + c1._Vals[1]*c2._Vals[1])/q;
  cdivide._Vals[1] = (c1._Vals[1]*c2._Vals[0] - c1._Vals[0]*c2._Vals[1])/q;
  return cdivide;
}
#endif /*  __polyspace___c99_complex_float_divide */

#if defined(__polyspace___c99_complex_float_multiply) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_float_multiply)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_float_multiply"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_float __c99_complex_float_multiply(struct _Complex_float c1, struct _Complex_float c2) {
  struct _Complex_float cmultiply;
  cmultiply._Vals[0] = c1._Vals[0] * c2._Vals[0] - c1._Vals[1] * c2._Vals[1];
  cmultiply._Vals[1] = c1._Vals[0] * c2._Vals[1] + c1._Vals[1] * c2._Vals[0];
  return cmultiply;
}
#endif /*  __polyspace___c99_complex_float_multiply */

#if defined(__polyspace___c99_complex_float_subtract) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_float_subtract)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_float_subtract"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_float __c99_complex_float_subtract(struct _Complex_float c1, struct _Complex_float c2) {
  struct _Complex_float csubtract;
  csubtract._Vals[0] = c1._Vals[0] - c2._Vals[0];
  csubtract._Vals[1] = c1._Vals[1] - c2._Vals[1];
  return csubtract;
}
#endif /*  __polyspace___c99_complex_float_subtract */

#if defined(__polyspace___c99_complex_float_negate) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_float_negate)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_float_negate"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_float __c99_complex_float_negate(struct _Complex_float c1) {
  struct _Complex_float cnegate;
  cnegate._Vals[0] = -c1._Vals[0];
  cnegate._Vals[1] = -c1._Vals[1];
  return cnegate;
}
#endif /*  __polyspace___c99_complex_float_negate */

#if defined(__polyspace___c99_complex_float_conj) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_float_conj)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_float_conj"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_float __c99_complex_float_conj(struct _Complex_float c1) {
  struct _Complex_float cconj;
  cconj._Vals[0] = c1._Vals[0];
  cconj._Vals[1] = -c1._Vals[1];
  return cconj;
}
#endif /*  __polyspace___c99_complex_float_conj */

#if defined(__polyspace_conjf) && defined(__PST_POLYSPACE_MODE)
struct _Complex_float conjf(struct _Complex_float c1) {
  struct _Complex_float cconj;
  cconj._Vals[0] = c1._Vals[0];
  cconj._Vals[1] = -c1._Vals[1];
  return cconj;
}
#endif /*  __polyspace_conjf */

#if defined(__polyspace___c99_complex_float_ne) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_float_ne)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_float_ne"
#endif /* !NO_CHECKS_INLINING */
int __c99_complex_float_ne(struct _Complex_float c1, struct _Complex_float c2) {
  return !(c1._Vals[0] == c2._Vals[0] && c1._Vals[1] == c2._Vals[1]);
}
#endif /*  __polyspace___c99_complex_float_eq */

#if defined(__polyspace___c99_complex_float_eq) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_complex_float_eq)
#pragma POLYSPACE_INLINE_CHECKS "__c99_complex_float_eq"
#endif /* !NO_CHECKS_INLINING */
int __c99_complex_float_eq(struct _Complex_float c1, struct _Complex_float c2) {
  return (c1._Vals[0] == c2._Vals[0] && c1._Vals[1] == c2._Vals[1]);
}
#endif /*  __polyspace___c99_complex_float_eq */

#if defined(__polyspace___c99_double_to_cdouble) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_double_to_cdouble)
#pragma POLYSPACE_INLINE_CHECKS "__c99_double_to_cdouble"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_double __c99_double_to_cdouble(double v) {
  struct _Complex_double c;
  c._Vals[0] = v;
  c._Vals[1] = 0.0;
  return c;
}
#endif /*  __polyspace___c99_double_to_cdouble */

#if defined(__polyspace___c99_idouble_to_cdouble) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_idouble_to_cdouble)
#pragma POLYSPACE_INLINE_CHECKS "__c99_idouble_to_cdouble"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_double __c99_idouble_to_cdouble(double v) {
  struct _Complex_double c;
  c._Vals[0] = 0.0;
  c._Vals[1] = v;
  return c;
}
#endif /*  __polyspace___c99_idouble_to_cdouble */

#if defined(__polyspace___c99_long_double_to_clong_double) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_long_double_to_clong_double)
#pragma POLYSPACE_INLINE_CHECKS "__c99_long_double_to_clong_double"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_long_double __c99_long_double_to_clong_double(long double v) {
  struct _Complex_long_double c;
  c._Vals[0] = v;
  c._Vals[1] = 0.0;
  return c;
}
#endif /*  __polyspace___c99_long_double_to_clong_double */

#if defined(__polyspace___c99_ilong_double_to_clong_double) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_ilong_double_to_clong_double)
#pragma POLYSPACE_INLINE_CHECKS "__c99_ilong_double_to_clong_double"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_long_double __c99_ilong_double_to_clong_double(long double v) {
  struct _Complex_long_double c;
  c._Vals[0] = 0.0;
  c._Vals[1] = v;
  return c;
}
#endif /*  __polyspace___c99_ilong_double_to_clong_double */

#if defined(__polyspace___c99_float_to_cfloat) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_float_to_cfloat)
#pragma POLYSPACE_INLINE_CHECKS "__c99_float_to_cfloat"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_float __c99_float_to_cfloat(float v) {
  struct _Complex_float c;
  c._Vals[0] = v;
  c._Vals[1] = 0.0;
  return c;
}
#endif /*  __polyspace___c99_float_to_cfloat */

#if defined(__polyspace___c99_ifloat_to_cfloat) && defined(__PST_POLYSPACE_MODE)
#if !defined(NO_CHECKS_INLINING) && !defined(__polyspace_no_inlined___c99_ifloat_to_cfloat)
#pragma POLYSPACE_INLINE_CHECKS "__c99_ifloat_to_cfloat"
#endif /* !NO_CHECKS_INLINING */
struct _Complex_float __c99_ifloat_to_cfloat(float v) {
  struct _Complex_float c;
  c._Vals[0] = 0.0;
  c._Vals[1] = v;
  return c;
}
#endif /*  __polyspace___c99_ifloat_to_cfloat */

#endif /* NO_POLYSPACE_COMPLEX */


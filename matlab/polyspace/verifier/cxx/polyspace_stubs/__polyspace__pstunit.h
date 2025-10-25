/* Copyright 2022-2024 The MathWorks, Inc. */

#ifndef __POLYSPACE__PSTUNIT_H
#define __POLYSPACE__PSTUNIT_H

#ifdef __cplusplus
#include <cmath>
#include <cstring>
#else
#include <math.h>
#include <string.h>
#endif

/* ---------------------------------------------------------------------------------------------- */
/* Suite/test declaration and registration, simple tests are gather in the SIMPLE_SUITE */

#define __PST_REGFCN(name) void __builtin_mw_pstunit_regfnc_##name(void)
#define __PST_REGFCN_CALL(name)
#define __PST_MAIN(argc, argv) 0

#define __PST_SUITE_CONFIG(name) void __builtin_mw_pstunit_new_suite_##name(void)
#define __PST_SUITE_EXTERN(name)                                    \
    extern inline void __builtin_mw_pstunit_forward_declare_suite_##name(void) {} \
    struct __pst_dummy_struct_for_PST_SUITE_EXTERN_##name {         \
        int dummy;                                                  \
    }

#define __PST_TEST_CONFIG(suite, test) \
    void __builtin_mw_pstunit_new_test_##test##__IN__##suite(void)
#define __PST_SIMPLE_TEST_CONFIG(test) \
    void __builtin_mw_pstunit_new_test_##test##__IN__SIMPLE_SUITE(void)

extern void __builtin_mw_pstunit_suite_setup(void (*)(void));
extern void __builtin_mw_pstunit_suite_teardown(void (*)(void));
extern void __builtin_mw_pstunit_suite_test_setup(void (*)(void));
extern void __builtin_mw_pstunit_suite_test_teardown(void (*)(void));
extern void __builtin_mw_pstunit_test_setup(void (*)(void));
extern void __builtin_mw_pstunit_test_teardown(void (*)(void));

#define __PST_SUITE_SETUP(func) __builtin_mw_pstunit_suite_setup(func)
#define __PST_SUITE_TEARDOWN(func) __builtin_mw_pstunit_suite_teardown(func)
#define __PST_SUITE_TEST_SETUP(func) __builtin_mw_pstunit_suite_test_setup(func)
#define __PST_SUITE_TEST_TEARDOWN(func) __builtin_mw_pstunit_suite_test_teardown(func)
#define __PST_SETUP(func) __builtin_mw_pstunit_test_setup(func)
#define __PST_TEARDOWN(func) __builtin_mw_pstunit_test_teardown(func)

#define __PST_TEST_BODY(suite, test) void __builtin_mw_pstunit_test_body_##test##__IN__##suite(void)
#define __PST_SIMPLE_TEST_BODY(test) void __builtin_mw_pstunit_test_body_##test##__IN__SIMPLE_SUITE(void)
#define __PST_TEST_VAR_EXTERN(suite, test) extern void __builtin_mw_pstunit_test_body_##test##__IN__##suite(void)
#define __PST_SIMPLE_TEST_VAR_EXTERN(test) extern void __builtin_mw_pstunit_test_body_##test##__IN__SIMPLE_SUITE(void)
#define __PST_ADD_TEST(suite, test) __builtin_mw_pstunit_test_body_##test##__IN__##suite()
#define __PST_ADD_SIMPLE_TEST(test) __builtin_mw_pstunit_test_body_##test##__IN__SIMPLE_SUITE()

/* The struct at the end of the above macro is necessary as a ";" is used at the end
   of the calls to this macro. */
#define __PST_SUITE(suite)                            \
    __PST_SUITE_CONFIG(suite) {}                      \
    struct __pst_dummy_struct_for_PST_SUITE_##suite { \
        int dummy;                                    \
    }

#define __PST_TEST(suite, test)       \
    __PST_TEST_CONFIG(suite, test) {} \
    __PST_TEST_BODY(suite, test)

#define __PST_SIMPLE_TEST(test) __PST_TEST(SIMPLE_SUITE, test)

/* --------------------------------------------------------------------------------------------- */
/* Fixtures */

extern void __builtin_mw_pstunit_set_fixture_ptr(void *);
extern void *__builtin_mw_pstunit_fixture_ptr;
extern void *__builtin_mw_pstunit_suite_fixture_ptr;
extern void *__builtin_mw_pstunit_suite_test_fixture_ptr;
extern void *__builtin_mw_pstunit_test_fixture_ptr;

#define __PST_SET_FIXTURE_PTR(ptr) __builtin_mw_pstunit_set_fixture_ptr(ptr)
#define __PST_FIXTURE_PTR() __builtin_mw_pstunit_fixture_ptr
#define __PST_STATIC_CAST(to_type, var) ((to_type)(var))

#define __PST_SUITE_FIXTURE_PTR() __builtin_mw_pstunit_suite_fixture_ptr
#define __PST_SUITE_TEST_FIXTURE_PTR() __builtin_mw_pstunit_suite_test_fixture_ptr
#define __PST_TEST_FIXTURE_PTR() __builtin_mw_pstunit_test_fixture_ptr

/* --------------------------------------------------------------------------------------------- */
/* Params */

#define __PST_PARAM_WITH_VALUES(name, type, format, pointer, size) \
    type* __pst_param_##name##_pointer = (type*)(pointer);         \
    size_t __pst_param_##name##_index = 0;                         \
    size_t __pst_param_##name##_size = (size)

#define __PST_PARAM(name, type, format)               \
    type* __pst_param_##name##_pointer = (type*)NULL; \
    size_t __pst_param_##name##_index = 0;            \
    size_t __pst_param_##name##_size = 0

extern void __builtin_mw_pstunit_add_param(void*);
extern void __builtin_mw_pstunit_param_combination_exhaustive(void);
extern void __builtin_mw_pstunit_param_combination_sequential(void);

#define __PST_ADD_PARAM(name) __builtin_mw_pstunit_add_param(__pst_param_##name##_pointer)
#define __PST_PARAM_PTR(name) (__pst_param_##name##_pointer + __pst_param_##name##_index)
#define __PST_SET_PARAM(name, pointer, size)      \
    do {                                          \
        __pst_param_##name##_pointer = (pointer); \
        __pst_param_##name##_size = (size);       \
    } while (0)
#define __PST_PARAM_COMBINATION_EXHAUSTIVE()  __builtin_mw_pstunit_param_combination_exhaustive()
#define __PST_PARAM_COMBINATION_SEQUENTIAL()  __builtin_mw_pstunit_param_combination_sequential()

/* --------------------------------------------------------------------------------------------- */
/* Mocking */

#define __PST_MOCK_SELECTOR(name) int __pst_mock_##name = 0
#define __PST_MOCK_SELECTOR_EXTERN(name) extern int __pst_mock_##name
#define __PST_SELECTED_MOCK(name) __pst_mock_##name
#define __PST_SELECT_MOCK(name, value) __pst_mock_##name = (value)

/* --------------------------------------------------------------------------------------------- */
/* Assertions for integral, pointer, string, array of pointers and strings */

#ifdef __cplusplus
extern void PST_ASSERT(bool);
extern void PST_VERIFY(bool);
extern void PST_ASSUME(bool);
#else
extern void PST_ASSERT(int);
extern void PST_VERIFY(int);
extern void PST_ASSUME(int);
#endif

/* Fallback for assessments without specific implementation */
#define __PST_ASSERT_BODY(result) PST_ASSERT(result)
#define __PST_VERIFY_BODY(result) PST_VERIFY(result)
#define __PST_ASSUME_BODY(result) PST_ASSUME(result)

#define __PST_ASSERT_TRUE(result) PST_ASSERT(result)
#define __PST_VERIFY_TRUE(result) PST_VERIFY(result)
#define __PST_ASSUME_TRUE(result) PST_ASSUME(result)

#define __PST_ASSERT_FALSE(result) PST_ASSERT(!(result))
#define __PST_VERIFY_FALSE(result) PST_VERIFY(!(result))
#define __PST_ASSUME_FALSE(result) PST_ASSUME(!(result))

#define __PST_MSG(msg) perror(msg)

#define __PST_ASSERT_MSG(result, msg) \
    do {                              \
        __PST_MSG(msg);           \
        PST_ASSERT(result);         \
    } while (0)
#define __PST_VERIFY_MSG(result, msg) \
    do {                              \
        __PST_MSG(msg);           \
        PST_VERIFY(result);         \
    } while (0)
#define __PST_ASSUME_MSG(result, msg) \
    do {                              \
        __PST_MSG(msg);           \
        PST_ASSUME(result);           \
    } while (0)

#define __PST_ASSERT_TRUE_MSG(result, msg) __PST_ASSERT_MSG(result, msg)
#define __PST_VERIFY_TRUE_MSG(result, msg) __PST_VERIFY_MSG(result, msg)
#define __PST_ASSUME_TRUE_MSG(result, msg) __PST_ASSUME_MSG(result, msg)

#define __PST_ASSERT_FALSE_MSG(result, msg) __PST_ASSERT_MSG(!(result), msg)
#define __PST_VERIFY_FALSE_MSG(result, msg) __PST_VERIFY_MSG(!(result), msg)
#define __PST_ASSUME_FALSE_MSG(result, msg) __PST_ASSUME_MSG(!(result), msg)

/* --------------------------------------------------------------------------------------------- */
/* Assertions using operators */

#if __PST_ENABLE_LONG_LONG
#define pst_largest_int pst_long_long_t
#define pst_largest_uint pst_unsigned_long_long_t
#else
#define pst_largest_int long
#define pst_largest_uint unsigned long
#endif

#define pst_largest_flt long double
#define pst_abs(x) fabsl(x)

/* == */

#define __PST_ASSERT_EQ_INT(lhs, rhs) PST_ASSERT((pst_largest_int)(lhs) == (pst_largest_int)(rhs))
#define __PST_VERIFY_EQ_INT(lhs, rhs) PST_VERIFY((pst_largest_int)(lhs) == (pst_largest_int)(rhs))
#define __PST_ASSERT_EQ_INT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_int)(lhs) == (pst_largest_int)(rhs), msg)
#define __PST_VERIFY_EQ_INT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_int)(lhs) == (pst_largest_int)(rhs), msg)

#define __PST_ASSERT_EQ_UINT(lhs, rhs) \
    PST_ASSERT((pst_largest_uint)(lhs) == (pst_largest_uint)(rhs))
#define __PST_VERIFY_EQ_UINT(lhs, rhs) \
    PST_VERIFY((pst_largest_uint)(lhs) == (pst_largest_uint)(rhs))
#define __PST_ASSERT_EQ_UINT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_uint)(lhs) == (pst_largest_uint)(rhs), msg)
#define __PST_VERIFY_EQ_UINT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_uint)(lhs) == (pst_largest_uint)(rhs), msg)

/* TODO: should be done via bitwise casts, but we mimic the library behavior */
#define __PST_ASSERT_EQ_BITS(lhs, rhs) __PST_ASSERT_EQ_INT(lhs, rhs)
#define __PST_VERIFY_EQ_BITS(lhs, rhs) __PST_VERIFY_EQ_INT(lhs, rhs)
#define __PST_ASSERT_EQ_BITS_MSG(lhs, rhs, msg) __PST_ASSERT_EQ_INT_MSG(lhs, rhs, msg)
#define __PST_VERIFY_EQ_BITS_MSG(lhs, rhs, msg) __PST_VERIFY_EQ_INT_MSG(lhs, rhs, msg)

#define __PST_ASSERT_EQ_MASK_BITS(lhs, rhs, mask)                      \
    PST_ASSERT(((pst_largest_int)(lhs) & (pst_largest_int)(mask)) == \
                 ((pst_largest_int)(rhs) & (pst_largest_int)(mask)))
#define __PST_VERIFY_EQ_MASK_BITS(lhs, rhs, mask)                      \
    PST_VERIFY(((pst_largest_int)(lhs) & (pst_largest_int)(mask)) == \
                 ((pst_largest_int)(rhs) & (pst_largest_int)(mask)))
#define __PST_ASSERT_EQ_MASK_BITS_MSG(lhs, rhs, mask, msg)                   \
    __PST_ASSERT_MSG(((pst_largest_int)(lhs) & (pst_largest_int)(mask)) ==   \
                         ((pst_largest_int)(rhs) & (pst_largest_int)(mask)), \
                     msg)
#define __PST_VERIFY_EQ_MASK_BITS_MSG(lhs, rhs, mask, msg)                   \
    __PST_VERIFY_MSG(((pst_largest_int)(lhs) & (pst_largest_int)(mask)) ==   \
                         ((pst_largest_int)(rhs) & (pst_largest_int)(mask)), \
                     msg)

#define __PST_ASSERT_EQ_PTR(lhs, rhs) PST_ASSERT((void*)(lhs) == (void*)(rhs))
#define __PST_VERIFY_EQ_PTR(lhs, rhs) PST_VERIFY((void*)(lhs) == (void*)(rhs))
#define __PST_ASSERT_EQ_PTR_MSG(lhs, rhs, msg) __PST_ASSERT_MSG((void*)(lhs) == (void*)(rhs), msg)
#define __PST_VERIFY_EQ_PTR_MSG(lhs, rhs, msg) __PST_VERIFY_MSG((void*)(lhs) == (void*)(rhs), msg)

#define __PST_ASSERT_EQ_CSTR(lhs, rhs) PST_ASSERT(strcmp((lhs), (rhs)) == 0)
#define __PST_VERIFY_EQ_CSTR(lhs, rhs) PST_VERIFY(strcmp((lhs), (rhs)) == 0)
#define __PST_ASSERT_EQ_CSTR_MSG(lhs, rhs, msg) __PST_ASSERT_MSG(strcmp((lhs), (rhs)) == 0, msg)
#define __PST_VERIFY_EQ_CSTR_MSG(lhs, rhs, msg) __PST_VERIFY_MSG(strcmp((lhs), (rhs)) == 0, msg)

#define __PST_ASSERT_EACH_EQ_CSTR(lhs, rhs, nb_elem)                              \
    do {                                                                          \
        int pst_internal_index = 0;                                               \
        int pst_internal_nb_elem = (nb_elem);                                     \
        char const* const* pst_internal_lhs = (char const*const*)(lhs);           \
        char const* const* pst_internal_rhs = (char const*const*)(rhs);           \
        for (; pst_internal_index < pst_internal_nb_elem; pst_internal_index++) { \
            __PST_ASSERT_EQ_CSTR(pst_internal_lhs[pst_internal_index],            \
                                 pst_internal_rhs[pst_internal_index]);           \
        }                                                                         \
    } while (0)
#define __PST_ASSERT_EACH_EQ_CSTR_MSG(lhs, rhs, nb_elem, msg) \
    do {                                                      \
        __PST_MSG(msg);                                       \
        __PST_ASSERT_EACH_EQ_CSTR(lhs, rhs, nb_elem);         \
    } while (0)
#define __PST_VERIFY_EACH_EQ_CSTR(lhs, rhs, nb_elem)                              \
    do {                                                                          \
        int pst_internal_index = 0;                                               \
        int pst_internal_nb_elem = (nb_elem);                                     \
        char const* const* pst_internal_lhs = (char const*const*)(lhs);           \
        char const* const* pst_internal_rhs = (char const*const*)(rhs);           \
        for (; pst_internal_index < pst_internal_nb_elem; pst_internal_index++) { \
            __PST_VERIFY_EQ_CSTR(pst_internal_lhs[pst_internal_index],            \
                                 pst_internal_rhs[pst_internal_index]);           \
        }                                                                         \
    } while (0)
#define __PST_VERIFY_EACH_EQ_CSTR_MSG(lhs, rhs, nb_elem, msg) \
    do {                                                      \
        __PST_MSG(msg);                                       \
        __PST_VERIFY_EACH_EQ_CSTR(lhs, rhs, nb_elem);         \
    } while (0)

#define __PST_ASSERT_EACH_EQ_PTR(lhs, rhs, nb_elem)                     \
    do {                                                                \
        int pst_internal_index = 0;                                     \
        int pst_internal_nb_elem = (nb_elem);                           \
        void const* const* pst_internal_lhs = (void const*const*)(lhs); \
        void const* const* pst_internal_rhs = (void const*const*)(rhs); \
        int pst_all_equals = 1;                                         \
        for (; pst_internal_index < pst_internal_nb_elem; pst_internal_index++) { \
            pst_all_equals =                                            \
                ((void*)pst_internal_lhs[pst_internal_index]) == ((void*)pst_internal_rhs[pst_internal_index]) && \
                pst_all_equals;                                         \
        }                                                               \
        PST_ASSERT(pst_all_equals);                                     \
    } while (0)
#define __PST_ASSERT_EACH_EQ_PTR_MSG(lhs, rhs, nb_elem, msg) \
    do {                                                     \
        __PST_MSG(msg);                                      \
        __PST_ASSERT_EACH_EQ_PTR(lhs, rhs, nb_elem);         \
    } while (0)
#define __PST_VERIFY_EACH_EQ_PTR(lhs, rhs, nb_elem)                     \
    do {                                                                \
        int pst_internal_index = 0;                                     \
        int pst_internal_nb_elem = (nb_elem);                           \
        void const* const* pst_internal_lhs = (void const*const*)(lhs); \
        void const* const* pst_internal_rhs = (void const*const*)(rhs); \
        int pst_all_equals = 1;                                         \
        for (; pst_internal_index < pst_internal_nb_elem; pst_internal_index++) { \
            pst_all_equals =                                            \
                ((void*)pst_internal_lhs[pst_internal_index]) == ((void*)pst_internal_rhs[pst_internal_index]) && \
                pst_all_equals;                                         \
        }                                                               \
        __PST_VERIFY(pst_all_equals);                                   \
    } while (0)
#define __PST_VERIFY_EACH_EQ_PTR_MSG(lhs, rhs, nb_elem, msg) \
    do {                                                     \
        __PST_MSG(msg);                                      \
        __PST_VERIFY_EACH_EQ_PTR(lhs, rhs, nb_elem);         \
    } while (0)

#define __PST_ASSERT_EQ_CUSTOM(lhs, rhs, cmp_fcn, disp_fcn) \
    PST_ASSERT(cmp_fcn(&(lhs), &(rhs)) == 0)
#define __PST_VERIFY_EQ_CUSTOM(lhs, rhs, cmp_fcn, disp_fcn) \
    PST_VERIFY(cmp_fcn(&(lhs), &(rhs)) == 0)
#define __PST_ASSERT_EQ_CUSTOM_MSG(lhs, rhs, cmp_fcn, disp_fcn, msg) \
    __PST_ASSERT_MSG(cmp_fcn(&(lhs), &(rhs)) == 0, msg)
#define __PST_VERIFY_EQ_CUSTOM_MSG(lhs, rhs, cmp_fcn, disp_fcn, msg) \
    __PST_VERIFY_MSG(cmp_fcn(&(lhs), &(rhs)) == 0, msg)

#define __PST_ASSERT_EACH_EQ_CUSTOM(lhs, rhs, nb_elem, type, cmp_fcn, disp_fcn)   \
    do {                                                                          \
        int pst_internal_index = 0;                                               \
        int pst_internal_nb_elem = (nb_elem);                                     \
        const type* pst_internal_lhs = (const type*)(lhs);                        \
        const type* pst_internal_rhs = (const type*)(rhs);                        \
        for (; pst_internal_index < pst_internal_nb_elem; pst_internal_index++) { \
            PST_ASSERT(!cmp_fcn(&pst_internal_lhs[pst_internal_index],            \
                                &pst_internal_rhs[pst_internal_index]));          \
        }                                                                         \
    } while (0)
#define __PST_ASSERT_EACH_EQ_CUSTOM_MSG(lhs, rhs, nb_elem, type, cmp_fcn, disp_fcn, msg) \
    do {                                                                                 \
        __PST_MSG(msg);                                                                  \
        __PST_ASSERT_EACH_EQ_CUSTOM(lhs, rhs, nb_elem, type, cmp_fcn, disp_fcn);         \
    } while (0)
#define __PST_VERIFY_EACH_EQ_CUSTOM(lhs, rhs, nb_elem, type, cmp_fcn, disp_fcn)         \
    do {                                                                                \
        int pst_internal_index = 0;                                                     \
        int pst_internal_nb_elem = (nb_elem);                                           \
        const type* pst_internal_lhs = (const type*)(lhs);                              \
        const type* pst_internal_rhs = (const type*)(rhs);                              \
        for (; pst_internal_index < pst_internal_nb_elem; pst_internal_index++) {       \
            PST_VERIFY(!cmp_fcn(&pst_internal_lhs[pst_internal_index],                  \
                                &pst_internal_rhs[pst_internal_index]));                \
        }                                                                               \
    } while (0)
#define __PST_VERIFY_EACH_EQ_CUSTOM_MSG(lhs, rhs, nb_elem, type, cmp_fcn, disp_fcn, msg) \
    do {                                                                                 \
        __PST_MSG(msg);                                                                  \
        __PST_VERIFY_EACH_EQ_CUSTOM(lhs, rhs, nb_elem, type, cmp_fcn, disp_fcn);         \
    } while (0)

/* == with approximation */

#define __PST_ASSERT_EQ_APPROX_FLT(lhs, rhs, delta) \
    PST_ASSERT(pst_abs((lhs) - (rhs)) <= pst_abs(delta))
#define __PST_VERIFY_EQ_APPROX_FLT(lhs, rhs, delta) \
    PST_VERIFY(pst_abs((lhs) - (rhs)) <= pst_abs(delta))
#define __PST_ASSERT_EQ_APPROX_FLT_MSG(lhs, rhs, delta, msg) \
    __PST_ASSERT_MSG(pst_abs((lhs) - (rhs)) <= pst_abs(delta), msg)
#define __PST_VERIFY_EQ_APPROX_FLT_MSG(lhs, rhs, delta, msg) \
    __PST_VERIFY_MSG(pst_abs((lhs) - (rhs)) <= pst_abs(delta), msg)

/* != */

#define __PST_ASSERT_NE_INT(lhs, rhs) PST_ASSERT((pst_largest_int)(lhs) != (pst_largest_int)(rhs))
#define __PST_VERIFY_NE_INT(lhs, rhs) PST_VERIFY((pst_largest_int)(lhs) != (pst_largest_int)(rhs))
#define __PST_ASSERT_NE_INT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_int)(lhs) != (pst_largest_int)(rhs), msg)
#define __PST_VERIFY_NE_INT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_int)(lhs) != (pst_largest_int)(rhs), msg)

#define __PST_ASSERT_NE_UINT(lhs, rhs) \
    PST_ASSERT((pst_largest_uint)(lhs) != (pst_largest_uint)(rhs))
#define __PST_VERIFY_NE_UINT(lhs, rhs) \
    PST_VERIFY((pst_largest_uint)(lhs) != (pst_largest_uint)(rhs))
#define __PST_ASSERT_NE_UINT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_uint)(lhs) != (pst_largest_uint)(rhs), msg)
#define __PST_VERIFY_NE_UINT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_uint)(lhs) != (pst_largest_uint)(rhs), msg)

#define __PST_ASSERT_NE_PTR(lhs, rhs) PST_ASSERT((void*)(lhs) != (void*)(rhs))
#define __PST_VERIFY_NE_PTR(lhs, rhs) PST_VERIFY((void*)(lhs) != (void*)(rhs))
#define __PST_ASSERT_NE_PTR_MSG(lhs, rhs, msg) __PST_ASSERT_MSG((void*)(lhs) != (void*)(rhs), msg)
#define __PST_VERIFY_NE_PTR_MSG(lhs, rhs, msg) __PST_VERIFY_MSG((void*)(lhs) != (void*)(rhs), msg)

#define __PST_ASSERT_NE_CSTR(lhs, rhs) PST_ASSERT(strcmp((lhs), (rhs)) != 0)
#define __PST_VERIFY_NE_CSTR(lhs, rhs) PST_VERIFY(strcmp((lhs), (rhs)) != 0)
#define __PST_ASSERT_NE_CSTR_MSG(lhs, rhs, msg) __PST_ASSERT_MSG(strcmp((lhs), (rhs)) != 0, msg)
#define __PST_VERIFY_NE_CSTR_MSG(lhs, rhs, msg) __PST_VERIFY_MSG(strcmp((lhs), (rhs)) != 0, msg)

#define __PST_ASSERT_NE_CUSTOM(lhs, rhs, cmp_fcn, disp_fcn) \
    PST_ASSERT(cmp_fcn(&(lhs), &(rhs)) != 0)
#define __PST_VERIFY_NE_CUSTOM(lhs, rhs, cmp_fcn, disp_fcn) \
    PST_VERIFY(cmp_fcn(&(lhs), &(rhs)) != 0)
#define __PST_ASSERT_NE_CUSTOM_MSG(lhs, rhs, cmp_fcn, disp_fcn, msg) \
    __PST_ASSERT_MSG(cmp_fcn(&(lhs), &(rhs)) != 0, msg)
#define __PST_VERIFY_NE_CUSTOM_MSG(lhs, rhs, cmp_fcn, disp_fcn, msg) \
    __PST_VERIFY_MSG(cmp_fcn(&(lhs), &(rhs)) != 0, msg)

/* != with approximation */

#define __PST_ASSERT_NE_APPROX_FLT(lhs, rhs, delta) \
    PST_ASSERT(pst_abs((lhs) - (rhs)) > pst_abs(delta))
#define __PST_VERIFY_NE_APPROX_FLT(lhs, rhs, delta) \
    PST_VERIFY(pst_abs((lhs) - (rhs)) > pst_abs(delta))
#define __PST_ASSERT_NE_APPROX_FLT_MSG(lhs, rhs, delta, msg) \
    __PST_ASSERT_MSG(pst_abs((lhs) - (rhs)) > pst_abs(delta), msg)
#define __PST_VERIFY_NE_APPROX_FLT_MSG(lhs, rhs, delta, msg) \
    __PST_VERIFY_MSG(pst_abs((lhs) - (rhs)) > pst_abs(delta), msg)

/* < */

#define __PST_ASSERT_LT_INT(lhs, rhs) PST_ASSERT((pst_largest_int)(lhs) < (pst_largest_int)(rhs))
#define __PST_VERIFY_LT_INT(lhs, rhs) PST_VERIFY((pst_largest_int)(lhs) < (pst_largest_int)(rhs))
#define __PST_ASSERT_LT_INT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_int)(lhs) < (pst_largest_int)(rhs), msg)
#define __PST_VERIFY_LT_INT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_int)(lhs) < (pst_largest_int)(rhs), msg)

#define __PST_ASSERT_LT_UINT(lhs, rhs) PST_ASSERT((pst_largest_uint)(lhs) < (pst_largest_uint)(rhs))
#define __PST_VERIFY_LT_UINT(lhs, rhs) PST_VERIFY((pst_largest_uint)(lhs) < (pst_largest_uint)(rhs))
#define __PST_ASSERT_LT_UINT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_uint)(lhs) < (pst_largest_uint)(rhs), msg)
#define __PST_VERIFY_LT_UINT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_uint)(lhs) < (pst_largest_uint)(rhs), msg)

#define __PST_ASSERT_LT_CSTR(lhs, rhs) PST_ASSERT(strcmp((lhs), (rhs)) < 0)
#define __PST_VERIFY_LT_CSTR(lhs, rhs) PST_VERIFY(strcmp((lhs), (rhs)) < 0)
#define __PST_ASSERT_LT_CSTR_MSG(lhs, rhs, msg) __PST_ASSERT_MSG(strcmp((lhs), (rhs)) < 0, msg)
#define __PST_VERIFY_LT_CSTR_MSG(lhs, rhs, msg) __PST_VERIFY_MSG(strcmp((lhs), (rhs)) < 0, msg)

#define __PST_ASSERT_LT_FLT(lhs, rhs) PST_ASSERT((pst_largest_flt)(lhs) < (pst_largest_flt)(rhs))
#define __PST_VERIFY_LT_FLT(lhs, rhs) PST_VERIFY((pst_largest_flt)(lhs) < (pst_largest_flt)(rhs))
#define __PST_ASSERT_LT_FLT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_flt)(lhs) < (pst_largest_flt)(rhs), msg)
#define __PST_VERIFY_LT_FLT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_flt)(lhs) < (pst_largest_flt)(rhs), msg)

#define __PST_ASSERT_LT_CUSTOM(lhs, rhs, cmp_fcn, disp_fcn) \
    PST_ASSERT(cmp_fcn(&(lhs), &(rhs)) < 0)
#define __PST_VERIFY_LT_CUSTOM(lhs, rhs, cmp_fcn, disp_fcn) \
    PST_VERIFY(cmp_fcn(&(lhs), &(rhs)) < 0)
#define __PST_ASSERT_LT_CUSTOM_MSG(lhs, rhs, cmp_fcn, disp_fcn, msg) \
    __PST_ASSERT_MSG(cmp_fcn(&(lhs), &(rhs)) < 0, msg)
#define __PST_VERIFY_LT_CUSTOM_MSG(lhs, rhs, cmp_fcn, disp_fcn, msg) \
    __PST_VERIFY_MSG(cmp_fcn(&(lhs), &(rhs)) < 0, msg)

/* <= */

#define __PST_ASSERT_LE_INT(lhs, rhs) PST_ASSERT((pst_largest_int)(lhs) <= (pst_largest_int)(rhs))
#define __PST_VERIFY_LE_INT(lhs, rhs) PST_VERIFY((pst_largest_int)(lhs) <= (pst_largest_int)(rhs))
#define __PST_ASSERT_LE_INT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_int)(lhs) <= (pst_largest_int)(rhs), msg)
#define __PST_VERIFY_LE_INT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_int)(lhs) <= (pst_largest_int)(rhs), msg)

#define __PST_ASSERT_LE_UINT(lhs, rhs) PST_ASSERT((pst_largest_uint)(lhs) <= (pst_largest_uint)(rhs))
#define __PST_VERIFY_LE_UINT(lhs, rhs) PST_VERIFY((pst_largest_uint)(lhs) <= (pst_largest_uint)(rhs))
#define __PST_ASSERT_LE_UINT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_uint)(lhs) <= (pst_largest_uint)(rhs), msg)
#define __PST_VERIFY_LE_UINT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_uint)(lhs) <= (pst_largest_uint)(rhs), msg)

#define __PST_ASSERT_LE_CSTR(lhs, rhs) PST_ASSERT(strcmp((lhs), (rhs)) <= 0)
#define __PST_VERIFY_LE_CSTR(lhs, rhs) PST_VERIFY(strcmp((lhs), (rhs)) <= 0)
#define __PST_ASSERT_LE_CSTR_MSG(lhs, rhs, msg) __PST_ASSERT_MSG(strcmp((lhs), (rhs)) <= 0, msg)
#define __PST_VERIFY_LE_CSTR_MSG(lhs, rhs, msg) __PST_VERIFY_MSG(strcmp((lhs), (rhs)) <= 0, msg)

#define __PST_ASSERT_LE_FLT(lhs, rhs) PST_ASSERT((pst_largest_flt)(lhs) <= (pst_largest_flt)(rhs))
#define __PST_VERIFY_LE_FLT(lhs, rhs) PST_VERIFY((pst_largest_flt)(lhs) <= (pst_largest_flt)(rhs))
#define __PST_ASSERT_LE_FLT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_flt)(lhs) <= (pst_largest_flt)(rhs), msg)
#define __PST_VERIFY_LE_FLT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_flt)(lhs) <= (pst_largest_flt)(rhs), msg)

#define __PST_ASSERT_LE_CUSTOM(lhs, rhs, cmp_fcn, disp_fcn) \
    PST_ASSERT(cmp_fcn(&(lhs), &(rhs)) <= 0)
#define __PST_VERIFY_LE_CUSTOM(lhs, rhs, cmp_fcn, disp_fcn) \
    PST_VERIFY(cmp_fcn(&(lhs), &(rhs)) <= 0)
#define __PST_ASSERT_LE_CUSTOM_MSG(lhs, rhs, cmp_fcn, disp_fcn, msg) \
    __PST_ASSERT_MSG(cmp_fcn(&(lhs), &(rhs)) <= 0, msg)
#define __PST_VERIFY_LE_CUSTOM_MSG(lhs, rhs, cmp_fcn, disp_fcn, msg) \
    __PST_VERIFY_MSG(cmp_fcn(&(lhs), &(rhs)) <= 0, msg)

/* > */

#define __PST_ASSERT_GT_INT(lhs, rhs) PST_ASSERT((pst_largest_int)(lhs) > (pst_largest_int)(rhs))
#define __PST_VERIFY_GT_INT(lhs, rhs) PST_VERIFY((pst_largest_int)(lhs) > (pst_largest_int)(rhs))
#define __PST_ASSERT_GT_INT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_int)(lhs) > (pst_largest_int)(rhs), msg)
#define __PST_VERIFY_GT_INT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_int)(lhs) > (pst_largest_int)(rhs), msg)

#define __PST_ASSERT_GT_UINT(lhs, rhs) PST_ASSERT((pst_largest_uint)(lhs) > (pst_largest_uint)(rhs))
#define __PST_VERIFY_GT_UINT(lhs, rhs) PST_VERIFY((pst_largest_uint)(lhs) > (pst_largest_uint)(rhs))
#define __PST_ASSERT_GT_UINT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_uint)(lhs) > (pst_largest_uint)(rhs), msg)
#define __PST_VERIFY_GT_UINT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_uint)(lhs) > (pst_largest_uint)(rhs), msg)

#define __PST_ASSERT_GT_CSTR(lhs, rhs) PST_ASSERT(strcmp((lhs), (rhs)) > 0)
#define __PST_VERIFY_GT_CSTR(lhs, rhs) PST_VERIFY(strcmp((lhs), (rhs)) > 0)
#define __PST_ASSERT_GT_CSTR_MSG(lhs, rhs, msg) __PST_ASSERT_MSG(strcmp((lhs), (rhs)) > 0, msg)
#define __PST_VERIFY_GT_CSTR_MSG(lhs, rhs, msg) __PST_VERIFY_MSG(strcmp((lhs), (rhs)) > 0, msg)

#define __PST_ASSERT_GT_FLT(lhs, rhs) PST_ASSERT((pst_largest_flt)(lhs) > (pst_largest_flt)(rhs))
#define __PST_VERIFY_GT_FLT(lhs, rhs) PST_VERIFY((pst_largest_flt)(lhs) > (pst_largest_flt)(rhs))
#define __PST_ASSERT_GT_FLT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_flt)(lhs) > (pst_largest_flt)(rhs), msg)
#define __PST_VERIFY_GT_FLT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_flt)(lhs) > (pst_largest_flt)(rhs), msg)

#define __PST_ASSERT_GT_CUSTOM(lhs, rhs, cmp_fcn, disp_fcn) \
    PST_ASSERT(cmp_fcn(&(lhs), &(rhs)) > 0)
#define __PST_VERIFY_GT_CUSTOM(lhs, rhs, cmp_fcn, disp_fcn) \
    PST_VERIFY(cmp_fcn(&(lhs), &(rhs)) > 0)
#define __PST_ASSERT_GT_CUSTOM_MSG(lhs, rhs, cmp_fcn, disp_fcn, msg) \
    __PST_ASSERT_MSG(cmp_fcn(&(lhs), &(rhs)) > 0, msg)
#define __PST_VERIFY_GT_CUSTOM_MSG(lhs, rhs, cmp_fcn, disp_fcn, msg) \
    __PST_VERIFY_MSG(cmp_fcn(&(lhs), &(rhs)) > 0, msg)

/* >= */

#define __PST_ASSERT_GE_INT(lhs, rhs) PST_ASSERT((pst_largest_int)(lhs) >= (pst_largest_int)(rhs))
#define __PST_VERIFY_GE_INT(lhs, rhs) PST_VERIFY((pst_largest_int)(lhs) >= (pst_largest_int)(rhs))
#define __PST_ASSERT_GE_INT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_int)(lhs) >= (pst_largest_int)(rhs), msg)
#define __PST_VERIFY_GE_INT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_int)(lhs) >= (pst_largest_int)(rhs), msg)

#define __PST_ASSERT_GE_UINT(lhs, rhs) PST_ASSERT((pst_largest_uint)(lhs) >= (pst_largest_uint)(rhs))
#define __PST_VERIFY_GE_UINT(lhs, rhs) PST_VERIFY((pst_largest_uint)(lhs) >= (pst_largest_uint)(rhs))
#define __PST_ASSERT_GE_UINT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_uint)(lhs) >= (pst_largest_uint)(rhs), msg)
#define __PST_VERIFY_GE_UINT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_uint)(lhs) >= (pst_largest_uint)(rhs), msg)

#define __PST_ASSERT_GE_CSTR(lhs, rhs) PST_ASSERT(strcmp((lhs), (rhs)) >= 0)
#define __PST_VERIFY_GE_CSTR(lhs, rhs) PST_VERIFY(strcmp((lhs), (rhs)) >= 0)
#define __PST_ASSERT_GE_CSTR_MSG(lhs, rhs, msg) __PST_ASSERT_MSG(strcmp((lhs), (rhs)) >= 0, msg)
#define __PST_VERIFY_GE_CSTR_MSG(lhs, rhs, msg) __PST_VERIFY_MSG(strcmp((lhs), (rhs)) >= 0, msg)

#define __PST_ASSERT_GE_FLT(lhs, rhs) PST_ASSERT((pst_largest_flt)(lhs) >= (pst_largest_flt)(rhs))
#define __PST_VERIFY_GE_FLT(lhs, rhs) PST_VERIFY((pst_largest_flt)(lhs) >= (pst_largest_flt)(rhs))
#define __PST_ASSERT_GE_FLT_MSG(lhs, rhs, msg) \
    __PST_ASSERT_MSG((pst_largest_flt)(lhs) >= (pst_largest_flt)(rhs), msg)
#define __PST_VERIFY_GE_FLT_MSG(lhs, rhs, msg) \
    __PST_VERIFY_MSG((pst_largest_flt)(lhs) >= (pst_largest_flt)(rhs), msg)

#define __PST_ASSERT_GE_CUSTOM(lhs, rhs, cmp_fcn, disp_fcn) \
    PST_ASSERT(cmp_fcn(&(lhs), &(rhs)) >= 0)
#define __PST_VERIFY_GE_CUSTOM(lhs, rhs, cmp_fcn, disp_fcn) \
    PST_VERIFY(cmp_fcn(&(lhs), &(rhs)) >= 0)
#define __PST_ASSERT_GE_CUSTOM_MSG(lhs, rhs, cmp_fcn, disp_fcn, msg) \
    __PST_ASSERT_MSG(cmp_fcn(&(lhs), &(rhs)) >= 0, msg)
#define __PST_VERIFY_GE_CUSTOM_MSG(lhs, rhs, cmp_fcn, disp_fcn, msg) \
    __PST_VERIFY_MSG(cmp_fcn(&(lhs), &(rhs)) >= 0, msg)

#ifdef __cplusplus

/* EQ */
#define __PST_ASSERT_EQ(lhs, rhs) PST_ASSERT((lhs) == (rhs))
#define __PST_ASSERT_EQ_MSG(lhs, rhs, msg) __PST_ASSERT_MSG((lhs) == (rhs), msg)
#define __PST_VERIFY_EQ(lhs, rhs) PST_VERIFY((lhs) == (rhs))
#define __PST_VERIFY_EQ_MSG(lhs, rhs, msg) __PST_VERIFY_MSG((lhs) == (rhs), msg)

/* NE */
#define __PST_ASSERT_NE(lhs, rhs) PST_ASSERT((lhs) != (rhs))
#define __PST_ASSERT_NE_MSG(lhs, rhs, msg) __PST_ASSERT_MSG((lhs) != (rhs), msg)
#define __PST_VERIFY_NE(lhs, rhs) PST_VERIFY((lhs) != (rhs))
#define __PST_VERIFY_NE_MSG(lhs, rhs, msg) __PST_VERIFY_MSG((lhs) != (rhs), msg)

/* LT */
#define __PST_ASSERT_LT(lhs, rhs) PST_ASSERT((lhs) < (rhs))
#define __PST_ASSERT_LT_MSG(lhs, rhs, msg) __PST_ASSERT_MSG((lhs) < (rhs), msg)
#define __PST_VERIFY_LT(lhs, rhs) PST_VERIFY((lhs) < (rhs))
#define __PST_VERIFY_LT_MSG(lhs, rhs, msg) __PST_VERIFY_MSG((lhs) < (rhs), msg)

/* LE */
#define __PST_ASSERT_LE(lhs, rhs) PST_ASSERT((lhs) <= (rhs))
#define __PST_ASSERT_LE_MSG(lhs, rhs, msg) __PST_ASSERT_MSG((lhs) <= (rhs), msg)
#define __PST_VERIFY_LE(lhs, rhs) PST_VERIFY((lhs) <= (rhs))
#define __PST_VERIFY_LE_MSG(lhs, rhs, msg) __PST_VERIFY_MSG((lhs) <= (rhs), msg)

/* GT */
#define __PST_ASSERT_GT(lhs, rhs) PST_ASSERT((lhs) > (rhs))
#define __PST_ASSERT_GT_MSG(lhs, rhs, msg) __PST_ASSERT_MSG((lhs) > (rhs), msg)
#define __PST_VERIFY_GT(lhs, rhs) PST_VERIFY((lhs) > (rhs))
#define __PST_VERIFY_GT_MSG(lhs, rhs, msg) __PST_VERIFY_MSG((lhs) > (rhs), msg)

/* GE */
#define __PST_ASSERT_GE(lhs, rhs) PST_ASSERT((lhs) >= (rhs))
#define __PST_ASSERT_GE_MSG(lhs, rhs, msg) __PST_ASSERT_MSG((lhs) >= (rhs), msg)
#define __PST_VERIFY_GE(lhs, rhs) PST_VERIFY((lhs) >= (rhs))
#define __PST_VERIFY_GE_MSG(lhs, rhs, msg) __PST_VERIFY_MSG((lhs) >= (rhs), msg)

/* EACH_EQ */

// simplified version of pst_each_eq_assessment without the extra
// copies to buffer
template <typename lt, typename rt>
int __pst_each_eq(lt lhs_it, rt rhs_it, const int nb_elems) {
    int all_equals = 1;
    for (int index = 0; index < nb_elems; ++index, ++lhs_it, ++rhs_it) {
        if (*lhs_it != *rhs_it) {
            all_equals = 0;
        }
    }
    return all_equals;
}

#define __PST_ASSERT_EACH_EQ(lhs, rhs, num) PST_ASSERT(__pst_each_eq(lhs, rhs, num))
#define __PST_ASSERT_EACH_EQ_MSG(lhs, rhs, num, msg)        \
    do {                                                    \
        __PST_MSG(msg);                                     \
        __PST_ASSERT_EACH_EQ(lhs, rhs);                     \
    } while(0)

#define __PST_VERIFY_EACH_EQ(lhs, rhs, num) PST_VERIFY(__pst_each_eq(lhs, rhs, num))
#define __PST_VERIFY_EACH_EQ_MSG(lhs, rhs, num, msg)    \
    do {                                                \
        __PST_MSG(msg);                                 \
        __PST_VERIFY_EACH_EQ(lhs, rhs);                 \
    } while(0)

#endif

/* ---------------------------------------------------------------------------------------------- */
/* test manager specific APIs */

#define __PST_BLOCK(name) void __PST_BLOCK##name(void)
#define __PST_CALL_BLOCK(name) __PST_BLOCK##name()
#define __PST_ADD_BLOCK(name)
#define __PST_ASSESSMENT_ID(id)

#endif /* __POLYSPACE__PSTUNIT_H */

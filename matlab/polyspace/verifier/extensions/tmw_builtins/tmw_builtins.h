/*
 * Copyright 2024 The MathWorks, Inc.
 */

#ifndef _TMW_BUILTINS_H_
#define _TMW_BUILTINS_H_

#pragma tmw no_emit
#pragma tmw code_instrumentation off
#pragma tmw push(builtins)

#define GNU_LE(major)          (__GNUC__ <= (major))
#define GNU_LE2(major,minor)   (__GNUC__ < (major) || (__GNUC__ == (major) && __GNUC_MINOR__ <= (minor)))
#define GNU_GE(major)          (__GNUC__ >= (major))
#define GNU_GE2(major,minor)   (__GNUC__ > (major) || (__GNUC__ == (major) && __GNUC_MINOR__ >= (minor)))
#define CLANG_LE(major)        (__tmw_clang_major__ <= (major))
#define CLANG_LE2(major,minor) (__tmw_clang_major__ < (major) || (__tmw_clang_major__ == (major) && __tmw_clang_minor__ <= (minor)))
#define CLANG_GE(major)        (__tmw_clang_major__ >= (major))
#define CLANG_GE2(major,minor) (__tmw_clang_major__ > (major) || (__tmw_clang_major__ == (major) && __tmw_clang_minor__ >= (minor)))

#include "../__polyspace_common.h"

#include "tmw_builtins_common.h"

#if defined(__x86_64__)

  #include "tmw_builtins_x86_64.h"

#elif defined(__ARM_ARCH)

  #define __edg_neon_vector_type__(T,n) __attribute__((neon_vector_type(n))) T
  #define __edg_neon_polyvector_type__(T,n) __attribute__((neon_polyvector_type(n))) T
  #define __edg_scalable_vector_type__(T,n) __attribute__((neon_polyvector_type(n))) T

  #include "tmw_builtins_arm.h"
  #if defined(__ARM_32BIT_STATE)
  #include "tmw_builtins_arm_32.h"
  #elif defined(__ARM_64BIT_STATE)
  #include "tmw_builtins_arm_64.h"
  #endif

  #ifdef __ARM_NEON
  #include "tmw_builtins_arm_neon.h"
  #ifndef __aarch64__
  #include "tmw_builtin_types_arm_neon32.h"
  #include "tmw_builtins_arm_neon32.h"
  #elif defined(__TMW_HAS_INT128__)
  /* Only include ARM64 Neon headers if __int128 is available. */
  #include "tmw_builtin_types_arm_neon64.h"
  #include "tmw_builtins_arm_neon64.h"
  #endif
  #endif /* __ARM_NEON */

  #undef __edg_neon_vector_type__
  #undef __edg_neon_polyvector_type__
  #undef __edg_scalable_vector_type__

#endif /* __ARM_ARCH */

#undef GNU_LE
#undef GNU_LE2
#undef GNU_GE
#undef GNU_GE2
#undef CLANG_LE
#undef CLANG_LE2
#undef CLANG_GE
#undef CLANG_GE2

#pragma tmw pop(builtins)
#pragma tmw code_instrumentation on
#pragma tmw emit

#endif /* _TMW_BUILTINS_H_ */

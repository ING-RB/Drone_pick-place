/* Copyright 2024 The MathWorks, Inc. */
#include <stdint.h>
typedef void* __m128;
typedef float single;
typedef int32_t int32;
typedef uint32_t uint32;

//SSE --> xmmintrin.h
__m128   _mm_add_ps( __m128 u1, __m128 u2  );
__m128   _mm_and_ps( __m128 u1, __m128 u2  );
__m128   _mm_cmpeq_ps( __m128 u1, __m128 u2  );
__m128   _mm_cmpge_ps( __m128 u1, __m128 u2  );
__m128   _mm_cmpgt_ps( __m128 u1, __m128 u2  );
__m128   _mm_cmple_ps( __m128 u1, __m128 u2  );
__m128   _mm_cmplt_ps( __m128 u1, __m128 u2  );
__m128   _mm_cmpord_ps( __m128 u1, __m128 u2  );
__m128   _mm_cmpneq_ps( __m128 u1, __m128 u2  );
__m128   _mm_div_ps( __m128 u1, __m128 u2  );
__m128   _mm_loadu_ps( const single* u1  );
__m128   _mm_max_ps( __m128 u1, __m128 u2  );
__m128   _mm_min_ps( __m128 u1, __m128 u2  );
__m128   _mm_mul_ps( __m128 u1, __m128 u2  );
__m128   _mm_or_ps( __m128 u1, __m128 u2  );
__m128   _mm_set1_ps( single u1  );
__m128   _mm_set_ps( single u1, single u2, single u3, single u4  );
__m128   _mm_shuffle_ps( __m128 u1, __m128 u2, uint32 u3  );
__m128   _mm_sqrt_ps( __m128 u1  );
__m128   _mm_sub_ps( __m128 u1, __m128 u2  );
__m128   _mm_xor_ps( __m128 u1, __m128 u2  );
void _mm_storeu_ps( single* u1, __m128 u2  );

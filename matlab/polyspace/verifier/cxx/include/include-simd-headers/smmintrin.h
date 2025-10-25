/* Copyright 2024 The MathWorks, Inc. */
typedef void* __m128;
typedef void* __m128i;
typedef void* __m128d;

//SSE4.1 -> smmintrin.h
__m128d   _mm_blendv_pd( __m128d u2, __m128d u3, __m128d u1  );
__m128d   _mm_ceil_pd( __m128d u1  );
__m128d   _mm_floor_pd( __m128d u1  );
__m128i   _mm_blendv_epi8( __m128i u2, __m128i u3, __m128i u1  );
__m128i   _mm_cmpeq_epi64( __m128i u1, __m128i u2  );
__m128i   _mm_cvtepi16_epi32( __m128i u1  );
__m128i   _mm_cvtepi16_epi64( __m128i u1  );
__m128i   _mm_cvtepi32_epi64( __m128i u1  );
__m128i   _mm_cvtepi8_epi16( __m128i u1  );
__m128i   _mm_cvtepi8_epi32( __m128i u1  );
__m128i   _mm_cvtepi8_epi64( __m128i u1  );
__m128i   _mm_cvtepu16_epi32( __m128i u1  );
__m128i   _mm_cvtepu16_epi64( __m128i u1  );
__m128i   _mm_cvtepu32_epi64( __m128i u1  );
__m128i   _mm_cvtepu8_epi16( __m128i u1  );
__m128i   _mm_cvtepu8_epi32( __m128i u1  );
__m128i   _mm_cvtepu8_epi64( __m128i u1  );
__m128i   _mm_max_epi32( __m128i u1, __m128i u2  );
__m128i   _mm_max_epi8( __m128i u1, __m128i u2  );
__m128i   _mm_min_epi32( __m128i u1, __m128i u2  );
__m128i   _mm_min_epi8( __m128i u1, __m128i u2  );
__m128i   _mm_mullo_epi32( __m128i u1, __m128i u2  );
__m128   _mm_blendv_ps( __m128 u2, __m128 u3, __m128 u1  );
__m128   _mm_ceil_ps( __m128 u1  );
__m128   _mm_floor_ps( __m128 u1  );

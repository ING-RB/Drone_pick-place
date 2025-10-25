/* Copyright 2020-2024 The MathWorks, Inc. */
#ifndef __MW_GPUFUNCTIONIMPL_UTIL_H__
#define __MW_GPUFUNCTIONIMPL_UTIL_H__

#ifdef __CUDACC__

#define MW_GC_DEVICE __device__

template <class T>
MW_GC_DEVICE T mwGpuSign(T x) {
    if (isnan(x)) {
        return x;
    }
    T sgn = (T)((int)(x > 0) - (int)(x < 0));
    return sgn;
}


#endif
#endif

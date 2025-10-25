/* Copyright 2018-2024 The MathWorks, Inc. */
#ifndef __MW_CTRANSPOSE_UTIL_H__
#define __MW_CTRANSPOSE_UTIL_H__

#ifdef __CUDACC__

#define MW_DEVICE  __device__
#define TILE_SIZE  32
#define BLOCKDIM_X 32
#define BLOCKDIM_Y 8

template <typename T>
__global__ void ctransposeKernel2DColMajor(const T* idata, T* odata, int nrows, int ncols) {
    __shared__ T tile[TILE_SIZE][TILE_SIZE + 1];

    // 2D coordinates (x, y) => (rows, cols)
    int x = blockIdx.x * TILE_SIZE + threadIdx.x; // rows
    int y = blockIdx.y * TILE_SIZE + threadIdx.y; // cols

    for (int j = 0; j < TILE_SIZE; j += BLOCKDIM_Y) {
        if (y + j < ncols && x < nrows) {
            T var = idata[(y + j) * nrows + x];
            var.im = -1 * var.im;
            tile[threadIdx.x][threadIdx.y + j] = var;
        }
    }

    __syncthreads();

    x = blockIdx.y * TILE_SIZE + threadIdx.x;
    y = blockIdx.x * TILE_SIZE + threadIdx.y;

    for (int j = 0; j < TILE_SIZE; j += BLOCKDIM_Y) {
        if (y + j < nrows && x < ncols) {
            odata[(y + j) * ncols + x] = tile[threadIdx.y + j][threadIdx.x];
        }
    }
}

template <typename T>
__global__ void ctransposeKernel2DRowMajor(const T* idata, T* odata, int nrows, int ncols) {
    __shared__ T tile[TILE_SIZE][TILE_SIZE + 1];

    // 2D coordinates (y, x) => (rows, cols)
    int x = blockIdx.x * TILE_SIZE + threadIdx.x; // cols
    int y = blockIdx.y * TILE_SIZE + threadIdx.y; // rows

    for (int j = 0; j < TILE_SIZE; j += BLOCKDIM_Y) {
        if (y + j < nrows && x < ncols) {
            T var = idata[(y + j) * ncols + x];
            var.im = -1 * var.im;
            tile[threadIdx.y + j][threadIdx.x] = var;
        }
    }

    __syncthreads();

    x = blockIdx.y * TILE_SIZE + threadIdx.x;
    y = blockIdx.x * TILE_SIZE + threadIdx.y;

    for (int j = 0; j < TILE_SIZE; j += BLOCKDIM_Y) {
        if (y + j < ncols && x < nrows) {
            odata[(y + j) * nrows + x] = tile[threadIdx.x][threadIdx.y + j];
        }
    }
}

template <class T>
void transposeImplConjugate(const T* src, T* dest, int nrows, int ncols, bool isRowMajor) {

    if (nrows == 1 || ncols == 1) {
        // scalar or 1-d vector
        cudaMemcpy(dest, src, sizeof(T) * nrows * ncols, cudaMemcpyDeviceToDevice);
    } else {
        // 2d matrix
        if (isRowMajor) {
            dim3 dimGrid((ncols - 1) / TILE_SIZE + 1, (nrows - 1) / TILE_SIZE + 1);
            dim3 dimBlock(BLOCKDIM_X, BLOCKDIM_Y, 1);
            ctransposeKernel2DRowMajor<<<dimGrid, dimBlock>>>(src, dest, nrows, ncols);
        } else {
            dim3 dimGrid((nrows - 1) / TILE_SIZE + 1, (ncols - 1) / TILE_SIZE + 1);
            dim3 dimBlock(BLOCKDIM_X, BLOCKDIM_Y, 1);
            ctransposeKernel2DColMajor<<<dimGrid, dimBlock>>>(src, dest, nrows, ncols);
        }
    }
}

template <class T>
MW_DEVICE void transposeImplConjugateDevice(const T* src,
                                            T* dest,
                                            int nrows,
                                            int ncols,
                                            bool isRowMajor) {

    if (nrows == 1 || ncols == 1) {
        // scalar or 1-d vector
        memcpy(dest, src, sizeof(T) * nrows * ncols);
    } else {
        // 2d matrix
        if (isRowMajor) {
            for (int rowid = 0; rowid < nrows; rowid++) {
                for (int colid = 0; colid < ncols; colid++) {
                    T var = src[rowid * ncols + colid];
                    var.im = -1 * var.im;
                    dest[colid * nrows + rowid] = var;
                }
            }
        } else {
            for (int colid = 0; colid < ncols; colid++) {
                for (int rowid = 0; rowid < nrows; rowid++) {
                    T var = src[colid * nrows + rowid];
                    var.im = -1 * var.im;
                    dest[rowid * ncols + colid] = var;
                }
            }
        }
    }
}


template <class T>
__host__ __device__ void gpu_shared_mem_ctranspose(const T* src,
                                                   T* dest,
                                                   int nrows,
                                                   int ncols,
                                                   bool isRowMajor) {
    bool isDevice;
#ifdef __CUDA_ARCH__
    isDevice = true;
#else
    isDevice = false;
#endif

    if (nrows == 0 || ncols == 0) {
        return;
    }

    if (isDevice) {
        transposeImplConjugateDevice<T>(src, dest, nrows, ncols, isRowMajor);
    } else {
        transposeImplConjugate<T>(src, dest, nrows, ncols, isRowMajor);
    }
}

#endif

#endif

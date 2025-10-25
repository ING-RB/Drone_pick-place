function c = cat(dim,varargin)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.

%#codegen
narginchk(2,Inf);
coder.internal.prefer_const(dim);
coder.internal.assert(coder.internal.isConst(dim), ...
                      'Coder:toolbox:dimNotConst');
coder.internal.assertValidDim(dim);
intdim = coder.const(coder.internal.indexInt(dim));
coder.internal.assert(intdim == ones('like',intdim) || intdim == cast(2,'like',intdim), ...
                      'MATLAB:catenate:sparseDimensionBad');
strictEmpty = true;
[ceg, cnnz, cnrows, cncols] = catCheck(intdim,strictEmpty,varargin{:});
c = spcat(intdim,ceg,cnnz,cnrows,cncols,varargin{:});
coder.internal.sparse.sanityCheck(c);

%--------------------------------------------------------------------------

function n = prodsize(x,opt,dim)
%MATLAB Code Generation Private Function

%   Calculate a partial product of the elements of the vector size(x).
%
%   1. n = prodsize(x,'above',dim)
%      returns n = size(x,dim+1) * size(x,dim+2) * ... * size(x,ndims(x)).
%
%   2. n = prodsize(x,'below',dim)
%      returns n = size(x,1) * size(x,2) * ... * size(x,dim-1).
%
%   3. n = prodsize(x,'except',dim)
%      returns n = prodsize(x,'below',dim) * prodsize(x,'above',dim)
%
%   The output n belongs to coder.internal.indexIntClass.
%
%   THIS FUNCTION DOES NO ERROR CHECKING. It requires:
%   1. OPT is 'except', 'above', or 'below', case sensitive. If you supply
%      an invalid OPT input, it will default to 'above'.
%   2. DIM is valid dimension argument, i.e. a real, positive, integer
%      scalar in indexing range. Zero is *not* a valid DIM input.

%   Copyright 2009-2021 The MathWorks, Inc.
%#codegen

if isempty(coder.target)
    % Use MATLAB-optimized implementation in MATLAB for speed.
    n = matlab_prodsize(x,opt,dim);
    return
end
coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
coder.inline('always');
coder.internal.prefer_const(opt,dim);
ONE = coder.internal.indexInt(1);
EXCEPT = strcmp(opt,'except');
BELOW = strcmp(opt,'below');
NDIMS = coder.const(coder.internal.indexInt(coder.internal.ndims(x)));
if dim > NDIMS
    if EXCEPT || BELOW
        n = coder.internal.indexInt(numel(x));
    else % if ABOVE
        n = ONE;
    end
elseif EXCEPT
    sx = size(x);
    sx(dim) = 1;
    n = coder.internal.indexInt(numel(false(sx)));
elseif BELOW
    n = ONE;
    upperDim = coder.internal.indexInt(dim) - 1;
    if coder.internal.isConst(dim)
        coder.unroll;
    end
    for k = ONE:upperDim
        n = n*coder.internal.indexInt(size(x,k));
    end
else % if ABOVE
    n = ONE;
    lowerDim = coder.internal.indexInt(dim) + 1;
    if coder.internal.isConst(dim)
        coder.unroll;
    end
    for k = lowerDim:NDIMS
        n = n*coder.internal.indexInt(size(x,k));
    end
end

%--------------------------------------------------------------------------

function n = matlab_prodsize(x,opt,dim)
% Use MATLAB-oriented idioms.
if strcmp(opt,'except')
    n = coder.internal.indexInt(numel(x)/size(x,dim));
elseif strcmp(opt,'below')
    sx = size(x);
    n = coder.internal.indexInt(prod(sx(1:min(ndims(x),dim-1))));
else
    sx = size(x);
    n = coder.internal.indexInt(prod(sx(dim+1:end)));
end

%--------------------------------------------------------------------------

function c = horzcat(varargin)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.

%#codegen
% Since this is a sparse method, there must be a sparse argument implying there
% must be at least one input
narginchk(1,Inf);
dim = coder.internal.indexInt(2);
strictEmpty = false;
[ceg,cnnz,cnrows,cncols] = catCheck(dim,strictEmpty,varargin{:});
c = spcat(dim,ceg,cnnz,cnrows,cncols,varargin{:});
coder.internal.sparse.sanityCheck(c);

%--------------------------------------------------------------------------

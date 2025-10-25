function o = ones(varargin)
%SE2.ONES Create se2 array of identity transformations
%
%   T = SE2.ONES(N) returns an N-by-N se2 matrix with each element an identity
%   transformation (identity matrix).
%
%   T = SE2.ONES(M,N) returns an M-by-N se2 matrix of identity transformations.
%
%   T = SE2.ONES(M,N,K,...) returns an M-by-N-by-K-by-... se2 array
%   of identity transformations.
%
%   T = SE2.ONES(M,N,K,...,CLASSNAME) returns an M-by-N-by-K-by-...
%   se2 array of identity transformations with the underlying class
%   specified by CLASSNAME.
%
%
%   T = ONES("se2") returns a scalar se2 identity transformation.
%
%   T = ONES(N,"se2") returns an N-by-N se2 matrix with each element an identity
%   transformation (identity matrix).
%
%   T = ONES(SZ,"se2") returns an array of se2 identities where the size
%   vector, SZ, defines size(T).
%
%   T = ONES(SZ1,...,SZN,"se2") returns a SZ1-by-...-by-SZN array of SE2
%   identities where SZ1,...,SZN indicate the size of each dimension.
%
%   T = ONES(___,"like",prototype,"se2") specifies the underlying class of
%   the returned se2 array to be the same as the underlying class of the
%   se2 PROTOTYPE.

%   Copyright 2022-2024 The MathWorks, Inc.

    x = ones(varargin{:});
    coder.internal.assert(isa(x,"float"), "shared_spatialmath:matobj:SingleDouble", "se2", class(x));

    % Create identity se2 transforms for each 1 in the input
    oneMat = eye(se2.Dim, "like", x);
    allMats = repmat(oneMat, 1, 1, numel(x));

    o = se2.fromMatrix(allMats,size(x));

end

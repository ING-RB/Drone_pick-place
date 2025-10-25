function o = ones(varargin)
%SE3.ONES Create se3 array of identity transformations
%
%   T = SE3.ONES(N) returns an N-by-N se3 matrix with each element an identity
%   transformation (identity matrix).
%
%   T = SE3.ONES(M,N) returns an M-by-N se3 matrix of identity transformations.
%
%   T = SE3.ONES(M,N,K,...) returns an M-by-N-by-K-by-... se3 array
%   of identity transformations.
%
%   T = SE3.ONES(M,N,K,...,CLASSNAME) returns an M-by-N-by-K-by-...
%   se3 array of identity transformations with the underlying class
%   specified by CLASSNAME.
%
%
%   T = ONES("se3") returns a scalar se3 identity transformation.
%
%   T = ONES(N,"se3") returns an N-by-N se3 matrix with each element an identity
%   transformation (identity matrix).
%
%   T = ONES(SZ,"se3") returns an array of se3 identities where the size
%   vector, SZ, defines size(T).
%
%   T = ONES(SZ1,...,SZN,"se3") returns a SZ1-by-...-by-SZN array of SE3
%   identities where SZ1,...,SZN indicate the size of each dimension.
%
%   T = ONES(___,"like",prototype,"se3") specifies the underlying class of
%   the returned se3 array to be the same as the underlying class of the
%   se3 PROTOTYPE.

%   Copyright 2022-2024 The MathWorks, Inc.

    x = ones(varargin{:});
    coder.internal.assert(isa(x,"float"), "shared_spatialmath:matobj:SingleDouble", "se3", class(x));

    % Create identity se3 transforms for each 1 in the input
    oneMat = eye(4, "like", x);
    allMats = repmat(oneMat, 1, 1, numel(x));

    o = se3.fromMatrix(allMats,size(x));

end

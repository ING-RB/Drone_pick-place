function o = ones(varargin)
%SO3.ONES Create so3 array of identity rotations
%
%   T = SO3.ONES(N) returns an N-by-N so3 matrix with each element an identity
%   rotation (identity matrix).
%
%   T = SO3.ONES(M,N) returns an M-by-N so3 matrix of identity rotations.
%
%   T = SO3.ONES(M,N,K,...) returns an M-by-N-by-K-by-... so3 array
%   of identity rotations.
%
%   T = SO3.ONES(M,N,K,...,CLASSNAME) returns an M-by-N-by-K-by-...
%   so3 array of identity rotations with the underlying class
%   specified by CLASSNAME.
%
%
%   T = ONES("so3") returns a scalar so3 identity rotation.
%
%   T = ONES(N,"so3") returns an N-by-N so3 matrix with each element an identity
%   rotation (identity matrix).
%
%   T = ONES(SZ,"so3") returns an array of so3 identities where the size
%   vector, SZ, defines size(T).
%
%   T = ONES(SZ1,...,SZN,"so3") returns a SZ1-by-...-by-SZN array of SO3
%   identities where SZ1,...,SZN indicate the size of each dimension.
%
%   T = ONES(___,"like",prototype,"so3") specifies the underlying class of
%   the returned so3 array to be the same as the underlying class of the
%   so3 PROTOTYPE.

%   Copyright 2022-2024 The MathWorks, Inc.

    x = ones(varargin{:});
    coder.internal.assert(isa(x,"float"), "shared_spatialmath:matobj:SingleDouble", "so3", class(x));

    % Create identity so3 transforms for each 1 in the input
    oneMat = eye(3, "like", x);
    allMats = repmat(oneMat, 1, 1, numel(x));

    o = so3.fromMatrix(allMats,size(x));

end

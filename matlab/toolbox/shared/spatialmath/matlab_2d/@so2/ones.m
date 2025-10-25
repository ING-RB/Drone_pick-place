function o = ones(varargin)
%SO2.ONES Create so2 array of identity rotations
%
%   T = SO2.ONES(N) returns an N-by-N so2 matrix with each element an identity
%   rotation (identity matrix).
%
%   T = SO2.ONES(M,N) returns an M-by-N so2 matrix of identity rotations.
%
%   T = SO2.ONES(M,N,K,...) returns an M-by-N-by-K-by-... so2 array
%   of identity rotations.
%
%   T = SO2.ONES(M,N,K,...,CLASSNAME) returns an M-by-N-by-K-by-...
%   so2 array of identity rotations with the underlying class
%   specified by CLASSNAME.
%
%
%   T = ONES("so2") returns a scalar so2 identity rotation.
%
%   T = ONES(N,"so2") returns an N-by-N so2 matrix with each element an identity
%   rotation (identity matrix).
%
%   T = ONES(SZ,"so2") returns an array of so2 identities where the size
%   vector, SZ, defines size(T).
%
%   T = ONES(SZ1,...,SZN,"so2") returns a SZ1-by-...-by-SZN array of SO2
%   identities where SZ1,...,SZN indicate the size of each dimension.
%
%   T = ONES(___,"like",prototype,"so2") specifies the underlying class of
%   the returned so2 array to be the same as the underlying class of the
%   so2 PROTOTYPE.

%   Copyright 2022-2024 The MathWorks, Inc.

    x = ones(varargin{:});
    coder.internal.assert(isa(x,"float"), "shared_spatialmath:matobj:SingleDouble", "so2", class(x));

    % Create identity so2 transforms for each 1 in the input
    oneMat = eye(so2.Dim, "like", x);
    allMats = repmat(oneMat, 1, 1, numel(x));

    o = so2.fromMatrix(allMats,size(x));

end

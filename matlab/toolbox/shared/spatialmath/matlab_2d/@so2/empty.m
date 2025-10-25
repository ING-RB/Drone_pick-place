function obj = empty(varargin)
%EMPTY Create an empty array of so2 rotations
%   T = SO2.EMPTY returns an empty 0-by-0 array of so2 rotations.
%
%   T = SO2.EMPTY(M,N,P,...) returns an empty array of so2 rotations
%   with the specified dimensions. At least one of the dimensions
%   must be 0.
%
%   T = SO2.EMPTY([M,N,P,...]) using size vector [M,N,P,...] returns
%   an empty array of so2 rotations with the specified dimensions. At
%   least one of the dimensions must be 0.
%
%   Use EMPTY to create an empty array of so2 rotations.
%   An empty array is useful when you need to create an array of
%   rotations with a shape, but with
%   no data.  For example, use EMPTY to produce an empty array in which
%   some dimensions are not zero.
%
%   EMPTY is not supported in code generation.

%   Copyright 2022-2024 The MathWorks, Inc.

    M = double.empty(so2.Dim,so2.Dim,0);
    MInd = double.empty(varargin{:});
    obj = so2.fromMatrix(M, size(MInd));

end

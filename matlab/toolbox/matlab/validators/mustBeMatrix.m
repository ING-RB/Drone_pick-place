function mustBeMatrix(x)
%mustBeMatrix Validate that value is a matrix
%   mustBeMatrix(A) throws an error if A is not a matrix.
%   MATLAB calls ismatrix to determine if A is a matrix.
%
%   See also: ismatrix, mustBeVector.

%   Copyright 2024 The MathWorks, Inc.

if ~ismatrix(x)
    throwAsCaller(MException(message('MATLAB:validators:mustBeMatrix')));
end

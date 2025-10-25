function mustBeRow(x)
%mustBeRow Validate that value is a row vector
%   mustBeRow(A) throws an error if A is not a row vector.
%   MATLAB calls isrow to determine if A is a row vector.
%
%   See also: isrow, mustBeVector.

%   Copyright 2024 The MathWorks, Inc.

if ~isrow(x)
    throwAsCaller(MException(message('MATLAB:validators:mustBeRow')));
end

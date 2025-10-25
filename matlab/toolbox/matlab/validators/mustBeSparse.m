function mustBeSparse(A)
%mustBeSparse Validate that value is sparse
%   mustBeSparse(A) throws an error if A is not sparse.
%   MATLAB calls issparse to determine if A is sparse.
%
%   Class support:
%   All numeric classes, logical
%   MATLAB classes that define an issparse method.
%
%   See also: issparse, mustBeNumericOrLogical, mustBeNonsparse.

%   Copyright 2023-2024 The MathWorks, Inc.

if ~issparse(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeSparse'));
end

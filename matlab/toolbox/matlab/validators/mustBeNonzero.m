function mustBeNonzero(A)
%MUSTBENONZERO Validate that value is nonzero
%   MUSTBENONZERO(A) throws an error if A contains a value that is zero.
%
%   Class support:
%   All numeric classes, logical
%   MATLAB classes that define these methods:
%       eq, isnumeric, islogical
%
%   See also: MUSTBENUMERICORLOGICAL.

%   Copyright 2016-2024 The MathWorks, Inc.

if ~isnumeric(A) && ~islogical(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNumericOrLogical'));
end

if any(A == 0, 'all')
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNonzero'));
end

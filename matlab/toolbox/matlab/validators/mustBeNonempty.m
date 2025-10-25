function mustBeNonempty(A)
%MUSTBENONEMPTY Validate that value is nonempty
%   MUSTBENONEMPTY(A) throws an error if A is empty.
%   MATLAB calls isempty to determine if A is empty.
%
%   Class support:
%   All MATLAB classes
%
%   See also: ISEMPTY.

%   Copyright 2016-2024 The MathWorks, Inc.

if isempty(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeNonempty'));
end

function mustBeReal(A)
%MUSTBEREAL Validate that value is real
%   MUSTBEREAL(A) throws an error if A contains nonreal values.
%   MATLAB call isreal to determine if A is real.
%
%   Class support:
%   All MATLAB classes
%
%   See also: ISREAL.

%   Copyright 2016-2024 The MathWorks, Inc.

if ~isreal(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeReal'));
end

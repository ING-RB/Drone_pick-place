function mustBeBetween(A,LB,UB,varargin)
% Syntax:
%     TF = mustBeBetween(A,LB,UB)
%     TF = mustBeBetween(A,LB,UB,intervalType)
%     TF = mustBeBetween(___,Name=Value)
%
%     Name-Value Arguments for tabular inputs:
%         DataVariables
%
% For more information, see documentation

%   Copyright 2024 The MathWorks, Inc.

if isnumeric(A) && ~isreal(A)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeReal'));
end

if isnumeric(LB) && ~isreal(LB)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeReal'));
end

if isnumeric(UB) && ~isreal(UB)
    throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeReal'));
end

if ~allbetween(A,LB,UB,varargin{:})
    if isScalarConvertibleToString(LB) && isScalarConvertibleToString(UB)
        throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeBetweenScalarBounds',string(LB),string(UB)))
    else
        throwAsCaller(matlab.internal.validation.util.createValidatorException('MATLAB:validators:mustBeBetween'));
    end
end
end

function stringable = isScalarConvertibleToString(input)
try
    input = string(input);
    stringable = isscalar(input) && isstring(input) && ~ismissing(input); % Prevent objects with a string method that doesn't return a string
catch
    stringable = false;
end
end
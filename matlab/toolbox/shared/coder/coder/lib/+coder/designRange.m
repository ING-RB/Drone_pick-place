function designRange(targetVar, rangeMin, rangeMax)
%CODER.DESIGNRANGE Introduce design range constraints on an input variable.
% 
%   CODER.DESIGNRANGE(VAR, MIN, MAX) constrains the function argument VAR to a
%   value between MIN and MAX inclusively. If VAR is non-scalar, then all
%   elements of VAR must respect the design range constraint.
%   If runtime checks are enabled (or when coding MEX), this will be enforced by
%   a runtime assertion verifying that the target variable's value is within the
%   design range.
%   Furthermore, design ranges are also used by code generation optimizations,
%   and allow code verification tools such as Polyspace, to perform more
%   accurately (when applied to input parameters of entry point functions).
%   
%   Example: 
%     Require function parameter 'x' to be within range [-5, 10]:
%
%     function foo(x)
%     coder.designRange(x, -5, 10);
%     ...

%   Copyright 2017-2019 The MathWorks, Inc.

try
    % Check common input type restrictions
    checkCommon(targetVar, rangeMin, rangeMax);
    
    % Verify that the bounds are valid
    checkBound(rangeMin);
    checkBound(rangeMax);
    coder.internal.assert(rangeMin <= rangeMax, ...
        'Coder:builtins:DesignRangeUpperBoundBelowLowerBound');
    
    % Verify that the target value is valid
    coder.internal.assert(isnumeric(targetVar), ...
        'Coder:builtins:DesignRangeMustApplyToNumericData');
    coder.internal.assert(isreal(targetVar), ...
        'Coder:builtins:ExpectedNonComplex');
    
    % Check the actual value against the bounds
    coder.internal.designRange(targetVar, double(rangeMin), double(rangeMax));
catch me
    throwAsCaller(me);
end
end

function checkCommon(varargin)
    for v = varargin
        value = v{1};
        coder.internal.assert(~isenum(value), ...
            'Coder:builtins:EnumsNotAllowedForLibraryFcn', ...
            'coder.designRange', class(value));
        coder.internal.assert(~issparse(value), ...
            'Coder:builtins:SparseNotSupported', 'coder.designRange');
    end
end

function checkBound(rangeBound)
    coder.internal.assert(isnumeric(rangeBound) && isscalar(rangeBound), ...
        'Coder:builtins:DesignRangeBoundsMustBeScalarDouble');
    coder.internal.assert(isreal(rangeBound), ...
        'Coder:builtins:NonZeroImag');
    coder.internal.assert(~isnan(rangeBound), ...
        'Coder:builtins:DesignRangeBoundsCannotBeNaN');
    if ~isinf(rangeBound)
        coder.internal.assert(rangeBound <= flintmax('double'), ...
            'Coder:builtins:ExpectedScalarNumericAsDouble');
    end
end

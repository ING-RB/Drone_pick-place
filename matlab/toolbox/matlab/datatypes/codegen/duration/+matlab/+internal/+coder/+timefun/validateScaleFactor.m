function [x,validConversion] = validateScaleFactor(x,allowNonDouble) %#codegen
%VALIDATESCALEFACTOR Validate a value by which a duration is to be scaled.
%   [X,VALIDCONVERSION] = VALIDATESCALEFACTOR(X) errors if X is not a valid
%   factor for scaling a duration. Otherwise X is returned and
%   VALIDCONVERSION is set to true.
%
%   [X,VALIDCONVERSION] = VALIDATESCALEFACTOR(X,ALLOWNONDOUBLE), when
%   ALLOWNONDOUBLE is true, converts X to a double value if it is a
%   non-double numeric scalar.

%   Copyright 2019-2020 The MathWorks, Inc.
if isa(x,'double') || islogical(x)
    coder.internal.errorIf(~isreal(x),'MATLAB:datetime:ComplexNumeric')
    validConversion = true;
else
    validConversion = (nargin == 2) && allowNonDouble && isnumeric(x);
    coder.internal.errorIf(~isreal(x),'MATLAB:datetime:ComplexNumeric')
    if validConversion
        x = double(x); % days -> ms
    end
end
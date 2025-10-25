function x = validateScaleFactor(x,allowNonDouble)
%VALIDATESCALEFACTOR Validate a value by which a duration is to be scaled.
%   X = VALIDATESCALEFACTOR(X) errors if X is not a valid factor for
%   scaling a duration. Otherwise X is returned.
%
%   X = VALIDATESCALEFACTOR(X,ALLOWNONDOUBLE), when ALLOWNONDOUBLE is true,
%   converts X to a double value if it is a non-double numeric scalar.

%   Copyright 2014-2020 The MathWorks, Inc.

try
    
    if isa(x,'double') || islogical(x)
        if ~isreal(x)
            error(message('MATLAB:datetime:ComplexNumeric'));
        end
    elseif (nargin == 2) && allowNonDouble && isnumeric(x)
        if ~isreal(x)
            error(message('MATLAB:datetime:ComplexNumeric'));
        end
        x = double(x); % days -> ms
    else
        error(message('MATLAB:datetime:DurationConversion'));
    end
    
catch ME
    throwAsCaller(ME);
end

function c = mtimes(a,b)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.validateScaleFactor
import matlab.internal.datatypes.throwInstead

% Numeric input interpreted as a scale factor.
if isa(a,'duration')
    if isa(b,'duration')
        error(message('MATLAB:duration:DurationMultiplicationNotDefined'));
    else
        try
            b = validateScaleFactor(b);
        catch ME
            throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:duration:MultiplicationNotDefined',class(a),class(b)));
        end
        c = a;
        c.millis = a.millis * b;
    end
elseif isa(b,'duration')
    try
        a = validateScaleFactor(a);
    catch ME
        throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:duration:MultiplicationNotDefined',class(a),class(b)));
    end
    c = b;
    c.millis = a * b.millis;
end

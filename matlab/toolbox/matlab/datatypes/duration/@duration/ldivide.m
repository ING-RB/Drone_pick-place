function c = ldivide(a,b)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.validateScaleFactor
import matlab.internal.datatypes.throwInstead

if isa(a,'duration')
    if isa(b,'duration')
        c = a.millis .\ b.millis; % unitless numeric result
    else
        error(message('MATLAB:duration:DurationDivisionNotDefined',class(b)));
    end
else % isa(b,'duration')
    % Numeric input a is interpreted as a scale factor.
    try
        a = validateScaleFactor(a);
    catch ME
        throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:duration:DivisionNotDefined',class(a),class(b)));
    end
    c = b;
    c.millis = a .\ b.millis;
end

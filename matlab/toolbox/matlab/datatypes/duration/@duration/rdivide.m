function c = rdivide(a,b)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.validateScaleFactor
import matlab.internal.datatypes.throwInstead

if isa(a,'duration')
    if isa(b,'duration')
        c = a.millis ./ b.millis; % unitless numeric result
    else
        % Numeric input b is interpreted as a scale factor.
        try
            b = validateScaleFactor(b);
        catch ME
            throwInstead(ME,'MATLAB:datetime:DurationConversion',message('MATLAB:duration:DivisionNotDefined',class(a),class(b)));
        end
        c = a;
        c.millis = a.millis ./ b;
    end
else % isa(b,'duration')
    error(message('MATLAB:duration:DurationDivisionNotDefined',class(a)));
end

function [amillis,bmillis,template] = compareUtil(a,b)
%COMPAREUTIL Convert durations into values that can be compared directly.
%   [AMILLIS,BMILLIS,TEMPLATE] = COMPAREUTIL(A,B) returns the milliseconds
%   corresponding to A and B in AMILLIS and BMILLIS respectively and a
%   TEMPLATE duration, which has the same format property as the duration
%   object occuring first in the input arguments. If one of the inputs is
%   numeric or logical, it is converted into milliseconds by treating it as
%   a datenum. If one of the inputs is a string or char array, it is
%   converted into milliseconds by treating it as a text representation of
%   a duration.

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.throwInstead
try
    % Convert to seconds.  Numeric input interpreted as a number of days.
    if isa(a,'duration')
        template = a;
        % When b is missing, we cast to a duration NaN. If a is missing,
        % dispatching goes to the missing relop which handles the necessary
        % casting and redispatch.
        if strcmp(class(b),'missing') %#ok<STISA>
            b = nan(size(b));
        end
        [amillis,bmillis] = convert(template,b);
    else % b must have been a duration
        template = b;
        [bmillis,amillis] = convert(template,a);
    end
catch ME
    % Rethrow invalid comparison with arguments in the right order. However,
    % MATLAB:duration:AutoConvertString is left alone.
    throwAsCaller(throwInstead(ME, ...
        {'MATLAB:duration:InvalidComparison','MATLAB:datetime:DurationConversion'}, ... 
        message('MATLAB:duration:InvalidComparison',class(a),class(b))));
end
end


%-----------------------------------------------------------------------
function [amillis,bmillis] = convert(template,b)
amillis = template.millis;
if isa(b,'duration')
    bmillis = b.millis;
elseif isnumeric(b) || islogical(b)
    bmillis = matlab.internal.datetime.datenumToMillis(b);
else
    bmillis = detectFormatFromData(b,template);
end
end

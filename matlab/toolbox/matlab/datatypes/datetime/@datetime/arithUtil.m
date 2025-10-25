function [a,b] = arithUtil(a,b)
%

%ARITHUTIL Convert a pair of values into datetimes in order to perform arithmetic.
%   [A,B] = ARITHUTIL(A,B) returns datetimes corresponding to A and B. If
%   one of the inputs is a string or char array, it is converted into a
%   datetime by treating it as a date string.

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isText

try

    if isa(a,'datetime') && isa(b,'datetime')
        checkCompatibleTZ(a.tz,b.tz);

    % Convert date strings to datetime, letting conversion errors happen. If the
    % strings are converted to durations, the caller will handle as if they had
    % been duration values.
    elseif isText(a)
        a = autoConvertStrings(a,b,isstring(a)); % b must have been a datetime
    elseif isText(b)
        b = autoConvertStrings(b,a,isstring(b)); % a must have been a datetime
    end
    
    % Inputs that are not datetimes or strings pass through to the caller
    % and are handled there.

catch ME
    throwAsCaller(ME);
end

function [aData,bData,prototype] = compareUtil(a,b)
%

%COMPAREUTIL Convert datetimes into doubledouble values that can be compared directly.
%   [ADATA,BDATA,PROTOTYPE] = COMPAREUTIL(A,B) returns doubledouble values
%   corresponding to A and B in ADATA and BDATA respectively and a
%   PROTOTYPE datetime, which has the same metadata properties as the
%   datetime object occuring first in the input arguments. If one of the
%   inputs is a string or char array, it is converted into a value by
%   treating it as a text representation of a datetime.

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isText

try

    % Two datetime inputs must either have or not have a time zone.
    if isa(a,'datetime') && isa(b,'datetime')
        checkCompatibleTZ(a.tz,b.tz);

    % Convert date strings to datetime, letting conversion errors happen. If
    % either a or b converts to a duration, give a specific error.
    elseif isText(a)
        a = autoConvertStrings(a,b,isstring(a)); % b must have been a datetime
        if isa(a,'duration')
            error(message('MATLAB:datetime:CompareTimeOfDay'));
        end
    elseif isText(b)
        b = autoConvertStrings(b,a,isstring(b)); % a must have been a datetime
        if isa(b,'duration')
            error(message('MATLAB:datetime:CompareTimeOfDay'));
        end
    elseif strcmp(class(b),'missing') %#ok<STISA>
        % When b is missing, we cast to a datetime NaT. If a is missing,
        % dispatching goes to the missing relop which handles the necessary
        % casting and redispatch.
        b = NaT(size(b),TimeZone = a.tz);
    elseif isa(a,'duration') || isa(b,'duration')
        % If either a or b was passed in as a duration, give a specific error.
        error(message('MATLAB:datetime:CompareTimeOfDay'));
    else
        error(message('MATLAB:datetime:InvalidComparison',class(a),class(b)));
    end
    
    % Both inputs must (by now) be datetime.
    aData = a.data;
    bData = b.data;

catch ME
    throwAsCaller(ME);
end

if nargout > 2
    prototype = a;
end

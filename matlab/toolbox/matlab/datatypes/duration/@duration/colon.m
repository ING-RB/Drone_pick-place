function c = colon(a,d,b)
%

%   Copyright 2014-2024 The MathWorks, Inc.

import matlab.internal.datetime.datenumToMillis
import matlab.internal.datatypes.throwInstead

try
    if nargin < 3
        b = d;
        [millis,c] = duration.isequalUtil({a,b});
        [amillis,bmillis] = millis{:};
        dmillis = 86400*1000; % default is one day
    else
        % Numeric step input interpreted as a multiple of 24 hours.       
        [millis,c] = duration.isequalUtil({a,d,b});
        [amillis,dmillis,bmillis] = millis{:};
    end
catch ME
    if nargin > 2 && ~isa(d,'duration') && ~isa(d,'double')
        ME = throwInstead(ME, ...
            {'MATLAB:datetime:DurationConversion','MATLAB:duration:InvalidComparison'}, ...
            'MATLAB:duration:colon:NonNumericStep');
    else
        ME = throwInstead(ME, ....
            {'MATLAB:duration:InvalidComparison'}, ...
            'MATLAB:duration:colon:DurationConversion');
    end
    throw(ME); % make error seem to come from front end
end

if  ~isScalarOrTextScalar(a,amillis) || ~isScalarOrTextScalar(b,bmillis) || ~isScalarOrTextScalar(d,dmillis)
    throw(MException(message('MATLAB:duration:colon:NonScalarInputs')));
end

c.millis = colon(amillis,dmillis,bmillis);
    
end


%-----------------------------------------------------------------------
function tf = isScalarOrTextScalar(x,xMillis)
import matlab.internal.datatypes.isCharString
tf = (isscalar(xMillis) || isCharString(x) || (isduration(x)&&isempty(x)));
end

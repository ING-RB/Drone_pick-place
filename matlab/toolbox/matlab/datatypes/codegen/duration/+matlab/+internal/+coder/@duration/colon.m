function c = colon(a,d,b) %#codegen
%COLON Create equally-spaced sequence of durations.

%   Copyright 2020 The MathWorks, Inc.

if nargin < 3
    b = d;
    [millis,prototype,validComparison] = duration.isequalUtil({a,b});
    coder.internal.assert(validComparison,'MATLAB:duration:colon:DurationConversion');
    [amillis,bmillis] = millis{:};
    dmillis = 86400*1000; % default is one day
else
    % Numeric step input interpreted as a multiple of 24 hours.
    [millis,prototype,validComparison] = duration.isequalUtil({a,d,b});
    if ~validComparison
        coder.internal.assert(validComparison || isa(d,'duration') || isa(d,'double'),'MATLAB:duration:colon:NonNumericStep');
        coder.internal.assert(validComparison,'MATLAB:duration:colon:DurationConversion');
    end
    [amillis,dmillis,bmillis] = millis{:};
end

coder.internal.assert(coder.internal.isConst(size(a)) && ...
    coder.internal.isConst(size(d)) && ...
    coder.internal.isConst(size(b)),'MATLAB:duration:colon:NonScalarInputs');
coder.internal.errorIf(~isScalarOrTextScalar(a,amillis) || ...
    ~isScalarOrTextScalar(b,bmillis) || ...
    ~isScalarOrTextScalar(d,dmillis),'MATLAB:duration:colon:NonScalarInputs');

c = matlab.internal.coder.duration;
c.fmt = prototype.fmt;
c.millis = colon(amillis,dmillis,bmillis);

end


%-----------------------------------------------------------------------
function tf = isScalarOrTextScalar(x,xMillis)

tf = (isscalar(xMillis) || matlab.internal.coder.datatypes.isCharString(x) || (isduration(x)&&isempty(x)));
end

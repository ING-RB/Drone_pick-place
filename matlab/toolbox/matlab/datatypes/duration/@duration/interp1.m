function vq = interp1(x,v,xq,method,extrapVal)
%

%   Copyright 2015-2024 The MathWorks, Inc.

import matlab.internal.datatypes.throwInstead

narginchk(3,5); % interp1(V,Xq) is not supported

if nargin < 4, method = 'linear'; end

% Convert X and Xq to numeric if necessary
if isa(x,'duration') || isa(xq,'duration')
    try
        [x,xq] = duration.compareUtil(x,xq);
    catch ME
        throwInstead(ME,{'MATLAB:duration:InvalidComparison','MATLAB:duration:AutoConvertString'},message('MATLAB:duration:interp1:XandXqBothDurations'));
    end
end

% Convert V (and extrapVal, if given as a value) to durations if necessary
timey = isa(v,'duration') || (nargin == 5 && isa(extrapVal,'duration'));
if timey
    if nargin < 5 || strcmpi(extrapVal,"extrap") % extrapVal may be numeric
        vqOut = v;
        v = v.millis;
    else
        try
            [v,extrapVal,vqOut] = duration.compareUtil(v,extrapVal);
        catch ME
            throwInstead(ME,{'MATLAB:duration:InvalidComparison','MATLAB:duration:AutoConvertString'},message('MATLAB:duration:interp1:VandExtrapValBothDurations'));
        end
    end
end

% Do the interpolation on (numeric) ms.
if nargin < 5
    vq = interp1(x,v,xq,method);
else
    vq = interp1(x,v,xq,method,extrapVal);
end

% Convert output to duration.
if timey
    vqOut.millis = vq;
    vq = vqOut;
end

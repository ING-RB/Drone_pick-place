function vq = interp1(x,v,xq,method,extrapVal)
%

%   Copyright 2015-2024 The MathWorks, Inc.

import matlab.internal.datetime.datetimeAdd
import matlab.internal.datetime.datetimeMean
import matlab.internal.datetime.datetimeSubtract
import matlab.internal.datatypes.throwInstead

narginchk(3,5); % interp1(V,Xq) is not supported

if nargin < 4
    method = 'linear';
elseif isa(method,'datetime')
    % Let interp1 handle a common mistake, interp1(X,V,Xq,EXTRAPVAL)
    method = char(method);
end

needMeanCenter = ~any(strcmp(method, ["previous" "next" "nearest"]));

% If X and Xq are datetimes, convert them to numeric after making sure they're
% compatible. Either can be datetime strings if the other is datetimes.
if isa(x,'datetime') || isa(xq,'datetime')
    try
        [x,xq] = datetime.compareUtil(x,xq);
    catch ME
        throwInstead(ME,'MATLAB:datetime:InvalidComparison',message('MATLAB:datetime:interp1:XandXqBothDatetimes'));
    end
    
    % If X or Xq have a low-order part, it is better to mean-center because
    % the high-order part does not solely have enough precision to do the
    % interpolation accurately. If they do not have a low-order part, it is not
    % necessary to mean center for the 'next', 'nearest', or 'previous'
    % methods because the mean centering operation will conversely introduce roundoff.
    haveLowOrderX = ~isreal(x) && nnz(imag(x)) > 0;
    haveLowOrderXq = ~isreal(xq) && nnz(imag(xq)) > 0;
    if (needMeanCenter || haveLowOrderX || haveLowOrderXq)
        % Convert to double precision offsets from the mean x location.
        [x,xq] = dd2d(x,xq);
    end
end

% If V (and extrapVal, if given as a value) are datetimes, convert them to
% numeric after making sure they're compatible. Either can be datetime
% strings if the other is datetimes.
timey = isa(v,'datetime') || (nargin > 4 && isa(extrapVal,'datetime'));
if timey
    if nargin < 5 || strcmpi(extrapVal,"extrap")
        vqOut = v; % use as a template for the output
        if (needMeanCenter)
            v_data = v.data;
            v0 = datetimeMean(v_data(:),1,false); % v0 = mean(v(:),'includenan')
            % We round the mean to the nearest whole number to avoid introducing new
            % round-off errors into the centered values.
            v0 = round(real(v0));
            v = datetimeSubtract(v_data,v0,true); % v = milliseconds(v - v0), full precision
        else
            v = v.data;
        end
        haveLowOrder = ~isreal(v) && nnz(imag(v)) > 0;
        if haveLowOrder
            vLow = imag(v); v = real(v);
            extrapValLow = 0; % Extrapolate using zero for interp1(...,'extrap')
        end
    else
        try
            [v,extrapVal,vqOut] = datetime.compareUtil(v,extrapVal);
        catch ME
            throwInstead(ME,'MATLAB:datetime:InvalidComparison',message('MATLAB:datetime:interp1:VandExtrapValBothDatetimes'));
        end
        if (needMeanCenter)
            v0 = datetimeMean(v(:),1,false); % v0 = mean(v(:),'includenan')
            % We round the mean to the nearest whole number to avoid introducing new
            % round-off errors into the centered values.
            v0 = round(real(v0));
            v = datetimeSubtract(v,v0,true); % v = milliseconds(v - v0), full precision
            extrapVal = datetimeSubtract(extrapVal,v0,true); % extrapVal = milliseconds(extrapVal - v0)
        end
        haveLowOrder = (~isreal(v) && nnz(imag(v)) > 0) ...
            || (~isreal(extrapVal) && nnz(imag(extrapVal)) > 0);
        if haveLowOrder
            vLow = imag(v); v = real(v);
            extrapValLow = imag(extrapVal); extrapVal = real(extrapVal);
        end
    end
end

% Do the interpolation on (numeric) ms since 1970. If there's a low-order part,
% do interpolation on that separately, to be added in later. This makes
% querying the original x data return exactly the original v data.
if nargin < 5
    vq = interp1(x,v,xq,method);
    if timey && haveLowOrder
        % Extrapolate the low-order part using zero for interp1(x,v,xq,method),
        % otherwise it would end up as NaN for 'linear' and others.
        vqLow = interp1(x,vLow,xq,method,0);
    end
else % interp1(...,'extrap') or interp1(...,extrapVal)
    vq = interp1(x,v,xq,method,extrapVal);
    if timey && haveLowOrder
        vqLow = interp1(x,vLow,xq,method,extrapValLow);
    end
end

% Convert output to datetime.
if timey
    if haveLowOrder
        vq = datetimeAdd(vq,vqLow); % vq = milliseconds(vq + vqLow)
    end
    % Add back the datetime "origin"
    if (needMeanCenter)
        vqOut.data = datetimeAdd(v0,vq); % vq = v0 + milliseconds(vq)
    else
        vqOut.data = vq;
    end
    vq = vqOut;
end


%-----------------------------------------------------------------------
function [xc,xqc] = dd2d(x,xq)
import matlab.internal.datetime.datetimeMean
import matlab.internal.datetime.datetimeSubtract

% Convert double-double values to double offsets from the mean.
x0 = datetimeMean(x(:),1,false); % x0 = mean(x,'includenan')
% We round the mean to the nearest whole number to avoid introducing new
% round-off errors into the centered values.
x0 = round(real(x0));
xc = datetimeSubtract(x,x0); % x = milliseconds(x - x0)
xqc = datetimeSubtract(xq,x0); % xq = milliseconds(xq - x0)

% Double-double x values that were distinct may have become identical double
% precision xc values as an artifact of the conversion. Cannot just remove the
% duplicates, because they may have different y values. Error gracefully.
if any((diff(xc(:)) == 0) & (diff(x(:)) ~= 0))
    x = datetime.fromMillis(x(:));
    range = max(x) - min(x);
    minDiff = min(diff(x));
    error(message('MATLAB:datetime:interp1:GridPointMinimumDifference',string(range,'s'),string(minDiff,'s')));
end

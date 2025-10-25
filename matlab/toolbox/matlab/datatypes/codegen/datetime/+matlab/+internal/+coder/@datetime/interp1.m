function vq = interp1(x,v,xq,method,extrapVal) %#codegen
%INTERP1 1-D interpolation on datetimes (table lookup)

%   Copyright 2020 The MathWorks, Inc.


narginchk(3,5); % interp1(V,Xq) is not supported

if nargin < 4
    method = 'linear';
elseif isa(method,'datetime')
    % Let interp1 handle a common mistake, interp1(X,V,Xq,EXTRAPVAL)
    method = char(method);
end

needMeanCenter = ~any(strcmp(method, {'previous' 'next' 'nearest'}));

% If X and Xq are datetimes, convert them to numeric after making sure they're
% compatible. Either can be datetime strings if the other is datetimes.
if isa(x,'datetime') || isa(xq,'datetime')
    [xProcessed,xqProcessed] = datetime.compareUtil(x,xq);
    
    
    % If X or Xq have a low-order part, it is better to mean-center because
    % the high-order part does not solely have enough precision to do the
    % interpolation accurately. If they do not have a low-order part, it is not
    % necessary to mean center for the 'next', 'nearest', or 'previous'
    % methods because the mean centering operation will conversely introduce roundoff.
    haveLowOrderX = ~isreal(xProcessed) && nnz(imag(xProcessed)) > 0;
    haveLowOrderXq = ~isreal(xqProcessed) && nnz(imag(xqProcessed)) > 0;
    if (needMeanCenter || haveLowOrderX || haveLowOrderXq)
        % Convert to double precision offsets from the mean x location
        [xData,xqData] = dd2d(xProcessed,xqProcessed);
    else
        xData = real(xProcessed);
        xqData = real(xqProcessed);
    end
else
    xData = x;
    xqData = xq;
end

% If V (and extrapVal, if given as a value) are datetimes, convert them to
% numeric after making sure they're compatible. Either can be datetime
% strings if the other is datetimes.
timey = isa(v,'datetime') || (nargin > 4 && isa(extrapVal,'datetime'));
if timey
    if nargin < 5 || strcmpi(extrapVal,"extrap")
        vqDT = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized); % use v as a template for the output
        vqDT.tz = v.tz;
        vqDT.fmt = v.fmt;
        if (needMeanCenter)
            v0 = matlab.internal.coder.datetime.datetimeMean(v.data(:),1,false); % v0 = mean(v(:),'includenan')
            % We round the mean to the nearest whole number to avoid introducing new
            % round-off errors into the centered values.
            v0 = round(real(v0));
            vData = matlab.internal.coder.doubledouble.minus(v.data,v0,true); % v = milliseconds(v - v0), full precision
        else
            vData = v.data;
        end
        haveLowOrder = ~isreal(vData) && nnz(imag(vData)) > 0;
        vHi = real(vData);
        vLow = imag(vData);
        if nargin > 4
            extrapValHi = extrapVal;
            extrapValLow = 0;
        end
        if haveLowOrder
            vLow = imag(vData);
            extrapValLow = 0; % Extrapolate using zero for interp1(...,'extrap')
        end
    else
        
        [vData,extrapValData,vqDT] = datetime.compareUtil(v,extrapVal);
        
        if (needMeanCenter)
            v0 = matlab.internal.coder.datetime.datetimeMean(vData(:),1,false); % v0 = mean(v(:),'includenan')
            % We round the mean to the nearest whole number to avoid introducing new
            % round-off errors into the centered values.
            v0 = round(real(v0));
            vData = matlab.internal.coder.doubledouble.minus(vData,v0,true); % v = milliseconds(v - v0), full precision
            extrapValData = matlab.internal.coder.doubledouble.minus(extrapValData,v0,true); % extrapVal = milliseconds(extrapVal - v0)
        end
        
        haveLowOrder = (~isreal(vData) && nnz(imag(vData)) > 0) ...
            || (~isreal(extrapValData) && nnz(imag(extrapValData)) > 0);
        vHi = real(vData);
        vLow = imag(vData);
        extrapValHi = real(extrapValData);
        extrapValLow = imag(extrapValData);
        if haveLowOrder
            vLow = imag(vData);
            extrapValLow = imag(extrapValData);
        end
    end
else
    if isa(v,'duration')
        vHi = v;
    else
        vHi = real(v);
        vLow = imag(v);
    end
    if nargin > 4
        extrapValHi = extrapVal;
        extrapValLow = 0;
    end
end

% Do the interpolation on (numeric) ms since 1970. If there's a low-order part,
% do interpolation on that separately, to be added in later. This makes
% querying the original x data return exactly the original v data.
if nargin < 5
    vqHi = interp1(xData,vHi,xqData,method);
    if timey && haveLowOrder
        % Extrapolate the low-order part using zero for interp1(x,v,xq,method),
        % otherwise it would end up as NaN for 'linear' and others.
        vqLow = interp1(xData,vLow,xqData,method,0);
    else
        vqLow = imag(vqHi);
    end
else % interp1(...,'extrap') or interp1(...,extrapVal)
    vqHi = interp1(xData,vHi,xqData,method,extrapValHi);
    if timey && haveLowOrder
        vqLow = interp1(xData,vLow,xqData,method,extrapValLow);
    else
        if isa(vqHi,'duration')
            vqLow = 0;
        else
            vqLow = imag(vqHi);
        end
    end
end

% Convert output to datetime.
if timey
    if haveLowOrder
        vqData = matlab.internal.coder.doubledouble.plus(vqHi,vqLow); % vq = milliseconds(vq + vqLow)
    else
        vqData = vqHi;
    end
    % Add back the datetime "origin"
    if (needMeanCenter)
        vqDT.data = matlab.internal.coder.doubledouble.plus(v0,vqData); % vq = v0 + milliseconds(vq)
    else
        vqDT.data = vqData;
    end
    vq = vqDT;
    
else
    vq = vqHi;
end


%-----------------------------------------------------------------------
function [xc,xqc] = dd2d(x,xq)
% Convert double-double values to double offsets from the mean.
x0 = matlab.internal.coder.datetime.datetimeMean(x(:),1,false); % x0 = mean(x,'includenan')
% We round the mean to the nearest whole number to avoid introducing new
% round-off errors into the centered values.
x0 = round(real(x0));
xc = matlab.internal.coder.doubledouble.minus(x,x0,false); % x = milliseconds(x - x0)
xqc = matlab.internal.coder.doubledouble.minus(xq,x0,false); % xq = milliseconds(xq - x0)

% Double-double x values that were distinct may have become identical double
% precision xc values as an artifact of the conversion. Cannot just remove the
% duplicates, because they may have different y values. Error gracefully.
if any((diff(xc(:)) == 0) & (diff(x(:)) ~= 0)) % calls complex diff, that's OK
    xdt = datetime.fromMillis(x(:));
    range = max(xdt) - min(xdt);
    minDiff = min(diff(xdt));
    rangeStr = sprintf('%.5g',seconds(range));
    minDiffStr = sprintf('%.5g',seconds(minDiff));
    coder.internal.error('MATLAB:datetime:interp1:GridPointMinimumDifference',rangeStr,minDiffStr);
end

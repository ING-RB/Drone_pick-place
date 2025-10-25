function [pp, toa] = mkcapp(L, v, entryTime, waitTimes)
% MATLABSHARED.TRACKING.INTERNAL.SCENARIO.MKTRAPP - make constant acceleration piecewise polynomial
%
% This file is for internal use only and may be removed in a future release.

% Copyright 2022, The MathWorks, Inc.

%#codegen

% compute initial, final and average acceleration between each segment
vi = v(1:end-1);
vf = v(2:end);
vavg = (vi + vf) ./ 2;

% compute the acceleration and duration of each segment
a = (vf - vi) .* vavg ./ L;
dt = L ./ vavg;
a(~isfinite(a)) = 0;
dt(~isfinite(dt)) = 0;

if nargin < 4
    % use vectorized version
    toa = cumsum([entryTime; dt]);
    pp = mkpp(toa,horzcat(zeros(size(a)),a/2,vi,cumsum([0;L(1:end-1)])));
else
    % pre-allocate
    breaks = zeros(2*numel(v),1);
    coeffs = zeros(2*numel(v)-1,4);
    
    index = 0;
    
    currentDistance = 0;
    currentTime = entryTime;
    
    for i=1:numel(dt)
        if waitTimes(i) ~= 0
            index = index + 1;
    
            breaks(index) = currentTime;
            coeffs(index, 1) = 0;
            coeffs(index, 2) = 0;
            coeffs(index, 3) = 0;
            coeffs(index, 4) = currentDistance;
    
            currentTime = currentTime + waitTimes(i);
        end
        index = index + 1;
    
        breaks(index) = currentTime;
        coeffs(index,1) = 0;
        coeffs(index,2) = a(i)/2;
        coeffs(index,3) = v(i);
        coeffs(index,4) = currentDistance;
    
        currentTime = currentTime + dt(i);
        currentDistance = currentDistance + L(i);
    end
    
    nCoeffs = index;
    
    if waitTimes(end) ~= 0
        index = index + 1;
    
        breaks(index) = currentTime;
        coeffs(index, 1) = 0;
        coeffs(index, 2) = 0;
        coeffs(index, 3) = 0;
        coeffs(index, 4) = currentDistance;
    
        currentTime = currentTime + waitTimes(end);
    end
    
    index = index + 1;
    breaks(index) = currentTime;
    nBreaks = index;
    

    if coder.target('MATLAB') || coder.internal.eml_option_eq('UseMalloc','VariableSizeArrays')
        % construct polynomial
        pp = mkpp(breaks(1:nBreaks),coeffs(1:nCoeffs,:));
    else
        % pad with penultimate break and its coefficients
        breaks(end) = breaks(nBreaks-1);
        breaks(nBreaks:end-1) = breaks(nBreaks-1);

        % provide hint to MATLAB Coder
        coeffs(nBreaks:end,1) = coeffs(nBreaks,1);
        coeffs(nBreaks:end,2) = coeffs(nBreaks,2);
        coeffs(nBreaks:end,3) = coeffs(nBreaks,3);
        coeffs(nBreaks:end,4) = coeffs(nBreaks,4);
        pp = mkpp(breaks,coeffs);
    end

    % fill time of arrival vector
    toa = entryTime + cumsum([0;dt + waitTimes(1:end-1)]);
end
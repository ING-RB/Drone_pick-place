function [t,tIsUniform,scaleFactor,tgrid] = scaleSamplePoints(t)
%scaleSamplePoints Check sample points for exact uniform spacing,
% scale, and respace if non-uniform.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

% Copyright 2023 The Mathworks, Inc.

if numel(t) < 2
    tIsUniform = false;
    scaleFactor = t; % This should not be used
    tgrid = t; % This should not be used
    return
end

tIsUniform = isExactlyUniform(t);
if tIsUniform
    scaleFactor = t(2) - t(1);
    tgrid = t;
    return
else % Non-uniform sample points
    if isinteger(t)
        scaleFactor = getIntegerScaleFactor(t);
        if (t(end) > flintmax) || (t(1) < -flintmax)
            t = rescaleIntegers(t);
        else
            t = double(t);
        end
    else
        scaleFactor = (t(end) - t(1))/(length(t)-1);
    end
    tgrid = linspace(t(1), t(end), length(t))';
end
end

%--------------------------------------------------------------------------

function sf = getIntegerScaleFactor(t)
% Return the scaling factor for the window size used for auto-tuned selection
N = length(t) - 1;
if (t(1) < 0) && (t(end) < 0)
    % May lose 1 in the cast if t(1) == intmin('int64'), so determine
    % if it needs to be added back in
    padBit = uint64(t(1) == intmin('int64'));
    sf = cast((padBit + uint64(-t(1)) - uint64(-t(end))) / N, 'like', t);
elseif (t(1) > 0) && (t(end) > 0)
    % Whole vector is positive, so cast to uint64 to compute the
    % difference
    sf = cast((uint64(t(end)) - uint64(t(1))) / N, 'like', t);
else % t(1) < 0, t(end) > 0
    % May lose 1 in the cast if t(1) == intmin('int64')
    padBit = uint64(t(1) == intmin('int64'));
    sf = cast((uint64(t(end)) + padBit + uint64(-t(1))) / N, 'like', t);
end
end

%--------------------------------------------------------------------------

function td = rescaleIntegers(t)
t = matlab.internal.math.convertToUnsignedWithSameSpacing(t);
td = t - t(1);
if td(end) > flintmax
    % Approximate sample points if we can't get things aligned
    % exactly
    td = (double(td) / double(td(end)));
    % Ensure values are sorted
    for i = 2:length(td)
        if (td(i) <= td(i-1))
            td(i) = td(i-1) + eps(td(i-1));
        end
    end
else
    td = double(td);
end

end

%--------------------------------------------------------------------------

function tf = isExactlyUniform(t)
% Determine if sample points are uniformly spaced.
% This will return an empty when t is scalar

dt = diff(t);
tf = (max(dt) == min(dt));

end
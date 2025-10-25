function lazyStats = getArrayStatistics(X)
% Compute descriptive statistics for tall X, omitting nan and +/-inf

%   Copyright 2016-2018 The MathWorks, Inc.

lazyStats = [];
fX = X(isfinite(X));
lazyStats.max = max(fX, [], 'omitnan');
lazyStats.min = min(fX, [], 'omitnan');
lazyStats.numel = numel(fX);

% STD is only valid for floating-point input. Calculate in double to be safe.
lazyStats.std = std(double(fX), 'omitnan');
end

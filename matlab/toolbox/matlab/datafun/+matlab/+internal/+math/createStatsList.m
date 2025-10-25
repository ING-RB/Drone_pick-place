function [stats,statFields,isFcnHandles] = createStatsList(X,dim,isStatisticsSet,stats)
%createStatsList Convert statistics names to function handles and create a
%   list of corresponding field/display names.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2024 The MathWorks, Inc.

if ~isStatisticsSet
    stats = matlab.internal.math.getDefaultSummaryStatistics(X);
end

% Change each option to a function handle and set names appropriately
numStats = numel(stats);
statFields = strings(1,numStats);
isFcnHandles = false(1,numStats);
for jj = 1:numStats
    [stats{jj},statFields(jj),isFcnHandles(jj)] = matlab.internal.math.groupMethod2FcnHandle(stats{jj},"summary",dim);
end

if any(isFcnHandles)
    statFields = matlab.lang.makeUniqueStrings([statFields "Size" "Type" "TimeZone"],...
        [isFcnHandles false false false]);
    statFields(end-2:end) = [];
end

% Remove repeated statistics names
if isStatisticsSet && (numStats ~= 1)
    [statFields,idx] = unique(statFields,"stable");
    stats = stats(idx);
    isFcnHandles = isFcnHandles(idx);
end
end
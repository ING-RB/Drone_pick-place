function inds = timesubs2inds(subscripts,labels,tol)
% TIMESUBS2INDS Convert datetime subscripts to timetable row indices.

%   Copyright 2022 The MathWorks, Inc.

checkCompatibleTZ(subscripts.tz,labels.tz);

% Convert datetimes to numeric ms. .data will catch any durations that end up here
subsMillis = subscripts.data(:);
labelsMillis = labels.data(:);
if nargin < 3
    % Absolute tolerance of 1e-12 sec for datetime subscripting.
    tolMillis = 1e-9; % 1e-9ms == 1e-12s
else
    tolMillis = milliseconds(tol);
end

doubledoubleMinus = true;
inds = matlab.internal.tabular.timesubs2inds(subsMillis,labelsMillis,tolMillis,doubledoubleMinus);

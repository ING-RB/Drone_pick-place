function inds = timesubs2inds(subscripts,labels,tol)
% TIMESUBS2INDS Convert duration subscripts to timetable row indices.

%   Copyright 2022 The MathWorks, Inc.

% Convert durations to numeric ms. .millis will catch any datetimes that end up here
subsMillis = subscripts.millis(:);
labelsMillis = labels.millis(:);
if nargin < 3
    % Elementwise relative tolerance for duration subscripting,
    % transitioning to absolute tolerance for times smaller than 1ns. 
    tolMillis = 1000*eps*max(abs(subsMillis),1e-6); % transition at 1ns (1e-6ms) timestamps
    tolMillis(isinf(tolMillis)) = 0; % +/- Inf subscripts must match exactly
else
    tolMillis = tol.millis;
end

doubledoubleMinus = false;
inds = matlab.internal.tabular.timesubs2inds(subsMillis,labelsMillis,tolMillis,doubledoubleMinus);

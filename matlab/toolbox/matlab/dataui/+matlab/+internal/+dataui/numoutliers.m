function N = numoutliers(T,V)
% numOutliers: Helper for data cleaner app
% This function uses the defaults in the Clean Outlier Data live task to
% determine the number of outliers in a given variable V of (time)table T
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2021 The MathWorks, Inc.

% current default uses movmedian, with a window chosen automatically

% get sample points
if istimetable(T)
    x = T.Properties.RowTimes;
else
    x = [];
end
% adapted from movWindowWidgets/setWindowDefault
window = matlab.internal.math.chooseWindowSize(T,1,x,0.75,V);
if ~isempty(x)
    % mimic the live task: get default unit, convert to double, round, then
    % call isoutlier with the appropriate duration value
    units = {'milliseconds' 'seconds' 'minutes' 'hours' 'days' 'years'};
    secondsInUnit = [1/1000 1 60 3600 86400 31556952];
    index = find(seconds(window) >= secondsInUnit,1,'last');
    if isempty(index)
        % less than a millisecond
        index = 1;
    end
    fun = units{index};
    window = feval(fun,window);
    window = round(double(window),2,'significant');
    window = feval(fun,window);
else
    window = round(double(window),2,'significant');
end
% call isoutlier, and tally the result
N = nnz(isoutlier(T,"movmedian",window,"DataVariables",V));


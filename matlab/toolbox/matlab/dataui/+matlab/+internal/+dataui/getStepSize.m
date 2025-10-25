function stepSize = getStepSize(currentValue,doRound,previousValue)
% getStepSize: Helper for performing tasks in a Live Script
% Find a good step size for a spinner, given its current value
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019 The MathWorks, Inc.

% the current value will fall somewhere in a list of dividers
% for example: if dividers = [1 10 100]
% if val < 1, step is .1
% if 1 < val < 10, step is 1
% if 10 < val < 100, step is 10
% if 100 < val, step is 100
% In actuality, we will use several more dividers
% What to do if val is equal to a divider is dependent on if we think the
% user is stepping up or stepping down in the spinner

if currentValue == 0
    % special case, if current value is zero, step size is always 1
    stepSize = 1;
    return
end

% find out if user is clicking the up button or the down button, if we can
userSteppingUp = true;
if nargin == 3
    userSteppingUp = abs(currentValue) > abs(previousValue);
end

% set the dividers
lowestDividerOrder = -8;
if doRound
    lowestDividerOrder = 1;
end
highestDividerOrder = 7;
dividers = 10.^(lowestDividerOrder:highestDividerOrder);

% decide what to do if currentValue is equal to a divider
if userSteppingUp
    operation = @lt;
else
    operation = @le;
end

% find the smallest divider greater than the currentValue
index = find(operation(abs(currentValue),dividers),1);
if isempty(index)
    % current value is above the highest divider
    stepSize = 1e7;
else
    % current value is between dividers(ind-1) and dividers(ind)
    % set the value to a tenth of the size of that divider
    stepSize = 0.1*dividers(index);
end
end
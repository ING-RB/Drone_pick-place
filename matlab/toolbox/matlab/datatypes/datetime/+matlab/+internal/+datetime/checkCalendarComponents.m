function [componentNums, components] = checkCalendarComponents(components, requireSorted)
%CHECKCOMPONENTS Validate components argument to datetime caldiff and between.
%   COMPONENTNUMS = CHECKCOMPONENTS(COMPONENTS) validates COMPONENTS and
%   returns a numeric array COMPONENTNUMS corresponding to the positions of
%   COMPONENTS in the aray of calendar components:
%
%     {'years' 'quarters' 'months' 'weeks' 'days' 'time'}
%
%   COMPONENTS can be one of the character vectors listed above, or a cell
%   array or string array containing one or more of these values.
%   COMPONENTNUMS = CHECKCOMPONENTS(COMPONENTS, CHECKORDER) if
%   CHECKORDER is true, the components listed must be in descending
%   order
%   [COMPONENTNUMS, COMPONENTS] = CHECKCOMPONENTS(...) returns the
%   validated, unique component names.

%   Copyright 2014-2020 The MathWorks, Inc.

import matlab.internal.datatypes.isText

try
    % Make sure it's text, and weed out '', "", or <missing>. Convert char row to
    % cellstr, leave cellstr or string alone.
    [tf,components] = isText(components,false,false);
    if ~tf || length(components) < 1
        error(message('MATLAB:datetime:InvalidComponents'));
    end

    componentNames = ["years" "quarters" "months" "weeks" "days" "time"];
    componentNums = zeros(size(components));
    for i = 1:length(components)
        componentNums(i) = matlab.internal.datatypes.getChoice(components{i},componentNames,'MATLAB:datetime:InvalidComponents');
        components{i} = componentNames{componentNums(i)};
    end
    % Since componentNames is in decreasing order, just need to check if
    % componentNums is sorted without flipping. Only used in
    % calendarDuration/split.
    if nargin > 1 && requireSorted && ~issorted(componentNums)
            error(message('MATLAB:datetime:InvalidComponentsOrder'));
    end
    componentNums = unique(componentNums); % sorted
    components = componentNames(componentNums);
catch ME
    throwAsCaller(ME);
end

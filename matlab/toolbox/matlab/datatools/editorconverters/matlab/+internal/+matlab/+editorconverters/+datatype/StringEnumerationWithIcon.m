classdef StringEnumerationWithIcon
    % This is an interface for data types that want to have their
    % editor be shown with a group of toggle buttons w/ icons.

    % Copyright 2017-2023 The MathWorks, Inc.

    properties(Abstract, Constant)
        % EnumeratedValues
        %
        % A 1xN cell array of chars, where each value corresponds to a
        % valid enumerated value for the property
        %
        % Ex: {
        %      'left',
        %      'right'
        %      }
        EnumeratedValues

        % IconNames
        %
        % A 1xN string array, where each value is the id of an icon in the
        % icon repository.
        %
        % The iTH element of IconNames corresponds to the iTH
        % EnumeratedValues element.
        %
        % Ex: ["rotateClockwise", "rotateCounterclockwise"];
        IconNames
    end
end


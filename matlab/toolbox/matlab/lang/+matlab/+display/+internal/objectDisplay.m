function [propDisplay, footer] = objectDisplay(obj, width, optional)
% objectDisplay returns property display information for the properties of
% an object honoring any display customizations made through the
% CustomDisplay mixin whenever possible

%   Copyright 2023 The MathWorks, Inc.

arguments(Input)
    obj (1,:) {mustBeNonempty, matlab.display.internal.isMCOSClass(obj, "IssueError", 1)}
    width (1,1) double {mustBePositive}
    optional.PropertyNames (1,:) string = string.empty;
    optional.IncludeAllProperties (1,1) logical = false;
    optional.Format (1,1) string {mustBeNonempty} = matlab.internal.display.format
end
arguments(Output)
    propDisplay (1,:) matlab.display.internal.PropertyDisplay
    footer (1,1) string
end
if ~isempty(optional.PropertyNames) && ~all(optional.PropertyNames == "")
    [propDisplay, footer] = matlab.display.internal.objectDisplayHelper(obj, width, ...
        optional.IncludeAllProperties, optional.Format, optional.PropertyNames);
else
    if ~matlab.display.internal.doesClassUsePropertyValuePairDisplay(obj)
        % For objects that provide a text-based display customization (i.e.
        % doesClassUsePropertyValuePairDisplay returns false),
        % PropertyNames is a required input
        error(message('MATLAB:objectPropertyDisplay:PropertyNamesRequired'));
    end
    [propDisplay, footer] = matlab.display.internal.objectDisplayHelper(obj, width, ...
        optional.IncludeAllProperties, optional.Format);
end
end
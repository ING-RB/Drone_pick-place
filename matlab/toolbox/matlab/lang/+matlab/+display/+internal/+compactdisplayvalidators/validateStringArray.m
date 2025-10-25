function validateStringArray(stringArr, obj, displayConfiguration)
% Validate that input string array based on the layout

% Copyright 2020-2021 The MathWorks, Inc.
arguments
    % Input string array
    stringArr string;
    % The object being displayed
    obj;
    % DisplayConfiguration object
    displayConfiguration (1,1) matlab.display.DisplayConfiguration;
end
import matlab.display.internal.DisplayLayout;
objClassName = class(obj);
if isempty(stringArr)
    % Error if the input StringArray is set to emtpy
    error(message('MATLAB:display:EmptyStringArray', objClassName));
elseif displayConfiguration.DisplayLayout == DisplayLayout.Columnar && size(obj,1) ~= size(stringArr,1)
    % In columnar layouts, error if the number of rows in the string
    % array do not match the number of rows in the object
    error(message('MATLAB:display:StringArrayRowMismatch', objClassName));
end
end
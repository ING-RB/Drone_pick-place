function truncate = canObjectBeTruncated(obj, stringArr, displayConfiguration)
% Validate that it is possible to truncate the object based on the display
% layout

% Copyright 2020-2021 The MathWorks, Inc.
arguments
    obj
    stringArr string
    displayConfiguration (1,1) matlab.display.DisplayConfiguration
end
import matlab.display.internal.DisplayLayout;
truncate = false;
switch displayConfiguration.DisplayLayout
    case DisplayLayout.SingleLine
        % For single line layouts, the object must be scalar and its
        % corrresponding StringArray must not be set to missing or
        % empty
        truncate = isscalar(obj) && ~ismissing(stringArr) && strlength(stringArr) ~= 0;
    case DisplayLayout.Columnar
        % For columnar layouts, the object must be a column vector so
        % that effectively each row contains a scalar object and there
        % must be at least one element in the vector that is not empty
        truncate = iscolumn(obj) && ~all(ismissing(stringArr)) && any(strlength(stringArr) > 0);
end
end
function str = getDescription(hObj)
% This function takes in a graphics object as input and returns a string
% which describes the object. 

%   Copyright 2021 The MathWorks, Inc.

arguments
    hObj (1, 1) {ishghandle(hObj)}
end

str = "";

switch class(hObj)
    case {'matlab.graphics.axis.Axes', 'matlab.ui.control.UIAxes'}
        str = matlab.graphics.internal.screenreader.getDescriptionForCartesianAxes(hObj);
    case 'matlab.graphics.primitive.Text'
        str = matlab.graphics.internal.screenreader.getDescriptionForTextObject(hObj);
    otherwise
        if(isprop(hObj, 'Type'))
            str = string(hObj.Type);
        end
end

end


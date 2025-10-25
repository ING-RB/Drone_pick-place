function removeFocusIndicator(~, hObj)

%

%   Copyright 2021 The MathWorks, Inc.

% If the object has the 'Selected' property, and if the property is 'on',
% then turn the property 'off'. 

if(isprop(hObj, 'Selected') && strcmp(hObj.Selected, 'on'))
    hObj.Selected = 'off';
    return;
end

% Todo : For objects that don't have the 'Selected' property (like charts)
% remove their focus indicator. 

end


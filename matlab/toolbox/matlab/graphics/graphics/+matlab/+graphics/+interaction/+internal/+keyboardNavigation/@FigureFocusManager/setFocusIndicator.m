function setFocusIndicator(~, hObj)

%

%   Copyright 2021 The MathWorks, Inc.

% If the object has the 'Selected' property, then turn the property on. 
if(isprop(hObj, 'Selected'))
    localSetSelectionMarkers(hObj);
    return;
end

% Todo : For objects that don't have the 'Selected' property (like charts)
% indicate focus in a different way. 

end

function localSetSelectionMarkers(hObj)

% Given an object that has the 'Selected' property, sets it to 'on', and
% changes the marker style and color. 

hObj.Selected = 'on';
drawnow;

sh = localGetSelectionHandleMarkers(hObj);

if(isempty(sh))
    return;
end

sh.Style = 'o';
sh.FaceColor = uint8([0, 153, 255, 255]');
sh.EdgeColor = uint8([0, 153, 255, 255]');
end


function markers = localGetSelectionHandleMarkers(hObj)
% Given an object, returns the marker object used to display its selection
% handles

if(isa(hObj, 'matlab.graphics.axis.AbstractAxes'))
    markers = findobjinternal(hObj.NodeChildren, ...
            '-isa', 'matlab.graphics.axis.decorator.SelectionHighlight');
else
    markers = findobjinternal(hObj, ...
            '-isa', 'matlab.graphics.interactor.ListOfPointsHighlight');
end

end

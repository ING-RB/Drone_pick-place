function focus(this, hObj)

%

%   Copyright 2021 The MathWorks, Inc.

% Focus on a given object 'hObj'. 
% Currently, this involves : 
% 1. Drawing focus indicators for the object
% 2. Making a screenreader announcement for the object 

this.setFocusIndicator(hObj);


str = matlab.graphics.internal.screenreader.getDescription(hObj);
fsrm = matlab.graphics.internal.AriaFigureScreenReaderManager;
fsrm.updateFigureAriaLiveTextContent(this.Figure, str);

end


function closeCshWebWindow
%


%   Copyright 2021 The MathWorks, Inc.

% Add winId so we can reuse the window.
winIdName = 'winid';
winIdValue = 'cshww';

cefWindow = matlab.internal.doc.ui.java.findCshWindow(winIdName, winIdValue);
if ~isempty(cefWindow)
    cefWindow.close;
end

end
function out = openhtml(filename)
%OPENHTML Display HTML file in the Help Browser
%   Helper function for OPEN.
%
%   See OPEN.

%   Copyright 1984-2023 The MathWorks, Inc. 

if nargout, out = []; end
import matlab.internal.capability.Capability;

if (Capability.isSupported(Capability.LocalClient))
    web(filename, '-new');
else
    web_path = connector.getUrl(matlab.ui.internal.URLUtils.getURLToUserFile(filename));
    w = matlab.internal.webwindow(web_path, 'WindowContainer', 'Tabbed');
    w.show;
end

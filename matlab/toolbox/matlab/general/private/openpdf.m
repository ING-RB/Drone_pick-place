function openpdf(filename)
%OPENPDF Opens a PDF file in the appropriate viewer/editor.

%   Copyright 1984-2023 The MathWorks, Inc.

import matlab.internal.capability.Capability;

if (Capability.isSupported(Capability.LocalClient))
    if ~isfile(filename)
        error(message('MATLAB:openpdf:noSuchFile', filename));
    end

    if ispc
        winopen(filename);
    elseif ismac
        matlab.system.internal.executeCommand(['open "' filename '" &']);
    else
        web(filename, '-browser');
    end
else
    web_path = connector.getUrl(matlab.ui.internal.URLUtils.getURLToUserFile(filename));
    w = matlab.internal.webwindow(connector.getUrl(web_path), 'WindowContainer', 'Tabbed');
    w.show;
end

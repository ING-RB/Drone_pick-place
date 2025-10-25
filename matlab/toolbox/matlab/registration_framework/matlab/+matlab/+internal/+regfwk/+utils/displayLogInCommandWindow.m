function msg = displayLogInCommandWindow(evt)
% displayLogInCommandWindow Displays log messages to the MATLAB Command Window for Extension Points Framework log events
%
%   matlab.internal.regfwk.utils.displayLogInCommandWindow(evt)
%   Displaying formatted Extension Points Framework log messages to the MATLAB Command Window based on their properties
%
%
%   evt refers to the serialized epfwk_event::Log struct which has associated log info
%   (timestamp, description, resourceName, filePath, severity)

% Copyright 2023 The MathWorks, Inc.

msg = sprintf('[%s] %s', evt.timestamp, evt.description);
if (~isempty(evt.resourceName))
    msg = msg + " Property: '" + evt.resourceName + "'.";
end
if (~isempty(evt.filePath)) % create a file hyperlink
    filePath = strrep(evt.filePath, "\", "/"); % replace \ otherwise treated as escape characters
    if (evt.lineNumber ~= 0) % if line number is present, hyperlink to open file in editor and go to line
        msg = msg + " File: " + sprintf('<a href="matlab: matlab.desktop.editor.openAndGoToLine(''%s'', %d);">%s line %d', filePath, evt.lineNumber, filePath, evt.lineNumber);
        if (evt.columnNumber ~= 0)
            msg = msg + sprintf(', column %d', evt.columnNumber);
        end
        msg = msg + '</a>';
    else
        msg = msg + " File: " + sprintf('<a href="matlab: open(''%s'')">%s</a>', filePath, filePath);
    end
end
if (~isempty(evt.severity))
    if (evt.severity == "info")
        disp(msg);
    elseif (evt.severity == "warning")
        warning('off','backtrace');
        warning("epfwk:warning", msg);
        warning('on','backtrace');
    elseif (evt.severity == "error")
        warning('off','backtrace');
        warning("epfwk:error", msg);
        warning('on','backtrace');
    end
else
    disp(msg);
end
end
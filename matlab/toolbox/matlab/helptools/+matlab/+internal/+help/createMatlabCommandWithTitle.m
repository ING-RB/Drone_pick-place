function result = createMatlabCommandWithTitle(allowHotlinks, message, action, item)
    if allowHotlinks
        link = matlab.internal.help.createMatlabLink(action, item, message);
        result = matlab.internal.help.formatHelpTextLine(link);
    else
        message = matlab.internal.help.formatHelpTextLine(message);
        command = "   " + matlab.internal.help.makeDualCommand(action, item);
        command = matlab.internal.help.formatHelpTextLine(command);
        result = append(message, command);
    end
end

%   Copyright 2015-2020 The MathWorks, Inc.

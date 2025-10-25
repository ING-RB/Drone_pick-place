function link = createMatlabLink(command, linkTarget, linkText)
    linkTarget = convertStringsToChars(linkTarget);
    linkText = convertStringsToChars(linkText);
    command = matlab.internal.help.makeDualCommand(command, linkTarget);
    link = append('<a href="matlab:', erase(command, '"'), '">', linkText, '</a>');
end

%   Copyright 2020-2024 The MathWorks, Inc.

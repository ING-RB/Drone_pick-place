function linkText = getOtherNamesLink(hp, topic, linkTopic, linkID, linkFcn)
    shouldPrintFullList = ~hp.commandIsHelp || ~hp.wantHyperlinks;
    
    linkText = getString(message(linkID, topic));
    
    if ~shouldPrintFullList
        linkText = matlab.internal.help.createMatlabLink(linkFcn, linkTopic, linkText);
    end
    
    linkText = matlab.internal.help.formatHelpTextLine(linkText);
    
    if shouldPrintFullList
        linkText = append(linkText, newline, feval(linkFcn, linkTopic, hp.wantHyperlinks, hp.command));
    end
end

%   Copyright 2020-2022 The MathWorks, Inc.

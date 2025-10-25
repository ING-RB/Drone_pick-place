function displayStr = displayHelp(hp)
    if hp.helpStr ~= ""
        displayStr = hp.helpStr;
    elseif hp.topic ~= ""
        inaccessibleMessage = matlab.lang.internal.introspective.findInaccessibleFunctions(hp.topic);
        if isempty(inaccessibleMessage)
            inaccessibleMessage = matlab.lang.internal.registry.findUnlicensedFunctions(hp.topic);
        end
        if isempty(inaccessibleMessage)
            compatibilityMessage = matlab.internal.help.getCompatibilityMessage(hp.topic);
            if compatibilityMessage ~= ""
                displayStr = compatibilityMessage;
                if hp.wantHyperlinks
                    displayStr = regexprep(displayStr, "'(\S+)'", "<strong>$1</strong>");
                end
            else
                displayStr = getString(message('MATLAB:helpUtils:displayHelp:TopicNotFound', hp.topic));
                searchMessage = getString(message('MATLAB:helpUtils:displayHelp:SearchMessageWithTopic', hp.topic));
                searchCommand = matlab.internal.help.createMatlabCommandWithTitle(hp.wantHyperlinks, searchMessage, "docsearch", hp.topic);
                displayStr = append(displayStr, newline, searchCommand);
            end
        else
            displayStr = getString(inaccessibleMessage);
        end
    else
        if hp.wantHyperlinks
            displayStr = getString(message('MATLAB:helpUtils:displayHelp:GettingStarted'));
        else
            displayStr = getString(message('MATLAB:helpUtils:displayHelp:SearchMessageNoLinks'));
        end
    end
end

%   Copyright 2007-2024 The MathWorks, Inc.

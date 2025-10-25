function getShadowedOrdinaryFunctionHelp(hp, methodName)
    fullTopic = matlab.lang.internal.introspective.safeWhich(methodName, true);
    if fullTopic ~= "" && ~matlab.lang.internal.introspective.isObjectDirectorySpecified(fullTopic) || exist(methodName, "builtin") || exist(methodName, "class")
        hp2 =  matlab.internal.help.helpProcess(1, 1, {methodName});
        hp2.specifyCommand(hp.command);
        hp2.noDefault = true;
        hp2.getTopicHelpText;
        hp.helpStr = hp2.helpStr;
        if hp.helpStr ~= ""
            hp.topic = methodName;
            hp.fullTopic = fullTopic;
            hp.docLinks = hp2.docLinks;
            hp.objectSystemName = hp.docLinks.referencePage;
        end
    end
end

%   Copyright 2014-2024 The MathWorks, Inc.

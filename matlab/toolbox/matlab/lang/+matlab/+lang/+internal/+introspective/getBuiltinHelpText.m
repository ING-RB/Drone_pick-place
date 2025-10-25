function helpText = getBuiltinHelpText(metaInfo, topic, justH1)
    helpText = '';

    if ~isempty(metaInfo) && metaInfo.Description ~= ""
        helpText = metaInfo.Description;
        if ~justH1
            helpText = matlab.internal.help.managePrefix(helpText, topic, true);
            if metaInfo.DetailedDescription ~= ""
                helpText = append(helpText, newline, metaInfo.DetailedDescription);
            end
            helpText = append(helpText, newline);
        end
    end
end

%   Copyright 2019-2024 The MathWorks, Inc.

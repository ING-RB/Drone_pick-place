function [result,type] = getHelpPopupUrl(topic)
    callerWorkspaceVars = matlab.lang.internal.introspective.callerWorkspaceVars;
    topic = matlab.internal.doc.reference.ReferenceTopicInput({topic}, callerWorkspaceVars);

    result = '';
    type = '';
    [docPage, displayText, primitive] = matlab.internal.doc.reference.getReferencePage(topic, false);

    if ~isempty(docPage) && docPage.IsValid
        % HelpPopup content displays in an internal browser with navigation suppressed
        docPage.ContentType = "Standalone";
        type = 'url';
        result = char(docPage);
    elseif ~isempty(displayText)
        type = 'text';
        result = char(displayText);
    elseif primitive
        type = 'output';
        result = matlab.internal.help.getInstanceIsa(topic.VariableName, topic.Topic);
    end   
end

%   Copyright 2021-2024 The MathWorks, Inc.

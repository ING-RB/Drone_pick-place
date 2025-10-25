function clearedVariableMessage = findClearedVariable(variableName, history)
    arguments
        variableName (1,1) string;
        history      (1,1) matlab.lang.internal.history.CommandHistory = matlab.lang.internal.history.CommandHistory.create;
    end
    
    clearedVariableMessage = message.empty;
    
    if matlab.internal.display.isHot && desktop('-inuse')
        if contains(variableName, '.')
            variableName = extractBefore(variableName, '.');
        end
        try %#ok<TRYNC>
            % This will throw if it can't work here
            [~] = matlab.lang.internal.lasso.createScript('Variables', variableName, 'History', history);
            
            recreateLink = createCallbackLink("recreateVariable('", variableName, "VariableNoLongerInWorkspaceRecreate");
            createScriptLink = createCallbackLink("createScript('Variables', '", variableName, "VariableNoLongerInWorkspaceCreateScript");

            clearedVariableMessage = message('MATLAB:ErrorRecovery:VariableNoLongerInWorkspace', variableName, recreateLink, createScriptLink);
        end
    end
end

function link = createCallbackLink(callbackFunction, variableName, callbackID)
    callback = "matlab:matlab.lang.internal.lasso." + callbackFunction + variableName + "');";
    linkText = getString(message("MATLAB:ErrorRecovery:" + callbackID, variableName));
    link = '<a href="' + callback + '">' + linkText + "</a>";
end

%   Copyright 2019-2023 The MathWorks, Inc.

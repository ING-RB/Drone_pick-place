function recreateVariable(variable, history)
    arguments
        variable (1,1) string;
        history  (1,1) matlab.lang.internal.history.CommandHistory = matlab.lang.internal.history.CommandHistory.create;
    end
    
    script = matlab.lang.internal.lasso.createScript('History', history, 'Variables', variable);
            
    lines = splitlines(script);
    for line = lines'
        internal.matlab.desktop.commandwindow.executeCommandForUser(line);
    end
end

%   Copyright 2019-2023 The MathWorks, Inc.

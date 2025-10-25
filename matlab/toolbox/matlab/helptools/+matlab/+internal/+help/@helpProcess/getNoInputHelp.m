function getNoInputHelp(hp, history)
    arguments
        hp (1,1) matlab.internal.help.helpProcess;
        history (1,1) matlab.lang.internal.history.CommandHistory = matlab.lang.internal.history.CommandHistory.create;
    end
    session = history.getSessions(1);
    commands = session.getCommands;
    
    lastCommand = matlab.internal.help.getLastCommandForHelp(commands);
    
    if lastCommand ~= ""
        hp.getHelpOnExpression(lastCommand);
    end
end

% Copyright 2018-2023 The MathWorks, Inc.

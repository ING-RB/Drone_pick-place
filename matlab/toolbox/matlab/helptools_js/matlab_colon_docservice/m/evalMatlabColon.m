function evalMatlabColon(currentUrl, matlabCommand)
    dduxMatlabCommandLogger = com.mathworks.mlwidgets.help.messages.DduxMatlabCommandLogger();
    dduxMatlabCommandLogger.logUIEvent(currentUrl, "matlab:" + matlabCommand);
    eval(matlabCommand);
end

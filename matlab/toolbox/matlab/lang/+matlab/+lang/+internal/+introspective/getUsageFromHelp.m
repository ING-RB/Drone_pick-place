function usages = getUsageFromHelp(functionName, helpStr)
    %GETUSAGEFROMHELP Get usage syntax from help text.
    %   USAGE = GETUSAGEFROMHELP(FUNCTIONNAME) returns a string array of the
    %   syntaxes found for functionName.
    %
    %   USAGE = GETUSAGEFROMHELP(..., HELPTEXT) returns a string array of the
    %   syntaxes found in helpText.
    %
    %   GETUSAGEFROMHELP attempts to get the syntax information from the
    %   help text for functionName.
    %
    %   GETUSAGEFROMHELP will return syntaxes only for the first function
    %   that WHICH finds. To get syntaxes for overloaded methods, provide
    %   the full classname and methodname to GETUSAGEFROMHELP.
    %
    %   Examples:
    %      usage = matlab.lang.internal.introspective.getUsageFromHelp("magic");
    %
    %         returns a string:
    %
    %           "magic(N)"
    %
    %      usage = matlab.lang.internal.introspective.getUsageFromHelp("LinearModel.Plot");
    %
    %         returns a 1x2 string array with:
    %
    %         usage(1) =
    %           "plot(LM)"
    %
    %         usage(2) =
    %           "H = plot(LM)"
    %
    %   See also HELP, GETUSAGE, GETUSAGEFROMDOC, GETUSAGEFROMSOURCE.

    %   Copyright 2017-2023 The MathWorks, Inc.

    if nargin < 2
        functionName = convertStringsToChars(functionName);
        hp = matlab.internal.help.helpProcess(1, 2, {'-helpwin', functionName});
        hp.justChecking = true;
        hp.getTopicHelpText(false, false);
        helpStr = hp.helpStr;
        if hp.isTypo
            functionName = hp.topic;
        end
    end

    if contains(functionName, '.')
        functionParts = split(functionName, '.');
        packageName = char(join(functionParts(1:end-1), '.'));
        functionName = functionParts{end};
    else
        packageName = '';
    end
    helpSections = matlab.internal.help.HelpSections(helpStr, functionName, packageName);
    usages = helpSections.Usages;
end

%GETH1ORHELP Get H1 line or help text for class or member
%   PARSEDHELP = GETH1ORHELP(MEMBERNAME, H1FLAG) parses the comment text of
%   the specified class or member, MEMBERNAME, using the Flexible Name Resolver API
%   and returns either the H1 line or help text (associated with the
%   Description and DetailedDescription meta-class properties, respectively)
%   based on the value of H1FLAG.
%
%   MEMBERNAME - a string scalar or character vector representing the
%   fully-qualified name of the class or member to be parsed.
%
%   H1FLAG - a scalar logical. When it is set to true, GETH1ORHELP returns
%   the H1 line. When it is set to false, GETH1ORHelp returns the help
%   text.

%   Copyright 2021-2022 The MathWorks, Inc.

function parsedHelp = getH1OrHelp(memberName, H1Flag)
    arguments
        memberName {mustBeTextScalar}
        H1Flag (1,1) logical
    end
    try
        rawHelp = matlab.internal.help.getHelpTextForDescription(memberName);

        % Split help text into Description and DetailedDescription components
        % and return the correct component
        if contains(rawHelp, newline)
            h1   = extractBefore(rawHelp, newline);
            help = extractAfter(rawHelp, newline);
        else
            h1   = rawHelp;
            help = '';
        end
        if H1Flag
            parsedHelp = h1;
        else
            parsedHelp = help;
        end
    catch
        parsedHelp = '';
    end
end

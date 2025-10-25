function helpStr = sanitizeHelpComments(helpStr, justH1)
    helpStr = regexprep(helpStr, '^\s*%%?', ' ', 'lineanchors');
    helpStr = erase(helpStr, char(13));
    helpStr = strip(helpStr, 'right');
    if ~justH1 && helpStr ~= ""
        helpStr = append(helpStr, newline);
    end
end

%   Copyright 2018-2023 The MathWorks, Inc.

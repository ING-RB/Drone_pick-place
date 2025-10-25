function helpStr = getMFileHelpText(fullPath, getFileTextFcn, justH1)
    %GETMFILEHELPTEXT Utility to get MATLAB code file help text

    %   Copyright 2021-2024 The MathWorks, Inc.

    [filePath, fileName, localFunction] = matlab.lang.internal.introspective.splitFilePath(fullPath);

    fullPath = append(filePath, filesep, fileName);
    fullText = string(getFileTextFcn(fullPath));

    fullText = replace(fullText, compose(["\r\n", "\r"]), newline);

    if localFunction == ""
        % remove leading blank lines
        fullText = strip(fullText, 'left');
        helpStr = getHelpFromComments(fullText, justH1);
        if helpStr == ""
            firstWord = lower(regexp(fullText, '^\w+\>', 'match', 'once'));
            if firstWord == "function" || firstWord == "classdef"
                fullText = matlab.lang.internal.introspective.stripLineContinuations(fullText);

                % skip one line
                postText = regexprep(fullText, '.*\s*', '', 'dotexceptnewline', 'once');
                helpStr = getHelpFromPostText(postText, firstWord, justH1);
            end
        end
    else
        fullText = matlab.lang.internal.introspective.stripLineContinuations(fullText);
        postTexts = stripToFunction(fullText, extractAfter(localFunction, 1));
        helpStr = '';
        for postText = postTexts
            helpStr = getHelpFromPostText(postText, "function", justH1);
            if helpStr ~= ""
                return;
            end
        end
    end
end

function helpStr = getHelpFromComments(fullText, justH1)
    helpPattern = '(^[ \t]*%.*\n?)*';
    helpPattern = append('(?-m:^)', helpPattern);
    helpStr = regexp(char(fullText), helpPattern, 'match', 'once', 'dotexceptnewline', 'lineanchors');
    if ~endsWith(helpStr, newline)
        helpStr = append(helpStr, newline);
    end
    if justH1
        helpStr = extractBefore(helpStr, newline);
    end
    helpStr = matlab.internal.help.sanitizeHelpComments(helpStr, justH1);
end

function helpStr = getHelpFromPostText(postText, fileType, justH1)
    helpStr = getHelpFromComments(postText, justH1);
    if helpStr == "" && fileType == "function"
        postText = stripArgumentsBlocks(postText);
        helpStr = getHelpFromComments(postText, justH1);
    end
end

function fullText = stripArgumentsBlocks(fullText)
    fullText = regexprep(fullText, '(^\s*arguments\>.*?^\s*end\>\s*\n)+\s*', '', 'once', 'lineanchors');
end

function postTexts = stripToFunction(fullText, localFunction)
    postTexts = [];
    [functionNames, functionSplit] = matlab.lang.internal.introspective.getFunctionLine(fullText, localFunction, false);
    if ~isempty(functionNames)
        if isscalar(functionNames)
            postTexts = functionSplit(2);
        else
            exactIndex = [functionNames.functionName] == localFunction;
            postTexts = functionSplit([false, exactIndex]);
        end
        postTexts = strip(postTexts, 'left');
    end
end


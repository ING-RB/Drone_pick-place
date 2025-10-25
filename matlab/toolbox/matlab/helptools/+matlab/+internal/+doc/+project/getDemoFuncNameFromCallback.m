function funcName = getDemoFuncNameFromCallback(callback)
%MATLAB.INTERNAL.DOC.PROJECT.GETDEMOFUNCNAMEFROMCALLBACK get the function
%   name from the callback.
%
% For the callback functions 'xpgallry', 'xpmovie', 'sshow', and'playshow'
% remove:
%   the function name
%   the parens and tick marks from the arg list
%
% For all other callback functions, remove all arguments.
%
%   Examples:
%       matlab.internal.doc.project.getDemoFuncNameFromCallback('playshow(''GuitarFilterExample'')')
%       returns GuitarFilterExample
%
%   Examples:
%       matlab.internal.doc.project.getDemoFuncNameFromCallback('help(''plot'')')
%       returns help

%  Copyright 2020 The MathWorks, Inc.

funcName = '';

if startsWith(callback,'web')
   return;
end


stripWords = {'xpgallry', 'xpmovie', 'sshow', 'playshow'};
for i = 1:length(stripWords)
    stripWord = stripWords{i};
    if startsWith(callback,stripWord)
        funcName = getFuncNameForStrippedWord(callback, stripWord);
    end
end

if isempty(funcName)
    funcName = getFuncNameFromCallback(callback);
end

end

function funcName = getFuncNameForStrippedWord(funcName, stripWord)
    % Remove the leading stripWord
    funcName = extractAfter(funcName, stripWord);
    % Remove parens and tick marks
    funcName = removeParens(funcName);
    funcName = strrep(funcName, '''', '');
    % Fix any misc characters that we do not want
    funcName = strrep(funcName, ' ', '');
    funcName = strrep(funcName, ';', '');
end

function funcName = removeParens(funcName)
    if contains(funcName,'(') && contains(funcName,')')
        funcName = strrep(funcName, '(', '');
        funcName = strrep(funcName, ')', '');
    end
end

% Remove any arguments from the function call.
function funcName = getFuncNameFromCallback(funcName)
    stripAfterChar = {' ', '('};
    for i = 1:length(stripAfterChar)
        stripAfter = stripAfterChar{i};
        if contains(funcName,stripAfter)
            % Remove everything after the first occurance of the character
            funcName = extractBefore(funcName, stripAfter); 
        end
    end
    % Fix any misc characters that we do not want
    funcName = strrep(funcName, ';', '');
end
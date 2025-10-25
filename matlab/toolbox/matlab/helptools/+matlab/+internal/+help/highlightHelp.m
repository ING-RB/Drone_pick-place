function helpStr = highlightHelp(helpStr, fullName, fcnName, prefix, suffix)
%

%   Copyright 2011-2024 The MathWorks, Inc.

    helpStr = highlightSingleKeyword(helpStr, fullName, prefix, suffix);
    helpStr = highlightSingleKeyword(helpStr, fcnName, prefix, suffix);
end

%% ------------------------------------------------------------------------
function helpStr = highlightSingleKeyword(helpStr, keyword, prefix, suffix)
    % Highlight occurrences of the function name, ignoring occurrences
    % immediately preceded or followed by some punctuation as well as
    % occurrences that occur within hyperlinks.
    if keyword ~= "" && ~strcmpi(keyword,'matlab')
        if ~isempty(regexp(keyword,'\w','once'))
            upperRegexp = makeExpression(upper(keyword));
            if ~all(isstrprop(keyword, 'lower'))
                fcnRegexp = makeExpression(keyword);
                fcnPattern = append('(', fcnRegexp, '|', upperRegexp, ')');
            else
                fcnPattern = upperRegexp;
            end
        else
            fcnPattern = regexptranslate('escape',keyword);
        end
        
        toReplace = append('(?<![a-zA-Z0-9_])', fcnPattern, '(?![a-zA-Z0-9_])');

        highlightText = append(prefix, keyword, suffix);
        highlightFunc = @(match)(highlightMatch(match, highlightText)); %#ok<NASGU>
        helpStr = regexprep(helpStr, append('((?i:<a\s+href.*?</a>|', prefix, '.*?', suffix, '))?(', toReplace, ')?'), '$1${highlightFunc($2)}');
    end
end

%% ------------------------------------------------------------------------
function fcnRegexp = makeExpression(fcnName)
    fcnRegexp = replace(fcnName, ["\", "/"], '.');
    fcnRegexp = regexptranslate('escape', fcnRegexp);
    fcnRegexp = replace(fcnRegexp, '\.', '[\\/.]');
end

%% ------------------------------------------------------------------------
function match = highlightMatch(match, highlighted)
    if match ~= ""
        match = highlighted; 
    end
end
    

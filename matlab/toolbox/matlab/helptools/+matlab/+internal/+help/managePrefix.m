function helpStr = managePrefix(helpStr, prefix, wantPrefix)
    if contains(prefix, regexpPattern('[.\\/]'))
        flexiblePrefix = regexpPattern(regexptranslate('flexible', prefix, '[.\\/]'));
        [helpStr, hadPrefix] = prefixCheck(helpStr, flexiblePrefix, wantPrefix);
        if hadPrefix
            return;
        end
        prefix = regexprep(prefix, '.*[.\\/]', '');
    end

    [helpStr, hadPrefix] = prefixCheck(helpStr, prefix, wantPrefix);

    if ~hadPrefix && wantPrefix
        helpStr = append(char(prefix), ' - ', helpStr); % helpStr is char
    end
end

function [helpStr, hadPrefix] = prefixCheck(helpStr, topicPattern, wantPrefix)
    topicPattern = caseInsensitivePattern(topicPattern) + regexpPattern('\>') + asManyOfPattern(characterListPattern(" -:"));
    hadPrefix = startsWith(helpStr, topicPattern);
    if hadPrefix && ~wantPrefix
        if ~startsWith(helpStr, topicPattern + newline)
            helpStr = extractAfter(helpStr, topicPattern);
        end
    end
end

%   Copyright 2021-2023 The MathWorks, Inc.

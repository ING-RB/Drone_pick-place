function fixedName = extractCaseCorrectedName(fullName, subName)
    fixedNames = regexpi(fullName, append('\<', regexprep(subName, '\W*', '\\W*'), '\>'), 'match');
    if isempty(fixedNames)
        fixedName = '';
    else
        fixedName = strrep(fixedNames{end}, '\', '/');
        fixedName = regexprep(fixedName, '(^|/)[@+]?', '$1');
    end
end

%   Copyright 2007-2023 The MathWorks, Inc.

function h1Line = extractPurposeFromH1(h1Line, itemName)
    % extractPurposeFromH1 - helper function that removes the name of the 
    % property or method if it precedes the class member's help comments.
    h1Regexp = append('^\s*(', itemName, '(\.\w*)?\>\s*(-\s*)?)?');
    h1Line = regexprep(h1Line, h1Regexp, '', 'ignorecase', 'once');
end

%   Copyright 2022 The MathWorks, Inc.

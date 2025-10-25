function result = casedStrCmp(isCaseSensitive, string1, string2)
    result = matches(string1, string2, IgnoreCase=~isCaseSensitive);
end

%   Copyright 2014-2023 The MathWorks, Inc.

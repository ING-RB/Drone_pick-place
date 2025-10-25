function names = getLegacyParameterNames(value)
%

% Copyright 2022-2023 The MathWorks, Inc.

import matlab.lang.makeUniqueStrings;
import matlab.lang.makeValidName;

if iscellstr(value) %#ok<ISCLSTR>
    % Allow valid identifiers and keywords in the parameter names
    names = cellfun(@(v)reshape(permute(v, [2, 1, 3:ndims(v)]), 1, []), value, ...
        'UniformOutput',false);
    keywordMask = cellfun(@iskeyword, names);
    names(~keywordMask) = makeValidName(names(~keywordMask), 'Prefix','p_');
    names = makeUniqueStrings(names, {}, maximumTextLength);
else
    names = arrayfun(@(n)sprintf('value%d',n), 1:numel(value), 'UniformOutput',false);
end
end

function n = maximumTextLength
n = 63;
end

% LocalWords:  lang

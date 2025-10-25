function S = checkAlias(S)
    % Replace obsolete symbols with new aliases

%   Copyright 2018-2020 The MathWorks, Inc.

    alias_idx = matlab.alias.internal.isAlias(S);
    S(alias_idx) = matlab.alias.internal.getNewNameFromAlias(S(alias_idx));
    S = unique(S);
end
function [bool, dupKey] = hasDuplicateKeys(r)
%

%   Copyright 2024 The MathWorks, Inc.

    [~, modified] = matlab.lang.makeUniqueStrings(r.keys);

    bool = any(modified);

    % Get the name of the duplicate keys to return
    dupKey = "";
    if bool
        modifiedKeysOnly = r.keys(modified);
        dupKey = modifiedKeysOnly(1);
    end
end

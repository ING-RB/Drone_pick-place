function makeUniqueKeys(r)
%

%   Copyright 2024 The MathWorks, Inc.

    [r.keys, ~] = matlab.lang.makeUniqueStrings(r.keys);
end

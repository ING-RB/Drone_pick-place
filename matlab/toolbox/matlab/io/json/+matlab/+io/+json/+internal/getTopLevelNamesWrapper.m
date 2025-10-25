function topLevelNames = getTopLevelNamesWrapper(file)
%getTopLevelNames   Test for component structure.

%   Copyright 2022 The MathWorks, Inc.

    topLevelNames = matlab.io.internal.json.getTopLevelNames(file);
end

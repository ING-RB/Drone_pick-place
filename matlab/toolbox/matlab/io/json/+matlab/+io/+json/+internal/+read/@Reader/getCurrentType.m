function t = getCurrentType(r)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.LevelReader.*;

    t = matlab.io.json.internal.read.JSONType(getCurrentType(r.reader));
end

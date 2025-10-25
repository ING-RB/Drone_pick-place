function b = isAbsoluteFile(topic)
    b = matlab.io.internal.common.isAbsolutePath(topic) && isfile(topic);
end

%   Copyright 2022 The MathWorks, Inc.

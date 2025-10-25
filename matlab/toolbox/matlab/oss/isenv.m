function tf = isenv(name)
name = convertCharsToStrings(name);
try
    tf = matlab.oss.internal.isenv(name);
catch ME
    throw( ME)
end
end

%   Copyright 2022 The MathWorks, Inc.

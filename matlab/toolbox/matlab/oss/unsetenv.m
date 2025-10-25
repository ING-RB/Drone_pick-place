function unsetenv(name)
name = convertCharsToStrings(name);
try
    matlab.oss.internal.unsetenv(name);
catch ME
    throw( ME)
end
end

%   Copyright 2022 The MathWorks, Inc.

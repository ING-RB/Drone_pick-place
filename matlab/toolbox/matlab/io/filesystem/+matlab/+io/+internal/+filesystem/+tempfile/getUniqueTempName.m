function fullname = getUniqueTempName(location,name)
% Get an unused temp name for the location and name specified

fullname = fullfile(location,name);
while isfile(fullname)
    % It's very unlikely this hits more than one loop, but in a very long
    % running session that could happen.
    fullname = fullfile(location, matlab.lang.internal.uuid + "_" + name);
end
end

%   Copyright 2024 The MathWorks, Inc.

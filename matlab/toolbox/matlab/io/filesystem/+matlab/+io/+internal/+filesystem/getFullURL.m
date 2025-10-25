function path = getFullURL(path)
% Returns a URL for the path input, adding PWD if needed.
if ~matlab.io.internal.vfs.validators.hasIriPrefix(path)
    if ~matlab.io.internal.filesystem.isAbsolutePathNoIO(path)
        path = fullfile(pwd,path);
    end
    path = matlab.io.internal.filesystem.createFileURL(path);
end
end

%   Copyright 2024 The MathWorks, Inc.

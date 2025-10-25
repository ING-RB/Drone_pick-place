function p = findBuildFile(name)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2023 The MathWorks, Inc.

arguments
    name = "buildfile.m"
end

folder = pwd();
while ~isfile(fullfile(folder, name))
    [folder, n] = fileparts(folder);
    if isempty(n)
        p = string.empty();
        return;
    end
end

p = fullfile(folder, name);
end
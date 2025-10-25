function LatestBlackboxRuntime = getLatestBlackboxRuntime(aBlackboxruntimeDirectoryPath)
%

%   Copyright 2019 The MathWorks, Inc.

    blackboxruntimeFolders = dir(aBlackboxruntimeDirectoryPath);
    blackboxValidRuntimeFolders = blackboxruntimeFolders(arrayfun(@(x) startsWith(x.name,'+R'), blackboxruntimeFolders));
    blackboxValidRuntimeNames = arrayfun(@(x) x.name, blackboxValidRuntimeFolders, 'UniformOutput', false);
    LatestBlackboxRuntime = blackboxValidRuntimeNames{end}(2:end);
end

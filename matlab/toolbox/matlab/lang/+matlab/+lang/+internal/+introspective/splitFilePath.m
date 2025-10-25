function [filePath, fileName, localFunction] = splitFilePath(fullPath)
    split = regexp(fullPath, filemarker + "(?=[^\\/]*$)", 'split', 'once');
    [filePath, fileName, fileExt] = fileparts(split{1});
    if fileExt == ".p"
        fileExt = '.m';
    end
    fileName = append(fileName, fileExt);
    if isscalar(split)
        localFunction = '';
    else
        localFunction = append(filemarker, split{2});
    end
end

%   Copyright 2018-2024 The MathWorks, Inc.

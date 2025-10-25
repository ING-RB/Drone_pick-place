function fullFilePath = appendFileExtensionIfNeeded(inputFullFile)
    %APPENDFILEEXTENSIONIFNEEDED If the passed file lacks an extension,
    % append '.mlapp' to the file.
    %   If the file extension of the passed file is empty, return
    %   the passed file path with '.mlapp' appended to it.

    % Copyright 2019 The MathWorks, Inc.

    defaultFileExt = '.mlapp';
    [path, name, ext] = fileparts(inputFullFile);

    if isempty(ext)
        ext = defaultFileExt;
    end

    fullFilePath = fullfile(path, [name, ext]);
end
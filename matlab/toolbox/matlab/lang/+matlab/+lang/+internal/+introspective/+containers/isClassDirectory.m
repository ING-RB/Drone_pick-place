function result = isClassDirectory(folderPath)
    % isClassDirectory - checks to see if enclosing folder is
    % an @-class directory.

    % Copyright 2009-2023 The MathWorks, Inc.
    result = false;
    
    [~, parentDirName] = fileparts(folderPath);
    
    if parentDirName ~= "" && startsWith(parentDirName, '@')
        result = true;
    end
end

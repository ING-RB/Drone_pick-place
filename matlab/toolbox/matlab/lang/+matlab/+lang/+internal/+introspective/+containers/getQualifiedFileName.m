function qualifiedName = getQualifiedFileName(filePath)
    % GETQUALIFIEDFILENAME - used to extract the file name
    % qualified by the enclosing package and/or class

    % Copyright 2009-2023 The MathWorks, Inc.
    qualifiedName = matlab.lang.internal.introspective.getPackageName(filePath);
    
    [folderPath, fileName] = fileparts(filePath);
    
    if ~matlab.lang.internal.introspective.containers.isClassDirectory(folderPath)
        if qualifiedName ~= ""
            qualifiedName = append(qualifiedName, '.', fileName);
        else
            qualifiedName = fileName;
        end
    end
end

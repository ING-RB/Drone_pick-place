function [b, className, whichComment] = isClassMFile(fullPath)
    pathParts = regexp(fullPath, '[\\/]@(?<class>\w+)[\\/](?<method>\w+)\.m', 'names', 'once');
    if ~isempty(pathParts)
        whichName = fullPath;
        if strcmp(pathParts.class, pathParts.method)
            whichComment = append(pathParts.class, ' constructor');
        else
            whichComment = append(pathParts.class, ' method');
        end
    else
        [whichName, whichComment] = which(fullPath);
    end
    
    if whichName == ""
        [explicitPath, fileName] = fileparts(fullPath);
        [explicitPart, implicitPart] = matlab.lang.internal.introspective.separateImplicitDirs(explicitPath);
        [whichPath, whichComment] = which(fullfile(implicitPart, fileName));
        if whichComment ~= ""
            % verify that stripping the explicit part resolved back to the
            % original path
            resolvedExplicitPart = matlab.lang.internal.introspective.separateImplicitDirs(fileparts(whichPath));
            canonical = what(resolvedExplicitPart);
            if ~strcmp(append(canonical.path, filesep), explicitPart)
                whichComment = '';
            end
        end        
    end
    [b, className] = matlab.lang.internal.introspective.isClassComment(whichComment);
end

%   Copyright 2013-2024 The MathWorks, Inc.

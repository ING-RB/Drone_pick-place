function validateSourceRoot(sourceRoot, obj)
%validateSourceRoot   validate if all the files analyzed in the codeIssues object
%   start with the sourceRoot supplied

%   Copyright 2020-2023 The MathWorks, Inc.

    arguments
        sourceRoot
        obj codeIssues
    end
    % Look for default value, which is a scalar value missing.
    % This has a max dimension of 1.
    % Using length() will not work for tables.
    if isscalar(sourceRoot) && ismissing(sourceRoot)
        % This is just the default value, ignore it.
        return
    end

    mustBeTextScalar(sourceRoot)

    if ~isfolder(sourceRoot)
        error(message("MATLAB:codeanalyzer:FolderNotFound", sourceRoot));
    end

    % For every file, confirm that source root exists in full filename 
    % AND source root is at the beginning of full file name.
    if ~all(startsWith(obj.Issues.FullFilename, sourceRoot))
            error(message("MATLAB:codeanalyzer:BeginWithSourceRoot"));
    end
end
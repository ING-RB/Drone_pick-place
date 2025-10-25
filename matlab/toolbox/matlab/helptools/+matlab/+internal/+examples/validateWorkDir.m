function workDir = validateWorkDir(workDir,exampleId)
    % Verify dir input.

%   Copyright 2020-2023 The MathWorks, Inc.

    if nargin < 2
        exampleId = "exampleId";
    end
  
    if isstring(workDir)
        workDir = char(workDir);
    end
    if isempty(workDir)
        error(message("MATLAB:examples:EmptyDirectory"));
    elseif ~ischar(workDir)
        error(message("MATLAB:examples:InvalidDirectory"));
    elseif any(workDir < 32)
        error(message("MATLAB:examples:UnsupportedDirectoryName",exampleId));
    end
end

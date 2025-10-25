function obj = createLiveScript(fullfilePath)
% createLiveScript - Creates an empty live script file with the given
% fullfilePath
%
%   createLiveScript(fullfilePath) - Creates a empty live script given a
%   full file path. Returns a struct with the following fields
%   status - false, if the file already exists on disk, or 
%   if the file creation fails, true otherwise
%   error - an error message in case the file creation fails
%
%   Example:
%       matlab.internal.liveeditor.createLiveScript('foo.mlx');
%   creates an empty live script, named foo.mlx, in the current working directory.

%   Copyright 2019-2022 The MathWorks, Inc.

    obj.status = true;
    obj.error = "";
    if(isfile(fullfilePath))
        obj.status = false;
        obj.error = "File exists on disk";
    end
    fm = matlab.internal.livecode.FileModel.createEmptyLiveCodeFile(fullfilePath);
    if(isempty(fm))
        obj.status = false;
        obj.error = "Error while creating live script. This could be due to the target location not being writable.";
    end
end

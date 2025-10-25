classdef FolderReference< handle
%FolderReference Referenced folder information
%    Return information about a folder being referenced by the project.

 
%   Copyright 2022-2023 The MathWorks, Inc.

    methods
    end
    properties
        Delegate;

        % Full path to the project's path folder
        File;

        % Type specific path to the project's path folder
        StoredLocation;

        % Type of reference being defined
        Type;

    end
end

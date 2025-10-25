classdef FolderReference
%FolderReference Information about a referenced folder
%    Return information about a folder being referenced by the project.

 
%   Copyright 2014-2021 The MathWorks, Inc.

    methods
        function out=sort(~) %#ok<STOUT>
            % Return a sorted list of project path elements, keyed on File.
        end

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

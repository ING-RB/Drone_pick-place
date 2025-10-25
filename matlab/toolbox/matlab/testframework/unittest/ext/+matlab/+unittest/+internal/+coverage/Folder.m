classdef Folder < matlab.unittest.internal.coverage.MATLABSource
    % Class is undocumented and may change in a future release.
    
    %  Copyright 2017-2019 The MathWorks, Inc.
    
    properties (SetAccess = private)
        Name string = string.empty(1,0);
    end
    
    methods
        function sources = Folder(folders)
            sources = repmat(sources,size(folders));
            [sources.Name] = folders{:};
        end
        
        function files = getFiles(source)
            currentContent = what(char(source.Name));
            files = fullfile(string(currentContent.path),[currentContent.m; currentContent.mlx; currentContent.mlapp].');
        end
        
        function folderName = getFolderName(source)
            folderName = source.Name;
        end
    end
end
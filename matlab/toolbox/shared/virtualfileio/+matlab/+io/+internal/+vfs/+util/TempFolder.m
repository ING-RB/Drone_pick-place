classdef TempFolder < handle
%TempFolder A self cleaning folder object to create temporary copies of files.

%   Copyright 2018 The MathWorks, Inc.

    properties (SetAccess = immutable)
        % A temporary local folder name.
        FullPath
    end

    methods
        function obj = TempFolder()
            basePath = tempname;
            while (true)
                % One of the ways to avoid race conditions
                [status, message, messageID] = mkdir(basePath);
                if ~status
                    error(messageID, message);
                elseif isempty(messageID)
                    break;
                end
                basePath = tempname;
            end
            obj.FullPath = basePath;
        end

        function delete(obj)
            % Delete if there exists a temporary directory created by this object. 
            deleteIfExists(obj);
        end

        function deleteIfExists(obj)
            %DELETEIFEXISTS This helper deletes the temporary local files,
            % if a local directory was created during construction.
            if ~exist(obj.FullPath, 'dir')
                return;
            end
            rmdir(obj.FullPath, 's');
        end
    end
end

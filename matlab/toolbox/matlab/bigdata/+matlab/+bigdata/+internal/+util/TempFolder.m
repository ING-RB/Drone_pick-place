%TempFolder
% A helper class that maintains a local temporary folder. If this object is
% sent to a worker, the worker will not hold lifetime ownership over the
% temporary folder.

%   Copyright 2015-2020 The MathWorks, Inc.

classdef (Sealed) TempFolder < handle
    properties (SetAccess = immutable)
        % The path to the temporary local folder.
        Path;
        
        % Path in URI form.
        PathUri;
    end
    
    properties (GetAccess = private, SetAccess = immutable, Transient)
        % A flag that indicates if this instance is responsible for cleanup of the folder.
        ShouldCleanup = false;
    end
    
    methods
        % Create a temporary local folder.
        function obj = TempFolder
            [obj.Path, obj.PathUri] = iCreateTempFolder(matlab.bigdata.internal.util.TempFolder.tempPath());
            obj.ShouldCleanup = true;
        end
        
        function delete(obj)
            if obj.ShouldCleanup && exist(obj.Path, 'dir')
                matlab.io.internal.vfs.stream.removeFolder(obj.PathUri);
            end
        end
    end
    
    methods (Static)
        function out = tempPath(in)
            persistent value;
            if isempty(value) && ~nargin
                value = tempdir;
            end
            if nargout
                out = value;
            end
            if nargin
                mlock;
                value = in;
            end
        end
    end
end

function [path, pathUri] = iCreateTempFolder(tempPath)
while (true)
    path = tempname(tempPath);
    pathUri = matlab.io.datastore.internal.localPathToIRI(path);
    pathUri = pathUri{1};
    
    % We use this syntax as the only way to atomically detect
    % whether a folder already exists is to catch the warning
    % that is generated.
    [success, folderAlreadyExisted] = matlab.io.internal.vfs.stream.createFolder(pathUri);
    if success
        return;
    elseif ~folderAlreadyExisted
        matlab.bigdata.internal.io.throwTempStorageError();
    end
end
end

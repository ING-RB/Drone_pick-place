classdef RemoteToLocalFile < handle
%REMOTETOLOCALFILE A self cleaning object to get a local copy of a remote file.
%
% See also - matlab.io.datastore.splitreader.WholeFileCustomReadSplitReader

%   Copyright 2018 The MathWorks, Inc.
    properties (SetAccess = immutable)
        % Remote file name provided during construction.
        RemoteFileName
        % A temporary local file name, if RemoteFileName is in fact a remote file.
        % Otherwise, it is the same as the RemoteFileName.
        LocalFileName
    end

    properties (Access = private)
        % True if a local temporary copy has been created for the remote file.
        LocalCopyCreated = false
    end

    properties (Constant, Access = private)
        % Download 100MB at a time. If the remote file is 16GB or 100GB,
        % this prevents out of memory issues.
        STREAM_SIZE = 100*1024*1024; % 100 MB
    end

    methods
        function obj = RemoteToLocalFile(remoteFileName)
            %REMOTETOLOCALFILE A self cleaning object to get a local copy of a remote file.
            %
            % See also - matlab.io.datastore.splitreader.WholeFileCustomReadSplitReader

            %   Copyright 2018 The MathWorks, Inc.
            remoteFileName = convertStringsToChars(remoteFileName);
            if ~matlab.io.internal.validators.isCharVector(remoteFileName) || ...
                    isempty(remoteFileName)
                error(message('MATLAB:virtualfileio:path:cellWithEmptyStr', ...
                    'File input'));
            end
            obj.RemoteFileName = remoteFileName;
            obj.LocalFileName = createLocalFile(obj);
        end

        function delete(obj)
            % Delete if there's a local copy
            deleteIfLocalCopy(obj);
        end

    end % methods

    methods (Access = private)
        function localFile = createLocalFile(obj)
            %CREATELOCALFILE Create a local file, if RemoteFileName is in fact remote .
            import matlab.io.datastore.mixin.RemoteToLocalFile;
            if ~matlab.io.internal.vfs.validators.isIRI(obj.RemoteFileName)
                obj.LocalCopyCreated = false;
                localFile = obj.RemoteFileName;
                return;
            end
            localFile = copyFileToLocal(obj);
        end

        function localFile = copyFileToLocal(obj)
            %COPYFILETOLOCAL This helper creates the local file in a tempname base directory.
            if obj.LocalCopyCreated
                return;
            end
            basePath = tempname;
            while (true)
                [status, msg, msgID] = mkdir(basePath);
                if ~status
                    error(msgID, msg);
                elseif isempty(msgID)
                    break;
                end
                basePath = tempname;
            end

            import matlab.io.datastore.mixin.RemoteToLocalFile;
            % file to read from
            fileReader = fopen(obj.RemoteFileName, "r");
            if fileReader ~= -1
                c1 = onCleanup(@()fclose(fileReader));
                % file to write to
                [~, name, ext] = fileparts(char(obj.RemoteFileName));
                localFile = fullfile(basePath, [name ext]);
                fileWriter = fopen(localFile, 'a');
                c2 = onCleanup(@()fclose(fileWriter));

                while ~feof(fileReader)
                    uint8Values = fread(fileReader, ...
                        RemoteToLocalFile.STREAM_SIZE, "uint8=>uint8");
                    fwrite(fileWriter, uint8Values);
                end
                obj.LocalCopyCreated = true;
            else
                % first attempt to throw cloud exception
                matlab.io.internal.vfs.validators.validateCloudEnvVariables(obj.RemoteFileName);
                % if not cloud exception, throw local exception
                error(message("MATLAB:fopen:InvalidFileLocation"));
            end
        end

        function deleteIfLocalCopy(obj)
            %DELETEIFLOCALCOPY This helper deletes the temporary local file 
            % if a local copy was created during construction.
            if ~obj.LocalCopyCreated
                return;
            end
            localTempDir = fileparts(obj.LocalFileName);
            if exist(localTempDir, 'dir')
                rmdir(localTempDir, 's');
            end
            obj.LocalCopyCreated = false;
        end

    end % methods

end % classdef

classdef ZipToTempFileUtil < handle
%ZIPTOTEMPFILEUTIL A self cleaning object to get a local copy of a zip file.
%

%   Copyright 2021 The MathWorks, Inc.
    properties (SetAccess = public)
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
        function obj = ZipToTempFileUtil(remoteFileName)
        %ZipToTempFileUtil A self cleaning object to get a local copy of a zip file.
        %
            remoteFileName = convertStringsToChars(remoteFileName);
            if ~matlab.io.internal.validators.isCharVector(remoteFileName) || ...
                    isempty(remoteFileName)
                error(message('MATLAB:virtualfileio:path:cellWithEmptyStr', ...
                              'File input'));
            end

            if matlab.io.internal.vfs.validators.GetScheme(remoteFileName) == "file"
                obj.LocalCopyCreated = false;
                obj.RemoteFileName = remoteFileName;
                obj.LocalFileName = matlab.io.internal.vfs.validators.LocalPath(remoteFileName);
                return;
            end
            copyFileToLocal(obj, remoteFileName);
        end

        function delete(obj)
        % Delete if there's a local copy
            deleteIfLocalCopy(obj);
        end

    end % methods

    methods (Access = private)
        function copyFileToLocal(obj, remoteFileName)
        %COPYFILETOLOCAL This helper creates the local file in a tempname base directory.
            import matlab.internal.filesystem.ZipToTempFileUtil;
            if obj.LocalCopyCreated
                return;
            end
            basePath = tempname;
            while (true)
                % One of the ways to avoid race conditions
                [status, message, messageID] = mkdir(basePath);
                if ~status
                    error(messageID, message);
                elseif isempty(messageID)
                    % basePath folder created successfully, break out of loop and proceed
                    break;
                end
                basePath = tempname;
            end

            % self-open, self-close reader, that canonicalizes input paths
            reader = matlab.io.internal.vfs.stream.createStream(remoteFileName);
            obj.RemoteFileName = reader.Filename;
            [~, fName, ext] = fileparts(obj.RemoteFileName);
            localFile = fullfile(basePath, [fName ext]);
            fileID = fopen(localFile, 'a');

            if fileID ~= -1
                c = onCleanup(@()fclose(fileID));
            end

            while reader.tell < reader.FileSize
                uint8Values = reader.read(ZipToTempFileUtil.STREAM_SIZE, 'uint8');
                fwrite(fileID, uint8Values);
            end
            obj.LocalCopyCreated = true;
            obj.LocalFileName = localFile;
            
            % Make basePath folder and its contents read-only
            if ispc
                fileattrib(basePath,'-w','', 's');
            else
                fileattrib(obj.LocalFileName,'-w','a', 's');
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

classdef LocalToRemote < handle
%LOCALTOREMOTE A self cleaning object to write a local copy to a remote file.
%   LTR = LOCALTOREMOTE(REMOTELOCATION) creates a LocalToRemote object, that
%   helps in uploading local files to remote locations, such as Amazon S3, or
%   Microsoft Azure, or HDFS.
%
%   Example:
%   ========
%      % Set cloud credentials.
%      setenv('AWS_ACCESS_KEY_ID', <MY-KEY-ID>);
%      setenv('AWS_SECRET_ACCESS_KEY', <MY-ACCESS-KEY>);
%
%      % Setup LocalToRemote object with a remote folder.
%      remoteFolder = 's3://my-bucket/my-test';
%      ltr = matlab.io.internal.vfs.stream.LocalToRemote(remoteFolder);
%      % Set the file name that needs to go into the remote folder.
%      setfilename(ltr,'my-peppers.png');
%
%      % Validate path early and error before writing to local file.
%      try
%         validateRemotePath(ltr);
%      catch e
%         throw(e)
%      end
%
%      % Use ltr.CurrentLocalFilePath to write data locally.
%      a = imread('peppers.png');
%      imwrite(a,ltr.CurrentLocalFilePath,'png');
%
%      % Once done writing to the local file, then upload.
%
%      upload(ltr);
%
%   See also - matlab.io.internal.vfs.stream.RemoteToLocal

%   Copyright 2018-2021 The MathWorks, Inc.

    properties (SetAccess = immutable)
        %REMOTEFILENAME - Remote file name provided during construction.
        RemoteFolder
    end

    properties
        %CURRENTLOCALFILEPATH - local file name.
        CurrentLocalFilePath
    end

    properties (SetAccess = protected)
        %CURRENTLOCALFILESIZE - local file size.
        CurrentLocalFileSize
        %ISCURRENTFILEUPLOADED
        % Logical to indicate whether current local file is already uploaded or not.
        IsCurrentFileUploaded logical
    end

    properties (Access = private)
        %TEMPFOLDER - A temporary local folder that automatically cleans up.
        TempFolder
        %FileName
        RemoteFileName
        %Writer - Remote writer object.
        Writer
    end

    properties (Constant, Access = private)
        % Upload 32MB at a time. If the remote file is 16GB or 100GB,
        % this prevents out of memory issues.
        STREAM_SIZE = 32*1024*1024; % 32 MB
    end

    methods
        function obj = LocalToRemote(remoteFolder)
            remoteFolder= convertStringsToChars(remoteFolder);

            if ~matlab.io.internal.validators.isCharVector(remoteFolder) || ...
                    isempty(remoteFolder)
                error(message('MATLAB:virtualfileio:path:cellWithEmptyStr', ...
                    'Folder input'));
            end
            if ~iHasPathComponent(remoteFolder)
                obj.RemoteFolder = strcat(remoteFolder, '/');
            else
                obj.RemoteFolder = remoteFolder;
            end
            obj.IsCurrentFileUploaded = false;
        end

        function path = get.CurrentLocalFilePath(obj)
            path = obj.CurrentLocalFilePath;
        end

        function sz = get.CurrentLocalFileSize(obj)
            if isempty(obj.CurrentLocalFilePath)
                sz = 0;
                return;
            end
            info = dir(obj.CurrentLocalFilePath);
            if ~isempty(info)
                sz = info.bytes;
            else
                sz = 0;
            end
        end

        function set.CurrentLocalFilePath(obj, filename)
            validateattributes(filename, {'char','string'},{'scalartext'});
            obj.CurrentLocalFilePath = filename;
        end

        function validateRemotePath(obj)
            %VALIDATEREMOTEPATH Validate the remote path set on this object.
            % This expects the file name to be set. The correct sequence of
            % this method's invocation would be:
            %
            %      % Set cloud credentials.
            %      setenv('AWS_ACCESS_KEY_ID', <MY-KEY-ID>);
            %      setenv('AWS_SECRET_ACCESS_KEY', <MY-ACCESS-KEY>);
            %
            %      % Setup LocalToRemote object with a remote folder.
            %      remoteFolder = 's3://my-bucket/my-test';
            %      ltr = matlab.io.internal.vfs.stream.LocalToRemote(remoteFolder);
            %      % Set the file name that needs to go into the remote folder.
            %      setfilename(ltr,'my-peppers.png');
            %
            %      % Validate path early and error before writing to local file.
            %      try
            %         validateRemotePath(ltr);
            %      catch e
            %         throw(e)
            %      end
            %
            %   See also - matlab.io.internal.vfs.stream.LocalToRemote

            if obj.IsCurrentFileUploaded
                error(message('MATLAB:virtualfileio:localtoremote:currentFileUploaded'));
            end
            if matlab.io.internal.vfs.validators.GetScheme(obj.RemoteFolder) == "file"
                return;
            end
            if matlab.io.internal.vfs.validators.isIRI(obj.RemoteFolder)
                if isempty(obj.RemoteFileName)
                    error(message('MATLAB:virtualfileio:localtoremote:filenameNotSet'));
                end
                if isempty(obj.Writer)
                    try
                        obj.Writer = matlab.io.internal.vfs.stream.createStream(obj.RemoteFileName, 'w');
                    catch e
                        iConvertStreamException(e,obj.RemoteFolder);
                    end
                end
            end
        end

        function setfilename(obj, filename, ext)
            %SETFILENAME Sets the filename to be appended to the RemoteFolder and uploaded.
            % This method must be called before upload. The correct sequence of
            % this method's invocation would be:
            %
            %      % Set cloud credentials.
            %      setenv('AWS_ACCESS_KEY_ID', <MY-KEY-ID>);
            %      setenv('AWS_SECRET_ACCESS_KEY', <MY-ACCESS-KEY>);
            %
            %      % Setup LocalToRemote object with a remote folder.
            %      remoteFolder = 's3://my-bucket/my-test';
            %      ltr = matlab.io.internal.vfs.stream.LocalToRemote(remoteFolder);
            %      % Set the file name that needs to go into the remote folder.
            %      setfilename(ltr,'my-peppers.png');
            %
            %      % Validate path early and error before writing to local file.
            %      try
            %         validateRemotePath(ltr);
            %      catch e
            %         throw(e)
            %      end
            %
            %      % Use ltr.CurrentLocalFilePath to write data locally.
            %      a = imread('peppers.png');
            %      imwrite(a,ltr.CurrentLocalFilePath,'png');
            %
            %      % Once done writing to the local file, then upload.
            %
            %      upload(ltr);
            %
            %
            %   See also - matlab.io.internal.vfs.stream.LocalToRemote
            narginchk(1,3);
            localFile = tempname;
            [~, localFile, ~] = fileparts(localFile);
            if nargin < 3
                [~,filename, ext] = fileparts(filename);
            end

            if ~startsWith(ext,'.')
                error(message('MATLAB:virtualfileio:localtoremote:invalidFileExtension'));
            end

            if matlab.io.internal.vfs.validators.GetScheme(obj.RemoteFolder) == "file"
                obj.RemoteFileName = [obj.RemoteFolder, filename, ext];
                obj.CurrentLocalFilePath = fullfile(matlab.io.internal.vfs.validators.LocalPath(obj.RemoteFolder), [filename, ext]);
                return;
            end

            obj.CurrentLocalFilePath = generateLocalFileName(obj, localFile, ext);
            setRemoteFileName(obj, filename, ext);
        end

        function setRemoteFileName(obj, filename, ext)
            %SETREMOTEFILENAME Set the RemoteFileName property using the filename and extension.
            obj.RemoteFileName = [obj.RemoteFolder, filename, ext];
            obj.IsCurrentFileUploaded = false;
        end

        function upload(obj)
            %UPLOAD Uploads the LocalFileName to RemoteFileName.
            %   If RemoteFileName is not a valid remote URL, then this returns immediately.
            %   If RemoteFileName is a valid remote URL and cannot be created, this fails.
            validateRemotePath(obj);
            if matlab.io.internal.vfs.validators.GetScheme(obj.RemoteFileName) == "file"
                return;
            end
            fileID = fopen(obj.CurrentLocalFilePath, 'r');
            if fileID == -1
                error(message('MATLAB:virtualfileio:stream:fileNotFound',obj.CurrentLocalFilePath));
            end
            c = onCleanup(@()closeCleanup(obj,fileID));

            import matlab.io.internal.vfs.stream.LocalToRemote;
            if ~isOpen(obj.Writer)
                obj.Writer = matlab.io.internal.vfs.stream.createStream(obj.RemoteFileName, 'w');
            end
            while ~feof(fileID)
                uint8Values = fread(fileID, LocalToRemote.STREAM_SIZE, 'uint8=>uint8');
                try
                    write(obj.Writer, uint8Values);
                catch e
                    iConvertStreamException(e,obj.RemoteFolder);
                end
            end
            closeWriter(obj);
            obj.IsCurrentFileUploaded = true;
        end

    end

    methods (Access = private)
        function localFile = generateLocalFileName(obj, filename, ext)
            %CREATELOCALFILE Create a local file, if RemoteFileName is in fact remote .
            if matlab.io.internal.vfs.validators.isIRI(obj.RemoteFolder)
                import matlab.io.internal.vfs.util.TempFolder;
                obj.TempFolder = TempFolder(); %#ok<CPROPLC>
                localFolder = obj.TempFolder.FullPath;
            else
                localFolder = obj.RemoteFolder;
            end

            localFile = fullfile(localFolder, [filename, ext]);
        end

        function closeCleanup(obj, fileID)
            %CLOSECLEANUP Close the opened readable/writable streams.
            try
                fclose(fileID);
                closeWriter(obj);
            catch ME
                throwAsCaller(ME);
            end
        end

        function closeWriter(obj)
            %CLOSEWRITER Close the opened writable stream.
            try
                if isOpen(obj.Writer)
                    close(obj.Writer);
                end
            catch e
                iConvertStreamException(e,obj.RemoteFolder);
            end
        end
    end
end

function iConvertStreamException(streamException, remoteFolder)
    import matlab.io.internal.vfs.util.convertStreamException;
    error(convertStreamException(streamException,remoteFolder));
end

function tf = iHasPathComponent(remoteFolder)
    tf = false;
    if ~endsWith(remoteFolder, '/')
        return;
    end
    import matlab.io.internal.vfs.validators.isIRI;
    import matlab.io.internal.vfs.validators.hasIriPrefix;
    if ~isIRI(remoteFolder) && hasIriPrefix(remoteFolder)
        return;
    end
    tf = true;
end

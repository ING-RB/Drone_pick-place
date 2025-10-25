classdef RemoteToLocal < handle
    %REMOTETOLOCAL A self cleaning object to get a local copy of a remote file.
    %
    % See also - matlab.io.datastore.splitreader.WholeFileCustomReadSplitReader

    %   Copyright 2018-2024 The MathWorks, Inc.
    properties (SetAccess = private)
        % Remote file name provided during construction.
        RemoteFileName
        % A temporary local file name, if RemoteFileName is in fact a remote file.
        % Otherwise, it is the same as the RemoteFileName.
        LocalFileName
        % A weboptions object to configure the websave request
        WebOptions
        % File Type
        FileType
    end

    properties (Access = private)
        % True if a local temporary copy has been created for the remote file.
        LocalCopyCreated = false

        RemoteFileIsHTTP = false;

        Scheme = '';

        Extension = '';
    end

    properties (Constant, Access = private)
        % Download 100MB at a time. If the remote file is 16GB or 100GB,
        % this prevents out of memory issues.
        STREAM_SIZE = 100*1024*1024; % 100 MB

        % G3334265: Reading from BinaryStream gets stuck in infinite loop
        % when file size obtained from HTTP headers is different from
        % actual file size obtained during reading. Retry for 3 more times
        % in such cases and exit if no data was read.
        MAX_RETRIES = 3;
        RETRY_DELAY = 0.5; % Delay between retries in seconds.
        START_RETRY_NUM = 0;

        URL_PATH_SEP = '/';
    end

    methods
        function obj = RemoteToLocal(remoteFileName, webOptions, fileType)
            %RemoteToLocal A self cleaning object to get a local copy of a remote file.
            %
            % See also - matlab.io.datastore.splitreader.WholeFileCustomReadSplitReader
            remoteFileName = convertStringsToChars(remoteFileName);
            if ~matlab.io.internal.validators.isCharVector(remoteFileName) || ...
                    isempty(remoteFileName)
                error(message('MATLAB:virtualfileio:path:cellWithEmptyStr', ...
                    'File input'));
            end

            isValidIRI = matlab.io.internal.vfs.validators.isIRI(remoteFileName);
            startsWithHTTP = startsWith(remoteFileName, ["http://", "https://"], "IgnoreCase", true);

            if ~isValidIRI && ~startsWithHTTP % HTTP/S URLs with query or fragments immediately after the domain without a slash might still fail for isIRI.
                % Assume that file isn't located on remote storage
                obj.LocalCopyCreated = false;
                obj.RemoteFileName = remoteFileName;
                obj.LocalFileName = obj.RemoteFileName;
                return;
            end

            [obj.Scheme, obj.Extension] = matlab.io.internal.vfs.stream.RemoteToLocal.getSchemeAndExtension(remoteFileName);
            if obj.Scheme == "file"
                obj.LocalCopyCreated = false;
                obj.RemoteFileName = remoteFileName;
                obj.LocalFileName = matlab.io.internal.vfs.validators.LocalPath(remoteFileName);
                return;
            elseif (any(obj.Scheme == ["http", "https"]))
                obj.RemoteFileIsHTTP = true;
            end

            if nargin >= 2 && ~isempty(webOptions)
                obj.WebOptions = webOptions;
            end

            if nargin >= 3 && ~isempty(fileType)
                obj.FileType = fileType;
            end

            copyFileToLocal(obj, remoteFileName);
        end

        function delete(obj)
            % Delete if there's a local copy
            deleteIfLocalCopy(obj);
        end
    end % methods

    methods (Static)
        function tf = hasHTTPSPrefix(filename)
            import matlab.io.internal.vfs.stream.RemoteToLocal.*;
            tf = any(getSchemeAndExtension(filename) == ["http", "https"]);
        end

        function [scheme, ext] = getSchemeAndExtension(remoteFileName)
            import matlab.io.internal.vfs.stream.RemoteToLocal;

            scheme = '';
            ext = '';
            try
                % Forward slashes can only be path separators in IRIs and
                % so can be safely trimmed off from beginning and end.
                remoteFileName = strip(remoteFileName, "both", RemoteToLocal.URL_PATH_SEP);

                % Path utility can handle IRIs including HTTP/S URLs with
                % "?" query and/or "#" fragment components.
                % Use internal Path utility for better performance.
                pathObj = matlab.io.internal.filesystem.pathObject(remoteFileName, "Type", "schema");

                if ~ismissing(pathObj.PathType)
                    % Schemes are always lower case.
                    scheme = lower(char(pathObj.PathType));
                end

                if ~ismissing(pathObj.Extension)
                    % Extension cannot have spaces, trim if any carried
                    % over spaces from the original IRI.
                    ext = strtrim(char(pathObj.Extension));
                end
            catch
                % Swallow exceptions.
            end
        end
    end

    methods (Access = private)
        function copyFileToLocal(obj, remoteFileName)
            %COPYFILETOLOCAL This helper creates the local file in a tempname base directory.
            import matlab.io.internal.vfs.stream.RemoteToLocal;
            if obj.LocalCopyCreated
                return;
            end
            basePath = tempname;
            while (true)
                % One of the ways to avoid race conditions
                [status, msg, msgID] = mkdir(basePath);
                if ~status
                    error(msgID, msg);
                elseif isempty(msgID)
                    break;
                end
                basePath = tempname;
            end

            obj.RemoteFileName = remoteFileName;

            if obj.RemoteFileIsHTTP && ~isempty(obj.WebOptions)
                % Use websave only when weboptions are provided.

                [~, fName, ~] = fileparts(tempname); % generate local name

                % Check for Google Sheet URI & that the FileType has been specified as "spreadsheet"
                if startsWith(remoteFileName, "https://docs.google.com/spreadsheets") && ~isempty(obj.FileType) && obj.FileType == "spreadsheet"
                    % Google sheet, extension should be xlsx
                    localFile = fullfile(basePath, fName + ...
                        matlab.io.internal.FileExtensions.SpreadsheetExtensions(1));
                    if ~endsWith(remoteFileName, '/export')
                        if endsWith(remoteFileName, RemoteToLocal.URL_PATH_SEP)
                            remoteFileName = strcat(remoteFileName, 'export');
                        else
                            remoteFileName = strcat(remoteFileName, '/export');
                        end
                        obj.RemoteFileName = remoteFileName;
                    end
                else
                    localFile = fullfile(basePath, fName);
                end

                downloadFromURL(obj, remoteFileName, localFile);
            else
                % No weboptions, do not download using websave.

                % self-open, self-close reader, that canonicalizes input paths
                reader = matlab.io.internal.vfs.stream.createStream(remoteFileName);

                % G3344867: readtable not working for HTTP file which
                % doesn't have Content-Length information in the response.
                if hasValidFileSize(reader)
                    maxFileSize = reader.FileSize;
                else
                    maxFileSize = Inf;
                end

                if maxFileSize == 0 && obj.RemoteFileIsHTTP
                    % G3351074: readtable does not work for URLs with APIs
                    % when HEAD response has Content-Length: 0.
                    maxFileSize = Inf;
                end

                obj.RemoteFileName = reader.Filename;

                % Construct local filename with same extension as the
                % remote file or the default empty extension if no
                % extension in input.
                [~, fName, ~] = fileparts(tempname);
                obj.LocalFileName = fullfile(basePath, [fName, obj.Extension]);

                writer = fopen(obj.LocalFileName, 'a');
                if writer ~= -1
                    c = onCleanup(@() fclose(writer));
                    % For cleaning up any local copy.
                    obj.LocalCopyCreated = true;
                end

                readerReadRetryNum = RemoteToLocal.START_RETRY_NUM;
                hasReadSomeData = false;
                while (reader.tell < maxFileSize) && (readerReadRetryNum <= RemoteToLocal.MAX_RETRIES)
                    uint8Values = reader.read(RemoteToLocal.STREAM_SIZE, 'uint8');
                    if isempty(uint8Values)
                        % Retry the read operation if no data was read.
                        if ~hasReadSomeData
                            % Before retrying, wait for a bit only if no
                            % data was read so far. Else, just retry
                            % without any delays as some data that was read
                            % already is available and the empty read is
                            % possibly due to dynamic FileSize from server.
                            pause(RemoteToLocal.RETRY_DELAY*(readerReadRetryNum+1));
                        end
                        readerReadRetryNum = readerReadRetryNum + 1;
                        continue;
                    else
                        % For non-empty reads, write out the data.
                        fwrite(writer, uint8Values);
                        % Reset the read flag and retry counter after a successful read.
                        hasReadSomeData = true;
                        readerReadRetryNum = RemoteToLocal.START_RETRY_NUM;
                    end
                end
            end
        end

        function downloadFromURL(obj, filename, localFile)
            %DOWNLOADFROMURL Utility function for downloading from HTTP/S locations
            obj.LocalCopyCreated = true;
            try
                % call websave to download local copy of file
                if isempty(obj.WebOptions)
                    obj.LocalFileName = websave(localFile, filename);
                else
                    obj.LocalFileName = websave(localFile, filename, obj.WebOptions);
                end
            catch ME
                % log the localFile that would have been written so
                % that the enclosing folder is cleaned up
                obj.LocalFileName = localFile;

                % throw error message when file is not found, add the
                % exception from websave as a cause
                baseException = MException('MATLAB:virtualfileio:stream:fileNotFound', ...
                    message('MATLAB:virtualfileio:stream:fileNotFound', filename));
                exception = addCause(baseException, ME);
                throw(exception);
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
classdef (Abstract) FileWritable < handle
%FileWritable Declares the expected interface for writable datastores
%   This class captures the interface expected of writable datastores.
%   FileWritable is a handle class.
%
%   FileWritable Properties:
%
%   SupportedOutputFormats - List of formats supported that can be written
%                            by this datastore.
%   DefaultOutputFormat    - The output format that will be written to when
%                            no output format is supplied via writeall.
%
%   FileWritable Property Attributes:
%
%   SupportedOutputFormats     - Public, Constant, Abstract
%   DefaultOutputFormat        - Public, Constant, Abstract
%
%   FileWritable Methods:
%
%   writeall                   - Read all the data in the datastore and
%                                write to a provided location.
%   write                      - Writes the output of a single read from
%                                the datastore.
%   getFiles                   - Returns the files backing this datastore.
%   getFolders                 - Returns the folders backing this datastore.
%   getCurrentFilename         - Get the file name for the file read from
%                                the datastore.
%   currentFileIndexComparator - Compare the index of the file read from
%                                the datastore to the file written to the
%                                output location.
%
%   FileWritable Method Attributes:
%
%   writeall                   - Public
%   write                      - Protected
%   getFiles                   - Protected
%   getFolders                 - Protected
%   getCurrentFilename         - Protected
%   currentFileIndexComparator - Protected
%
%   Subclasses derived from the FileWritable class must implement the
%   SupportedOutputFormats and DefaultOutputFormat properties. If the 
%   return data type from the read of the datastore is not one of the
%   following - "table", or "numeric matrix" (either representing an
%   image or an audio signal), the subclass must implement the write method.
%
%   Subclasses backed by files and folders that do not expose properties
%   named Files and Folders, and want to utilize the FolderLayout behavior
%   correctly,must implement the getFiles and getFolders methods.
%
%   Subclasses that can make multiple reads from the same file must implement
%   the currentFileIndexComparator method to avoid errors associated with
%   overwriting.
%
%   See also matlab.io.Datastore,
%            matlab.io.datastore.Partitionable, 
%            matlab.io.datastore.HadoopFileBased.

%   Copyright 2023-2024 The MathWorks, Inc.

    properties (Abstract, Constant)
        %SUPPORTEDOUTPUTFORMATS List of formats supported by this datastore
        SupportedOutputFormats (1,:) string;
        DefaultOutputFormat (1,1) string;
    end

    properties (Access = protected, Constant)
        %WRITER Writing logic for output formats supported by MATLAB
        Writer = matlab.io.datastore.writer.FileWriter();
    end

    properties (Access = protected, Transient)
        %ORIGFILESEP File separator identified from the output location
        OrigFileSep;
    end

    properties (Access = private, Transient)
    	%PARQUETWRITER Special functionality for writing to Parquet
        ParquetWriter;
    end

    methods (Access = protected)
        function tf = write(ds, data, writeInfo, outputFmt, varargin)
            %WRITE Logic for writing data read from datastore
            tf = ds.Writer.write(data, writeInfo, outputFmt, varargin{:});
        end

        function folders = getFolders(ds)
            %GETFOLDERS Get list of folders backing this datastore

            import matlab.io.datastore.internal.folders.addTrailingSlash;
            import matlab.io.datastore.internal.normalizeToCellstrColumnVector;
 
            try
                folders = ds.Folders;
            catch
                warning(message("MATLAB:io:datastore:write:write:NoFoldersDetected"));
                folders = {};
            end

            % Error early if Folders has an invalid datatype.
            folders = normalizeToCellstrColumnVector(folders);
            if ~iscellstr(folders) %#ok<ISCLSTR>
                error(message("MATLAB:io:datastore:write:write:IncorrectFoldersPropertyType"));
            end

            % Add a trailing separator to the folders list since the Folders
            % property does not have trailing separators anymore.
            folders = unique(folders);
            folders = addTrailingSlash(folders);
        end

        function tf = currentFileIndexComparator(~, ~)
            %CURRENTFILEINDEXCOMPARATOR Compare file indices
            %   Compare file index of file read from the datastore to the
            %   index of the file written by datastore. This provides an
            %   indication of the number of reads per file. Returns false
            %   by default.
            tf = false;
        end

        function filename = getCurrentFilename(~, info)
            %GETCURRENTFILENAME Get the current file name
            %   Get the name of the file read by the datastore
            if iscell(info)
                filename = strings(numel(info),1);
                for ii = 1 : numel(info)
                    if isfield(info{ii}, "Filename")
                        filename(ii) = info{ii}.Filename;
                    else
                        filename(ii) = "";
                    end
                end
            elseif isfield(info, "Filename")
                filename = string(info.Filename);
            else
                filename = "";
            end
        end

        function location = validateOutputLocation(ds, location)
            %VALIDATEOUTPUTLOCATION Validate the output location
            % Convert to a string array.
            location = string(location);

            tf = matlab.io.internal.vfs.validators.isIRI(convertStringsToChars(location));

            % G3361228: Error immediately if output location is HTTP/S.
            if tf && startsWith(location, ["http", "https"], "IgnoreCase", true)
                error(message("MATLAB:virtualfileio:stream:writeNotAllowed"));
            end

            % Make sure that the output location has a trailing '/' or '\'.
            if tf
                ds.OrigFileSep = "/";
            else
                ds.OrigFileSep = filesep;
            end

            if ~endsWith(location, ds.OrigFileSep)
                location = location + ds.OrigFileSep;
            end

            if ispc && ~tf
                % update the location with the correct file separators for
                % Windows paths
                location = replace(location, "/", "\");
            end
        end
    end

    methods(Access = {?matlab.io.datastore.FileWritable, ...
            ?matlab.bigdata.internal.executor.FullfileDatastorePartitionStrategy})
        function files = getFiles(ds)
            %GETFILES Get list of files backing this datastore
            try
                files = ds.Files;
            catch ME
                error(message("MATLAB:io:datastore:write:write:NoFilesProperty"));
            end
        end
    end

    methods
        function writeall(ds, location, varargin)
            %WRITEALL    Read all the data in the datastore and write to disk
            %   WRITEALL(DS, OUTPUTLOCATION) will write files to the
            %   specified output location using the default writer and file
            %   format for the datastore DS.
            %
            %   WRITEALL(__, "OutputFormat", FORMAT) writes files using the
            %   specified output format. The allowed FORMAT values are:
            %     - Tabular formats: "txt", "csv", "xlsx", "xls",
            %     "parquet", "parq"
            %     - Image formats: "png", "jpg", "jpeg", "tif", "tiff"
            %     - Audio formats: "wav", "ogg", "opus", "flac", "mp3",
            %                      "mp4", "m4a"
            %
            %   WRITEALL(__, "FolderLayout", LAYOUT) specifies whether folders
            %   should be copied from the input data locations. Specify
            %   LAYOUT as one of these values:
            %
            %     - "duplicate" (default): Input folders contained
            %       within the folders listed in the "Folders"
            %       property are copied to the output location.
            %
            %     - "flatten": Files are written directly to the output
            %       location without generating any intermediate folders.
            %
            %   WRITEALL(__, "UseParallel", TF) specifies whether a parallel
            %   pool is used to write data. By default, "UseParallel" is
            %   set to false.
            %
            %   WRITEALL(__, "FilenamePrefix", PREFIX) specifies a common
            %   prefix to be applied to the output file names.
            %
            %   WRITEALL(__, "FilenameSuffix", SUFFIX) specifies a common
            %   suffix to be applied to the output file names.
            %
            %   WRITEALL(__, "WriteFcn", @MYCUSTOMWRITER) customizes the
            %   function that is executed to write each file. The function
            %   signature of the "WriteFcn" must be similar to:
            %
            %      function MYCUSTOMWRITER(data, writeInfo, outputFmt, varargin)
            %         ...
            %      end
            %
            %   where 'data' is the output of the read method on the
            %   datastore, 'outputFmt' is the output format to be written,
            %   and 'writeInfo' is a struct containing the
            %   following fields:
            %
            %     - "ReadInfo": the second output of the read method.
            %
            %     - "SuggestedOutputName": a fully qualified, unique file
            %       name that meets the location and naming requirements.
            %
            %     - "Location": the location argument passed to the write
            %       method.
            %   Any optional Name-Value pairs can be passed in via varargin.
            %
            %   See also: matlab.io.Datastore
            import matlab.io.datastore.write.*;
            try
                % Validate the location input first.
                location = validateOutputLocation(ds, location);
                ds.OrigFileSep = matlab.io.datastore.internal.write.utility.iFindCorrectFileSep(location);

                % if this datastore is backed by files, get list of files
                files = getFiles(ds);
                if isempty(files)
                    error(message("MATLAB:io:datastore:write:write:EmptyDatastore"));
                end

                % if this datastore is backed by files, get list of folders
                folders = getFolders(ds);

                % Validate name-value pairs.
                nvStruct = parseWriteallOptions(ds, varargin{:});
                outFmt = ds.SupportedOutputFormats;
                nvStruct = validateWriteallOptions(ds, folders, nvStruct, outFmt);

                % Construct the output folder structure.
                createFolders(ds, location, folders, nvStruct.FolderLayout);

                % Write using a serial or parallel strategy.
                writeParallel(ds, location, files, nvStruct);
            catch ME
                % Throw an exception without the full stack trace. If the
                % MW_DATASTORE_DEBUG environment variable is set to 'on',
                % the full stacktrace is shown.
                handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
                handler(ME);
            end
        end
    end

    methods(Access = protected)
        writeSerial(ds, location, compressStr, nvStruct);
        writeParallel(ds, location, files, nvStruct);
        writeHadoop(ds, location, compressStr, mr, nvStruct);
        createFolders(ds, outputLocation, files, folders, folderLayout);
    end
end

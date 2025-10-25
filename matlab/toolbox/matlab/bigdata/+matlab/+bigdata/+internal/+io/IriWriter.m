classdef IriWriter < matlab.bigdata.internal.io.Writer & matlab.mixin.Copyable
    %IRIWRITER A writer that stages files to a temporary location before
    %   uploading them to a remote IRI.  The upload is performed as the last
    %   step in commit, where any files that were previously written to the
    %   temporary location will then be copied to the remote storage location.
    %   Note this assumes that the portion of the dataset written by a single
    %   writer instance can fit in a temporary location.
    
    %   Copyright 2018-2020 The MathWorks, Inc.
    
    properties (Access = private)
        TempFolder
    end
    
    properties (SetAccess = immutable)
        % The temporary location where files are locally written to.
        Location
        
        % The remote destination represented as an IRI
        DestinationIri
    end
    
    properties
        UnderlyingWriter
    end
    
    methods
        function obj = IriWriter(location)
            obj.TempFolder = matlab.bigdata.internal.util.TempFolder();
            obj.Location = iEnsureEndsWithFilesep(obj.TempFolder.Path);
            obj.DestinationIri = location;
        end
        
        function set.UnderlyingWriter(obj, underlyingWriter)
            obj.UnderlyingWriter = underlyingWriter;
            assertWriterIsValid(obj);
        end
        
        function add(obj, value)
            assertWriterIsValid(obj);
            add(obj.UnderlyingWriter, value);
        end
        
        function commit(obj)
            import matlab.io.internal.vfs.util.convertStreamException
            
            assertWriterIsValid(obj);
            commit(obj.UnderlyingWriter);
            
            try
                doUpload(obj);
            catch e
                error(convertStreamException(e, obj.DestinationIri));
            end
        end
    end
    
    methods (Access = private)
        function assertWriterIsValid(obj)
            isaWriter = isa(obj.UnderlyingWriter, ...
                'matlab.bigdata.internal.io.Writer');
            
            assert(isaWriter && isvalid(obj.UnderlyingWriter), ...
                "Invalid UnderlyingWriter");
        end
        
        function doUpload(obj)
            import matlab.bigdata.internal.io.uploadfile
            import matlab.io.datastore.internal.iriFullfile
            import matlab.io.datastore.internal.pathLookup
            
            try
                includeSubfolders = true;
                files = pathLookup(obj.Location, includeSubfolders);
            catch
                % No files in location -> underlying writer did not write
                % any files for this partition.
                return;
            end
            
            for ii = 1:numel(files)
                % Upload file with the same name to the remote IRI
                fii = files{ii};
                filePath = extractAfter(files{ii}, obj.Location);
                fileParts = split(filePath, filesep);
                remoteDestIri = iriFullfile(obj.DestinationIri, fileParts{:});
                uploadfile(fii, remoteDestIri);
            end
        end
    end
end

function folderPath = iEnsureEndsWithFilesep(folderPath)
if ~endsWith(folderPath, filesep)
    folderPath = append(folderPath, filesep);
end
end
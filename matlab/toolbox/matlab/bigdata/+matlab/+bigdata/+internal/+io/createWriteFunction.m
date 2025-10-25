function writeFunction = createWriteFunction(varargin)
%CREATEWRITEFUNCTION Creates the function handle used to WRITE.
%
%   fileType must be one of:
%
%   * "auto"         the most efficient format for the target filesystem
%   * "sequence"     MathWorks specific Hadoop sequence files
%   * "mat"          MathWorks specific binary files
%   * "text"         Text-based formats including CSV.
%   * "spreadsheet"  Export to spreadsheets.
%   * "custom"       User-supplied function handle.

%   Copyright 2018-2019 The MathWorks, Inc.

% Bind in the input arguments as well as the maximum block size on the client.
% The necessary writer will be instantiated based on these arguments on the
% (potentially remote) workers.  By default ChunkedWriter.maxChunkSize
% determines the block size used except when writing to the Parquet format,
% where ParquetFileArrayWriter.maxRowGroupSize is used instead to allow
% independent tuning of the block size when writing for the Parquet format.
import matlab.bigdata.internal.io.ChunkedWriter
import matlab.bigdata.internal.io.ParquetFileArrayWriter

fileType = varargin{1};

if fileType == "parquet"
    maxChunkSizeInBytes = ParquetFileArrayWriter.maxRowGroupSize();
else
    maxChunkSizeInBytes = ChunkedWriter.maxChunkSize();
end

fh = @(partitionIndex, numPartitions) iCreateWriter(...
    partitionIndex, numPartitions, maxChunkSizeInBytes, varargin{:});

writeFunction = matlab.bigdata.internal.io.WriteFunction(fh);
end

%--------------------------------------------------------------------------
function outputWriter = iCreateWriter(...
    partitionIndex, numPartitions, maxChunkSizeInBytes, ...
    fileType, location, filePattern, isIri, isHdfs, otherArgs, fcn)

import matlab.bigdata.internal.io.ChunkedWriter
import matlab.bigdata.internal.io.CustomArrayWriter
import matlab.bigdata.internal.io.IriWriter
import matlab.bigdata.internal.io.MatArrayWriter
import matlab.bigdata.internal.io.SequenceFileArrayWriter
import matlab.bigdata.internal.io.ParquetFileArrayWriter
import matlab.io.datastore.internal.PathTools

% Convert file IRIs to an absolute path as seen by a worker.
isFileIri = isIri && startsWith(location, 'file');

if isFileIri
    location = PathTools.convertIriToLocalPath(location);
end

% The IriWriter is used for remote IRI destinations.  Except for:
%  * When the location is specified as a file IRI which must be resolved as
%    an absolute path on the worker to support writing to NFS locations.
%  * Writing SEQ files to HDFS as the SequenceFileArrayWriter has native
%    support for writing directly to HDFS.
%  * Writing Parquet format files as this has native VFS support.
useIriWriter = isIri && ~isFileIri ...
    && ~(isHdfs && any(fileType == ["auto" "sequence"])) ...
    && fileType ~= "parquet";

if useIriWriter
    iriWriter = IriWriter(location);
    location = iriWriter.Location;
end

if fileType == "auto"
    % Default to sequence files for HDFS, MAT files everywhere else
    if isHdfs
        outputWriter = SequenceFileArrayWriter(...
            partitionIndex, numPartitions, ...
            location, filePattern);
    else
        outputWriter = MatArrayWriter(...
            partitionIndex, numPartitions, ...
            location, filePattern);
    end
    
elseif fileType == "sequence"
    % Force use of sequence files, even if not HDFS
    outputWriter = SequenceFileArrayWriter(...
        partitionIndex, numPartitions, ...
        location, filePattern);
    
elseif fileType == "mat"
    % Force use of MAT files, even if writing to HDFS
    outputWriter = MatArrayWriter(...
        partitionIndex, numPartitions, ...
        location, filePattern);
    
elseif fileType == "parquet"
    outputWriter = ParquetFileArrayWriter(...
        partitionIndex, numPartitions, ...
        location, otherArgs, filePattern);
    
elseif fileType == "spreadsheet"
    if strlength(filePattern)==0
        filePattern = "data_*.xls";
    end
    
    % WRITETABLE only allows 65535 rows. Aim a bit below that to be
    % safe.
    maxRows = 65000;
    writeFcn = @(a,b) iWriteSpreadsheet(a, b, otherArgs);
    
    outputWriter = CustomArrayWriter(...
        writeFcn, partitionIndex, numPartitions, ...
        location, filePattern, maxRows);
    
elseif fileType == "text"
    if strlength(filePattern)==0
        filePattern = "data_*.txt";
    end
    writeFcn = @(a,b) iWriteText(a, b, otherArgs);
    
    outputWriter =  CustomArrayWriter(...
        writeFcn, partitionIndex, numPartitions, ...
        location, filePattern, []);
    
elseif fileType == "custom"
    if strlength(filePattern)==0
        filePattern = "data_*";
    end
    
    outputWriter = CustomArrayWriter(...
        fcn, partitionIndex, numPartitions, ...
        location, filePattern, []);
    
else
    assert("Unsupported fileType: " + fileType);
end

outputWriter = ChunkedWriter(outputWriter, maxChunkSizeInBytes);

if useIriWriter
    iriWriter.UnderlyingWriter = outputWriter;
    outputWriter = iriWriter;
end
end

%--------------------------------------------------------------------------
% Custom function to write a single spreadsheet file using WRITETABLE
function iWriteSpreadsheet(info, data, otherArgs)
writetable(data, info.SuggestedFilename, 'FileType', 'spreadsheet', ...
    'Basic', true, ... % Prevent use of Excel as it doesn't work on workers on Windows
    otherArgs{:})
end

%--------------------------------------------------------------------------
% Custom function to write a single text file using WRITETABLE
function iWriteText(info, data, otherArgs)
writetable(data, info.SuggestedFilename, 'FileType', 'text', otherArgs{:})
end

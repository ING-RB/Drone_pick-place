function tf = write(ds, data, writeInfo, outputFmt, varargin)
%
%
%

%   Copyright 2022 The MathWorks, Inc.

tf = false; %#ok<NASGU>
idx = ds.CurrentDatastoreIndex;

try
    if ~any(contains(ds.SupportedOutputFormats, outputFmt))
        tf = ds.UnderlyingDatastores{idx}.write(data, writeInfo, outputFmt, varargin{:});
    else
        tf = ds.Writer.write(data, writeInfo, outputFmt, varargin{:});
    end
catch causeException
    noFilesWrittenException = getNoFilesWrittenException(outputFmt, idx);
    baseException = addCause(noFilesWrittenException, causeException);
    throwAsCaller(baseException);
end

if ~tf
    throwAsCaller(getNoFilesWrittenException(outputFmt, idx));
end
end

function noFilesWrittenException = getNoFilesWrittenException(outputFmt, idx)
noFilesWrittenMsgID = "MATLAB:io:datastore:common:sequentialdatastore:UnderlyingDatastoreNoFilesWritten";
noFilesWrittenMessage = message(noFilesWrittenMsgID, outputFmt, idx).getString();

writeallErrorMessage = message("MATLAB:io:datastore:common:sequentialdatastore:WriteallError").getString();

noFilesWrittenException = MException(noFilesWrittenMsgID, [noFilesWrittenMessage, '\n', writeallErrorMessage]);
end
function extractedFilePath = extractFileToTempLocation(iri)
% extractFileToTempLocation Extracts the specified file to temp location on OS and sets the permission to read-only. 
%
%   matlab.internal.filesystem.extractFileToTempLocation(iri)
%   Extracts the specified file to temp location on OS and sets the permission to read-only. 
%

% Copyright 2021 The MathWorks, Inc.
mlock;
persistent extractedTempFiles;
persistent extractedTempFile;
extractedTempFile = matlab.internal.filesystem.ZipToTempFileUtil(iri);
extractedTempFiles = [extractedTempFiles extractedTempFile];
extractedFilePath = extractedTempFile.LocalFileName;
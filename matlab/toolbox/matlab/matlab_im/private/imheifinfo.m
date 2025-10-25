function info = imheifinfo(filename)
%IMHEIFINFO Information about a HEIF file.
%   INFO = IMHEIFINFO(FILENAME) returns a structure containing
%   information about the HEIF file specified by the string
%   FILENAME.

%   Copyright 2024-2025 The MathWorks, Inc.

arguments
    filename (1,:) char {mustBeFile}
end

% The libheif and libde265 3p libraries cannot be packaged in a deployed
% application due to their legal conditions. Hence the deployed workflow is
% currently not supported for HEIF/HEIC images
if isdeployed
    error(message('MATLAB:imagesci:imread:heifDeploymentNotSupported'));
end

% Check if the HEIF support package is installed. Else throw an error
if ~(isHEIFPackageInstalled)
    % Unique identifier for HEIF data
    heifData = 'ML_HEIF';
    % HEIF Support Package base code
    heifSpkgBasecode = 'ML_HEIF_HEIC';
    % Function from where customers will call this file
    heifFunction = 'imfinfo';
    % Support Package Name
    heifSpkgName = 'HEIF/HEIC Image Format';
    error(message('MATLAB:imagesci:imread:spkgNotInstalled',filename,heifFunction,heifData,heifSpkgBasecode,heifSpkgName));
end

% Read the metadata from the image. We do not need the decoded image
[~,info] = readheifutil(filename,readImage = false);

% The order in which fields should appear in the output display
fieldOrder = ["Filename","FileModDate","FileSize",string(fieldnames(info))'];

% Get basic information about the file
fileInfo = dir(filename);
% Parse the file information
info.Filename = fileInfo.name;
info.FileModDate = datetime(fileInfo.datenum,"ConvertFrom","datenum");
info.FileSize = fileInfo.bytes;

% Order the output fields in the desired order
info = orderfields(info,fieldOrder);
end





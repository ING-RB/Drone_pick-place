function [X,map,alpha] = readheif(filename,options)
% READHEIF Reads an image from a HEIF file.

%   Copyright 2024-2025 The MathWorks, Inc.

arguments
    filename (1,:) char {mustBeFile}
    % HEIF images will be Auto oriented by default
    options.AutoOrient (1,1) logical = true
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
    heifFunction = 'imread';
    % Support Package Name
    heifSpkgName = 'HEIF/HEIC Image Format';
    error(message('MATLAB:imagesci:imread:spkgNotInstalled',filename,heifFunction,heifData,heifSpkgBasecode,heifSpkgName));
end

% We currently don't support reading the alpha channel of HEIF images
if nargout > 2
    % Save the user's current warning stack trace settings
    currentBacktraceState = warning('query','backtrace');
    % Ensure the original warning stack trace settings are restored
    % when this function completes execution
    restoreBacktraceState = onCleanup(@()warning(currentBacktraceState));
    % Disable the warning stack trace
    warning('off','backtrace');
    % Issue a warning indicating that the alpha channel is not supported
    warning(message('MATLAB:matlab_images:heif:heif:alphaNotSupported'))
    % Initialize the alpha variable as empty since alpha channel is not supported
    alpha = [];
end

% Get the decoded RGB image from the file
[X,info] = readheifutil(filename, readImage = true);

if (options.AutoOrient) && isfield(info, "Orientation")
    % Apply Exif Orientation value to the image data
    X = applyExifOrientation(X, info.Orientation);
end

% colormap does not apply to HEIF images
map = [];
end

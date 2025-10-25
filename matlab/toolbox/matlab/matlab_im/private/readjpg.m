function [A,map] = readjpg(filename, options)
% READJPG Read image data from a JPEG file.

%  Copyright 1984-2024 The MathWorks, Inc.

arguments
    filename (1,:) char
    options.AutoOrient (1,1) {mustBeA(options.AutoOrient,'logical')} = false
end

% turn off all warnings for call to imfinfo
origWarnState = warning('off');
restoreWarnings = onCleanup(@()warning(origWarnState));

% Disable reading XMP Data using parameter "readXmpData " as false
info = imjpginfo(filename,"readXmpData", false);
clear("restoreWarnings")

depth = info.BitDepth / info.NumberOfSamples;

if depth <= 8
    A = matlab.internal.imagesci.rjpg8c(filename);
elseif depth <= 12
    A = matlab.internal.imagesci.rjpg12c(filename);
elseif depth <= 16
    A = matlab.internal.imagesci.rjpg16c(filename);
else
    error(message('MATLAB:imagesci:readjpg:unsupportedJPEGBitDepth', depth))
end

if options.AutoOrient && isfield(info, "Orientation")
    % apply Exif Orientation value to the image data
    A = applyExifOrientation(A, info.Orientation);
end

map = []; % colormap does not apply to JPEG images
end

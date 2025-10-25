function [X, map] = readfits(filename, options)
%READFITS Read image data from a FITS file.
%   A = READFITS(FILENAME) reads the unscaled data from the primary HDU
%   of a FITS file.
%
%   A = READFITS(FILENAME,'AutoOrient',tf) same as above, AutoOrient 
%   value is ignored.
%
%   See also FITSREAD.

%   Copyright 1984-2024 The MathWorks, Inc.

arguments
    filename 

    % AutoOrient value is ignored for FITS images
    options.AutoOrient (1,1) {mustBeA(options.AutoOrient,'logical')} = false %#ok<INUSA> 
end

warning(message('MATLAB:imagesci:readfits:use_fitsread'));

X = fitsread(filename, 'raw');
map = []; % colormap does not apply to FITS images

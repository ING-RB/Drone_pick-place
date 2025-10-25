%#codegen
function indexedImage = ind2rgbPreProcess(a, cm)
%IND2RGBPREPROCESS Pre-processes the input image before performing the
%conversion.
%   The operations performed by this function are:
%   * Switch the index to a 1-based index depending upon the type of the
%   input.
%   * Clamp the values in the image to the maximum entries in the colormap.

%   Copyright 2018 The MathWorks, Inc.

if ~isfloat(a)
    indexedImage = double(a)+1;    % Switch to one based indexing
else
    indexedImage = a;
end
 
% Make sure indexedImage is in the range from 1 to number of colormap
% entries
numColormapEntries = size(cm,1);
indexedImage = max( 1, min(indexedImage, numColormapEntries) );
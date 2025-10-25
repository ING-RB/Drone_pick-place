%#codegen
function varargout = ind2rgb(a,cm)
%IND2RGB Convert indexed image to RGB image.
%   RGB = IND2RGB(X,MAP) converts the matrix X and corresponding
%   colormap MAP to RGB (truecolor) format. This asumes Colum-Major
%   ordering. This is a private helper that is shared between the codegen
%   and MATLAB version of ind2rgb
%
%   Class Support
%   -------------
%   X can be of class uint8, uint16, or double. RGB is an 
%   M-by-N-by-3 array of class double.
%
%   See also RGB2IND.

%   Copyright 2018 The MathWorks, Inc.

indexedImage = matlab.images.internal.ind2rgbPreProcess(a, cm);

height = size(indexedImage, 1);
width = size(indexedImage, 2);

rgb = zeros(height, width, 3);
rgb(1:height, 1:width, 1) = reshape(cm(indexedImage, 1), [height width]);
rgb(1:height, 1:width, 2) = reshape(cm(indexedImage, 2), [height width]);
rgb(1:height, 1:width, 3) = reshape(cm(indexedImage, 3), [height width]);

if nargout > 1
    varargout{1} = rgb(1:height, 1:width, 1);
    varargout{2} = rgb(1:height, 1:width, 2);
    varargout{3} = rgb(1:height, 1:width, 3);
else
    varargout{1} = rgb;
end
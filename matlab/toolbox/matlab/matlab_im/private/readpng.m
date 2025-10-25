function [X,map,alpha] = readpng(filename, options)
%READPNG Read an image from a PNG file.
%   [X,MAP] = READPNG(FILENAME) reads the image from the
%   specified file.
%
%   [X,MAP] = READPNG(FILENAME,'BackgroundColor',BG) uses the
%   specified background color for compositing transparent
%   pixels.  By default, READPNG uses the background color
%   specified in the file, if present.  If not present, the
%   default is either the first colormap color or black.  If the
%   file contains an indexed image, BG must be an integer in the
%   range [1,P] where P is the colormap length.  If the file
%   contains a grayscale image, BG must be an integer in the
%   range [0,65535].  If the file contains an RGB image, BG must
%   be a 3-element vector whose values are in the range
%   [0,65535].
%
%   [X,MAP] = READPNG(FILENAME,'AutoOrient',tf) when AutoOrient is true,
%   shows warning that AutoOrient is not supported. Otherwise, AutoOrient
%   value is ignored.
%
%   See also IMREAD, IMWRITE, IMFINFO.

%   Copyright 1984-2024 The MathWorks, Inc.

arguments
    filename
    options.BackgroundColor = [];
    options.AutoOrient (1,1) {mustBeA(options.AutoOrient,'logical')} = false  
end

% applying AutoOrient is not supported for PNG images
if options.AutoOrient
    warning(message('MATLAB:imagesci:png:autoOrientPNG'));
end

if isempty(options.BackgroundColor) && nargout >= 3
    % User asked for alpha and didn't specify a background
    % color; in this case we don't perform the compositing.
    options.BackgroundColor = 'none';
end

% Specify that the PNG image should be read starting at the beginning of
% the file.
[X, map, alpha] = readpngutil(filename, options.BackgroundColor, 0);

end



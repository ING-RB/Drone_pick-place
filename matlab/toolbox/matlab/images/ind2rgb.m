function [r,g,b] = ind2rgb(a,cm)
%IND2RGB Convert indexed image to RGB image.
%   RGB = IND2RGB(X,MAP) converts the matrix X and corresponding
%   colormap MAP to RGB (truecolor) format.
%
%   Class Support
%   -------------
%   X can be of class uint8, uint16, or double. RGB is an 
%   M-by-N-by-3 array of class double.
%
%   See also RGB2IND.

%   Clay M. Thompson 9-29-92
%   Copyright 1984-2018 The MathWorks, Inc.

if nargout == 1
    r = matlab.images.internal.ind2rgb(a, cm);
else
    [r, g, b] = matlab.images.internal.ind2rgb(a, cm);
end

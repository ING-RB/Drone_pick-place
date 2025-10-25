function NEWMAP = cmap2gray(MAP)
%CMAP2GRAY Convert colormap to grayscale colormap.
%
%   NEWMAP = CMAP2GRAY(MAP) returns a grayscale colormap that is
%   equivalent to MAP. MAP is a colormap specified as a c-by-3 numeric
%   matrix with values in the range of [0,1]. NEWMAP is a grayscale
%   colormap returned as c-by-3 numeric matrix with values in the range
%   [0,1].
%
%   Class Support
%   ------------- 
%   The input and output colormaps are both of class
%   double.
%
%   Notes
%   -----
%   CMAP2GRAY converts colormap values to grayscale colormap
%   values by forming a weighted sum of the R, G, and B components of
%   the colormap:
%
%       0.2989 * R + 0.5870 * G + 0.1140 * B
%
%   The coefficients used here are the same as used in IM2GRAY.
%
%   In the output colormap NEWMAP, the three columns are identical.
%   Each row in the output colormap specifies a single intensity value.
%
%   Example
%   -------
%
%   indImage = load('clown');
%   gmap = cmap2gray(indImage.map);
%   figure, imshow(indImage.X,indImage.map), figure, imshow(indImage.X,gmap);
%
%   See also IM2GRAY, RGB2IND, RGB2LIGHTNESS.

%   Copyright 2020 The MathWorks, Inc.
arguments
    MAP {mustBeReal,mustBeNonempty,mustBeSize(MAP),mustBeDouble(MAP)}
end

% Calculate transformation matrix
T = inv([1.0 0.956 0.621; 1.0 -0.272 -0.647; 1.0 -1.106 1.703]);
coef = T(1,:);
NEWMAP = MAP * coef';
NEWMAP = min(max(NEWMAP,0),1);
NEWMAP = repmat(NEWMAP, [1 3]);

end

function mustBeSize(MAP)
    if(~ismatrix(MAP) || size(MAP,2)~=3 || size(MAP,1)<1)
         error(message('MATLAB:images:cmap2gray:invalidSizeForColormap'))
    end

end

function mustBeDouble(arg)
    validateattributes(arg,{'double'},{'nonnan','finite'},mfilename, 'MAP')
end

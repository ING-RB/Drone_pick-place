function [B,map] = imresize(varargin)
%IMRESIZE Resize image.
%   B = IMRESIZE(A, SCALE) returns an image that is SCALE times the
%   size of A, which is a grayscale, RGB, binary or a categorical image. 
%   If A has more than two dimensions, only the first two dimensions are 
%   resized.
%  
%   B = IMRESIZE(A, [NUMROWS NUMCOLS]) resizes the image so that it has
%   the specified number of rows and columns.  Either NUMROWS or NUMCOLS
%   may be NaN, in which case IMRESIZE computes the number of rows or
%   columns automatically in order to preserve the image aspect ratio.
%  
%   [Y, NEWMAP] = IMRESIZE(X, MAP, SCALE) resizes an indexed image.
%  
%   [Y, NEWMAP] = IMRESIZE(X, MAP, [NUMROWS NUMCOLS]) resizes an indexed
%   image.
%  
%   To control the interpolation method used by IMRESIZE, add a METHOD
%   argument to any of the syntaxes above, like this:
%
%       IMRESIZE(A, SCALE, METHOD) 
%       IMRESIZE(A, [NUMROWS NUMCOLS], METHOD),
%       IMRESIZE(X, MAP, SCALE, METHOD)
%       IMRESIZE(X, MAP, [NUMROWS NUMCOLS], METHOD)
%
%   METHOD can be a string naming a general interpolation method:
%  
%       'nearest'    - nearest-neighbor interpolation
% 
%       'bilinear'   - bilinear interpolation
% 
%       'bicubic'    - cubic interpolation; the default method
%
%   METHOD can also be a string naming an interpolation kernel:
%
%       'box'        - interpolation with a box-shaped kernel
%
%       'triangle'   - interpolation with a triangular kernel
%                         (equivalent to 'bilinear')
%
%       'cubic'      - interpolation with a cubic kernel 
%                         (equivalent to 'bicubic')
%  
%       'lanczos2'   - interpolation with a Lanczos-2 kernel
%  
%       'lanczos3'   - interpolation with a Lanczos-3 kernel
%
%   Categorical inputs only support the 'nearest' interpolation method(default) 
%   or the'box' interpolation kernel. 
%
%       IMRESIZE(C, SCALE, 'nearest') 
%       IMRESIZE(C, [NUMROWS NUMCOLS], 'nearest') 
%
%   Finally, METHOD can be a two-element cell array of the form {f,w},
%   where f is the function handle for a custom interpolation kernel, and
%   w is the custom kernel's width.  f(x) must be zero outside the
%   interval -w/2 <= x < w/2.  Your function handle f may be called with a
%   scalar or a vector input.
%  
%   You can achieve additional control over IMRESIZE by using
%   parameter/value pairs following any of the syntaxes above.
%   For example:
%
%       B = IMRESIZE(A, SCALE, PARAM1, VALUE1, PARAM2, VALUE2, ...)
%
%   Parameters include:
%  
%       'Antialiasing'  - true or false; specifies whether to perform 
%                         antialiasing when shrinking an image. The
%                         default value depends on the interpolation 
%                         method you choose.  For the 'nearest' method,
%                         the default is false; for all other methods,
%                         the default is true.
%
%       'Colormap'      - (only relevant for indexed images) 'original'
%                         or 'optimized'; if 'original', then the
%                         output newmap is the same as the input map.
%                         If it is 'optimized', then a new optimized
%                         colormap is created. The default value is
%                         'optimized'. 
%
%       'Dither'        - (only for indexed images) true or false;
%                         specifies whether to perform color
%                         dithering. The default value is true.
%  
%       'Method'        - As described above
%  
%       'OutputSize'    - A two-element vector, [MROWS NCOLS],
%                         specifying the output size.  One element may
%                         be NaN, in which case the other value is
%                         computed automatically to preserve the aspect
%                         ratio of the image. 
%  
%       'Scale'         - A scalar or two-element vector specifying the
%                         resize scale factors.  If it is a scalar, the
%                         same scale factor is applied to each
%                         dimension.  If it is a vector, it contains
%                         the scale factors for the row and column
%                         dimensions, respectively.
%
%   Class Support
%   -------------
%   The input image A can be numeric, logical or categorical and it must be
%   nonsparse.
%   The output image is of the same class as the input image.  The input
%   indexed image X can be uint8, uint16, or double.
%
%   Note
%   ----
%   [1] For bicubic interpolation, the output image may have some values
%   slightly outside the range of pixel values in the input image.  This
%   may also occur for user-specified interpolation kernels.
%
%   [2] The function IMRESIZE changed in version 5.4 (R2007a).  Previous 
%   versions of the Image Processing Toolbox used a somewhat 
%   different algorithm by default.  If you need the same results 
%   produced by the previous implementation, use the function 
%   IMRESIZE_OLD.
%
%   Examples
%   --------
%   % Shrink by factor of two using the defaults of bicubic interpolation
%   % and antialiasing.
%
%       I = imread('ngc6543a.jpg');
%       J = imresize(I, 0.5);
%       figure, imshow(I), figure, imshow(J)
%
%   % Shrink by factor of two using nearest-neighbor interpolation.
%   % (This is the fastest method, but it has the lowest quality.)
%
%       I = imread('ngc6543a.jpg');
%       J2 = imresize(I, 0.5, 'nearest');
%
%   % Resize an indexed image.
%
%       [X, map] = imread('corn.tif');
%       [Y, newmap] = imresize(X, map, 0.5);
%       imshow(Y, newmap)
%
%   % Resize an RGB image to have 64 rows.  The number of columns is
%   % computed automatically.
%
%       RGB = imread('peppers.png');
%       RGB2 = imresize(RGB, [64 NaN]);
%  
%   See also IMRESIZE3, IMROTATE, IMTRANSFORM, TFORMARRAY.

%   Copyright 1992-2020 The MathWorks, Inc.

args = matlab.images.internal.stringToChar(varargin);

params = matlab.images.internal.resize.resizeParseInputs(args{:});

matlab.images.internal.resize.checkForMissingOutputArgument(params, nargout);

A = matlab.images.internal.resize.preprocessImage(params);

% Determine which dimension to resize first.
order = matlab.images.internal.resize.dimensionOrder(params.scale);

% Calculate interpolation weights and indices for each dimension.
weights = cell(1,params.num_dims);
indices = cell(1,params.num_dims);
allDimNearestNeighbor = true;
for k = 1:params.num_dims
    [weights{k}, indices{k}] = matlab.images.internal.resize.contributions( ...
        size(A, k), ...
        params.output_size(k), params.scale(k), params.kernel, ...
        params.kernel_width, params.antialiasing);
    if ~matlab.images.internal.resize.isPureNearestNeighborComputation(weights{k})
        allDimNearestNeighbor = false;
    end
end

if allDimNearestNeighbor
    B = matlab.images.internal.resize.resizeAllDimUsingNearestNeighbor(A, indices);
else
    B = A;
    for k = 1:numel(order)
        dim = order(k);
        B = resizeAlongDim(B, dim, weights{dim}, indices{dim});
    end
end

[B, map] = matlab.images.internal.resize.postprocessImage(B, params);

end

%=====================================================================
function out = resizeAlongDim(in, dim, weights, indices)
% Resize along a specified dimension
%
% in           - input array to be resized
% dim          - dimension along which to resize
% weights      - weight matrix; row k is weights for k-th output pixel
% indices      - indices matrix; row k is indices for k-th output pixel

if matlab.images.internal.resize.isPureNearestNeighborComputation(weights)
    out = matlab.images.internal.resize.resizeAlongDimUsingNearestNeighbor(in, ...
        dim, indices);
    return
end

out_length = size(weights, 1);

size_in = size(in);
size_in((end + 1) : dim) = 1;

if (ndims(in) > 3)
    % Reshape in to be a three-dimensional array.  The size of this
    % three-dimensional array is the variable pseudo_size_in below.
    %
    % Final output will be consistent with the original input.
    pseudo_size_in = [size_in(1:2) prod(size_in(3:end))];
    in = reshape(in, pseudo_size_in);
end

% The 'out' will be uint8 if 'in' is logical 
% Otherwise 'out' datatype will be same as 'in' datatype
out = matlab.images.internal.resize.imresizemex(in, weights', indices', dim);

if ( (length(size_in) > 3) && (size_in(end) > 1) )
    % Restoring final output to expected size
    size_out = size_in;
    size_out(dim) = out_length;
    out = reshape(out, size_out);
end

end
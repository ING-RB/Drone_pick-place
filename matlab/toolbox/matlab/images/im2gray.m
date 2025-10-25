function I = im2gray(RGB)
%IM2GRAY Convert RGB image to grayscale.
%   I = IM2GRAY(RGB) converts the truecolor image RGB to the grayscale
%   intensity image I. Grayscale inputs to IM2GRAY are returned unchanged.
%
%   IM2GRAY converts RGB images to grayscale by eliminating the hue and
%   saturation information while retaining the luminance.
%
%   Class Support
%   -------------
%   A truecolor input image can be an MxNx3 array of any numeric type. A
%   grayscale input image can be an MxN matrix of any numeric type. The
%   output image I is an MxN matrix of the same class as the input image.
%
%   Notes
%   -----
%   IM2GRAY converts RGB values to grayscale values by forming
%   a weighted sum of the R, G, and B components:
%
%   0.2989 * R + 0.5870 * G + 0.1140 * B
%
%   The coefficients used to calculate grayscale values in IM2GRAY are
%   identical to those used to calculate luminance (E'y) in Rec.ITU-R
%   BT.601-7 after rounding to 3 decimal places.
%
%   Rec.ITU-R BT.601-7 calculates E'y using the following formula:
%
%   0.299 * R + 0.587 * G + 0.114 * B
%
%   Example
%   -------
%   I = imread('example.tif');
%
%   J = im2gray(I);
%   figure, imshow(I), figure, imshow(J);
%
%   See also CMAP2GRAY, RGB2IND, RGB2LIGHTNESS.
  
%   Copyright 2020 The MathWorks, Inc.

arguments
    RGB {mustBeNumeric,validateSize(RGB)}
end

if (ndims(RGB) == 3)
    if isa(RGB,'numeric')
        % For all numeric types: double,single,int8,int16,int32,int64,
        % uint8,uint16,uint32,uint64
        I = matlab.images.internal.rgb2gray(RGB);
    else
        % gpuArray, distributed and other numeric-like types 
        I = rgb2gray(RGB);
    end    
else
    I = RGB;
end
end

function validateSize(RGB)

if(ndims(RGB) > 3)
 error(message('MATLAB:images:im2gray:invalidDim'));
end
if((ndims(RGB) == 3) && size(RGB,3) ~= 3)   
    error(message('MATLAB:images:im2gray:invalidThirdDimSize'))
end

end
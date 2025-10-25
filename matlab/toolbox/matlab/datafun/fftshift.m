function x = fftshift(x,dim)
%FFTSHIFT Shift zero-frequency component to center of spectrum.
%   For vectors, FFTSHIFT(X) swaps the left and right halves of
%   X.  For matrices, FFTSHIFT(X) swaps the first and third
%   quadrants and the second and fourth quadrants.  For N-D
%   arrays, FFTSHIFT(X) swaps "half-spaces" of X along each
%   dimension.
%
%   FFTSHIFT(X,DIM) applies the FFTSHIFT operation along the 
%   dimension DIM.
%
%   FFTSHIFT is useful for visualizing the Fourier transform with
%   the zero-frequency component in the middle of the spectrum.
%
%   Class support for input X:
%      float: double, single
%
%   See also IFFTSHIFT, FFT, FFT2, FFTN, CIRCSHIFT.

%   Copyright 1984-2023 The MathWorks, Inc.

if nargin > 1
    if (~isscalar(dim)) || fix(dim) ~= dim || dim < 1 || ~isreal(dim)
        error(message('MATLAB:fftshift:DimNotPosInt'))
    end
    x = circshift(x,fix(size(x,dim)./2),dim);
else
    x = circshift(x,fix(size(x)./2));
end

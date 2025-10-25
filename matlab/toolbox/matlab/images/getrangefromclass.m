function range = getrangefromclass(I) %#codegen
%GETRANGEFROMCLASS Get dynamic range of image based on its class.
%   RANGE = GETRANGEFROMCLASS(I) returns the dynamic range of the 
%   image I, based on its class type. 
%
%   Class Support
%   -------------
%   I can be numeric or logical. RANGE is a two-element vector of doubles.
%
%   Note
%   ----
%   For single and double data, GETRANGEFROMCLASS returns the range [0 1],
%   to be consistent with the way double and single images are interpreted
%   in MATLAB.  For integer data, GETRANGEFROMCLASS returns the range of
%   the class. For example, if the class is uint8, the dynamic range is
%   [0 255].
%
%   Example
%   -------
%       % Get the dynamic range of a uint8 image.
%       A = imread('peppers.png');
%       r = getrangefromclass(A)
%
%   See also INTMIN, INTMAX.
  
%   Copyright 1993-2020 The MathWorks, Inc.
  
narginchk(1,1);
validateattributes(I,{'numeric','logical','int64','uint64','dlarray','gpuArray'}, {}, mfilename,'I',1);

if isinteger(I)
    classType = iGetClass(I);
    range = double([intmin(classType) intmax(classType)]);
else
    %double, single, or logical
    range = [0 1];
end

end

function classType = iGetClass(x)
if isa(x,'gpuArray') || isa(x,'dlarray')
    classType = underlyingType(x);
else
    classType = class(x);
end
end


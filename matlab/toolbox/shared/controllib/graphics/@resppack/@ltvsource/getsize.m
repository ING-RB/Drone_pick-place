function s = getsize(this,dim)
%GETSIZE  Inquires about lti source size.
%
%   S = GETSIZE(SRC) returns the 3-entry vector [Ny Nu Nsys] where
%     * Ny is the number of outputs
%     * Nu is the number of inputs
%     * Nsys is the total number of models.
%
%   S = GETSIZE(SRC,DIM) returns the size if the requested dimension
%   (DIM must be 1, 2, or 3).

%  Copyright 2022 The MathWorks, Inc.
s = [size(this.Model) 1];
if nargin>1
   s = s(dim);
end
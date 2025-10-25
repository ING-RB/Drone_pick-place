function se = diskstrel(r)
%This function is for internal use only. It may be removed in the future.

%diskstrel Create circular structuring element of radius r
%   SE = diskstrel(R) creates a logical structuring element of size 2*R+1 by
%   2*R+1, where R is the radius of the circular structuring element. R is
%   expected to be an integer. This function creates a disk shaped
%   structuring element that puts logical true at every cell which is
%   within the circle or touches the circle of radius R.

%   Copyright 2014-2019 The MathWorks, Inc.

%#codegen

    [x,y] = meshgrid(-r:r);
    se = x.^2 + y.^2 <= (r + 0.75)^2;

end

function [x,y,z] = pol2cart(th,r,z)
%POL2CART Transform polar to Cartesian coordinates.
%   [X,Y] = POL2CART(TH,R) transforms corresponding elements of data stored
%   in polar coordinates (angle TH, radius R) to Cartesian coordinates X,Y.
%   The arrays TH and R must have compatible sizes. In the simplest cases,
%   they can be the same size or one can be a scalar. Two inputs have
%   compatible sizes if, for every dimension, the dimension sizes of the
%   inputs are either the same or one of them is 1. TH must be in radians.
%
%   [X,Y,Z] = POL2CART(TH,R,Z) transforms corresponding elements of data
%   stored in cylindrical coordinates (angle TH, radius R, height Z) to
%   Cartesian coordinates X,Y,Z. The arrays TH, R, and Z must have
%   compatible sizes.  TH must be in radians.
%
%   Class support for inputs TH,R,Z:
%      float: double, single
%
%   See also CART2SPH, CART2POL, SPH2CART.

%   L. Shure, 4-20-92.
%   Copyright 1984-2021 The MathWorks, Inc. 

x = r.*cos(th);
y = r.*sin(th);

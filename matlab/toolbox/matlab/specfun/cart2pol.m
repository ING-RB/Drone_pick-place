function [th,r,z] = cart2pol(x,y,z)
%CART2POL Transform Cartesian to polar coordinates.
%   [TH,R] = CART2POL(X,Y) transforms corresponding elements of data stored
%   in Cartesian coordinates X,Y to polar coordinates (angle TH and radius
%   R). The arrays X and Y must have compatible sizes. In the simplest
%   cases, they can be the same size or one can be a scalar. Two inputs
%   have compatible sizes if, for every dimension, the dimension sizes of
%   the inputs are either the same or one of them is 1. TH is returned in
%   radians.
%
%   [TH,R,Z] = CART2POL(X,Y,Z) transforms corresponding elements of data
%   stored in Cartesian coordinates X,Y,Z to cylindrical coordinates (angle
%   TH, radius R, and height Z). The arrays X,Y, and Z must have compatible
%   sizes. TH is returned in radians.
%
%   Class support for inputs X,Y,Z:
%      float: double, single
%
%   See also CART2SPH, SPH2CART, POL2CART.

%   Copyright 1984-2021 The MathWorks, Inc. 

th = atan2(y,x);
r = hypot(x,y);

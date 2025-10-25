function [xx,yy,zz] = meshgrid(x,y,z)
%MESHGRID   Cartesian rectangular grid in 2-D or 3-D
%   [X,Y] = MESHGRID(x,y) returns 2-D grid coordinates based on the
%   coordinates contained in vectors x and y. X is a matrix where each row
%   is a copy of x, and Y is a matrix where each column is a copy of y. The
%   grid represented by the coordinates X and Y has length(y) rows and
%   length(x) columns.
%
%   [X,Y,Z] = MESHGRID(x,y,z) returns 3-D grid coordinates defined by the
%   vectors x, y, and z. The grid represented by X, Y, and Z has size
%   length(y)-by-length(x)-by-length(z).
%
%   [X,Y] = MESHGRID(x) is the same as [X,Y] = MESHGRID(x,x), returning
%   square grid coordinates with grid size length(x)-by-length(x).
%
%   [X,Y,Z] = MESHGRID(x) is the same as [X,Y,Z] = MESHGRID(x,x,x),
%   returning 3-D grid coordinates with grid size
%   length(x)-by-length(x)-by-length(x).
%
%   MESHGRID outputs are typically used for the evaluation of functions of
%   two or three variables and for surface and volumetric plots.
%
%   MESHGRID and NDGRID are similar, but MESHGRID is restricted to 2-D and
%   3-D while NDGRID supports 1-D to N-D. In 2-D and 3-D the coordinates
%   returned by each function are the same. The difference is the shape of
%   their outputs. For grid vectors x, y, and z of length M, N, and P
%   respectively, NDGRID(x,y) outputs have size M-by-N while MESHGRID(x,y)
%   outputs have size N-by-M. Similarly, NDGRID(x,y,z) outputs have size
%   M-by-N-by-P while MESHGRID(x,y,z) outputs have size N-by-M-by-P.
%
%   Example: Evaluate and plot the two-variable function
%            f(x,y) = x*exp(-x^2-y^2) for -2 <= x <= 2 and -4 <= y <= 4
%
%       [X,Y] = meshgrid(-2:.2:2,-4:.4:4);
%       F = X .* exp(-X.^2 - Y.^2);
%       surf(X,Y,F)
%
%
%   Class support for inputs x, y, and z:
%      float: double, single
%      integer: uint8, int8, uint16, int16, uint32, int32, uint64, int64
%
%   See also MESH, SURF, SLICE, NDGRID.

%   Copyright 1984-2019 The MathWorks, Inc. 

if nargin == 0 || (nargin > 1 && nargout > nargin)
    error(message('MATLAB:meshgrid:NotEnoughInputs'));
end

if nargin == 2 || (nargin == 1 && nargout < 3) % 2-D array case
    if nargin == 1
        y = x;
    end
    if isempty(x) || isempty(y)
        xx = zeros(0,class(x));
        yy = zeros(0,class(y));
    else
        xrow = full(x(:)).'; % Make sure x is a full row vector.
        ycol = full(y(:));   % Make sure y is a full column vector.
        xx = repmat(xrow,size(ycol));
        yy = repmat(ycol,size(xrow));
    end
else  % 3-D array case
    if nargin == 1
        y = x;
        z = x;
    end
    if isempty(x) || isempty(y) || isempty(z)
        xx = zeros(0,class(x));
        yy = zeros(0,class(y));
        zz = zeros(0,class(z));
    else
        nx = numel(x);
        ny = numel(y);
        nz = numel(z);
        xx = reshape(full(x),[1 nx 1]); % Make sure x is a full row vector.
        yy = reshape(full(y),[ny 1 1]); % Make sure y is a full column vector.
        zz = reshape(full(z),[1 1 nz]); % Make sure z is a full page vector.
        xx = repmat(xx, ny, 1, nz);
        yy = repmat(yy, 1, nx, nz);
        zz = repmat(zz, ny, nx, 1);
    end
end

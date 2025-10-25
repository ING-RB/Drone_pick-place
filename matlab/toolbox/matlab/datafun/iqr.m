function [y,q] = iqr(x,dim)
%IQR Interquartile range of data set
%   Y = IQR(X) returns the interquartile range of the values in X. For
%   vector input, Y is the difference between the first and third quartiles
%   of X. For matrix input, Y is a row vector containing the interquartile
%   range of each column of X. For multidimensional arrays, IQR operates
%   along the first non-singleton dimension.
%
%   Y = IQR(X,'all') calculates the interquartile range of all the elements
%   in X.
%
%   Y = IQR(X,DIM) calculates the interquartile range along the dimension
%   DIM of X.
%
%   Y = IQR(X,VECDIM) calculates the interquartile range of elements of X
%   along the dimensions specified in the vector VECDIM.
%
%   [Y,Q] = IQR(X,...) also returns the first and third quartiles of X in
%   Q. Q is the same size as X, except that the size in the operating
%   dimension is 2. If VECDIM is specified, then the size of Q in the
%   smallest specified operating dimension is 2, and the size of Q in the
%   other operating dimensions is 1.
%
%   See also PRCTILE, STD, VAR

%   Copyright 1993-2024 The MathWorks, Inc.

if nargin == 1
    q = prctile(x, [25; 75]);
    y = diff(q);
    if nargout == 2 && isrow(x)
        % Orient p so that it is also a row vector.
        q = reshape(q,1,2);
    end
else
    dimIsAll = matlab.internal.math.checkInputName(dim,'all');
    if ~dimIsAll && ~isnumeric(dim)
        % Error now to avoid prctile error messages that reference
        % name-value arguments.
        error(message('MATLAB:getdimarg:invalidDim'));
    end
    q = prctile(x,[25; 75],dim);
    if dimIsAll
        dim = 1;
    end
    y = diff(q,[],min(dim));
end
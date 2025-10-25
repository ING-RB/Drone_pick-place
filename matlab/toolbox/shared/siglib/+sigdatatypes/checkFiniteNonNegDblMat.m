function checkFiniteNonNegDblMat(h, prop, value, reqSize ,varargin)
%CHECKFINITEDBLMAT Check if value is a finite non-negative double matrix
%   If H is a class handle, then a message that includes property name PROP and
%   class name of H is issued.  If H is a string, then a message that assumes
%   PROP is an input argument to a function or method is issued and
%   varargin includes datatype

%   Copyright 2008-2018 The MathWorks, Inc.

[m, n] = size(value);

% Note that if any of the sizes is 1, then it is a vector.  Currently works only
% with 2D matrices.
if reqSize(1)==1
    type = 'row vector';
elseif reqSize(2)==1
    type = 'column vector';
else
    type = 'matrix';
end

if isempty(varargin)
    datatype = 'double';
else
    datatype = varargin{1};
end

if  (m~=reqSize(1)) || (n~=reqSize(2)) || ~isa(value, datatype) ...
        || any(any(value<0)) || any(any(isinf(value))) ...
        || any(any(isnan(value))) || ~isreal(value)
    if ischar(h)
        msg = sprintf(['The %s input argument of %s must be a finite '...
            'non-negative %s %s of size %dx%d.'], prop, h, datatype, type, ...
            reqSize(1), reqSize(2));
    else
        msg = sprintf(['The ''%s'' property of ''%s'' must be a finite '...
            'non-negative %s %s of size %dx%d.'], prop, class(h), datatype, type, ...
             reqSize(1), reqSize(2));
    end
    throwAsCaller(MException('MATLAB:datatypes:NotFiniteNonNegDblMat', msg));
end
%---------------------------------------------------------------------------
% [EOF]
function c = dot(a,b,dim)
%DOT  Vector dot product.
%   C = DOT(A,B) returns the scalar product of the vectors A and B.
%   A and B must be vectors of the same length.  When A and B are both
%   column vectors, DOT(A,B) is the same as A'*B.
%
%   DOT(A,B), for N-D arrays A and B, returns the scalar product
%   along the first non-singleton dimension of A and B. A and B must
%   have the same size.
%
%   DOT(A,B,DIM) returns the scalar product of A and B in the
%   dimension DIM.
%
%   Class support for inputs A,B:
%      float: double, single
%
%   See also CROSS.

%   Copyright 1984-2023 The MathWorks, Inc. 

if isinteger(a) || isinteger(b)
    error(message('MATLAB:dot:integerClass'));
end

if nargin == 2

    if isvector(a) && isvector(b)
        % Special case: A and B are vectors and dim not supplied
        a = a(:);
        b = b(:);
        if length(a) ~= length(b)
            error(message('MATLAB:dot:InputSizeMismatch'));
        end
        c = a'*b;
    else
        if ~isequal(size(a),size(b))
            error(message('MATLAB:dot:InputSizeMismatch'));
        end
        c = sum(conj(a).*b);
    end

else

    if ~isequal(size(a),size(b))
        error(message('MATLAB:dot:InputSizeMismatch'));
    end
    if ~isnumeric(dim) || ~isscalar(dim)
        error(message('MATLAB:dot:dimensionMustBePositiveInteger'));
    end
    if iscolumn(a) && dim == 1
        c = a'*b;
    elseif isrow(a) && dim == 2
        c = b*a';
    else
        c = sum(conj(a).*b,dim);
    end

end

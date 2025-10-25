function eq = isequal(varargin)
%ISEQUAL Check if arrays are numerically equal
%
%   ISEQUAL(T1,T2) does element-by-element comparisons between the
%   arrays T1 and T2 and returns logical 1 (TRUE) if T1 and
%   T2 are the same size and all the underlying matrices are
%   numerically equal. It returns logical 0 (FALSE) otherwise.
%
%   When comparing numeric values of matrices, ISEQUAL does not
%   consider the underlying class of the values in determining
%   whether they are equal. In other words,
%   ISEQUAL(double(T), single(T)) will return logical 1 (TRUE).
%
%   See also eq.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    narginchk(2,inf);
    [obj,idx] = findFirstSpatialMatrix(varargin{:});

    eq = true;
    for i = 1:nargin
        if i ~= idx  % don't bother comparing with itself
            u = varargin{i};
            eq = eq && binaryIsEqual(obj,u);
        end
    end

end

function tf = isequaln(varargin)
%ISEQUALN Check if arrays are numerically equal, treating NaNs as equal
%
%   ISEQUALN(T1,T2) does element-by-element comparisons between the
%   arrays T1 and T2 and returns logical 1 (TRUE) if T1 and
%   T2 are the same size and all the underlying matrices are
%   numerically equal. It returns logical 0 (FALSE) otherwise.
%
%   When comparing numeric values of matrices, ISEQUALN does not
%   consider the underlying class of the values in determining
%   whether they are equal. In other words,
%   ISEQUALN(double(T), single(T)) will return logical 1 (TRUE).
%
%   See also isequal, eq.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

    narginchk(2,inf);
    [obj,idx] = findFirstSpatialMatrix(varargin{:});

    tf = true;
    for i = 1:nargin
        if i ~= idx  % don't bother comparing with itself
            u = varargin{i};
            tf = tf && binaryIsEqualn(obj,u);
        end
    end

end

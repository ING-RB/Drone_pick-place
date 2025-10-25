function tf = isScalarLogical(rhs)
%ISSCALARLOGICAL Returns true is rhs is a scalar logical value, or
% a scalar numeric value that is convertible to a logical.

% Copyright 2023 The MathWorks, Inc.

    tf = isscalar(rhs) && (islogical(rhs) || (isnumeric(rhs) && isreal(rhs)));
    tf = tf && ~issparse(rhs);
end

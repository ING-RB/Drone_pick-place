function data = parenReference_2D(data,rowIndices,colIndices)
%PARENREFERENCE_2D Subscripting helper for 2D paren reference.
%   DATA = PARENREFERENCE_2D(DATA,ROWINDICES) returns the specified
%   rows from a matrix, i.e. DATA(ROWINDICES,:). PARENREFERENCE_2D
%   has an optimized special case when ROWINDICES IS ':'.

%   Copyright 2019-2020 The MathWorks, Inc.

% inline matlab.internal.datatypes.isColon for both rowIndices & colIndices
optimizeColon = ischar(rowIndices) && ischar(colIndices) && ...
                isscalar(rowIndices) && isscalar(colIndices) && ...
                (rowIndices == ':') && (colIndices == ':');
            
if optimizeColon
    data = matlab.internal.datatypes.matricize(data);
else
    data = data(rowIndices,colIndices);
end
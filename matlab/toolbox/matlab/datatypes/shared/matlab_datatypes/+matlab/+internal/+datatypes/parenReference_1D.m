function data = parenReference_1D(data,rowIndices)
%PARENREFERENCE_1D Subscripting helper for 1D paren reference.
%   DATA = PARENREFERENCE_1D(DATA,ROWINDICES) returns the specified
%   rows from a column vector, i.e. DATA(ROWINDICES). PARENREFERENCE_1D
%   has an optimized special case when ROWINDICES is ':'.

%   Copyright 2019-2020 The MathWorks, Inc.

if ischar(rowIndices) && isscalar(rowIndices) && (rowIndices == ':') % inline matlab.internal.datatypes.isColon
    data = data(:); % literal colon for performance
else
    data = data(rowIndices);
end
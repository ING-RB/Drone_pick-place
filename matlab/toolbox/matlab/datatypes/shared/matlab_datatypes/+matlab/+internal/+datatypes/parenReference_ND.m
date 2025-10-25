function data = parenReference_ND(data,nsubs,rowIndices,colIndices,pageIndices)
%PARENREFERENCE_ND Subscripting helper for N-D paren reference.
%   DATA = PARENREFERENCE_2D(DATA,ROWINDICES) returns the specified
%   rows from an array, i.e. DATA(ROWINDICES,:,:,...). PARENREFERENCE_ND
%   has an optimized special case when ROWINDICES IS ':'.

%   Copyright 2019-2020 The MathWorks, Inc.

% Gate colon-optimize with size heuristic - array smaller than this is
% not worth the extra check to do the all-colon optimization
optimizeAllColon = (numel(data) > 1e3) && ...
    ischar(rowIndices) && ischar(colIndices) && ...
    isscalar(rowIndices) && isscalar(colIndices) && ...
    (rowIndices == ':') && (colIndices == ':');

% Check all subsequent subscripts for colon
i = 1;
while optimizeAllColon && ( i <= nsubs-2 )
    idx = pageIndices{i};
    optimizeAllColon = ischar(idx) && isscalar(idx) && (idx == ':');
    i = i + 1;
end

if optimizeAllColon
    % this would be incorrect if ISEMPTY(data); but optimizeAllColon is
    % gated with size up-front, so data must _not_ be empty at this point
    sz = cell(nsubs-1,1);
    [sz{:}] = size(data, 1:nsubs-1);
    data = reshape(data, sz{:}, []);
else
    data = data(rowIndices,colIndices,pageIndices{:});
end
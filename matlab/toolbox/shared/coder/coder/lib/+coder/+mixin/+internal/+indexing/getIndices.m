function out = getIndices(varargin)
%MATLAB Code Generation Private Function
%
%   Expand nonscalar index values into a
%   2-by-nArgs grid of index tuples.

%   Copyright 2019 The MathWorks, Inc.
%#codegen

nArgs = coder.internal.indexInt(numel(varargin));
grid = cell(1, nArgs);
[grid{:}] = ndgrid(varargin{:});

outCols = coder.internal.indexInt(nArgs);
outRows = coder.internal.indexInt(1);
for i = 1:nArgs
    nElements = coder.internal.indexInt(numel(varargin{i}));
    outRows = outRows * nElements;
end
out = coder.nullcopy(cell(outRows, outCols));
for row = 1:outRows
    for col = 1:outCols
        outValue = coder.internal.indexInt(grid{col}(row));
        out{row, col} = outValue;
    end
end

end

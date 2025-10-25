function n = numel(t,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isText
import matlab.internal.datatypes.isColon

switch nargin
case 1
    n = t.rowDim.length * t.varDim.length;

otherwise
    % Return the total number of elements in the subscript expression.  Don't do
    % any checks to see if the subscripts actually exist, just count them up.
    % subsref/subsasgn will error later on if the subscripts refer to something
    % that's not there.

    if numel(varargin) ~= t.metaDim.length
        tabular.throwNDSubscriptError(numel(varargin))
    end

    rowIndices = varargin{1};
    if ischar(rowIndices)
        if isColon(rowIndices)
            nrows = t.rowDim.length;
        else
            nrows = 1;
        end
    elseif islogical(rowIndices)
        nrows = nnz(rowIndices);
    elseif isnumeric(rowIndices) || isText(rowIndices)
        nrows = numel(rowIndices);
    end

    varIndices = varargin{2};
    if ischar(varIndices)
        if isColon(varIndices)
            nvars = t.varDim.length;
        else
            nvars = 1;
        end
    elseif islogical(varIndices)
        nvars = nnz(varIndices);
    elseif isnumeric(varIndices) || isText(varIndices)
        nvars = numel(varIndices);
    end
    n = nrows*nvars;
end

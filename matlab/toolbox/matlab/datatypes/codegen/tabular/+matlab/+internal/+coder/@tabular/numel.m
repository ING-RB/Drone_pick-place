function n = numel(t,varargin)    %#codegen
%NUMEL Number of elements in a table.
%   N = NUMEL(T) returns the number of elements in the table T, equivalent to
%   PROD(SIZE(T)).  Note that variables in a table may themselves have multiple
%   columns.  NUMEL(T) does not account for that.
%
%   See also SIZE, HEIGHT, WIDTH.

%   Copyright 2019 The MathWorks, Inc.

if nargin == 1

    n = t.rowDimLength() * t.varDim.length;

else
    % Return the total number of elements in the subscript expression.  Don't do
    % any checks to see if the subscripts actually exist, just count them up.
    % subsref/subsasgn will error later on if the subscripts refer to something
    % that's not there.
    coder.internal.errorIf(numel(varargin) == 1, 'MATLAB:table:LinearSubscript');
    coder.internal.assert(numel(varargin) == t.metaDim.length, 'MATLAB:table:NDSubscript'); % Error for ND indexing

    rowIndices = varargin{1};
    if ischar(rowIndices)
        if matlab.internal.datatypes.isColon(rowIndices)
            nrows = t.rowDimLength();
        else
            nrows = 1;
        end
    elseif islogical(rowIndices)
        nrows = nnz(rowIndices);
    elseif isnumeric(rowIndices) || matlab.internal.coder.datatypes.isText(rowIndices)
        nrows = numel(rowIndices);
    end

    varIndices = varargin{2};
    if ischar(varIndices)
        if matlab.internal.datatypes.isColon(varIndices)
            nvars = t.varDim.length;
        else
            nvars = 1;
        end
    elseif islogical(varIndices)
        nvars = nnz(varIndices);
    elseif isnumeric(varIndices) || matlab.internal.coder.datatypes.isText(varIndices)
        nvars = numel(varIndices);
    end
    n = nrows*nvars;
end

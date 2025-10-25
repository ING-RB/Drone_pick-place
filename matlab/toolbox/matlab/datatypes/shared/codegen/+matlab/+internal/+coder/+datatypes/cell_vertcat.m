function C = cell_vertcat(varargin) %#codegen
%CELL_VERTCAT Vertical concatenation for cell arrays.
%   CELL_VERTCAT(...) implements vertcat for cell array inputs in codegen.
%
%   All inputs must be cell arrays with consistent dimensions, even if
%   empty (e.g. cell_vertcat({},cell.empty(0,3)) will error).
%   
%   Scalar expansion and ignoring of empty arrays are not supported.

%   Copyright 2020-2023 The MathWorks, Inc.

    if nargin == 0
        C = [];
    elseif nargin == 1
        coder.internal.assert(iscell(varargin{1}),'MATLAB:datatypes:MustBeCell');
        C = varargin{1};
    else
        sizeOut = size(varargin{1});
        for i = 2:nargin
            sizeOut(1) = sizeOut(1) + size(varargin{i},1);
        end
        C = coder.nullcopy(cell(sizeOut));
        rowOffset = 0;
        for idx = 1:nargin
            A = varargin{idx};
            szA = size(A);
            coder.internal.assert(iscell(A),'MATLAB:datatypes:MustBeCell');
            coder.internal.assert((ndims(A) == ndims(C)) && isequal(sizeOut(2:end),szA(2:end)),'MATLAB:catenate:cellDimensionMismatch');
            for i = 1:szA(1)
                for j = 1:prod(szA(2:end))
                    C{rowOffset+i,j} = A{i,j};
                end
            end
            rowOffset = rowOffset + szA(1);
        end
    end
end
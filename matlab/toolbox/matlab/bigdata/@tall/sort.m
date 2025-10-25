function [tY,tI] = sort(tX,varargin)
%SORT Sort in ascending or descending order.
%   Y = SORT(X,DIM)
%   Y = SORT(X,DIM,MODE)
%   Y = SORT(X,DIM,...,'ComparisonMethod',C)
%   Y = SORT(X,DIM,...,'MissingPlacement',M)
%   [Y,I] = SORT(...)
%
%   Limitations:
%   1) SORT(X) is not supported.
%   2) SORT(X,1) is only supported for column vector X.
%
%   See also SORT

%   Copyright 2016-2019 The MathWorks, Inc.

nargoutchk(0, 2);

tall.checkIsTall(upper(mfilename), 1, tX);
tall.checkNotTall(upper(mfilename), 1, varargin{:});

% Tall/sort does not support cellstr as sort on cellstr does not support DIM.
if strcmp(tall.getClass(tX), 'cell')
    error(message('MATLAB:bigdata:array:SortCellUnsupported', upper(mfilename)));
end
tX = lazyValidate(tX, {@(x)~iscell(x), {'MATLAB:bigdata:array:SortCellUnsupported', upper(mfilename)}});

% Sort on every non-strong type apart from cell acts like double. As
% we disallow cell, we can validate parameters against the non-tall version
% of sort.
tall.validateSyntax(@sort, [{tX}, varargin], 'DefaultType', 'double');

if nargin == 1 || nargin >= 2 && ~isnumeric(varargin{1})
    error(message('MATLAB:bigdata:array:SortDimRequired'));
else
    dim = varargin{1};
end

inputArgs = varargin;
sortFunctionHandle = @(x) sort(x, inputArgs{:});
if dim == 1
    tX = tall.validateColumn(tX, 'MATLAB:bigdata:array:SortMustBeColumn');
    if nargout > 1
        tIdx = getAbsoluteSliceIndices(tX);
        [tY,tI] = sortCommon(sortFunctionHandle, tX, tIdx);
    else
        tY = sortCommon(sortFunctionHandle, tX);
    end
else
    [tY,tI] = slicefun(sortFunctionHandle, tX);
    tY.Adaptor = tX.Adaptor;
    % tIdx is a double vector, matrix or multidimensional array with
    % indices. tIdx has the same size as tX.
    tI = setKnownType(tI, 'double');
    tI.Adaptor = copySizeInformation(tI.Adaptor, tX.Adaptor);
end

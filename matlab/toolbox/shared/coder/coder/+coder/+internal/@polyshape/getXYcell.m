function [X, Y, next_arg] = getXYcell(varargin)
%MATLAB Code Generation Library Function
% parse and get the x- and y- coordinates when input is a cell array

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.internal.prefer_const(varargin);
coder.internal.assert(nargin>=2,'MATLAB:polyshape:twoCellArrays');

cell1 = varargin{1};
cell2 = varargin{2};

coder.internal.errorIf(isnumeric(cell2), 'MATLAB:polyshape:xyNumericCell');
coder.internal.assert(iscell(cell2), 'MATLAB:polyshape:twoCellArrays');

coder.internal.assert(isvector(cell1) && isvector(cell2), 'MATLAB:polyshape:cellArrayMismatch');
coder.internal.assert(isequal(size(cell1), size(cell2)), 'MATLAB:polyshape:cellArrayMismatch');

szpt = 0;
for ia = 1:length(cell1)
    szpt = szpt + numel(cell1{ia});
end
X = coder.nullcopy(zeros(1,numel(cell1)-1+szpt,'double'));
Y = coder.nullcopy(zeros(1,numel(cell1)-1+szpt,'double'));
k = 1;
for ia = 1:length(cell1)
    xx = cell1{ia};
    yy = cell2{ia};

    coder.internal.assert(isvector(xx) && isnumeric(xx) && isvector(yy) && isnumeric(yy), ...
        'MATLAB:polyshape:xyValueError');
    coder.internal.errorIf(issparse(xx) || issparse(yy), 'MATLAB:polyshape:sparseError');
    coder.internal.assert(isequal(size(yy), size(xx)),'MATLAB:polyshape:xyVectorCell');
    coder.internal.assert(isreal(xx) && isreal(yy), 'MATLAB:polyshape:xyValueError');
    
    if(k~=1)
        X(k) = NaN;
        Y(k) = NaN;
        k = k + 1;
    end

    vs = k+numel(xx)-1;
    if(isrow(xx))
        X(k:vs) = xx;
        Y(k:vs) = yy;
    else
        X(k:vs) = xx';
        Y(k:vs) = yy';
    end
    k = vs+1;

end
next_arg = 3;

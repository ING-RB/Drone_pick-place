function PM = perimeter(pshape, varargin)
%MATLAB Code Generation Library Function
% Obtain perimeter of polyshape or boundary inside polyshape

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.internal.polyshape.checkConsistency(pshape, nargin);

if (nargin == 1)
    n = coder.internal.polyshape.checkArray(pshape);
    PM = zeros(n);
    for i=1:numel(pshape)
        if ~pshape(i).isEmptyShape()
            PM(i) = pshape(i).polyImpl.getPerimeter();
        end
    end
else
    coder.internal.polyshape.checkScalar(pshape);
    coder.internal.polyshape.checkEmpty(pshape);
    II = coder.internal.polyshape.checkIndex(pshape, varargin{1});
    PM = zeros(length(II), 1);
    for i=1:length(II)
        PM(i) = pshape.polyImpl.getBoundaryPerimeter(II(i));
    end
end
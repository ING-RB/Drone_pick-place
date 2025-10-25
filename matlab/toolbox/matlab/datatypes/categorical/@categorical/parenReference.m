function obj = parenReference(obj,rowIndices,colIndices,varargin)
%
% OBJ = PARENREFERENCE(OBJ,LINEARINDICES)
% OBJ = PARENREFERENCE(OBJ,ROWINDICES,COLINDICES)
% OBJ = PARENREFERENCE(OBJ,ROWINDICES,COLINDICES,PAGEINDICES,...)

%   Copyright 2019-2020 The MathWorks, Inc.

% Only simple paren references get here; multi-level paren references like
% d(i).Property go to subsref.

import matlab.internal.datatypes.parenReference_1D;
import matlab.internal.datatypes.parenReference_2D;
import matlab.internal.datatypes.parenReference_ND;

nsubs = nargin-1;
switch nsubs
    case 1 % 1-D subscripting    
        obj.codes = parenReference_1D(obj.codes, rowIndices);
    case 2 % 2-D subscripting
        obj.codes = parenReference_2D(obj.codes, rowIndices, colIndices);
    case 0 % obj() is legal syntax but a no-op - return as is
    otherwise % >= 3, N-D subscripting
        obj.codes = parenReference_ND(obj.codes, nsubs, rowIndices, colIndices, varargin);
end
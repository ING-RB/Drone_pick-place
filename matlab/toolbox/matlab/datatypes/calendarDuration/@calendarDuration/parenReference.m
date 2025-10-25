function obj = parenReference(obj,rowIndices,colIndices,varargin)
%
% THIS = PARENREFERENCE(THIS,LINEARINDICES)
% THIS = PARENREFERENCE(THIS,ROWINDICES,COLINDICES)
% THIS = PARENREFERENCE(THIS,ROWINDICES,COLINDICES,PAGEINDICES,...)

%   Copyright 2019-2020 The MathWorks, Inc.

% Only simple paren references get here; multi-level paren references like
% d(i).Property go to subsref and ultimately to subsrefParens.

import matlab.internal.datatypes.parenReference_1D;
import matlab.internal.datatypes.parenReference_2D;
import matlab.internal.datatypes.parenReference_ND;

% If the array is not a scalar zero, at least one of the fields must not be a
% scalar zero placeholder, and will have subscripting applied. Any remaining
% (scalar zero placeholder) fields can be left alone. However, if the array is a
% scalar zero, have to handle the possibility of Tony's trick, or at least throw
% an error for out of range subscripts, so apply the subscripting to (arbitrarily)
% seconds.
nonZeros = false;

nsubs = nargin - 1;
if ~isequal(obj.components.months,0)
    nonZeros = true;
    switch nsubs
    case 1 % 1-D subscripting
        obj.components.months = parenReference_1D(obj.components.months,rowIndices);
    case 2 % 2-D subscripting
        obj.components.months = parenReference_2D(obj.components.months,rowIndices,colIndices);
    case 0 % obj() is legal syntax but a no-op - return as is
    otherwise % >= 3, N-D subscripting
        obj.components.months = parenReference_ND(obj.components.months,nsubs,rowIndices,colIndices,varargin);
    end
end
if ~isequal(obj.components.days,0)
    nonZeros = true;
    switch nsubs
    case 1 % 1-D subscripting
        obj.components.days = parenReference_1D(obj.components.days,rowIndices);
    case 2 % 2-D subscripting
        obj.components.days = parenReference_2D(obj.components.days,rowIndices,colIndices);
    case 0 % obj() is legal syntax but a no-op - return as is
    otherwise % >= 3, N-D subscripting
        obj.components.days = parenReference_ND(obj.components.days,nsubs,rowIndices,colIndices,varargin);
    end
end
if ~isequal(obj.components.millis,0) || (nonZeros == false)
    switch nsubs
    case 1 % 1-D subscripting
        obj.components.millis = parenReference_1D(obj.components.millis,rowIndices);
    case 2 % 2-D subscripting
        obj.components.millis = parenReference_2D(obj.components.millis,rowIndices,colIndices);
    case 0 % obj() is legal syntax but a no-op - return as is
    otherwise % >= 3, N-D subscripting
        obj.components.millis = parenReference_ND(obj.components.millis,nsubs,rowIndices,colIndices,varargin);
    end
end
function [tf,allFlag] = isValidDimArg(dim)
%ISVALIDDIMARG Validate a DIM argument.
%   TF = ISVALIDDIMARG(DIM) returns true if DIM is a positive integer scalar or
%   a vector of positive integers, or 'all', and returns false otherwise.
%
%   [TF,ALLFLAG] = ISVALIDDIMARG(DIM) also returns a logical flag indicating if DIM is
%   'all'.

%   Copyright 2018-2024 The MathWorks, Inc.

tf = true;
allFlag = false;
if isnumeric(dim)
    if ~isvector(dim)
        tf = false;
    else
        if ~matlab.internal.datatypes.isIntegerVals(dim,1)
            tf = false;
        end
        if ~isscalar(dim) && ~matlab.internal.datatypes.isUniqueNumeric(dim)
            tf = false;
        end
    end
elseif nargin == 1 && matlab.internal.datatypes.isScalarText(dim)
    if ~strncmpi(dim,'all',max(strlength(dim),1))
        tf = false;
    else
        allFlag = true;
    end
else
    tf = false;
end
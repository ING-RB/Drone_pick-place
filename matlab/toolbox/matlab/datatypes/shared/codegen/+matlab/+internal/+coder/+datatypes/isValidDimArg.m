function [tf,allFlag] = isValidDimArg(dim,requireNumeric) %#codegen
%ISVALIDDIMARG Validate a DIM argument.
%   TF = ISVALIDDIMARG(DIM) returns true if DIM is a positive integer
%   scalar or a vector of positive integers, or 'all', and returns
%   false otherwise.
%
%   TF = ISVALIDDIMARG(DIM,TRUE) returns true if DIM is a positive
%   integer scalar or a vector of positive integers, and returns
%   false otherwise. ISVALIDDIMARG(DIM,FALSE) is equivalent to
%   ISVALIDDIMARG(DIM).
%
%   [TF,ALLFLAG] = ISVALIDDIMARG(DIM) also returns a logical flag
%   indicating if DIM is 'all'.

%   Copyright 2020 The MathWorks, Inc.

tf = true;
allFlag = false;
if isnumeric(dim)
    if isempty(dim) || ~isvector(dim)
        tf = false;
    else
        if ~matlab.internal.datatypes.isIntegerVals(dim,1)
            tf = false;
        end
        if ~isscalar(dim) && ~matlab.internal.coder.datatypes.isUniqueNumeric(dim)
            tf = false;
        end
    end
elseif (nargin == 1 || ~requireNumeric) && matlab.internal.coder.datatypes.isScalarText(dim)
    if ~strncmpi(dim,'all',max(strlength(dim),1))
        tf = false;
    else
        allFlag = true;
    end
else
    tf = false;
end
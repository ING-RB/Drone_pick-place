function tf = isAllFlag(arg)
% True if the input is a partial case-insensitive match for the string "all"

% Copyright 2018 The MathWorks, Inc.

tf = matlab.internal.datatypes.isScalarText(arg) ...
    && strlength(arg)>0 && strncmpi(arg,"all",strlength(arg));
end

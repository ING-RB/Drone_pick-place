function varOut = createVarSize(varIn)
%

%   Copyright 2022 The MathWorks, Inc.

varOut = varIn;
coder.varsize('varOut',[1 inf]);

end

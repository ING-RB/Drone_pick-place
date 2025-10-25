function tf = isempty(t)
%

%   Copyright 2012-2024 The MathWorks, Inc. 

tf = (t.rowDim.length == 0) || (t.varDim.length == 0);

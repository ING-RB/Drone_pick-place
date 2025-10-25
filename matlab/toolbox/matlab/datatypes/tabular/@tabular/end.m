function e = end(t,k,~)
%

%   Copyright 2012-2024 The MathWorks, Inc. 

switch k
case 1
    e = t.rowDim.length;
case 2
    e = t.varDim.length;
otherwise
    e = 1;
end

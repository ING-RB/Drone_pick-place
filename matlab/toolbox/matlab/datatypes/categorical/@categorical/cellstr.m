function b = cellstr(a)
%

%   Copyright 2006-2024 The MathWorks, Inc. 

names = [categorical.undefLabel; a.categoryNames];
b = reshape(names(a.codes+1),size(a.codes));

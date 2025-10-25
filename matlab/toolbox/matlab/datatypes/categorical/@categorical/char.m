function b = char(a)
%

%   Copyright 2006-2024 The MathWorks, Inc. 

names = [categorical.undefLabel; a.categoryNames];
b = char(names(a.codes+1));

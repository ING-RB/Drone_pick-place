function b = string(a)
%

%   Copyright 2016-2024 The MathWorks, Inc.

names = string([string(nan); a.categoryNames(:)]);
b = reshape(names(a.codes+1),size(a.codes));

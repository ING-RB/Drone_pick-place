function s = strcmp(s1,s2)
%

%   Copyright 1984-2023 The MathWorks, Inc.

s = strcmp(fromOpaque(s1),fromOpaque(s2));

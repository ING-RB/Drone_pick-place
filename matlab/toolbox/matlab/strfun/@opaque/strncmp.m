function s = strncmp(s1,s2,n)
%

%   Copyright 1984-2023 The MathWorks, Inc.

s = strncmp(fromOpaque(s1),fromOpaque(s2),fromOpaque(n));

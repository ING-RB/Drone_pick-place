function s = strcmpi(s1,s2)
%

%   Copyright 1984-2023 The MathWorks, Inc.

s = strcmpi(fromOpaque(s1),fromOpaque(s2));

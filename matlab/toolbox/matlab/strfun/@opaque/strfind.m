function s = strfind(s1,s2)
%

%   Copyright 2011-2023 The MathWorks, Inc.

s = strfind(fromOpaque(s1),fromOpaque(s2));

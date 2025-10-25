function s = escapeQuotes(s)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2023 The MathWorks, Inc.

arguments
    s (1,1) string
end

s = replace(s, "'", "''");
end
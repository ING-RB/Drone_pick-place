function d = cellstr_diff(c)  %#codegen
%CELLSTR_DIFF Find consecutive non-duplicates in a cellstr.
%   D = CELLSTR_DIFF(C), for cellstr input C with length N, returns a logical
%   vector D with length N-1 indicating consecutive elements of C that are
%   not identical. The I-th element is TRUE if C{I} and C{I+1} are not equal.

%   Copyright 2018-2020 The MathWorks, Inc.

    d = false(numel(c)-1,1);
    for i = 1:numel(c)-1
        d(i) = (~strcmp(c{i},c{i+1}));
    end
end

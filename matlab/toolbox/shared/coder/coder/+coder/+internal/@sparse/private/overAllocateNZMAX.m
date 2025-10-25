function goOver = overAllocateNZMAX()
%   Copyright 2018 The MathWorks, Inc.
% This feature can be enabled in FBT's to force the sparse constructor to
% always make nzmax 10 larger than it would otherwise be. This is nice to
% check every once in a while, since sparse matricies with "extra" space in
% rowidx and d are legitimate, but don't come up in tests too often. In the
% past, there have been some bugs (g1708324) caused by processing the
% garbage data at the end of overallocated sparse matricies.

%#codegen

if coder.target('MATLAB')
    goOver = false;
elseif coder.internal.get_eml_option('SparseOverAllocation')
    goOver = true;
else
    goOver = false;
end
end
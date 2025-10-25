function timespec = makeEMLRTTimespec(sec,nsec)
%MATLAB Code Generation Private Function

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen

if nargin < 1
    sec = coder.internal.indexInt(0);
end
if nargin < 2
    nsec = coder.internal.indexInt(0);
end
timespec.tv_sec = double(sec);
timespec.tv_nsec = double(nsec);
coder.cstructname(timespec,'emlrtTimespec','extern','HeaderFile','emlrt.h');

%--------------------------------------------------------------------------

function tdiff = timedifference(tstart,tend)
%MATLAB Code Generation Private Function

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen

tdiff_sec = double(tend.tv_sec)-double(tstart.tv_sec);
tdiff_nsec = double(tend.tv_nsec)-double(tstart.tv_nsec);
tdiff = tdiff_sec + tdiff_nsec./coder.internal.time.impl.timescale;

%--------------------------------------------------------------------------

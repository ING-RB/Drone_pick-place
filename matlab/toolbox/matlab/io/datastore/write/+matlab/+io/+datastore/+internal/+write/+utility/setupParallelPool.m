function currentPool = setupParallelPool()
%setupParallelPool    Set up a parallel pool if Parallel Computing Toolbox
%   is installed

%   Copyright 2023 The MathWorks, Inc.
    if matlab.internal.parallel.isPCTInstalled()
        currentPool = gcp;
    else
        currentPool = [];
    end 
end
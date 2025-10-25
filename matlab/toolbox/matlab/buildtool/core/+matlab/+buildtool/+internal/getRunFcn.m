function runFcn = getRunFcn(options)
% This function is unsupported and might change or be removed without 
% notice in a future version.

%   Copyright 2023 The MathWorks, Inc.

arguments
    options.Parallel (1,1) logical = false
end

% Run serially by default
runFcn = @run;

if ~options.Parallel || ~matlab.internal.parallel.isPCTInstalled
    return
end

if canRunInParallel
    runFcn = @runInParallel;
end
end


function tf = canRunInParallel()
arguments (Output)
    tf (1,1) logical
end

if ~matlab.internal.parallel.canUseParallelPool()
    tf = false;
    return
end
licenseName = "Distrib_Computing_Toolbox";
[canCheckout, ~] = license("checkout", licenseName);
tf = canCheckout;
end

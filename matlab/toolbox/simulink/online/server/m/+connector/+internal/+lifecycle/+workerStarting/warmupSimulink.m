function warmupSimulink(isForced)
% warmupSimulink Prewarm Simulink if PREWARM_SIMULINK is set to true or
% isForced is true
    
% Copyright 2023 The MathWorks, Inc.

if nargin < 1
    isForced = false;
end

% start simulink online
simulink.online.internal.start();

if ~strcmp(getenv('PREWARM_SIMULINK'), 'true') && ~isForced
    return;
end

if isempty(which('start_simulink'))
    disp('Not warming up Simulink - start_simulink not found');
    return;
end

% Start Simulink.
start_simulink;

% the dastudio may load before the simulink online flag is set, like in test
% start the slonline online here to make sure the slonline start succuessfully
slonline.start();

% Get environment variable value for unit warmup control
warmupParamsEnv = str2num(getenv('PREWARM_SIMULINK_PARAMETERS'));
if isempty(warmupParamsEnv)
    warmupParamsEnv = 0;
end

% Iterate over all injected warmup units
p = meta.package.fromName('simulink.online.internal.warmup');
f = p.FunctionList;
for idx=1:numel(f)
    fh = str2func([p.Name '.' f(idx).Name]);
    try
        feval(fh, warmupParamsEnv);
    catch ex
        warning(ex.message);
    end
end
end

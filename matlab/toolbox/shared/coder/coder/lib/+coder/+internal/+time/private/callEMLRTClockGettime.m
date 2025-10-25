function timespec = callEMLRTClockGettime(clockname)
%MATLAB Code Generation Private Function

% Returns a MATLAB struct emulating the output of the POSIX clock_gettime function
% by calling EMLRT
%
%   t.tv_nsec - coder.opaque('long')
%   t.tv_sec - coder.opaque('time_t')
%
% The value of CLOCKNAME should be "monotonic" or "realtime"

%   Copyright 2019 The MathWorks, Inc.
%#codegen
coder.internal.assert(coder.internal.runs_in_matlab(), 'Coder:builtins:Explicit', ...
    'Internal error: This function is only supported when running in MATLAB. E.g. MEX, SIM, etc.');
coder.internal.assert(clockname == "monotonic", 'Coder:builtins:Explicit', ...
    'Internal error: EMLRT only supports the monotonic clock. Use getLocalTime');
clockInfo = getClockInfo(clockname);
timespec = getTimeEMLRT(clockInfo.emlrtFunction);

%--------------------------------------------------------------------------

function timespec = getTimeEMLRT(emlrtFunction)
coder.inline('always');
timespec = coder.internal.time.impl.makeEMLRTTimespec();
status = coder.internal.indexInt(0);
status = coder.ceval('-jit',emlrtFunction, ...
    coder.wref(timespec));
checkPOSIXStatus(emlrtFunction,status);

%--------------------------------------------------------------------------

function checkPOSIXStatus(fcn,status)
if status ~= zeros('like',status)
    if coder.internal.runs_in_matlab()
        % Don't query errorno to avoid JIT fallback
        coder.internal.error('Coder:toolbox:POSIXCallFailed',fcn,status);
    end
end

%--------------------------------------------------------------------------

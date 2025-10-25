function f = parfevalMethodInvoker(poolMethod, varargin)
%parfevalMethodInvoker Invoke parfeval(OnAll) on the current parallel pool

% Copyright 2013-2021 The MathWorks, Inc.

pool = parallel.Pool.empty;
if matlab.internal.parallel.isPCTInstalled && matlab.internal.parallel.isPCTLicensed
    pool = parallel.internal.parpool.getOrCreateCurrentPool();
end

f = poolMethod(pool, varargin{:});
end

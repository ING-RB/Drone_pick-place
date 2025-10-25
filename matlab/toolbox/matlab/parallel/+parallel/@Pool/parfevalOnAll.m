function f = parfevalOnAll(aPool, varargin)
%parfevalOnAll Execute function on all workers in parallel pool
%   F = parfevalOnAll(P, FCN, NUMOUT, IN1, IN2, ...) requests the execution of the
%   function FCN on all workers contained in the parallel pool P, requesting
%   NUMOUT output arguments and supplying IN1, IN2, ... as input arguments.  F
%   is an FevalOnAllFuture, from which the results can be obtained when all
%   workers have completed executing FCN.
%
%   Examples:
%   Close all open Simulink models on all Parallel Computing Toolbox workers
%   p = gcp(); % get the currently open parallel.Pool instance
%   f = parfevalOnAll(gcp, @bdclose, 0, 'all');
%   % We have no output arguments, but you might want to wait
%   % for completion
%   wait(f);
%
%   See also parallel.Pool.parfeval,
%            parfeval, parfevalOnAll,
%            parallel.FevalOnAllFuture.

%   Copyright 2013-2024 The MathWorks, Inc.

if ~isa(aPool, "parallel.Pool")
    varargin = [{aPool}, varargin];
    aPool = parallel.internal.parpool.getOrCreateCurrentPool();
end

if isempty(aPool)
    aPool = matlab.internal.serialPool();
end

if ~isscalar(aPool)
    parallel.internal.fevalqueue.parfevalError(aPool, 'parfevalOnAll');
end

f = parfevalOnAll(aPool, varargin{:});

end

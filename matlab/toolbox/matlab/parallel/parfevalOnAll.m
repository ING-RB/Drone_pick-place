function f = parfevalOnAll(varargin)
%parfevalOnAll Execute function on all workers in parallel pool
%   F = parfevalOnAll(FCN, NUMOUT, IN1, IN2, ...) requests the execution of the
%   function FCN on all workers contained in the current parallel pool, requesting
%   NUMOUT output arguments and supplying IN1, IN2, ... as input arguments.  F
%   is an FevalOnAllFuture, from which the results can be obtained when all
%   workers have completed executing FCN.
%
%   F = parfevalOnAll(P, FCN, NUMOUT, IN1, IN2, ...) requests execution on all
%   parallel pool workers in the parallel pool P.
%
%   Examples:
%   Close all open Simulink models on all workers
%   f = parfevalOnAll(@bdclose, 0, 'all');
%   % We have no output arguments, but you might want to wait
%   % for completion
%   wait(f);
%
%   See also parallel.FevalOnAllFuture.fetchOutputs,
%            parallel.FevalOnAllFuture.wait,
%            parallel.FevalOnAllFuture.cancel,
%            parfeval,
%            parallel.Pool.parfevalOnAll,
%            parallel.FevalOnAllFuture.

% Copyright 2013-2021 The MathWorks, Inc.

try
    f = parfevalMethodInvoker(@parfevalOnAll, varargin{:});
catch E
    throw(E);
end

end

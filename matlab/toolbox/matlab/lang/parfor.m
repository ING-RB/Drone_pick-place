%PARFOR Execute for loop in parallel on workers in parallel pool
%   The general form of a PARFOR statement is:  
%
%       PARFOR LOOPVAR = INITVAL:ENDVAL
%           <statements>
%       END 
% 
%   MATLAB executes the loop body denoted by STATEMENTS for a vector of
%   iterations specified by INITVAL and ENDVAL. If you have Parallel
%   Computing Toolbox, the iterations of STATEMENTS can execute on a
%   parallel pool of workers on your multi-core computer or computer
%   cluster. PARFOR differs from a traditional FOR loop in the following
%   ways:
%
%      1. Iterations must be monotonically increasing integer values.
%      2. The order in which the loop iterations are executed is not
%         guaranteed.
%      3. Restrictions apply to the STATEMENTS in the loop body.
%   
%   PARFOR (LOOPVAR = INITVAL:ENDVAL, M); <statements>; END uses M to
%   specify the maximum number of workers in the parallel pool that will
%   evaluate STATEMENTS in the loop body. M must be a nonnegative integer.
%   By default, MATLAB uses as many workers as it finds available. When
%   there are no workers available in the pool or M is zero, MATLAB will
%   still execute the loop body in an iteration independent order but not
%   in parallel.
%
%   PARFOR (LOOPVAR = INITVAL:ENDVAL, OPTS); <statements>; END uses OPTS to
%   specify the resources to be used to evaluate STATEMENTS in the loop
%   body. OPTS is created by the parforOptions function, and can specify
%   that STATEMENTS are to be executed on a cluster without using a
%   parallel pool.
%
%   PARFOR (LOOPVAR = INITVAL:ENDVAL, CLUSTER); <statements>; END executes
%   STATEMENTS on parallel.Cluster instance CLUSTER without creating a
%   parallel pool. This is equivalent to executing
%   PARFOR (LOOPVAR = INITVAL:ENDVAL, parforOptions(CLUSTER)); <statements>; END
%
%   Unless you specify a cluster object, a parfor-loop tries to run on an
%   existing parallel pool. If no pool exists, parfor starts a new parallel
%   pool, unless the automatic starting of pools is disabled in your
%   parallel preferences. If there is no parallel pool and parfor is unable
%   to start one, the loop runs in an iteration independent order, but not
%   in parallel, in the client session.
%   
%   EXAMPLE
% 
%   Offload three large eigenvalue computations to three workers:
%   
%       parfor i = 1:3
%           c(i) = max(eig(rand(1000)));
%       end
%     
%   See also for, parpool, parcluster, parallel.Pool, parforOptions, gcp.

% Copyright 2008-2021 The MathWorks, Inc.
% Built-in function.

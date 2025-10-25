%EXECUTERPC executes a function and retries if the function 
%    is rejected with an "RPC_E_CALL_REJECTED" error.
%
%    executeRPC(FCN) executes FCN and retries five times if the function
%    is rejected.  An error is thrown if the function does not succeed
%    within five tries.
%
%    executeRPC(FCN, "MaxTries", MAXTRIES) executes FCN and retries 
%    MAXTRIES times if the function is rejected.  An error is thrown 
%    if the function does not succeed within MAXTRIES tries.
%
%    executeRPC(FCN, "RetryPreFcn", RETRYPREFCN, "MaxTries", MAXTRIES) 
%    executes FCN. If FCN is rejected, then RETRYPREFCN is executed
%    before executing FCN.  RETRYPREFCN is a user-provided function
%    that might help FCN successfully execute.

     
    %   Copyright 2020 The MathWorks, Inc.


%AfterAllFuture Future for function invoked after all preceding futures
%   Create an AfterAllFuture by calling the afterAll method on
%   parallel.Future
%
%   parallel.AfterAllFuture methods:
%      afterAll     - Specify function to invoke after all Futures complete
%      afterEach    - Specify function to invoke after each Future completes
%      cancel       - Cancel a pending, queued, or running Future
%      fetchOutputs - Retrieve all Futures outputs
%      isequal      - true if futures have the same ID
%      wait         - Wait for Futures to complete
%
%   parallel.AfterAllFuture properties:
%      CreateDateTime     - Date and time at which this future was created
%      Error              - Future error information
%      FinishDateTime     - Date and time at which this future finished running
%      Function           - Function to evaluate
%      ID                 - Future's numeric identifier
%      InputArguments     - Input arguments to function
%      NumOutputArguments - Number of arguments returned by function
%      OutputArguments    - Output arguments from running Function on a worker
%      Predecessors       - The preceding futures
%      RunningDuration    - The duration the future has been running for, if it has started
%      StartDateTime      - Date and time at which this future started running
%      State              - Current state of future
%
%   See also parallel.Future.afterEach,
%            parallel.Future.afterAll, parfeval, parfevalOnAll.

% Copyright 2017-2021 The MathWorks, Inc.

%{
classdef AfterAllFuture < parallel.Future
    properties (SetAccess = immutable)
        %Predecessors The futures this continuation should be executed after
        %   (read-only)
        Predecessors
    end
end
%}

%Future Base class for Futures
%   parallel.Future is the base class for future objects running on a
%   parallel pool's FevalQueue, or on the client. Each future object is
%   created by a call to either parfeval, parfevalOnAll, afterEach or
%   afterAll.
%
%   parallel.Future methods:
%      afterAll     - Specify function to invoke after all Futures complete
%      afterEach    - Specify function to invoke after each Future completes
%      cancel       - Cancel a pending, queued, or running Future
%      isequal      - true if futures have the same ID
%      fetchOutputs - Retrieve all Futures outputs
%      wait         - Wait for Futures to complete
%
%   parallel.Future properties:
%      CreateDateTime     - Date and time at which this future was created
%      Error              - Future error information
%      FinishDateTime     - Date and time at which this future finished running
%      Function           - Function to evaluate
%      ID                 - Future's numeric identifier
%      InputArguments     - Input arguments to function
%      NumOutputArguments - Number of arguments returned by function
%      OutputArguments    - Output arguments from running Function
%      RunningDuration    - The duration the future has been running for, if it has started
%      StartDateTime      - Date and time at which this future started running
%      State              - Current state of future
%
%   See also parfeval, parfevalOnAll,
%            gcp, parallel.Pool.parfeval, parallel.Pool.parfevalOnAll.

% Copyright 2013-2021 The MathWorks, Inc.

%{
classdef (Abstract) Future < parallel.internal.queue.FutureBase
    properties (Transient, SetAccess = immutable)
        %ID Future's numeric identifier
        %   (read-only)
        ID = parallel.Future.InvalidID;

        %NumOutputArguments Number of arguments returned by function
        %   (read-only)
        NumOutputArguments = 0;
    end
    properties (Dependent, SetAccess = private)
        %Function Function to evaluate
        %   Function can be specified as a function handle or a string.
        %   (read-only)
        Function

        %InputArguments Input arguments to function
        %   (read-only)
        InputArguments

        %OutputArguments Output arguments from running Function
        %   When the future is in state 'finished', if no error occurred during
        %   task evaluation, OutputArguments contains the results of evaluating
        %   the future's Function.
        %   (read-only)
        OutputArguments

        %Error Future error information
        %   The Error property contains a ParallelException, which is empty if no
        %   error occurred.
        %   (read-only)
        Error

        %State Current state of future
        %   A future may be in state 'queued', 'running', 'finished',
        %   'failed', or 'unavailable'.
        %   (read-only)
        State

        %CreateDateTime Date and time at which this future was created
        %   (read-only)
        CreateDateTime

        %StartDateTime Date and time at which this future started running
        %   If this future has not started running, StartDateTime is empty.
        %   (read-only)
        StartDateTime

        %FinishDateTime Date and time at which this future finished running
        %   If this future has not finished running, FinishDateTime is empty.
        %   (read-only)
        FinishDateTime
        
        %RunningDuration The duration the future has been running for, if started.
        %   If this future has not yet started running, the RunningDuration will
        %   be a 0 length duration.
        %   (read-only)
        RunningDuration
    end
%}

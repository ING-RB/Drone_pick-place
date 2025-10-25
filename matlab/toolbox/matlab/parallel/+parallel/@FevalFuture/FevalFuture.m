%FevalFuture Single parfeval Future
%   An FevalFuture is created when you call the parfeval function. To create
%   multiple FevalFutures, call parfeval multiple times.
%
%   parallel.FevalFuture methods:
%      afterAll     - Specify function to invoke after all Futures complete
%      afterEach    - Specify function to invoke after each Future completes
%      cancel       - Cancel a pending, queued, or running Future
%      fetchNext    - Fetch next available unread FevalFuture outputs
%      fetchOutputs - Retrieve all Futures outputs
%      isequal      - true if futures have the same ID
%      wait         - Wait for Futures to complete
%
%   parallel.FevalFuture properties:
%      CreateDateTime     - Date and time at which this future was created
%      Diary              - Text produced by execution of future object's function.
%      Error              - Future error information
%      FinishDateTime     - Date and time at which this future finished running
%      Function           - Function to evaluate
%      ID                 - Future's numeric identifier
%      InputArguments     - Input arguments to function
%      NumOutputArguments - Number of arguments returned by function
%      OutputArguments    - Output arguments from running Function on a worker
%      Parent             - FevalQueue containing this future
%      Read               - Flag indicating if the outputs have been read by a call to fetchNext or fetchOutputs
%      RunningDuration    - The duration the future has been running for, if it has started
%      StartDateTime      - Date and time at which this future started running
%      State              - Current state of future
%
%   See also parfeval, parallel.Pool.parfeval,
%            parallel.Future.afterEach,
%            parallel.Future.afterAll, gcp.

% Copyright 2013-2021 The MathWorks, Inc.

%{
classdef FevalFuture < parallel.Future
    properties(Dependent, SetAccess=private)
        % Diary Text produced by execution of future object's function.
        %   (read-only)
        Diary
    end
    properties (Transient, SetAccess = protected)
        %Parent FevalQueue containing this future
        %   Empty if the future has not yet been submitted.
        %   (read-only)
        Parent = parallel.FevalQueue.empty();
    end
    properties (Dependent)
        %Read Flag indicating if the outputs have been read by a call to fetchNext or fetchOutputs
        %   The Read flag is initially false, and becomes true only when the
        %   outputs of the FevalFuture have been fetched by a call to fetchNext
        %   or fetchOutputs.
        %   (read-only)
        Read
    end
end
%}

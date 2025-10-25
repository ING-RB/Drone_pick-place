classdef AsyncTask < handle
    %ASYNCTASK Run a function in the background of MATLAB.
    %
    % If there's a long running script or funciton, but you do not want to
    % block MATLAB, this module could help.
    % task1 = AsyncTask(@()longRunScript());
    % future = task1.run(input1, input2);
    %
    %    Copyright 2021 The MathWorks, Inc.
    
    properties (Access = private)
        FunctionHandle
        % Todo: enable this when we can use backgroundPool.
        % Future
    end
    
    methods
        function obj = AsyncTask(funcHandle)
            validateattributes(funcHandle, {'function_handle'}, {});
            
            obj.FunctionHandle = funcHandle;
        end
        
        function future = run(obj, varargin)
            future = [];
            
            % Temporarily run a task in MVM's IQM queue by adding it
            % We cannot use appdesigner.internal.serialization.defer() because
            % it would put the task into the queue with default deque mode:
            % DEQUEUE_AT_PROMPT, which would be
            % jumped by drawnow to trigger other task in the queue with mode:
            % DEQUEUE_AT_PPE, for instance
            % getStartupState() feval request from client, which is an issue
            % in our tLaunchAppDesignerTest that would have implicit drawnow
            % through qePoll.
            % This would not be an issue when we start appdesigner manually
            % because no drawnow to happen.
            % Using the graphics callback deferring, which would use the queue
            % with DEQUEUE_AT_PPE.
            % todo: When we can use backgroundPool, we should be have a better
            % promise to maintain order, instead of relying on IQM itself.
            matlab.graphics.internal.drawnow.callback(@()obj.FunctionHandle(varargin{:}));
            
            % There's a new API for running a task in background pool, 
            % (https://confluence.mathworks.com/display/PCT/backgroundPool%3A+A+User+Guide#backgroundPool:AUserGuide-WhendoesbackgroundPoolopen?)
            % which is in a separated thread from MATLAB interpreter thread.
            % So that it could help paralleling a task with MATLAB, however,
            % there's a knonw start performance issue (g2455629), thus we
            % cannot use it for now.
            % 
            % Code could be:
            % if canUseParallelPool % User configured PCT - PCT required
            %     pool = gcp();
            % else
            %     pool = backgroundPool();
            % end
            % if nargin == 1
            %     future = parfeval(pool, obj.FunctionHandle, 0);
            % else
            %     future = parfeval(pool, obj.FunctionHandle, nargin - 1, varargin{:});
            % end
            % obj.Future = future;
        end
%         
%         % todo: support fetch result when backgroundPool is ready to use
%         function varargout = fetch(obj, noutput)
%            varargout = fetchOutputs(obj.Future, noutput); 
%         end
    end
end


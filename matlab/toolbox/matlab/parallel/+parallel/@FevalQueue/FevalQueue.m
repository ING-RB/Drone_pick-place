%FevalQueue Container for incomplete parallel.Future objects
%   The FevalQueue contains queued and running Future objects created by the
%   parfeval and parfevalOnAll functions. Futures which are in state 'finished'
%   are not retained by the FevalQueue.
%
%   parallel.FevalQueue properties:
%      QueuedFutures  - List of queued Future objects ordered by ID
%      RunningFutures - List of running Future objects ordered by ID
%
%   parallel.FevalQueue methods:
%      cancelAll  - cancel all incomplete parallel.Future objects
%
%   See also: parfeval, parfevalOnAll,
%             parallel.Future,
%             gcp, parallel.Pool,
%             parallel.Pool.parfeval,
%             parallel.Pool.parfevalOnAll,
%             parallel.Pool.FevalQueue.

% Copyright 2013-2024 The MathWorks, Inc.
classdef FevalQueue < handle
    
    properties (Dependent, SetAccess = private)
        %QueuedFutures List of queued Future objects ordered by ID
        %   (read-only)
        QueuedFutures
        
        %RunningFutures List of running Future objects ordered by ID
        %   (read-only)
        RunningFutures
    end
    
    properties (Dependent, Hidden, SetAccess = private)
        % All queued / running Futures, used for testing.
        OutstandingFutures
    end

    properties (Hidden, Access = private) 
        % Controller which sends parfevals to remote workers. Only set and
        % used for process pools.
        ParfevalController
    end
    
    properties (GetAccess = private, SetAccess = immutable, Transient)
        % Actual queue implementation, which holds on to the running
        % futures. Is a parallel.internal.fevalqueue.FevalQueue.
        QueueImpl
    end

    properties(SetAccess = immutable, Transient, Hidden)
        % Unique (per session) numeric ID so that this queue can be
        % identified from a static context.
        QueueID
    end
    
    properties (SetAccess = immutable, Transient, WeakHandle)
        %Parent The parallel.Pool object containing this FevalQueue
        Parent parallel.Pool
    end
    
    properties (Constant, GetAccess = private)
        Displayer = parallel.internal.fevalqueue.FevalQueueDisplayer()
    end
    
    events (Hidden)
        % FutureCompleted - fired each time a task completes.
        FutureCompleted
    end

    methods (Access=?parallel.internal.pool.ClusterClientSession)
        function setParfevalController(obj, parfevalController)
            obj.ParfevalController = parfevalController;
        end
    end
    
    methods
        function taskVector = get.QueuedFutures(obj)
            taskVector = obj.QueueImpl.QueuedFutures;
        end
        function taskVector = get.RunningFutures(obj)
            taskVector = obj.QueueImpl.RunningFutures;
        end
        function taskVector = get.OutstandingFutures(obj)
            taskVector = [obj.QueueImpl.QueuedFutures, ...
                    obj.QueueImpl.RunningFutures];
        end
    end
    
    methods (Access = private)
        function obj = FevalQueue(pool, implArg)
            % Instances of this class may exist on exit, so mlock
            % to avoid warnings.
            mlock
            obj.QueueID = iAllocateQueueID();
            obj.Parent = pool;
            assert(isa(implArg, 'parallel.internal.fevalqueue.FevalQueue'));
            obj.QueueImpl = implArg;
        end
    end
    
    methods (Access = ?parallel.Pool)
        function t = parfeval(obj, fcn, numArgsOut, varargin)
            %FEVAL create and submit a Future to this FevalQueue
            
            narginchk(3, Inf);
            nargoutchk(1, 1);
            obj.errorIfQueueNotValid()
            
            t = obj.ParfevalController.parfeval(obj, fcn, numArgsOut, varargin{:});
            
        end
        function bt = parfevalOnAll(obj, fcn, numArgsOut, varargin)
            %PARFEVALONALL create and submit a broadcast Future to this FevalQueue
            
            narginchk(3, Inf);
            nargoutchk(1, 1);
            obj.errorIfQueueNotValid()
            
            bt = obj.ParfevalController.parfevalOnAll(obj, fcn, numArgsOut, varargin{:});
        end
    end

    methods (Access = ?parallel.internal.pool.LeadWorkers)
        function bt = parfevalOnAllWithWorkerFilter(obj, filter, fcn, numArgsOut, varargin)
            narginchk(4, Inf);
            nargoutchk(1, 1);

            bt = obj.ParfevalController.parfevalOnAllWithWorkerFilter(obj, filter, fcn, numArgsOut, varargin{:});
        end
    end
    
    methods
        function cancelAll(obj)
            %CANCELALL Cancel all incomplete Future objects for this FevalQueue.
            cancel(obj.QueuedFutures);
            cancel(obj.RunningFutures);
        end

        function disp(objOrObjs)
            %DISP Display object.
            parallel.FevalQueue.Displayer.doDisp(objOrObjs);
        end
    end
    
    methods (Access = private)
        function notifyFutureCompleted(obj, taskId)
            if event.hasListener(obj, 'FutureCompleted')
                data = parallel.internal.queue.FutureCompletedEventData(taskId);
                notify(obj, 'FutureCompleted', data);
            end
        end
        
        function errorIfQueueNotValid(obj)
            if ~obj.hIsValid()
                err = MException(message('MATLAB:parallel:future:InvalidQueue'));
                throwAsCaller(err);
            end
        end
    end
    
    methods (Hidden)
        % Submit unsubmitted futures
        function submitFutures(obj, futures)           
            for i = 1:numel(futures)
                obj.ParfevalController.submitUnsubmitted(obj, futures(i));
            end
        end

        % Toggle the FutureCompleted event
        function wasEnabled = hToggleCallbacks(obj, newVal)
            wasEnabled = obj.ParfevalController.toggleCallbacks(newVal);
        end
        
        function f = hGetFutureByID(obj, id)
            allFutures = [obj.QueuedFutures, obj.RunningFutures];
            idx = find(arrayfun(@(f) f.ID, allFutures) == id);
            if isempty(idx)
                f = parallel.Future.empty();
            else
                f = allFutures(idx);
            end
        end
        
        function tf = hIsValid(obj)
            tf = isvalid(obj.QueueImpl);
        end
        
        function q = hGetQueueImpl(obj)
            obj.errorIfQueueNotValid()
            q = obj.QueueImpl;
        end

        function id = hGetMostRecentlyAssignedID(obj)
            id = obj.ParfevalController.hGetMostRecentlyAssignedID();
        end
    end
    
    methods (Static, Access = ?parallel.internal.pool.ISession)
        function obj = getQueueForSession(pool, queueImplBuilder)
            obj = parallel.FevalQueue(pool, queueImplBuilder);
        end
    end

    methods (Static, Hidden)
        function obj = wrapUnifiedFevalQueue(unifiedFevalQueue)
            assert(isa(unifiedFevalQueue, 'parallel.internal.fevalqueue.FevalQueue'), ...
                'Assertion failed: Expected a FevalQueue from the unified framework.')
            obj = parallel.FevalQueue(unifiedFevalQueue.Parent, unifiedFevalQueue);
        end
    end
    
    methods (Static, Hidden)
        function futureCompleted(queueID, taskId)
            % Called from the cpp layer each time a task is completed.
            
            % Stash the result of gcp() since it's most likely to be the same as last time.
            persistent POOL
            if isempty(POOL) || ~isvalid(POOL)
                POOL = gcp('nocreate');
                poolSetThisTime = true;
            else
                poolSetThisTime = false;
            end
            
            wasCorrectPool = parallel.FevalQueue.callNotifyIfPossible(POOL, queueID, taskId);
            if ~poolSetThisTime && ~wasCorrectPool
                POOL = gcp('nocreate');
                parallel.FevalQueue.callNotifyIfPossible(POOL, queueID, taskId);
            end
        end
        
        function wasCorrectPool = callNotifyIfPossible(pool, queueID, taskId)
            wasCorrectPool = false;
            if isscalar(pool)
                Q = pool.FevalQueue;
                if isscalar(Q) && queueID == Q.QueueID
                    wasCorrectPool = true;
                    
                    Q.notifyFutureCompleted(taskId);
                end
            end
        end
    end
end


function queueID = iAllocateQueueID()
persistent NEXT_ID
if isempty(NEXT_ID)
    NEXT_ID = 1;
end
queueID = NEXT_ID;
NEXT_ID = 1 + NEXT_ID;
end

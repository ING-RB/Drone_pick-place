%DataQueue class that enables sending and listening for data
%
%   parallel.pool.DataQueue enables transferring data or messages between
%   workers and the client in a parallel pool, while a computation is being
%   carried out. For example, you can return intermediate values from a
%   computation to indicate its progress. When data is received, the
%   functions specified by afterEach are called with that data. Data can
%   only be sent to the client or worker which created the data queue.
%
%   Use a parallel.pool.DataQueue if you want to execute callbacks when
%   data is received from the send method.
%
%   parallel.pool.DataQueue methods:
%      send        - Send data between workers and client afterEach   -
%      Define a function to call when data is received
%
%   parallel.pool.DataQueue properties:
%      QueueLength - Number of items currently held in the queue
%
%   See also: parallel.pool.PollableDataQueue
classdef DataQueue < parallel.internal.dataqueue.AbstractDataQueue
     
    % Copyright 2016-2025 The MathWorks, Inc.
    
    properties ( Dependent, Access = protected )
        % Flag to indicate that someone is listening to DataReceived events
        HasAfterEachTrigger
    end
    
    events (ListenAccess = 'protected', NotifyAccess = 'protected')
        % This event is used to trigger all the listener callbacks supplied
        % to afterEach. 
        AfterEachTrigger
    end
    
    properties (Access = 'protected')
        AfterEachListeners = event.listener.empty()
        Dispatching = false;
    end
    
    properties ( Hidden )
        UseWhenMatlabReady = true;
    end

    properties (Access = protected)
        CheckClosed = false;
    end
    
    methods
        function obj = DataQueue(varargin)
            narginchk(0, 1);
            obj@parallel.internal.dataqueue.AbstractDataQueue(varargin{:})
        end
        
        function send(obj, data)
            %SEND Send messages or data between workers and client using a
            %data queue
            %
            % Use the send and afterEach methods together to send messages
            % or data between workers and the client using a data queue.
            %
            % q = parallel.pool.DataQueue constructs a data queue and
            % returns an object that can be used to send data to the queue.
            % send(q, V) sends a message or data with the value V. This
            % data will be passed as input to any functions added by the
            % afterEach function.
            %
            % Example:  construct a DataQueue, send a message (some data
            % with the value of i) and display the result
            %
            % q = parallel.pool.DataQueue;
            % afterEach(q, @disp);
            % parfor i = 1:10
            %     send(q, i);
            % end
            %
            % See also parallel.pool.DataQueue/afterEach, parallel.pool.DataQueue
            %          parallel.pool.PollableDataQueue/poll
            
            
            % No matter if we are remote or local this will be
            % dispatched by either a previous call to send or
            % placement of a something on the IQM.
            arguments
                obj (1,1) parallel.pool.DataQueue
                data
            end
            
            send@parallel.internal.dataqueue.AbstractDataQueue(obj, data);
            
            if obj.OnInstantiatingProcess && obj.HasAfterEachTrigger 
                obj.Queue.triggerQueueDrainFromMatlab();
            end
        end
        
        function optionalListener = afterEach(obj, functionHandle)
            %AFTEREACH Add function to call when new data is received from
            %a data queue
            %
            % optionalListener = afterEach(q, funToCall) adds the function
            % defined by the function handle funToCall to the list of
            % functions to call when a piece of new data is received from
            % data queue q.
            %
            % The single (optional) output argument from the afterEach
            % method is the event.listener that is constructed to trigger
            % the callback supplied. You can remove the callback at some
            % later stage, by deleting the returned listener object. After
            % you have supplied the afterEach function handle, sending data
            % on the queue automatically triggers the afterEach listener.
            % All data is provided to the listeners and then discarded to
            % avoid memory leaks.
            %
            % Example: Dispatch of data on a queue when afterEach is called
            %
            % If you call the afterEach function and there are items on the
            % queue waiting to be dispatched, then these will be
            % immediately dispatched to the afterEach function.
            %
            % If you call afterEach before sending data to the queue, this
            % ensures that on send the afterEach function is called.
            %
            % q = parallel.pool.DataQueue;
            % afterEach(q, @disp);
            % parfor i = 1
            %     send(q, 3); 
            % end
            %      3
            % send(q, 3)
            %      3
            %
            % If you send the data to the queue and then call afterEach,
            % each of the pending messages are passed to the afterEach
            % function.
            %
            % q = parallel.pool.DataQueue;
            % parfor i = 1
            %     send(q, 3); 
            % end
            % send(q, 3)
            % afterEach(q, @disp);
            %      3
            %      3
            %
            % See also parallel.pool.DataQueue/send, parallel.pool.DataQueue

            arguments
                obj (1,1) parallel.pool.DataQueue 
                functionHandle (1,1) function_handle
            end

            % When a DataQueue has been serialized across to a worker the
            % Queue propoerty will be empty. So we need to guard against
            % this here.
            if ~obj.OnInstantiatingProcess
                error(message('MATLAB:parallel:dataqueue:NoQueue'));
            end

            listener = obj.createAfterEachListener(functionHandle);

            % Return the listener if requested.
            if nargout > 0
                optionalListener = listener;
            end

            % If there is any data on the queue we need to dispatch it
            if obj.QueueLength > 0
                obj.Queue.triggerQueueDrainFromMatlab();
            end
        end
        
        % -----------------------------------------------------------------
        % END OF PUBLIC INTERFACE TO DataQueue
        % -----------------------------------------------------------------
                
        function OK = get.HasAfterEachTrigger(obj)
            OK = event.hasListener(obj, 'AfterEachTrigger');
            % If ~OK we need to check if we have some valid but disabled
            % listeners since we still want to trigger events in this case
            % (see g1502515)
            if ~OK
                obj.removeInvalidAfterEachListeners();
                OK = ~isempty(obj.AfterEachListeners);
            end
        end        
    end
    
    methods (Access = protected)
        function S = saveobj(obj)
            % NOTE: any object that wants to be saved in a special way
            % needs to implement its own version of saveobj - we simply
            % defer to our base class implementation.
            S = saveobj@parallel.internal.dataqueue.AbstractDataQueue(obj);
        end
        
        function setShouldSignalMatlabOnDataArrival(obj)
            obj.Queue.startNotifyingMatlabOnDataReceived();
            obj.Queue.setUseWhenMatlabReady(obj.UseWhenMatlabReady);
        end
        
        function maybeDrainAndDispatchAllDataOnQueue(obj)
            c = onCleanup(@() obj.postDispatchContinuations()); 
            obj.Dispatching = true;
            % Loop until there is no data left on the queue.
            for ii = 1:obj.QueueLength
                % If during dispatching items on the queue someone has
                % deleted all the listeners then we have no way of knowing
                % that we should stop dispatching events. So we need to
                % check here to see if anyone is still listening. If they
                % aren't then we should tell the java layer no-one is
                % listening and return early.
                if ~obj.HasAfterEachTrigger 
                    obj.Queue.stopNotifyingMatlabOnDataReceived();
                    return
                end

                % We do not want this poll to dequeue IQM events
                [message, OK] = obj.pollImpl(0, false);
                if ~OK
                    return
                end
                obj.dispatchContinuation(message);
            end
        end
        
        % This queue may have a number of defined continuations that need
        % to be executed on some data. This function defines what to do for
        % that piece of data.
        function dispatchLocalMessage(obj, message)            
            c = onCleanup(@() obj.postDispatchContinuations()); 
            obj.Dispatching = true;
            obj.dispatchContinuation(message);
        end
        
        function postDispatchContinuations(obj)
            if obj.isvalid
                obj.Dispatching = false;
            end
        end
    end
    
    methods (Hidden, Access={?parallel.internal.dataqueue.DataQueueAccess})
        function redirectDiaryToCaller(obj)
            obj.Queue.redirectDiaryToCaller();
        end
        function redirectDiaryToDefault(obj)
            obj.Queue.redirectDiaryToDefault();
        end
    end
    
    methods (Access = private)
        function listener = createAfterEachListener(obj, func)
            listener = event.listener(obj, 'AfterEachTrigger', @(src, event) iDispatchDataReceived(func, src, event));
            listener.Recursive = true;
            obj.removeInvalidAfterEachListeners();
            obj.AfterEachListeners(end+1) = listener;
            obj.setShouldSignalMatlabOnDataArrival();
        end
        
        function removeInvalidAfterEachListeners(obj)
            obj.AfterEachListeners(~isvalid(obj.AfterEachListeners)) = [];
        end
        
        function dispatchContinuation(obj, message)
            evtData = parallel.pool.DataReceivedEventData(message);
            obj.notify('AfterEachTrigger', evtData);
        end
    end    
end

function iDispatchDataReceived(func, ~, evtData)
try
    feval(func, evtData.ReceivedData);
catch err
    parallel.internal.warningNoBackTrace(err.identifier, err.message);
    parallel.internal.schedulerMessage(2, 'Error caught while executing afterEach continuation: %s', err.message);
end
end

classdef (Abstract) AbstractDataQueue < handle
    %
    
    % Copyright 2016-2024 The MathWorks, Inc.
    
    
    properties ( Dependent, SetAccess = private )
        %QueueLength Number of items currently held in the queue.
        %    QueueLength is a read-only property on all types of DataQueue
        QueueLength;
    end

    properties ( Dependent, Access = protected )
        % Dependent properties to access Uuid_ and Queue_ that trigger
        % delayed construction of this object. The only reason for this is
        % to deal with array construction (for example
        %   clear D
        %   D(4) = parallel.internal.pool.DataQueue
        % We would like D(1) to D(3) to be working DataQueues - and hence
        % they will each need unique UUID's and Queue's.
        Uuid
        Queue
    end
    
    properties ( Dependent, Hidden, SetAccess = private, GetAccess = protected )
        % Flag to indicate if this is the MVM that created this queue
        OnInstantiatingProcess
    end
    
    properties ( SetAccess = private, GetAccess = protected )
        % The UUID of the MVM this queue was created on. This allows a
        % queue to know if the current MVM is the one it was created
        % on.
        MvmUuid
        
        % Internal flag that ensures the expected internal fields of this
        % object have been filled in. This happens in a delayed way, so
        % that array construction of this object works correctly (which
        % doesn't currently call the constructor the right number of times)
        HasBeenFullyConstructed = false
        
        % This is the Uuid representing the queue that will receive
        % messages. Messages will be sent from remote machines with this
        % UUID and they will be delivered by the core infrastructure to the
        % Queue associated with this object.
        Uuid_
        
        % NOTE: CommGroupUuid & ProcessInstance are populated
        % as late as possible, during serialization (just prior to being
        % sent to a worker). We only expect to see them filled in after a
        % queue has been used in a parallel pool
        
        % Factory for constructing remote process backed queue
        % implementation.
        RemoteProcessQueueFactory
        
        % NOTE: Queue_ is guaranteed to not be the original LocalQueue if
        % OnInstantiatingProcess is FALSE. Instead it will be a proxy to
        % that queue.
        
        % The Queue property is transient so that when serialized the
        % DataQueue will only contain the UUID of the queue to which
        % messages should be sent.
        Queue_
    end
    
    properties ( Constant, Access = private )
        % The UUID of this MVM to check loaded DataQueues against. If on a
        % thread worker, this is the prefix of the UUID, otherwise it is
        % the UUID itself.
        ThisMvmUuidBase = parallel.internal.getMvmID();
    end

    properties ( Constant, Hidden, Transient )
        % Registry to enable this class to act as a Flyweight, with one handle
        % object per UUID. Used during deserialization to recover the
        % same object for a given UUID.
        %
        % Note, public for testing purposes only.
        Registry = matlab.internal.parallel.FlyweightRegistry();
    end

    properties (Access = protected, Abstract)
        % Whether or not to check if the queue is closed before sending.
        % Only subclasses which can be closed should set this to true.
        CheckClosed
    end
    
    methods
        function obj = AbstractDataQueue(arg)
            % Zero-arg constructor is used by users to make a new DataQueue
            if nargin == 0
                obj.MvmUuid = obj.getThisMvmUuid();
                % Note the on use of UUID and Queue we will delay construct
                % the rest of the fields in this object.
            else
                % This is the deferred constructor, called for
                % deserialization.
                obj.construct(arg);
            end
        end
        
        function send(obj, data)
            % send(dataQueue, DATA)
            % This function sends DATA from the current worker to the
            % MATLAB that created the DataQueue. Some (short) time later
            % that data can be retrieved in that MATLAB using the poll
            % method.
            try
                obj.Queue.add(data, obj.CheckClosed)
            catch err
                throw(err);
            end
        end


        
        % -----------------------------------------------------------------
        % END OF PUBLIC INTERFACE TO AbstractDataQueue
        % -----------------------------------------------------------------   
        function OK = get.OnInstantiatingProcess(obj)
            OK = isequal(obj.MvmUuid, obj.getThisMvmUuid());
        end
        
        % Delay instantiation getters
        function uuid = get.Uuid(obj)
            if ~obj.HasBeenFullyConstructed
                obj.construct();
            end
            uuid = obj.Uuid_;
        end
        
        function queue = get.Queue(obj)
            if ~obj.HasBeenFullyConstructed
                obj.construct();
            end
            queue = obj.Queue_;
        end
        
        function len = get.QueueLength(obj)
            % NOTE: below is a call to the java size method of a
            % Collection, not a call to the MATLAB size function - hence
            % the test for emptiness of the Queue_ with the single zero
            % response.
            if ~obj.HasBeenFullyConstructed || isempty(obj.Queue_)
                len = 0;
            else
                len = obj.Queue_.getSize();
            end
        end
    end
    
    methods (Hidden, Static)
        function obj = loadobj(S)
            obj = parallel.internal.dataqueue.AbstractDataQueue.Registry.getIfExists(S.Uuid);

            % If we aren't in the Registry we need to call our constructor.
            if isempty(obj)
                % Make sure we construct the correct subclass on load.
                constructorFcn = str2func(S.Class);
                obj = constructorFcn(S);
            end
        end
        
        % This function is triggered from the runDrainOnMatlabThread C++ method in DataQueueStorage.
        % The intent is to drain all pending data in the queue (specified by the uuid) which has registered for
        % continuations. Each sub-class of AbstractDataQueue is expected to
        % override maybeDrainAndDispatchAllDataOnQueue.
        function tf = notifyQueue(uuid)
            try 
                obj = parallel.internal.dataqueue.AbstractDataQueue.Registry.getIfExists(uuid);
                obj.maybeDrainAndDispatchAllDataOnQueue();
                tf = true;
            catch err
                % If we can't find this DataQueue in our map or any other
                % error happens then we should tell the C++ layer not to
                % call us back again.
                tf = false;
                parallel.internal.schedulerMessage(1, 'Unexpected error in drainQueue: %s', err.message);
                return          
            end
        end
    end
    
    methods (Access = protected)
        
        function [data, OK] = pollImpl(obj, timeout, dequeueIqm)
            % Look on the blocking queue object to see if any messages
            % have arrived.
            
            dataAndOk = obj.Queue.poll(timeout, dequeueIqm);
            data = dataAndOk{1};
            OK = dataAndOk{2};
        end
        
        function S = saveobj(obj)
            
            if obj.OnInstantiatingProcess
                % Before serialization we need to ensure that we are
                % registered correctly with the current pool (if there is
                % one) as we expect messages to come back and we need to be
                % listening for them
                obj.initializeCommunication();
            end
            % Now form the serialized form of this object - which is a
            % simple structure type object.
            S = parallel.internal.dataqueue.SerializedDataQueue( ...
                obj.Uuid, ...
                obj.RemoteProcessQueueFactory, ...
                obj.MvmUuid,...
                class(obj));
            
            parallel.internal.general.SerializationNotifier.notifySerialized(...
                class(obj));
        end

        function closeImpl(obj)
            obj.Queue.close()
        end

        function ic = isClosedImpl(obj)
            ic = obj.Queue.isClosed();
        end
    end
    
    methods (Abstract, Access = protected)
        
        setShouldSignalMatlabOnDataArrival(obj)
        
        maybeDrainAndDispatchAllDataOnQueue(obj)
        
    end
    
    methods (Access = private)
        % This is the delayed instantiation method that will build the
        % internal data structures.
        function construct(obj, arg)
            import parallel.internal.dataqueue.LocalQueue
            import parallel.internal.dataqueue.AbstractDataQueue
            % Zero-arg constructor is used by users to make a new DataQueue
            if nargin == 1
                obj.Uuid_ = matlab.lang.internal.uuid;
                obj.Queue_ = LocalQueue.findOrCreateQueue(obj.Uuid_, obj.MvmUuid);
            elseif isa(arg, 'parallel.internal.dataqueue.SerializedDataQueue')
                % This is a construction method needed to allow
                % serialization across multiple processes
                obj.Uuid_ = arg.Uuid;
                obj.MvmUuid = arg.MvmUuid;
                % Check if this is a load/save into the same process (or
                % round trip from a client to a workers and back). To get
                % here we know that we were not previously in the
                % SoftReference map and so we need to create a Queue_
                if obj.OnInstantiatingProcess
                    obj.Queue_ = LocalQueue.findOrCreateQueue(obj.Uuid_, obj.MvmUuid);
                else
                    % We need to always keep the RemoteProcessQueueFactory
                    % if nonempty just in-case this send-only DataQueue is
                    % serialized again to build another send-only DataQueue
                    % elsewhere.
                    obj.RemoteProcessQueueFactory = arg.RemoteProcessQueueFactory;
                    % If we're in the same process but a different thread,
                    % we can just lookup Queue_ using in-process logic.
                    % This will return empty if not.
                    obj.Queue_ = parallel.internal.dataqueue.RemoteThreadsQueue.findQueue(obj.Uuid_, obj.MvmUuid);
                    % Otherwise, we try whatever communication is setup by
                    % the receiving end
                    if isempty(obj.Queue_) && ~isempty(arg.RemoteProcessQueueFactory)
                        obj.Queue_ = arg.RemoteProcessQueueFactory.build();
                    end
                    % Otherwise, fail.
                    if isempty(obj.Queue_)
                        % Initialize Queue_ anyway, as this code is
                        % triggered in deserialization and the user will
                        % always get an object back even if we error.
                        obj.Queue_ = parallel.internal.dataqueue.InvalidQueue();
                        obj.HasBeenFullyConstructed = true;
                        error(message('MATLAB:parallel:dataqueue:InvalidProcess'));
                    end
                end
            else
                % Broken Impl here
                obj.Queue_ = parallel.internal.dataqueue.InvalidQueue();
                obj.HasBeenFullyConstructed = true;
                error(message('MATLAB:parallel:dataqueue:WrongConstructorArgs'));
            end
            obj.HasBeenFullyConstructed = true;
            parallel.internal.dataqueue.AbstractDataQueue.Registry.add(obj, obj.Uuid);
        end
        
        function initializeCommunication(obj)
            
            if ~obj.OnInstantiatingProcess ...
                    || (~isempty(obj.RemoteProcessQueueFactory) && obj.RemoteProcessQueueFactory.isValid())
                % Already initialized, don't need to do this again.
                return;
            end
            
            % We have just defined the Queue - we need to let it
            % know if we need MATLAB to be signalled on receipt of data
            %TODO - work out how to template / do this correctly
            obj.setShouldSignalMatlabOnDataArrival();
            
            % As communication is implementation specific, we initialize by
            % dispatching on the session object underlying the current pool
            % The returned factory contains the necessary knowledge to
            % initialize the internals of send-only DataQueues.
            
            % For process-based pools, initialize communication.
            if matlab.internal.parallel.isPCTInstalled && matlab.internal.parallel.isPCTLicensed
                sessionObject = parallel.internal.pool.workerSession();
                if isempty(sessionObject)
                    pool = parallel.internal.pool.PoolArrayManager.getCurrentWithCleanup();
                    if ~isempty(pool) && ~isa(pool, "parallel.ThreadPool")
                        sessionObject = pool.hGetClient();
                    end
                end
                % If there isn't a pool we can't do anything
                if ~isempty(sessionObject) && sessionObject.Session.isSessionRunning()
                    obj.RemoteProcessQueueFactory = sessionObject.Session.createRemoteQueueFactory(obj.Uuid);
                end
            end
        end  
        
    end
    
    methods (Static, Access = private)
        % Get the MVM UUID for the current worker.
        function mvmUuid = getThisMvmUuid()
            mvmUuid = matlab.internal.parallel.threads.getLogicalPoolSessionId() ...
                + parallel.internal.dataqueue.AbstractDataQueue.ThisMvmUuidBase;
        end
    end

    methods (Static, Hidden)
        % This function is triggered when a thread-based pool is deleted.
        % We need to ensure state on a worker associated with the
        % thread-based pool is cleaned up.
        function cleanupWorkerLogicalState()
            import parallel.internal.dataqueue.AbstractDataQueue
            import parallel.internal.dataqueue.LocalQueue
            thisMvmUuid = AbstractDataQueue.getThisMvmUuid();
            queues = AbstractDataQueue.Registry.getAll();
            for ii = 1:numel(queues)
                queue = queues{ii};
                if queue.MvmUuid == thisMvmUuid
                    delete(queue);
                end
            end
            LocalQueue.cleanupMvmUuid(thisMvmUuid);
        end
    end
end


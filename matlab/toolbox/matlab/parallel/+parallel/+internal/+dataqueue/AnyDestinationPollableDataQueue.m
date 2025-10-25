classdef AnyDestinationPollableDataQueue < handle
    % Internal implementation of PollableDataQueue when created with
    % Destination="any". A PollableDataQueue where any client/worker can
    % send or poll.

    % Copyright 2024 The MathWorks, Inc.

    properties(Dependent, SetAccess = private)
        QueueLength
        IsClosed
    end

    properties(SetAccess = immutable, GetAccess = private)
        % ID of Queue. When the queue is sent to different workers, all the
        % queues on the different workers will have the same ID.
        QueueID
    end

    properties (SetAccess = immutable, GetAccess = private)
        % Used for cleanup of undelivered messages. Each queue with the
        % same ReferenceCountedID will count as a reference, and when the
        % count reaches 0, all undelivered messages will be deleted. It is
        % therefore important that queues with the same QueueID have the
        % same ReferenceCountedID
        ReferenceCountedID
    end

    properties(Access = private, Transient)
        % The ID of this instance of the queue. When a queue is sent to a
        % worker, it will have the same QueueID, but a different
        % DestinationID
        DestinationID

        % Whether the queue is valid and can be used. For the reference
        % counting to work, a queue can only be serialized when a
        % serialization context has been set. If it is deserialized after
        % having been serialized without a context, it will be invalid.
        % A serialization context will be set for most PLR constructs, but
        % not for save/load, spmdSend/spmdReceive and valueStore set/get.
        IsValid
    end

    methods
        function obj = AnyDestinationPollableDataQueue(referenceCountedID, queueId)

            if nargin == 0
                refId = matlab.lang.internal.uuid;
                queueId = matlab.lang.internal.uuid;

                % Register reference counting destruction callback. When
                % there are no more references to the queue, undelivered
                % messages are deleted. 
                obj.ReferenceCountedID = parallel.internal.pool.ReferenceCountedID(refId, @()parallel.internal.dataqueue.DataQueueExchangeAccess.deleteAllMessages(queueId));

                obj.QueueID = queueId;
            else
                obj.ReferenceCountedID = referenceCountedID;
                obj.QueueID = queueId;
            end

            obj.DestinationID = matlab.lang.internal.uuid;

            obj.IsValid = obj.ReferenceCountedID.isValid();
        end

        function send(obj, data)
            arguments
                obj (1,1) parallel.internal.dataqueue.AnyDestinationPollableDataQueue
                data
            end

            obj.errorIfNotValid();

            parallel.internal.dataqueue.DataQueueExchangeAccess.send(obj.QueueID, data);
        end

        function [data, OK] = poll(obj, timeout)
            arguments
                obj (1,1) parallel.internal.dataqueue.AnyDestinationPollableDataQueue
                timeout (1,1) {mustBeNumeric, mustBeNonnegative} = 0
            end

            obj.errorIfNotValid();

            dataAndOk = parallel.internal.dataqueue.DataQueueExchangeAccess.poll(obj.QueueID, obj.DestinationID, timeout);
            data = dataAndOk{1};
            OK = dataAndOk{2};
        end

        function close(obj)
            obj.errorIfNotValid();
            parallel.internal.dataqueue.DataQueueExchangeAccess.close(obj.QueueID);
        end

        function c = get.IsClosed(obj)
            obj.errorIfNotValid();
            c = parallel.internal.dataqueue.DataQueueExchangeAccess.isClosed(obj.QueueID);
        end

        function l = get.QueueLength(obj)
            obj.errorIfNotValid();
            l = obj.getQueueLength();
        end

        function l = getQueueLength(obj)
            obj.errorIfNotValid();
            l = parallel.internal.dataqueue.DataQueueExchangeAccess.getQueueLength(obj.QueueID);
        end
    end

    % Available for testing
    methods(Hidden)
        function deleteAllMessages(obj)
            obj.errorIfNotValid();
            parallel.internal.dataqueue.DataQueueExchangeAccess.deleteAllMessages(obj.QueueID)
        end
    end

    methods(Access=private)
        function errorIfNotValid(obj)
            if ~obj.IsValid
                error(message('MATLAB:parallel:dataqueue:InvalidQueue'));
            end
        end
    end

    methods(Static)
        function obj = loadobj(sobj)
            if isstruct(sobj)
                obj = parallel.internal.dataqueue.AnyDestinationPollableDataQueue(sobj.ReferenceCountedQueueID, sobj.QueueID);
            else
                obj = sobj;
                obj.DestinationID = matlab.lang.internal.uuid;
                obj.IsValid = sobj.ReferenceCountedID.isValid();
            end
        end
    end
end

%PollableDataQueue class that enables sending and polling for data
%
%   parallel.pool.PollableDataQueue enables transferring data or messages
%   between workers and the client in a parallel pool, while a computation
%   is being carried out. For example, you can return intermediate values
%   from a computation to indicate its progress. When data is received, it
%   can be removed from the queue by calling the poll method.
%
%   If the queue is constructed with the name-value pair
%   Destination="creator", or no name-value pair, poll() can only be called
%   on the worker or client which created the queue. If the queue is
%   constructed with the name-value pair Destination="any", any worker or
%   client can call poll().
%
%   Use a parallel.pool.PollableDataQueue if you want to programmatically
%   drain the queue (using the poll method) when data is received from the
%   send method.
%
%   parallel.pool.PollableDataQueue methods:
%      send        - Send data between workers and the client
%      poll        - Retrieve data sent from the worker
%      close       - Close the queue
%
%   parallel.pool.PollableDataQueue properties:
%      QueueLength - Number of items currently held in the queue
%      IsClosed    - Whether the queue has been closed
%
%   See also: parallel.pool.DataQueue
classdef PollableDataQueue < handle

    % Copyright 2024-2025 The MathWorks, Inc.
    
    % Accessible for testing
    properties(Hidden, SetAccess=private)
        impl
    end

    properties ( Dependent, SetAccess = private )
        %QueueLength Number of items currently held in the queue.
        %    QueueLength is a read-only property on all types of DataQueue
        QueueLength;

        %IsClosed Whether the queue has been closed
        %    IsClosed is a read-only property on PollableDataQueue
        IsClosed;
    end

    properties (Transient, Constant, Access = private)
        Displayer = parallel.internal.dataqueue.PollableDataQueueDisplayer();
    end

    methods
        function obj = PollableDataQueue(DestinationArg)
            arguments
                DestinationArg.Destination (1,1) string {mustBeMember(DestinationArg.Destination,["any","creator"])} = "creator"
            end

            if DestinationArg.Destination == "any"
                obj.impl = parallel.internal.dataqueue.AnyDestinationPollableDataQueue();
            elseif DestinationArg.Destination == "creator"
                obj.impl = parallel.internal.dataqueue.SingleDestinationPollableDataQueue();
            end
        end

        function [data, OK] = poll(obj, timeout)
            %POLL Poll for messages or data from workers or client using a
            %data queue
            %
            % Use the poll and send methods together to poll for and send
            % messages or data between workers and the client using a data
            % queue.
            %
            % q = parallel.pool.PollableDataQueue constructs a data queue
            % and returns an object that can be used to send and poll for
            % data. send(q, V)  sends a message or data with the value V.
            % poll(q)  polls for the result sometime later and returns V as
            % the answer.
            %
            % You can only send data to the client or worker which created
            % the data queue. You can therefore only call poll on the
            % worker or client which created the data queue.
            %
            % [V, OK] = poll(q, timeout) returns data with value V, and a
            % boolean true for OK  to indicate that data has been returned.
            % If there is no data in the queue, then an empty array is
            % returned and a boolean false for OK. Poll takes an optional
            % timeout as the second parameter (in seconds). In that case,
            % the method may block for that time before returning; if any
            % data arrives in the queue during that period, that data is
            % returned.
            %
            % Example: send and poll for a message using a data queue
            %
            % q = parallel.pool.PollableDataQueue;
            % parfor i = 1
            %     send(q, i);
            % end
            % poll(q)
            % ans =
            %        1
            %
            % See also parallel.pool.DataQueue/send, parallel.pool.PollableDataQueue
            arguments
                obj (1,1) parallel.pool.PollableDataQueue
                timeout (1,1) {mustBeNumeric, mustBeNonnegative} = 0
            end

            try
                [data, OK] = obj.impl.poll(timeout);
            catch e
                throwAsCaller(e);
            end
        end

        function send(obj, data)
            % send(dataQueue, DATA)
            % This function sends DATA from the current worker to the
            % MATLAB that created the DataQueue. Some (short) time later
            % that data can be retrieved in that MATLAB using the poll
            % method.

            arguments
                obj (1,1) parallel.pool.PollableDataQueue
                data
            end

            try
                obj.impl.send(data);
            catch e
                throwAsCaller(e);
            end
        end

        function len = get.QueueLength(obj)
            try
                len = obj.impl.QueueLength;
            catch e
                throwAsCaller(e);
            end
        end

        function closed = get.IsClosed(obj)
            try
                closed = obj.impl.IsClosed;
            catch e
                throwAsCaller(e);
            end
        end

        function close(obj)
            %CLOSE Close the queue
            %
            % After a queue has been closed, no further messages can be
            % sent, and subsequent calls to send will error. Already sent
            % messages can be received, and subsequent calls to poll will return
            % empty
            arguments
                obj (1,1) parallel.pool.PollableDataQueue
            end
            
            try
                obj.impl.close();
            catch e
                throwAsCaller(e);
            end
        end

        function disp(obj)
            parallel.pool.PollableDataQueue.Displayer.doDisp(obj);
        end
    end
end
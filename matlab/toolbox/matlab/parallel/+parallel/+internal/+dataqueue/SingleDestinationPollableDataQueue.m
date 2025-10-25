classdef SingleDestinationPollableDataQueue < parallel.internal.dataqueue.AbstractDataQueue
    % Internal implementation of PollableDataQueue when created with
    % Destination="creator". A PollableDataQueue where any client/worker can
    % send, but only the creating client/worker can call poll.

    % Copyright 2024 The MathWorks, Inc.

    properties(Dependent, SetAccess=private)
        IsClosed
    end

    properties (Access = protected)
        CheckClosed = true;
    end

    methods
        function obj = SingleDestinationPollableDataQueue(varargin)
            narginchk(0, 1);
            obj@parallel.internal.dataqueue.AbstractDataQueue(varargin{:})
        end

        function [data, OK] = poll(obj, timeout)

            arguments
                obj (1,1) parallel.internal.dataqueue.SingleDestinationPollableDataQueue
                timeout (1,1) {mustBeNumeric, mustBeNonnegative} = 0
            end

            % When a DataQueue has been serialized across to a worker the
            % Queue property will be empty. So we need to guard against
            % this here.
            if ~obj.OnInstantiatingProcess
                error(message('MATLAB:parallel:dataqueue:NoQueue'));
            end

            % Now defer to the internal implementation
            [data, OK] = obj.pollImpl(timeout, true);
        end

        function send(obj, data)
            send@parallel.internal.dataqueue.AbstractDataQueue(obj, data);
        end

        function close(obj)
            obj.closeImpl();
        end

        function ic = get.IsClosed(obj)
            ic = obj.isClosedImpl();
        end
    end
    
    methods (Access = protected)
        function S = saveobj(obj)
            % NOTE: any object that wants to be saved in a special way
            % needs to implement it's own version of saveobj - we simply
            % defer to our base class implementation.
            S = saveobj@parallel.internal.dataqueue.AbstractDataQueue(obj);
        end
        
        function setShouldSignalMatlabOnDataArrival(obj)
            obj.Queue.stopNotifyingMatlabOnDataReceived();
        end
        
        function maybeDrainAndDispatchAllDataOnQueue(~)
            assert(false, 'PollableDataQueue should never have this method called');
        end
    end
end
classdef DataQueue < parallel.pool.DataQueue
    %

    % Copyright 2015-2025 The MathWorks, Inc.

    events (NotifyAccess = 'protected')
        DataReceived
    end
    
    properties ( Dependent, Access = 'private' )
        HasDataReceivedListener
    end

    properties (Dependent, SetAccess = 'private')
        IsClosed
    end
    
    properties ( Dependent )
        % The minimum notification period in milliseconds. This is the
        % period between the last notification to MATLAB and the next.
        MinNotificationPeriod
    end
    
    methods
        function obj = DataQueue(varargin)
            narginchk(0, 1);
            obj@parallel.pool.DataQueue(varargin{:})
            obj.CheckClosed = true;
        end
        
        function [data, OK] = poll(obj, timeout)
            % [DATA, OK] = poll(dataQueue, timeout)
            arguments
                obj (1,1) parallel.internal.pool.DataQueue
                timeout (1,1) {mustBeNumeric, mustBeNonnegative} = 0
            end
            
            % When a DataQueue has been serialized across to a worker the
            % Queue property will be empty. So we need to guard against
            % this here.
            if ~obj.OnInstantiatingProcess
                error(message('MATLAB:parallel:dataqueue:NoQueue'));
            end
            
            % If this queue has registered continuations then there is no
            % ability to poll the queue, since all input data will be
            % drained by the continuations.
            assert(~obj.HasAfterEachTrigger, 'parallel:internal:pool:InvalidState', 'Internal DataQueue object must either poll or use afterEach, not both');
                
            % Now defer to the internal implementation
            [data, OK] = obj.pollImpl(timeout, true);
        end
        
        function newListener = afterEach(obj, functionHandle)

            arguments
                obj (1,1) parallel.internal.pool.DataQueue
                functionHandle (1,1) function_handle
            end
            
            % Simple override that makes sure we aren't also listening for
            % pollable events - if we are then throw an error.
            assert(~obj.HasDataReceivedListener, 'parallel:internal:pool:InvalidState', 'Internal DataQueue object must either poll or use afterEach, not both');
            newListener = afterEach@parallel.pool.DataQueue(obj, functionHandle);
        end
        
        function newListener = listener(obj, varargin)
            % Overload of the listener method that allows us to discover
            % that someone has created a listener. That then allows us to
            % indicate to the java layer that we need to turn notification
            % on.
            assert(~obj.HasAfterEachTrigger, 'parallel:internal:pool:InvalidState', 'Internal DataQueue object must either poll or use afterEach, not both');
            newListener = listener@handle(obj, varargin{:});
            obj.setShouldSignalMatlabOnDataArrival();
        end

        function newListener = addlistener(obj, varargin)
            assert(~obj.HasAfterEachTrigger, 'parallel:internal:pool:InvalidState', 'Internal DataQueue object must either poll or use afterEach, not both');
            newListener = addlistener@handle(obj, varargin{:});
            obj.setShouldSignalMatlabOnDataArrival();
        end
        
        function send(obj, data)

            arguments
                obj (1,1) parallel.internal.pool.DataQueue
                data
            end

            if obj.OnInstantiatingProcess
                % Should simply add the message to our queue.
                obj.Queue.add(data, true);
                obj.Queue.triggerQueueDrainFromMatlab();
            else
                send@parallel.internal.dataqueue.AbstractDataQueue(obj, data);
            end
        end
        
        function clear(obj)
            obj.Queue.clear();
        end
        
        function [data, OK] = drain(obj, optName, optValue)
            % When a DataQueue has been serialized across to a worker the
            % Queue property will be empty. So we need to guard against
            % this here.
            if ~obj.OnInstantiatingProcess
                error(message('MATLAB:parallel:dataqueue:NoQueue'));
            end
            narginchk(1, 3);
            
            if nargin == 1
                isUniformOutputs = true;
            else
                % Convert any string inputs to character vectors
                optName = convertStringsToChars(optName);
                if nargin == 3 && isequal(optName, 'UniformOutput') && ...
                        islogical(optValue) && isscalar(optValue)
                    isUniformOutputs = optValue;
                else
                    error(message('MATLAB:parallel:dataqueue:WrongConstructorArgs'));
                end
            end

            data = obj.Queue.drain();
            data = data{1};
            OK = numel(data) > 0;
            if OK && isUniformOutputs
                data = vertcat(data{:});
            end
            if ~OK
                % If there is NOTHING to return then we should simply send
                % back an empty double array (since OK == false indicates
                % this is from a lack of data)
                if isUniformOutputs
                    data = [];
                else
                    data = {};
                end
            end
        end
        
        function OK = get.HasDataReceivedListener(obj)
            OK = event.hasListener(obj, 'DataReceived');
        end
        
        function value = get.MinNotificationPeriod(obj)
            value = obj.Queue.getMinMillisBetweenMatlabNotification();
        end
        
        function set.MinNotificationPeriod(obj, value)
            obj.Queue.setMinMillisBetweenMatlabNotification(value);
        end

        function close(obj)
            %CLOSE Close the queue
            %
            % After a queue has been closed, no further messages can be
            % sent, and subsequent calls to send will error. Already sent 
            % messages can still be received using poll.
            arguments
                obj (1,1) parallel.internal.pool.DataQueue
            end

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
            S = saveobj@parallel.pool.DataQueue(obj);
        end
        
        function setShouldSignalMatlabOnDataArrival(obj)
            if obj.HasDataReceivedListener || obj.HasAfterEachTrigger
                obj.Queue.startNotifyingMatlabOnDataReceived();
                obj.Queue.setUseWhenMatlabReady(obj.UseWhenMatlabReady);
            else
                obj.Queue.stopNotifyingMatlabOnDataReceived();
            end
        end       
        
        function maybeDrainAndDispatchAllDataOnQueue(obj)
            if obj.HasDataReceivedListener
                c = onCleanup(@() obj.postDispatchContinuations());
                obj.Dispatching = true;
                if obj.Queue.getSize() > 0
                    obj.notify('DataReceived');
                end
            else
                maybeDrainAndDispatchAllDataOnQueue@parallel.pool.DataQueue(obj);
            end
        end        
    end       
end

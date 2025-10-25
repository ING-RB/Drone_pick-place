classdef DataSink < handle
    %DATASINK Base class for a data sink.
    %
    % Data sinks are meant to be used in conjunction with data pumps. Data
    % enters a data pump (and is stored in a buffer). The pump periodically
    % sends data to the data sink. Note that a data sink may contain
    % another data pump (subsequently, data may be pipelined using
    % pumps with different characteristics).
    %
    % Notes: none
    
    % Copyright 2018 The MathWorks, Inc.
    
    properties (SetAccess = private)
        % Indicates whether the sink is already open or not (and ready to
        % receive data)
        IsOpen
        
        % The total number of elements sent to the data sink
        TotalElementsHandled (1, 1) double {mustBeNonnegative}
    end       
    
    methods
        function obj = DataSink()
            obj.IsOpen = false;
            obj.TotalElementsHandled = 0;
        end
        
        function delete(obj)
            if obj.IsOpen
                obj.close();
            end
        end
    end

    %% Operations    
    
    methods (Sealed) 
        function open(obj)
            % OPEN Reserve resources required by the sink
            if ~obj.IsOpen
                obj.openHook();
                obj.IsOpen = true;            
            end
        end
        
        function close(obj)
            % CLOSE Release resources required by the sink
            if obj.IsOpen
                obj.closeHook();
                obj.IsOpen = false;
            end
        end
        
        function handleData(obj, data)
            % HANDLEDATA: send data to the sink
            if obj.IsOpen
                obj.TotalElementsHandled = obj.TotalElementsHandled + size(data, 1);
                obj.handleDataImpl(data);
            end
        end
    end
    
    %% Implementation required
    methods (Access = protected)
        function openHook(obj) %#ok<MANU>
            % OPENHOOK Used to prepare the sink to handle data (e.g. open a
            % file, create a figure, set a hold on figure axes, store
            % handles, etc.).
        end
        
        function closeHook(obj) %#ok<MANU>
            % CLOSEHOOK Used to unreserve resources required by the data
            % sink (for instance, close file handles).
        end
        
        function handleDataImpl(obj, data) %#ok<INUSD>
            % HANDLEDATAIMPL Used to send data to the sink (e.g. plot a
            % figure, store data in a file, etc.).
        end
    end    
    
end

classdef Queue < handle
    % Interface for internal implementations of DataQueue.
    
    % Copyright 2020-2024 The MathWorks, Inc.
    
    % Common methods implemented by all Queue implementation classes
    methods (Abstract)
        % Add the given data input as a single item on the queue.
        add(obj, data);
        
        % Poll the queue for existing items. This will return a 1x2 cell
        % array {data, OK} where:
        %   - data is the returned data or [] on timeout
        %   - OK is true if and only if data is valid (I.E. no timeout)
        out = poll(obj, timeInSeconds);
        
        % Drain the queue for existing items. This will return a 1x1 cell
        % array {items} where:
        %   - items is a cell array of items {data1, data2,...}
        out = drain(obj);
        
        % Clear the queue, removing all contents
        clear(obj);
        
        % Get the number of items on the queue.
        getSize(obj);
    end
end

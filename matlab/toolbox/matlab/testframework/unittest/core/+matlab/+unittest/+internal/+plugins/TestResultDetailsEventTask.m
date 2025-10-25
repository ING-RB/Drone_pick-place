classdef TestResultDetailsEventTask < matlab.unittest.internal.plugins.DetailsTask
    
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    
    properties (SetAccess=immutable)
        EventRecord;
        DetailsLocationProvider;
        Producer;
    end
    
    methods
        function task = TestResultDetailsEventTask(eventRecord, locationProvider, producer)
            task.DetailsLocationProvider = locationProvider;
            task.EventRecord = eventRecord;
            task.Producer = producer;
        end
        
        function performTask(task)
            task.Producer.processEventRecord(task.EventRecord,...
                task.DetailsLocationProvider.DetailsStartIndex:task.DetailsLocationProvider.DetailsEndIndex);
        end
    end
end


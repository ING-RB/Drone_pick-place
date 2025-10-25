classdef TestResultDetailsReplaceTask < matlab.unittest.internal.plugins.DetailsTask
    
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    
    properties (SetAccess=immutable)
        FieldName;
        Data;
        Value;
        DetailsLocationProvider;
        DistributeLoop;
    end
    
    methods
        function task = TestResultDetailsReplaceTask(data, propertyName, value, locationProvider, distributeLoop)
            task.FieldName = propertyName;
            task.Data = data;
            task.Value = value;
            task.DetailsLocationProvider = locationProvider;
            task.DistributeLoop = distributeLoop;
        end
        
        function performTask(task)
            task.Data.replaceDetails(task);
        end
    end
end


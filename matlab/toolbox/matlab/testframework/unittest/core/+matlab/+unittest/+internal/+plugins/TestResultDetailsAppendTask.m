classdef TestResultDetailsAppendTask < matlab.unittest.internal.plugins.DetailsTask
    
    %

    % Copyright 2020 The MathWorks, Inc.
    
    properties (SetAccess=immutable)
        FieldName;
        Data;
        Value;
        DetailsLocationProvider;
        DistributeLoop;
    end
    
    methods
        function task = TestResultDetailsAppendTask(data, propertyName, value, locationProvider, distributeLoop)
            task.FieldName = propertyName;
            task.Data = data;
            task.Value = value;
            task.DetailsLocationProvider = locationProvider;
            task.DistributeLoop = distributeLoop;
        end
        
        function performTask(task)
            task.Data.appendDetails(task);
        end
    end
end


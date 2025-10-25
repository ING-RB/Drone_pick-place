classdef EventRecordProcessor < ...
        matlab.buildtool.internal.plugins.EventRecordProducer
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    properties (GetAccess = private, SetAccess = immutable)
        ProcessFcn (1,1) function_handle = @(x)[]
    end
    
    methods
        function processor = EventRecordProcessor(processFcn)
            arguments
                processFcn (1,1) function_handle
            end
            processor.ProcessFcn = processFcn;
        end
        
        function processEventRecord(producer, eventRecord)
            arguments
                producer (1,1) matlab.buildtool.internal.plugins.EventRecordProcessor
                eventRecord (1,1) matlab.buildtool.internal.eventrecords.EventRecord
            end
            producer.ProcessFcn(eventRecord);
        end
    end
end


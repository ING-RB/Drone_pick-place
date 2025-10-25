classdef EventRecordProcessor < matlab.unittest.internal.plugins.EventRecordProducer
    % This class is undocumented and may change in a future release.
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    properties(GetAccess=private,SetAccess=immutable)
        ProcessFcn (1,1) function_handle = @(x) [];
    end
    
    methods
        function processor = EventRecordProcessor(processFcn)
            processor.ProcessFcn = processFcn;
        end
    
        function processEventRecord(producer,eventRecord,~)
            producer.ProcessFcn(eventRecord);
        end
    end
end
classdef TestViewerEventRecordProcessor < matlab.unittest.internal.diagnostics.plugins.TestViewerEventRecordProducer
    % This class is undocumented and may change in a future release.
    
    % Copyright 2021-2022 The MathWorks, Inc.
    
    properties(GetAccess=private,SetAccess=immutable)
        ProcessFcn (1,1) function_handle = @(x) [];
    end
    
    methods
        function processor = TestViewerEventRecordProcessor(processFcn)
            processor.ProcessFcn = processFcn;
        end
    
        function processEventRecord(producer,eventRecord,~)
            producer.ProcessFcn(eventRecord);
        end
    end
end
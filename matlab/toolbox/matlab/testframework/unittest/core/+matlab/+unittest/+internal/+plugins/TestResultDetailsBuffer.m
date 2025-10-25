classdef TestResultDetailsBuffer < handle
    
    %
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(Hidden, Access=private)
        TaskBuffer (1,:) matlab.unittest.internal.plugins.DetailsTask;
    end
    
    methods(Hidden)
        function insert(bufferObject, task)
            bufferObject.TaskBuffer(end + 1) = task;
            bufferObject.flushIfPossible;
            task.DetailsLocationProvider.addlistener("EndIndexSet",...
                @(~,~)bufferObject.flushIfPossible);
        end
    end
    
    methods(Access=private)
        function  flushIfPossible(bufferObject)
            sizeOfBuffer = numel(bufferObject.TaskBuffer);
            for i = 1:sizeOfBuffer
                if(isempty(bufferObject.TaskBuffer(i).DetailsLocationProvider.DetailsEndIndex))
                    return;
                end
            end
            bufferObject.flush;
        end
        
        function flush(bufferObject)
            tempTaskBuffer = bufferObject.TaskBuffer;
            bufferObject.TaskBuffer = matlab.unittest.internal.plugins.DetailsTask.empty;
            for i = 1:numel(tempTaskBuffer)
                tempTaskBuffer(i).performTask;
            end
        end
    end
end
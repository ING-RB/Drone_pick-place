%SelectNonEmptyPartitionProcessor
% Data Processor that vertically concatenates the inputs.
%

%   Copyright 2017-2018 The MathWorks, Inc.

classdef SelectNonEmptyPartitionProcessor < matlab.bigdata.internal.executor.DataProcessor
    % Properties overridden in the DataProcessor interface.
    properties (SetAccess = immutable)
        NumOutputs = 1;
    end
    properties (SetAccess = private)
        IsFinished = false;
        IsMoreInputRequired;
    end
    
    properties (SetAccess = private)
        % The function handle for error handling.
        FunctionHandle;
        
        % The input buffer.
        InputBuffer;
    end
    
    methods
        function data = process(obj, isLastOfInputs, varargin)
            assert(~obj.IsFinished, ...
                'Assertion Failed: Process invoked after processor finished.');
            
            obj.InputBuffer.add(isLastOfInputs, varargin{:});
            
            obj.IsFinished = all(isLastOfInputs);
            
            if ~all(obj.InputBuffer.IsBufferInitialized)
                assert(~obj.IsFinished, ...
                    ['Invalid ' mfilename ': InputBuffer not initialized']);
                
                data = cell(0,1);
                return;
            end
            
            % Vertically concatenate the inputs. Because the data has been
            % repartitioned by matlab.bigdata.internal.lazyeval.vertcatrepartition,
            % at most one of the inputs will be non-empty per partition.
            % The InputBuffer ensures that the remaining inputs will be
            % empty with the correct type.
            data = iPreprocessData(obj.InputBuffer.getAll());
            
            try
                data = {vertcat(data{:})};
            catch err
                obj.FunctionHandle.throwAsFunction(err);
            end
            
            % Output an empty cell array if all inputs are empty
            if isempty(data)
                data = cell(0,1);
            end
        end
    end
    
    methods
        function obj = SelectNonEmptyPartitionProcessor(functionHandle, numVariables)
            % Build a processor. This is normally done on the worker by the
            % respective factory.
            import matlab.bigdata.internal.lazyeval.InputBuffer
            
            obj.IsFinished = false;
            obj.IsMoreInputRequired = true(1,numVariables);
            obj.FunctionHandle = functionHandle;
            
            isInputSinglePartition = false(1, numVariables);
            obj.InputBuffer = InputBuffer(numVariables, isInputSinglePartition);
        end
    end
end

function data = iPreprocessData(data)
% Prepare input data for vertcat operation.  This function applies a
% workaround for the following behavior of vertcat using an empty string
% array with a categorical array:
% 
% >> [string.empty(0,1); categorical(2)]
% Error using categorical/cat (line 43)
% Unable to concatenate a string array and a categorical array.
% 
% Error in categorical/vertcat (line 22)
% a = cat(1,varargin{:});

containsCat = any(cellfun(@iscategorical, data));

if ~containsCat
    % No categorical inputs
    return;
end

% Work through data inputs and replace any empty string arrays with []
for ii=1:numel(data)
    if isstring(data{ii}) && isempty(data{ii})
        data{ii} = [];
    end
end

end

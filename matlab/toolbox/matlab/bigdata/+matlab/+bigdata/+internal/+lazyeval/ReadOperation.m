%ReadOperation
% An operation that reads from a datastore.

% Copyright 2015-2022 The MathWorks, Inc.

classdef (Sealed) ReadOperation < matlab.bigdata.internal.lazyeval.Operation
    properties (SetAccess = immutable)
        % The datastore object that underpins this read operation.
        Datastore;
        
        % SelectedVariableNames with the list of variable names to read
        % from Datastore if there is optimization with subsrefTabularVar.
        % When this optimization doesn't apply, it is an empty cell.
        SelectedVariableNames;

        % RowFilter with a matlab.io.RowFilter object that selects rows to
        % filter from the datastore during read. This will only be
        % optimized when ReadTabularVarAndRowOptimizer finds valid
        % row-indexing expressions for RowFilter. If no expressions are
        % found, it is an empty cell.
        RowFilter;
    end
    
    methods
        % The main constructor.
        function obj = ReadOperation(datastore, numOutputs, selectedVariableNames, rowFilter)
            numInputs = 0;
            supportsPreview = true;
            obj = obj@matlab.bigdata.internal.lazyeval.Operation(numInputs, numOutputs, supportsPreview);
            obj.Datastore = datastore;
            if nargin > 2
                assert(isprop(datastore, 'SelectedVariableNames'), 'Datastore must have ''SelectedVariableNames'' property.');
                obj.SelectedVariableNames = selectedVariableNames;
                if nargin > 3
                    assert(isprop(datastore, 'RowFilter'), 'Datastore must have ''RowFilter'' property.');
                    obj.RowFilter = rowFilter;
                else
                    obj.RowFilter = {};
                end
            else
                obj.SelectedVariableNames = {};
                obj.RowFilter = {};
            end
        end
    end
    
    % Methods overridden in the Operation interface.
    methods
        function task = createExecutionTasks(obj, ~, ~, ~)
            import matlab.bigdata.internal.executor.ExecutionTask;
            import matlab.bigdata.internal.executor.PartitionStrategy;
            import matlab.bigdata.internal.lazyeval.ReadProcessorFactory;
            
            task = ExecutionTask.createSimpleTask([], ...
                ReadProcessorFactory(obj.Datastore, obj.SelectedVariableNames, obj.RowFilter), ...
                obj.NumOutputs, 'ExecutionPartitionStrategy', PartitionStrategy.create(obj.Datastore));
        end
    end
end

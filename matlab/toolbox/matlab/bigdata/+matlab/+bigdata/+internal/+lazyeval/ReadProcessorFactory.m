%ReadProcessorFactory
% Factory for building a ReadProcessor

%   Copyright 2018-2023 The MathWorks, Inc.

classdef (Sealed) ReadProcessorFactory < matlab.bigdata.internal.executor.DataProcessorFactory
    properties (SetAccess = immutable)
        % An empty chunk generated from the preview of the datastore. This
        % is done early both:
        %  1. To verify correct size/type of data read from partitioned
        %     datastores.
        %  2. To emit in case of empty partitioned datastore.
        EmptyChunk
        
        % The original datastore prior to partitioning. When it is a memory
        % datastore, it will only hold an empty chunk as part of the data
        % to avoid data duplication.
        OriginalDatastore (1,1)
    end
    
    methods
        function obj = ReadProcessorFactory(originalDatastore, selectedVariableNames, rowFilter)
            % Build a ReadProcessorFactory whose processors read
            % datastores on MATLAB Workers.
            %
            % Inputs:
            %  - originalDatastore is the corresponding datastore instance
            %  that this processor will read. It is used here to generate
            %  an empty chunk.
            %  - selectedVariableNames contains the selectedVariableNames
            %  to read from originalDatastore after optimizing in
            %  ReadTabularVarSubsrefOptimizer or
            %  ReadTabularVarAndRowOptimizer.
            %  - rowFilter contains a matlab.io.RowFilter object that
            %  selects rows to filter from originalDatastore after
            %  optimizing in ReadTabularVarAndRowOptimizer.
            if nargin > 1
                % Make a copy of the datastore to avoid modifications in
                % the original datastore.
                originalDatastore = copy(originalDatastore);
                if ~isempty(selectedVariableNames)
                    assert(isprop(originalDatastore, 'SelectedVariableNames'), ...
                        'Datastore must have ''SelectedVariableNames'' property.');
                    % selectedVariableNames can only contain variables that
                    % have already been selected in the originalDatastore.
                    % Reduce the set selected variables to the ones
                    % required by tall tabular variable indexing.
                    originalDatastore.SelectedVariableNames = selectedVariableNames;
                end
                if ~isempty(rowFilter)
                    assert(isprop(originalDatastore, 'RowFilter'), ...
                        'Datastore must have ''RowFilter'' property.');
                    % If the originalDatastore has already the RowFilter
                    % property set, combine the conditions with AND
                    % operator. Tall row-indexing is filtering the
                    % already-filtered data by the RowFilter property.
                    % By default, the RowFilter property is set to an
                    % unconstrained RowFilter that can't be combined with a
                    % constrained one. We can only check if that's the case
                    % by inspecting the result of constrainedVariableNames.
                    if isempty(constrainedVariableNames(originalDatastore.RowFilter))
                        originalDatastore.RowFilter = rowFilter;
                    else
                        originalDatastore.RowFilter = originalDatastore.RowFilter & rowFilter;
                    end
                end
            end
            if matlab.io.datastore.internal.shim.isUniformRead(originalDatastore)
                previewChunk = iPreview(originalDatastore);
                obj.EmptyChunk = matlab.bigdata.internal.util.indexSlices(previewChunk, []);
                if istable(previewChunk)
                    obj.EmptyChunk.Properties.RowNames = {};
                elseif istimetable(previewChunk)
                    obj.EmptyChunk.Properties.Events = [];
                end
            else
                obj.EmptyChunk = cell(0, 1);
            end
            obj.OriginalDatastore = originalDatastore;
            % When it is a prepartitionable datastore (it contains a
            % datastoreId), it will only hold an empty chunk as part of the
            % data to avoid data duplication.
            if isprop(originalDatastore, "DatastoreId")
                obj.OriginalDatastore = createEmptyDatastore(originalDatastore, obj.EmptyChunk);
            end
        end
        
        % Build the processor.
        function processor = feval(obj, partitionContext, ~)
            partitionedDatastore = partitionContext.partitionDatastore(obj.OriginalDatastore);
            import matlab.bigdata.internal.lazyeval.ReadProcessor
            processor = ReadProcessor(partitionedDatastore, obj.EmptyChunk, partitionContext);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function data = iPreview(ds)
% Call datastore/preview and ensure a debuggable stack trace if error.
try
    data = preview(ds);
catch err
    matlab.bigdata.internal.throw(err, 'IncludeCalleeStack', true);
end
end

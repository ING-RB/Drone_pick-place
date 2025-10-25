function isNumericStrategy = validatePartitionNumericStrategy(N, ii)
%VALIDATEPARTITIONNUMERICSTRATEGY Validate numeric inputs for partition method.
%
%   See also matlab.io.datastore.TabularTextDatastore/partition.

%   Copyright 2018 The MathWorks, Inc.
    isNumericStrategy = true;
    if ~ischar(N) || ~strcmpi(N, 'Files')
        if ~ischar(N) && ~isa(N, 'double')
            error(message('MATLAB:datastoreio:splittabledatastore:invalidPartitionStrategyType'));
        elseif ischar(N)
            validateattributes(N, {'char'}, {'nonempty', 'row'}, 'partition', 'PartitionStrategy');
            error(message('MATLAB:datastoreio:splittabledatastore:invalidPartitionStrategy', N(:)'));
        end
        validateattributes(N, {'double'}, {'scalar', 'positive', 'integer'}, 'partition', 'NumPartitions');
        validateattributes(ii, {'double'}, {'scalar', 'positive', 'integer'}, 'partition', 'Index');
        if ii > N
            error(message('MATLAB:datastoreio:splittabledatastore:invalidPartitionIndex', ii));
        end
        return;
    end
    isNumericStrategy = false;
end

function processor = buildUnderlyingProcessor(obj, partition, varargin)
% Build the underlying DataProcessor associated with this one builder.

%   Copyright 2023 The MathWorks, Inc.

if nargin == 2 && ~isempty(obj.OutputPartitionStrategy)
    varargin = {obj.OutputPartitionStrategy};
end
processor = feval(obj.DataProcessorFactory, partition, varargin{:});
end

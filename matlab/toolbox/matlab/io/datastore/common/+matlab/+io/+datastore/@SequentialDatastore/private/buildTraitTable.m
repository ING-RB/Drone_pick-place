function t = buildTraitTable(ds)
%
%
%

%   Copyright 2022 The MathWorks, Inc.

% Assemble the metadata for the required table.
traits = ["isPartitionable", "isShuffleable", "isSubsettable"];
variableNames = ["Index", "Underlying datastore class", traits];
variableTypes = ["double", "string", "string", "string", "string"];

% Pre-allocate the table
t = table('Size', [numel(ds.UnderlyingDatastores), numel(variableNames)], ...
    'VariableTypes', variableTypes, ...
    'VariableNames', variableNames);

% Populate each row of the table.
for index = 1:numel(ds.UnderlyingDatastores)
    underlyingDatastore = ds.UnderlyingDatastores{index};
    t{index, 1} = index;
    t{index, 2} = string(class(underlyingDatastore));
    t{index, 3} = underlyingDatastore.isPartitionable();
    t{index, 4} = underlyingDatastore.isShuffleable();
    t{index, 5} = underlyingDatastore.isSubsettable();
end
end
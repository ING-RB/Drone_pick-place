function [T, hasUnsupportedType] = makeZeroRowTable(variableNames, ...
                                                    selectedVariableNames, ...
                                                    variableTypes, ...
                                                    preserveVariableNames)
%makeZeroRowTable   returns an empty table with the correct varnames and types.
%
%   Note: if one of the input types was missing, this returns an empty double array.
%   This was done for datastore compatibility, but you may need to handle that case
%   differently (probably by erroring with an UnsupportedParquetType exception).
%
%   See also parquetread, parquetDatastore.

%   Copyright 2021 The MathWorks, Inc.

    arguments
        variableNames         (1, :) string
        selectedVariableNames (1, :) string
        variableTypes         (1, :) string
        preserveVariableNames (1, 1) logical
    end

    names = selectedVariableNames;
    sizes = [0, numel(names)];
    [~, type_indices] = intersect(variableNames, names, 'stable');
    types = variableTypes(type_indices);

    hasUnsupportedType = any(ismissing(types));
    if hasUnsupportedType
        % Return empty double array when any of the types are missing - cannot create a
        % table in that case
        T = [];
    else
        % VariableNames must be normalized to avoid an error on table
        % construction.
        names = makeUniqueValidNames(names, preserveVariableNames);

        % Generate a zero-dimensional table with the right variable names
        % and types.
        T = table('Size', sizes, 'VariableNames', names, 'VariableTypes', types);
    end
end

function names = makeUniqueValidNames(names, preserveVariableNames)
    if ~preserveVariableNames
        names = matlab.lang.makeValidName(names);
    end

    % Ensure that column names are normalized away from "Properties"
    % and ":" since they are reserved table identifiers.
    reservedTableIdentifiers = {'Properties', ':'};
    names = matlab.lang.makeUniqueStrings(names, ...
        reservedTableIdentifiers, namelengthmax);
end
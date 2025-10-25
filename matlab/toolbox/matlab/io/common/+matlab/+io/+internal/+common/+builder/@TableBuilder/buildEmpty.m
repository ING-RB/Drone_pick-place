function T = buildEmpty(obj)
%TableBuilder.buildEmpty   Construct an empty table from the current TableBuilder options.
%
%   If VariableTypes is supplied, then the generated empty table contains empty
%   data of the supplied type in each variable.

%   Copyright 2022 The MathWorks, Inc.

    N = numel(obj.VariableNames);

    % Just re-use the build() code path, but with 0x0 empty double
    % arrays
    vars = cell(1, N);

    % Use table() constructor's logic to construct 0x1 empty data of the expected
    % variable types.
    validVariableTypeIndices = find(~ismissing(obj.VariableTypes));
    types = obj.VariableTypes(validVariableTypeIndices);
    emptyT = table(Size=[0 numel(types)], VariableTypes=types);

    % Use the supplied types for variables that need strict type checking.
    for index = 1:numel(validVariableTypeIndices)
        replacementIndex = validVariableTypeIndices(index);
        vars{replacementIndex} = emptyT.(index);
    end

    T = obj.build(vars{:});
end

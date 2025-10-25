function writetable(T, filename, args)
%WRITETABLE   Write a table to a JSON file

%   Copyright 2024 The MathWorks, Inc.

% Parse and validate input arguments. Arguments come in as chars, converted
% by the main writetable.m.
    import matlab.io.json.internal.write.parseWriteTableNVPairs
    args = parseWriteTableNVPairs(args{:});

    % Validate input table and data types.
    data = cell(1, width(T));
    varNames = T.Properties.VariableNames;
    for i = 1:width(T)
        data{i} = validateVariable(T.(i), args.DateLocale, true, true);
    end

    % Handle WriteRowNames.
    if args.WriteRowNames && ~isempty(T.Properties.RowNames)
        % Convert RowNames data and pre-pend.
        varNames = [T.Properties.DimensionNames(1) varNames];
        data = [{validateVariable(T.Properties.RowNames, args.DateLocale, true, true)} data];
    end

    % Convert all the table data to a JSON NodeVector.
    nv = convertTableDataToNodeVector(data, string(varNames), height(T));

    % Write NodeVector to a file. Uses PrettyPrint, PreserveInfAndNaN
    % Encoding, and IndentText N-V pairs.
    matlab.io.json.internal.writeNodeVectorToFile(nv, filename, args);
end

function verifyIsVector(var)

    if ~(isvector(var) || isempty(var))
        error(message('MATLAB:io:xml:writetable:UnsupportedType'));
    end
end

function var = validateVariable(var, dateLocale, allowCell, allowMatrix)

    if allowMatrix
        % Convert N-D to 2-D.
        var = matlab.internal.datatypes.matricize(var, true);
    else
        verifyIsVector(var);
    end

    if isstring(var) || ischar(var) || iscellstr(var) || isduration(var) || iscategorical(var)
        var = string(var);
        return;
    elseif isdatetime(var)
        var = string(var, var.Format, dateLocale);
    elseif isnumeric(var)
        if isa(var, "uint64") || isa(var, "int64")
            return;
        else
            var = double(var);
        end
    elseif islogical(var)
        return;
    elseif allowCell && iscell(var)
        % Nested check: We only allow 1-D cells containing 1-D primitive
        % arrays. Multidim cell matrices and multidim cell elements are not
        % currently supported.
        verifyIsVector(var);
        var = cellfun(@(x) validateVariable(x, dateLocale, false, false), var, UniformOutput=false);
    elseif isa(var, "missing")
        return;
    elseif istabular(var)
        % Nested tables not supported.
        error(message('MATLAB:io:xml:writetable:NestedTable'));
    else
        error(message('MATLAB:io:xml:writetable:UnsupportedType'));
    end
end

function nvd = convertToNodeVectorData(var, n)

    import matlab.io.json.internal.NodeVectorData
    import matlab.io.json.internal.JSONNodeType
    import matlab.io.json.internal.JSONNumberType

    nvd = NodeVectorData();

    % We either have a homogenous variable or a heterogeneous cell
    % variable.
    if iscell(var)
        nvd = setIfNonEmpty(nvd, "Types", cellfunWithPreallocation(@extractTypes, var, n, JSONNodeType.Null));
        nvd = setIfNonEmpty(nvd, "NumberTypes", cellfunWithPreallocation(@extractNumberTypes, var, n, JSONNumberType.Double));
        nvd = setIfNonEmpty(nvd, "Strings", cellfunWithPreallocation(@extractStrings, var, n, string(missing)));
        nvd = setIfNonEmpty(nvd, "Doubles", cellfunWithPreallocation(@(x) extractNumeric(x, "double"), var, n, 0));
        nvd = setIfNonEmpty(nvd, "Uint64s", cellfunWithPreallocation(@(x) extractNumeric(x, "uint64"), var, n, 0x0u64));
        nvd = setIfNonEmpty(nvd, "Int64s", cellfunWithPreallocation(@(x) extractNumeric(x, "int64"), var, n, 0x0s64));
    else
        nvd = setIfNonEmpty(nvd, "Types", extractTypes(var));
        nvd = setIfNonEmpty(nvd, "NumberTypes", extractNumberTypes(var));
        nvd = setIfNonEmpty(nvd, "Strings", extractStrings(var));
        nvd = setIfNonEmpty(nvd, "Doubles", extractNumeric(var, "double"));
        nvd = setIfNonEmpty(nvd, "Uint64s", extractNumeric(var, "uint64"));
        nvd = setIfNonEmpty(nvd, "Int64s", extractNumeric(var, "int64"));
    end
end

function obj = setIfNonEmpty(obj, param, value)
    if isempty(value)
        return;
    end

    obj.(param) = value;
end

function output = cellfunWithPreallocation(func, C, N, proto)

    output = repmat(proto, N, 1);

    outputStartIndex = 1;
    for i=1:numel(C)
        slice = func(C{i});
        outputEndIndex = outputStartIndex + numel(slice) - 1;
        output(outputStartIndex:outputEndIndex) = slice;
        outputStartIndex = outputEndIndex + 1;
    end
end

function types = extractTypes(var)
    import matlab.io.json.internal.JSONNodeType

    n = numel(var);
    if isnumeric(var)
        types = repmat(JSONNodeType.Number, n, 1);
    elseif isstring(var)
        types = repmat(JSONNodeType.Null, n, 1);
        missings = ismissing(var);
        types(~missings) = JSONNodeType.String;
    elseif islogical(var)
        types = repmat(JSONNodeType.False, n, 1);
        types(var) = JSONNodeType.True;
    else
        % Only primitive type left is missing/null.
        types = repmat(JSONNodeType.Null, n, 1);
    end
end

function ntypes = extractNumberTypes(var)
    if ~isnumeric(var)
        ntypes = matlab.io.json.internal.JSONNumberType.empty(0, 1);
        return;
    end

    import matlab.io.json.internal.JSONNumberType
    n = numel(var);
    if isfloat(var)
        ntypes = repmat(JSONNumberType.Double, n, 1);
    elseif isa(var, "uint64")
        ntypes = repmat(JSONNumberType.Uint64, n, 1);
    else % int64, since other uint* and int* are handled by the float case.
        ntypes = repmat(JSONNumberType.Int64, n, 1);
    end
end

function strs = extractStrings(var)
    if isstring(var)
        % Reshape to column vector and remove missings.
        strs = reshape(var, [], 1);
        strs(ismissing(strs)) = [];
    else
        strs = string.empty(0, 1);
    end
end

function var = extractNumeric(var, type)
    if ~isa(var, type)
        var = zeros([0, 1], type);
    end
end

function topLevelNode = convertTableDataToNodeVector(data, names, numRows)
% Write to a JSON file.
    topLevelNode = matlab.io.json.internal.NodeVector();

    % Configure top-level node as a JSON array.
    import matlab.io.json.internal.JSONNodeType
    topLevelNode.Types = JSONNodeType.Array;
    topLevelNode.setNumberOfChildren(numRows);

    % Configure the row nodes.
    rowNodes = topLevelNode.Children;
    rowNodes.Types = repmat(JSONNodeType.Object, numRows, 1);
    rowNodes.Keys = names;

    % Write each variable out.
    for i = 1:numel(data)
        varName = names(i);
        varNodes = rowNodes.getChildrenAtNodeName(varName).NodeVector;
        [varNodes, varData] = handleMultiColumnVariable(varNodes, data{i});
        varData = convertToNodeVectorData(varData, numel(varNodes.Types));
        varNodes.Data = varData;
    end
end

function [nv, data] = handleMultiColumnVariable(nv, data)
    if ~iscell(data) && size(data, 2) == 1
        % Primitive column vector. No need to create nested array nodes.
        return;
    end

    import matlab.io.json.internal.JSONNodeType
    nv.Types(:) = JSONNodeType.Array;

    if iscell(data)
        % Cell case.
        % Create a nested array in the JSON file corresponding to each
        % cell in the vector.
        % TODO: Vectorize setNumberOfChildren!
        for i=0x0u64:(numel(data)-1)
            nv.subset(i).setNumberOfChildren(numel(data{i+1}));
        end
        nv = nv.Children;

    else
        % Homogeneous matrix.
        % Create a nested array in the JSON file corresponding to the width
        % of the table variable.
        nv.setNumberOfChildren(size(data, 2));
        nv = nv.Children;

        % Data is reshaped to a column vector. Transpose to ensure that the
        % rows are grouped together.
        data = reshape(data', [], 1);
    end
end

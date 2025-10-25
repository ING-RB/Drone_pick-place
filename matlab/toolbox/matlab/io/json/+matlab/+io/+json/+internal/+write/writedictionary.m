function str = writedictionary(d, filename, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    arguments
        d (1, 1) dictionary
        filename (1, 1) string
        opts
    end

    r = matlab.io.json.internal.LevelReader();

    appendDictionaryToReader(r, d, opts);

    if nargout > 0
        % Return file contents as a convenience.
        str = matlab.io.json.internal.LevelReader.writeLevelReaderToString(r, opts);
    else
        matlab.io.json.internal.LevelReader.writeLevelReaderToFile(r, filename, opts);
    end
end

% rapidjson types:
% 0 - null
% 1 - false
% 2 - true
% 3 - object
% 4 - array
% 5 - string
% 6 - number

function appendDictionaryToReader(r, d, opts)

    import matlab.io.json.internal.LevelReader.*

    % Set current type to JSON object.
    setCurrentType(r, 0x3u8);

    if ~d.isConfigured
        % Unconfigured dictionary is handled as an empty JSON object.
        return;
    end

    % Coerce keys into string.
    keys = extractKeys(d.keys);

    % Extract values.
    values = d.values;
    [valueTypes, doubles, strings, numberTypes, uint64s, int64s] = extractValues(values);

    % Set the data at the current level.
    setKeyValueData(r, keys, valueTypes, doubles, strings, numberTypes, uint64s, int64s);

    % Recurse into nested objects and arrays.
    handleNestedObjects(r, values, valueTypes, opts);
    handleNestedArrays(r, values, valueTypes, opts);
end

function appendArrayToReader(r, values, opts)

    import matlab.io.json.internal.LevelReader.*

    % Set current type to JSON array.
    setCurrentType(r, 0x4u8);

    [valueTypes, doubles, strings, numberTypes, uint64s, int64s] = extractValues(values);

    % Set the data at the current level.
    setKeyValueData(r, string.empty, valueTypes, doubles, strings, numberTypes, uint64s, int64s);

    % Recurse into nested objects and arrays.
    handleNestedObjects(r, values, valueTypes, opts);
    handleNestedArrays(r, values, valueTypes, opts);
end

function t = getType(x)

    x = convertCharsToStrings(x);

    supportedDims = isempty(x) || isscalar(x) || isvector(x);
    if ~supportedDims
        error(message("MATLAB:io:dictionary:writedictionary:UnsupportedValueDimensions"));
    end

    if ~isscalar(x) % Must be a JSON array.
        t = 0x4u8;
        return
    end

    if isnumeric(x)
        t = 0x6u8;
    elseif isstring(x)
        t = 0x5u8;
    elseif islogical(x)
        if x
            t = 0x2u8;
        else
            t = 0x1u8;
        end
    elseif ismissing(x)
        t = 0x0u8;
    elseif isa(x, "dictionary")
        t = 0x3u8;
    elseif iscell(x)
        t = 0x4u8;
    elseif isdatetime(x) || isduration(x)
        t = 0x5u8;
    else
        error(message("MATLAB:io:dictionary:writedictionary:UnsupportedValueType", class(x)));
    end
end

function keys = extractKeys(keys)

    isSupportedKeyType = isstring(keys) ...
        || isnumeric(keys) ...
        || iscellstr(keys) ...
        || isdatetime(keys) ...
        || isduration(keys) ...
        || islogical(keys);

    if ~isSupportedKeyType
        error(message("MATLAB:io:dictionary:writedictionary:UnsupportedKeyType", class(keys)));
    end

    if isstring(keys) && anymissing(keys)
        % string missing has ambiguous serialization behavior.
        error(message("MATLAB:io:dictionary:writedictionary:UnsupportedMissingStringKey"));
    end

    if isfloat(keys) || isdatetime(keys) || isduration(keys)
        % missings need to be replaced with a "NaN" string.
        missingMask = ismissing(keys);
        keys = string(keys);
        keys(missingMask) = "NaN";
    else
        keys = string(keys);
    end

    keys = string(keys);
end

function [valueTypes, doubles, strings, numberTypes, uint64s, int64s] = extractValues(values, opts)
% List value types.
    if isempty(values)
        valueTypes = uint8.empty(0, 1);
    elseif iscell(values)
        valueTypes = cellfun(@getType, values, UniformOutput=true);
    elseif isa(values, "dictionary") % Can only be a nested scalar object.
        valueTypes = 0x3u8;
        doubles = double.empty(0, 1);
        strings = string.empty(0, 1);
        numberTypes = uint8.empty(0, 1);
        uint64s = uint64.empty(0, 1);
        int64s = int64.empty(0, 1);
        return;
    else
        if islogical(values) % Needs a special case since we can't repmat the valueType for rapidjson::BooleanType
            valueTypes = repmat(getType(values), size(values));
            valueTypes(values) = 0x2u8;
            valueTypes(~values) = 0x1u8;
        else
            valueTypes = getType(values(1));
            valueTypes = repmat(valueTypes, numel(values), 1);
        end
    end

    % Get all the numbers at the current nesting level.
    numberIndices = valueTypes == 0x6u8;
    [numberTypes, doubles, uint64s, int64s] = extractNumbers(values(numberIndices));

    stringIndices = valueTypes == 0x5u8;
    [strings, stringMissingIndices] = extractStrings(values(stringIndices));
    actualMissingIndices = find(valueTypes == 0x5u8);
    actualMissingIndices = actualMissingIndices(stringMissingIndices);
    valueTypes(actualMissingIndices) = 0x0u8;
end

function numberType = getNumberType(x)

    if isfloat(x)
        numberType = 0x0u8;
    elseif isa(x, "uint64") || isa(x, "uint32") || isa(x, "uint16") || isa(x, "uint8")
        numberType = 0x1u8;
    else
        numberType = 0x2u8;
    end
end

function [numberTypes, doubles, uint64s, int64s] = extractNumbers(arr)

    arr = reshape(arr, [], 1);

    numberTypes = uint8.empty(0, 1);
    doubles = double.empty(0, 1);
    uint64s = uint64.empty(0, 1);
    int64s = int64.empty(0, 1);

    if isempty(arr)
        return;
    elseif iscell(arr)
        numberTypes = cellfun(@getNumberType, arr, UniformOutput=true);

        % use vertcat to handle the coercion.
        doubles = [doubles; arr{numberTypes == 0x0u8}];
        uint64s = [uint64s; arr{numberTypes == 0x1u8}];
        int64s = [int64s; arr{numberTypes == 0x2u8}];
    else
        % Empty numeric arrays would've already been handled as empty JSON array.
        numberType = getNumberType(arr(1));
        numberTypes = repmat(numberType, numel(arr), 1);

        if numberType == 0x0u8
            doubles = double(arr);
        elseif numberType == 0x1u8
            uint64s = uint64(arr);
        else
            int64s = int64(arr);
        end
    end
end

function [strings, missingIndices] = extractStrings(arr)

    if isempty(arr)
        strings = string.empty();
        missingIndices = [];
        return;
    end

    if iscell(arr)
        strings = cellfun(@string, arr, UniformOutput=true);
    else
        % Coerce to string.
        strings = string(arr);
    end

    missingIndices = ismissing(strings);
    strings(missingIndices) = [];
end

function handleNestedObjects(r, values, valueTypes, opts)
    import matlab.io.json.internal.LevelReader.*

    objectIndices = find(valueTypes == 0x3u8);

    for i=1:numel(objectIndices)
        cd(r, objectIndices(i));
        if isa(values, "dictionary")
            appendDictionaryToReader(r, values, opts);
        else
            appendDictionaryToReader(r, values{objectIndices(i)}, opts);
        end
        cdup(r);
    end
end

function handleNestedArrays(r, values, valueTypes, opts)
    import matlab.io.json.internal.LevelReader.*

    arrayIndices = find(valueTypes == 0x4u8);

    for i=1:numel(arrayIndices)
        cd(r, arrayIndices(i));
        appendArrayToReader(r, values{arrayIndices(i)}, opts);
        cdup(r);
    end
end

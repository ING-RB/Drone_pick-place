function obj = removeDuplicateKeys(obj)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    [~, uniqueIdx] = unique(obj.keys, "last");

    % Get a logical array, duplicate, that is "true"
    % corresponding to duplicate values in valueTypes
    uniqueLogical = zeros(size(obj.valueTypes));
    uniqueLogical(uniqueIdx) = true;
    duplicate = ~uniqueLogical;

    % Remove duplicate keys
    obj.keys(duplicate) = [];

    % Remove numeric values associated with duplicate keys
    numDuplicate = duplicate(obj.valueTypes == JSONType.Number);

    % Remove double values associated to duplicate keys
    doubleDuplicate = numDuplicate(obj.numberTypes == NumericType.Double);
    obj.doubles(doubleDuplicate) = [];

    % Remove uint64 values associated to duplicate keys
    % uint64Idx = numberTypes == 1;
    uint64Duplicate = numDuplicate(obj.numberTypes == NumericType.UInt64);
    obj.uint64s(uint64Duplicate) = [];

    % Remove int64 values associated to duplicate keys
    int64Duplicate = numDuplicate(obj.numberTypes == NumericType.Int64);
    obj.int64s(int64Duplicate) = [];

    % Remove numberTypes entries associated with duplicate keys
    obj.numberTypes(numDuplicate) = [];

    % Remove string values associated to duplicate keys
    stringDuplicate = duplicate(obj.valueTypes == JSONType.String);
    obj.strings(stringDuplicate) = [];

    % Remove valueTypes entries associated with duplicate keys
    obj.valueTypes(duplicate) = [];

    % Count how many duplicates have been deleted for each new
    % position in valueTypes
    obj.cumulativeRemoved = cumsum(duplicate);
    obj.cumulativeRemoved(duplicate) = [];

    % Update object's numValues count
    obj.numValues = obj.numValues - obj.cumulativeRemoved(end);
end

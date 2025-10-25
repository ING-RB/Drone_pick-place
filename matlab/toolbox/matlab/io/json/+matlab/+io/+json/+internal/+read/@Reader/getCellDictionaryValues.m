function values = getCellDictionaryValues(r, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    values = cell(r.numValues, 1);

    values = r.fillCellArrayWithPrimitiveTypes(values, opts);

    % Handle nested data.
    objectIdxOffset = r.cumulativeRemoved(r.valueTypes == JSONType.Object);
    objectIndices = find(r.valueTypes == JSONType.Object);
    rObjectIndices = objectIndices + objectIdxOffset;

    arrayIdxOffset = r.cumulativeRemoved(r.valueTypes == JSONType.Array);
    arrayIndices = find(r.valueTypes == JSONType.Array);
    rArrayIndices = arrayIndices + arrayIdxOffset;

    for i=1:numel(objectIndices)
        cd(r, rObjectIndices(i));
        values{objectIndices(i)} = convertReaderToDictionary(r, opts);
        cdup(r);
    end

    for i=1:numel(arrayIndices)
        cd(r, rArrayIndices(i));
        values{arrayIndices(i)} = getArrayValues(r, opts);
        cdup(r);
    end
end

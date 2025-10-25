function values = getArrayValues(r, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    if r.getCurrentType() ~= 4
        error("JSON top-level must be an array node");
    end

    values = cell(r.numValues, 1);

    values = fillCellArrayWithPrimitiveTypes(r, values, opts);

    % Handle nested data.
    objectIndices = find(r.valueTypes == JSONType.Object);
    arrayIndices = find(r.valueTypes == JSONType.Array);

    for i=1:numel(objectIndices)
        r.cd(objectIndices(i));
        values{objectIndices(i)} = convertReaderToDictionary(r, opts);
        r.cdup();
    end

    for i=1:numel(arrayIndices)
        r.cd(arrayIndices(i));
        values{arrayIndices(i)} = getArrayValues(r, opts);
        r.cdup();
    end
end

function values = convertReaderToArray(r, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    if r.getCurrentType() ~= 4
        error("Current JSON node type must be an array node");
    end

    values = cell(r.numValues, 1);

    values = r.fillCellArrayWithPrimitiveTypes(values, opts);

    % Handle nested data.
    objectIndices = find(r.valueTypes == JSONType.Object);
    arrayIndices = find(r.valueTypes == JSONType.Array);

    for i=1:numel(objectIndices)
        cd(r, objectIndices(i));
        values{objectIndices(i)} = convertReaderToDictionary(r, opts);
        cdup(r);
    end

    for i=1:numel(arrayIndices)
        r.cd(arrayIndices(i));
        values{arrayIndices(i)} = convertReaderToArray(r, opts);
        r.cdup();
    end
end

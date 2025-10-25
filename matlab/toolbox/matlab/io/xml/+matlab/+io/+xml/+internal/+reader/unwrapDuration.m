function data = unwrapDuration(data)
%unwrapDuration   Converts a matlab.io.xml.internal.reader.DurationWrapper to a duration array.

%   Copyright 2020-2023 The MathWorks, Inc.

    [rawValues, missingIndices, errorIndices] = matlab.io.struct.internal.read.extractDurationData(data);

    % duration needs to convert to seconds
    data = matlab.io.internal.builders.Builder.processTimes(rawValues, 'default', '');

    % Process fill values
    persistent fill;
    if isempty(fill)
        [fill, data] = matlab.io.internal.processRawFill(NaN, data);
    end
    data(missingIndices) = fill;
    data(errorIndices) = fill;
end

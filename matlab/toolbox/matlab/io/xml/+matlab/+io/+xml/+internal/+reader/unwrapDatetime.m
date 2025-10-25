function data = unwrapDatetime(data)
%unwrapDatetime   Converts a matlab.io.xml.internal.reader.DatetimeWrapper to a datetime array.

%   Copyright 2020-2023 The MathWorks, Inc.

    [rawValues, missingIndices, errorIndices] = matlab.io.struct.internal.read.extractDatetimeData(data);

    % has Data, and Format if being detected
    data = matlab.io.internal.builders.Builder.processDates(rawValues, rawValues.Format, '', '');

    % Process fill values
    persistent fill;
    if isempty(fill)
        [fill, data] = matlab.io.internal.processRawFill(complex(NaN, 0), data);
    end
    data(missingIndices) = fill;
    data(errorIndices) = fill;
end


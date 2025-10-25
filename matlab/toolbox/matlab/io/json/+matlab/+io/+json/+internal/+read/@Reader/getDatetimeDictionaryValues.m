function values = getDatetimeDictionaryValues(r, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    values = repmat(NaT, numel(r.valueTypes), 1);
    values(r.valueTypes == JSONType.String) = matlab.io.json.internal.read.convertStringToHomogeneousType(r.strings, opts.ValueImportOptions{"datetime"});
end

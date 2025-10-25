function values = getDurationDictionaryValues(obj, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    values = repmat(duration(missing), numel(obj.valueTypes), 1);
    values(obj.valueTypes == JSONType.String) = matlab.io.json.internal.read.convertStringToHomogeneousType(obj.strings, opts.ValueImportOptions{"duration"});
end

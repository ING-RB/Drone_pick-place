function sTypes = getStringTypes(r, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.StringType

    if isempty(r.stringTypes)
        r.stringTypes = StringType(matlab.io.json.internal.detectTimeTypes( ...
            r.strings, ...
            opts.ValueImportOptions{"datetime"}.DatetimeLocale));
    end

    sTypes = r.stringTypes;
end

function d = convertReaderToDictionary(r, opts)
%

%   Copyright 2024 The MathWorks, Inc.

    import matlab.io.json.internal.read.*

    % JSON array, null, true, false, string, number
    if r.getCurrentType() ~= JSONType.Object
        % Error if RequireTopLevelObject=true and top level object is not
        % a JSON Object
        if opts.RequireTopLevelObject
            error(message("MATLAB:io:json:common:TopLevelNodeMustBeObject", opts.Filename));
        end

        % If the top level JSON type is not an object, then return
        % a dictionary with top-level key, "Element".
        % TODO: ?
        r.keys = "Element";
    end

    % Handle values
    if r.getCurrentType() == JSONType.Array
        values = {convertReaderToArray(r, opts)};
    else % JSON object, null, true, false, string, number
        switch opts.ValueType
          case "auto"
            values = r.getAutoDictionaryValues(opts);
          case "string"
            values = r.getStringDictionaryValues();
          case "double"
            values = r.getDoubleDictionaryValues(opts);
          case "single"
            values = r.getSingleDictionaryValues(opts);
          case "int64"
            values = r.getIntegerDictionaryValues(opts, @int64);
          case "uint64"
            values = r.getIntegerDictionaryValues(opts, @uint64);
          case "int32"
            values = r.getIntegerDictionaryValues(opts, @int32);
          case "uint32"
            values = r.getIntegerDictionaryValues(opts, @uint32);
          case "int16"
            values = r.getIntegerDictionaryValues(opts, @int16);
          case "uint16"
            values = r.getIntegerDictionaryValues(opts, @uint16);
          case "int8"
            values = r.getIntegerDictionaryValues(opts, @int8);
          case "uint8"
            values = r.getIntegerDictionaryValues(opts, @uint8);
          case "logical"
            values = r.getLogicalDictionaryValues(opts);
          case "datetime"
            values = r.getDatetimeDictionaryValues(opts);
          case "duration"
            values = r.getDurationDictionaryValues(opts);
          case "missing"
            values = r.getMissingDictionaryValues(opts);
          case "cell"
            values = r.getCellDictionaryValues(opts);
        end
    end

    % If there are no keys/values, then return an unset dictionary
    if numel(r.keys) == 0
        d = dictionary();
    else
        d = dictionary(r.keys, values);
    end
end

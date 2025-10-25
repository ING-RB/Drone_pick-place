function convertData(obj)
%

%   Copyright 2024 The MathWorks, Inc.

    persistent typeToFuncDict
    typeToFuncDict = dictionary();
    typeToFuncDict = typeToFuncDict.insert('string', @obj.getValuesAsString);
    typeToFuncDict = typeToFuncDict.insert('auto', @obj.getValuesAsString);
    typeToFuncDict = typeToFuncDict.insert('char', @obj.getValuesAsString);
    typeToFuncDict = typeToFuncDict.insert('datetime', @obj.getValuesAsDatetime);
    typeToFuncDict = typeToFuncDict.insert('duration', @obj.getValuesAsDuration);
    typeToFuncDict = typeToFuncDict.insert('double', @obj.getValuesAsDouble);
    typeToFuncDict = typeToFuncDict.insert('int8', @(varOpts)obj.getValuesAsInt(varOpts, @int8));
    typeToFuncDict = typeToFuncDict.insert('uint8', @(varOpts)obj.getValuesAsInt(varOpts, @uint8));
    typeToFuncDict = typeToFuncDict.insert('int16', @(varOpts)obj.getValuesAsInt(varOpts, @int16));
    typeToFuncDict = typeToFuncDict.insert('uint16', @(varOpts)obj.getValuesAsInt(varOpts, @uint16));
    typeToFuncDict = typeToFuncDict.insert('int32', @(varOpts)obj.getValuesAsInt(varOpts, @int32));
    typeToFuncDict = typeToFuncDict.insert('uint32', @(varOpts)obj.getValuesAsInt(varOpts, @uint32));
    typeToFuncDict = typeToFuncDict.insert('int64', @(varOpts)obj.getValuesAsInt(varOpts, @int64));
    typeToFuncDict = typeToFuncDict.insert('uint64', @(varOpts)obj.getValuesAsInt(varOpts, @uint64));
    typeToFuncDict = typeToFuncDict.insert('logical', @obj.getValuesAsLogical);
    typeToFuncDict = typeToFuncDict.insert('single', @obj.getValuesAsSingle);
    typeToFuncDict = typeToFuncDict.insert('missing', @obj.getValuesAsMissing);

    % TODO: handle case insensitivity

    % Get type from varOpts
    type = obj.varOpts.Type;

    % Get conversion function from dictionary
    % TODO: error if conversion not found, or default, return error info as
    %       a second return arg
    conversionFunction = typeToFuncDict(type);

    % Call conversion function
    obj.convertedData = conversionFunction(obj.varOpts);
    obj.erroredConversions = false(obj.numValues, 1);
end

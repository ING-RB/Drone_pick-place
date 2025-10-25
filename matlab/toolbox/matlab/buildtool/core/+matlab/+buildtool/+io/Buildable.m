classdef (Hidden, Abstract) Buildable < matlab.mixin.Heterogeneous
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2022-2023 The MathWorks, Inc.

    properties (Hidden, SetAccess = { ...
            ?matlab.buildtool.io.Buildable, ...
            ?matlab.buildtool.internal.TaskAttributable})
        BuildingTask (1,1) string
    end

    methods (Hidden, Static, Sealed, Access = protected)
        function convertedObject = convertObject(domClass, objectToConvert)
            if meta.class.fromName(domClass) <= ?matlab.buildtool.io.FileCollection && isText(objectToConvert)
                convertedObject = matlab.buildtool.io.FileCollection.fromPaths(objectToConvert);
                emptyConstructor = str2func(domClass + ".empty");
                convertedObject = [emptyConstructor() convertedObject];
                return;
            end

            try
                constructor = str2func(domClass);
                convertedObject = constructor(objectToConvert);
            catch x
                exception = MException(message("MATLAB:buildtool:Buildable:UnableToConvert", class(objectToConvert), domClass));
                exception = exception.addCause(x);
                throw(exception);
            end
        end
    end
end

function tf = isText(text)
tf = isstring(convertCharsToStrings(text));
end

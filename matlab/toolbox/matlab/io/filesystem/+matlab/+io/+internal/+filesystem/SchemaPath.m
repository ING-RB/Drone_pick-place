classdef SchemaPath < matlab.io.internal.filesystem.Path
%SCHEMAPATH Path object with access to name, parent, extension - path must 
%           contain an acceptable schema

%   Copyright 2023 The MathWorks, Inc.

    methods
        function obj = SchemaPath(pathStr)
            repeatedTypes = repmat("schema", size(pathStr, 1) * size(pathStr, 2), 1);
            obj = obj@matlab.io.internal.filesystem.Path(pathStr, Type = repeatedTypes);
        end
    end
end

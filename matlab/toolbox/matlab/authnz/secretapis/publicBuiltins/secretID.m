classdef (Sealed = true) secretID < matlab.mixin.CustomDisplay & ...
                                      matlab.mixin.CustomCompactDisplayProvider

    properties (SetAccess = private, GetAccess = public)
        Name (1,1) string {mustBeTextScalar}
    end

    methods (Access = public)
        function obj = secretID(name)
            validateattributes(name, ["string", "char"], ["scalartext", "nonempty"]);
            obj.Name = name;
        end

        function val = getSecret(obj)
            val = getSecret(obj.Name);
        end
    end

    methods
        function name = get.Name(obj)
            name = obj.Name;
        end

        function displayRep = compactRepresentationForSingleLine(obj,displayConfiguration,width)
            [displayRep, ~] = widthConstrainedDataRepresentation(obj,displayConfiguration,width, ...
                               StringArray=getStringArray(obj), Annotation="secretID");
        end

        function displayRep = compactRepresentationForColumn(obj, displayConfiguration, width)
            [displayRep, ~] = widthConstrainedDataRepresentation(obj,displayConfiguration,width, ...
                              StringArray=getStringArray(obj), Annotation=annotation(obj));
        end

        function res = annotation(obj)
            numRows = size(obj, 1);
            res = strings(numRows, 1);
            res(:) = "secretID";
        end
    end

    methods (Access = protected)

        function arr = getStringArray(obj)
            arr = strings(size(obj));
            for idx = 1: numel(obj)
                arr(idx) = obj(idx).Name;
            end
        end
    end
end

%   Copyright 2024 The MathWorks, Inc.
classdef DocPageOrigin
    properties
        Type (1,1) matlab.internal.doc.url.DocPageOriginType
        Inputs
    end

    methods
        function obj = DocPageOrigin(type, inputs)
            arguments
                type (1,1) matlab.internal.doc.url.DocPageOriginType = "Unknown"
                inputs string = string.empty
            end
            obj.Type = type;
            obj.Inputs = inputs;
        end
    end
end
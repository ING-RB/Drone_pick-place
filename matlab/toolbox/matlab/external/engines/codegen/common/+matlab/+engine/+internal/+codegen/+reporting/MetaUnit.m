classdef MetaUnit
    %MetaUnit Represents a MATLAB programing field which may have type or
    %size meta data that would be useful to a strongly-typed interface

    properties
        Type (1,1) matlab.engine.internal.codegen.reporting.MetaFieldType
        StructureName (1,1) string  % name of structure which contians the field
        Name (1,1) string  % name of the field
        HasSize (1,1) logical
        HasType (1,1) logical
    end

    methods
        function obj = MetaUnit(type, structname, name, hasSize, hasType)
            arguments
                type (1,1) matlab.engine.internal.codegen.reporting.MetaFieldType
                structname (1,1) string
                name (1,1) string
                hasSize (1,1) logical
                hasType (1,1) logical
            end

            obj.Type = type;
            obj.StructureName = structname;
            obj.Name = name;
            obj.HasSize = hasSize;
            obj.HasType = hasType;

            if(hasType && hasSize) % type or size should be missing
                messageObj = message("MATLAB:engine_codegen:InternalLogicError");
                error(messageObj);
            end
        end
    end

end


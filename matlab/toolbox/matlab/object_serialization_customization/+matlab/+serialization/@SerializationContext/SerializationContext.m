classdef SerializationContext
    %SERIALIZATIONCONTEXT Describe use case for customization while serializing data
    %   SerializationContext is a class that informs the class author about which use
    %   case(s) they are customizing their data under. The class author can decide
    %   to customize their data differently based on this information.
    %   
    %   Class authors can implement "modifyOutgoingSerializationContent" and use
    %   SerializationContext to perform customization based on the given use case.
    %   
    %   SerializationContext contains the property "CustomizeForReadability," which describes
    %   whether the serialized representation of the object will be used by
    %   external users or not. For example, if a class has a
    %   non-user-friendly internal representation, a class author may want
    %   to create a user-friendly representation for when the data is
    %   serialized to external (i.e., client-visible) locations.

%   Copyright 2023 The MathWorks, Inc.

    properties
        CustomizeForReadability(1,1) logical;
    end

    methods (Access=private)
        function obj = SerializationContext
            obj.CustomizeForReadability = false;
        end
    end
end

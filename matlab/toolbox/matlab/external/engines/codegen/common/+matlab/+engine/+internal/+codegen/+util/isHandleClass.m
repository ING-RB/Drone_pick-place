function result = isHandleClass(metaClass)
    %isHandle Determines if a class is a handle class.
    %A meta.class object input can be obtained with meta.class.fromName()
    arguments (Input)
        metaClass (1,1) meta.class
    end
    arguments (Output)
        result (1,1) logical
    end
    
    % Traverse superclasses
    [fromNodes, toNodes] = matlab.engine.internal.codegen.util.traverseSupers(metaClass);

    % Look for "handle" in nodes the class inherits from
    handleSearch =  sum(fromNodes == "handle") > 0;

    % Also check self name for "handle"
    selfIsHandle = string(metaClass.Name) == "handle";

    result = handleSearch || selfIsHandle;

end


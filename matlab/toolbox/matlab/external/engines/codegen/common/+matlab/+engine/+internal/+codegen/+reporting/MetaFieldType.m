classdef MetaFieldType
    %MetaFieldType A MATLAB programing unit which may have size or type
    %meta-data associated with it that is useful to the strongly-typed
    %interface

    enumeration
        Property
        MethodInputArgument
        MethodOutputArgument
        FunctionInputArgument
        FunctionOutputArgument
    end

end
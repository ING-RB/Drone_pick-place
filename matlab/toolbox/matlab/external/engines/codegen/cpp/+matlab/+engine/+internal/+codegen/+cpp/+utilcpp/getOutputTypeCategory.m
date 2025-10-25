function outCategory = getOutputTypeCategory(outputItem)
    %getOutputTypeCategory Gets the output type category of the argument or
    %property as it maps from MATLAB to C++. The type category can be used
    %to process the MDA output from MATLAB appropriately.
    
    %   Copyright 2022 The MathWorks, Inc.

    arguments (Input)
        outputItem (1,1) matlab.engine.internal.codegen.ArgumentTpl % ArgumentTpl (or PropertyTpl in future)
    end
    arguments (Output)
        outCategory (1,1) matlab.engine.internal.codegen.cpp.utilcpp.OutputTypeCategory
    end

    import matlab.engine.internal.codegen.cpp.*
    import matlab.engine.internal.codegen.*
    
    outCategory = utilcpp.OutputTypeCategory.empty(); % category will be an empty object until category is determined

    % Get size and C++ type data
    sizeType = outputItem.MATLABArrayInfo.SizeClassification;
    
    tc = matlab.engine.internal.codegen.cpp.CPPTypeConverter;
    [cppType, matchedTable] = tc.convertArg(outputItem); % Note: if there is a table lookup match, then the cppType will be a simple native type in C++ (e.g numeric or string)

    % Check if metadata is missing
    if ~outputItem.MATLABArrayInfo.HasSize || ~outputItem.MATLABArrayInfo.HasType
        outCategory = utilcpp.OutputTypeCategory.MissingMeta;

    % Check if size is higher dimensional
    elseif sizeType == DimType.MultiDim
        outCategory = utilcpp.OutputTypeCategory.MultiDim;
        
    % Check for simple non-complex types (e.g. double, char)
    elseif matchedTable==true && ~cppType.contains("std::complex")
        if sizeType == DimType.Scalar
            outCategory = utilcpp.OutputTypeCategory.SimpleScalar;
        elseif sizeType == DimType.Vector && outputItem.MATLABArrayInfo.ClassName == "char"
            outCategory = utilcpp.OutputTypeCategory.SimpleScalar; % if char vector, treat as string scalar (special case)
        elseif sizeType == DimType.Vector
            outCategory = utilcpp.OutputTypeCategory.SimpleVector;
        end

    % Check for simple complex types (e.g. complex double)
    elseif matchedTable==true && cppType.contains("std::complex")
        % else check for C++ native types that are complex

        if sizeType == DimType.Scalar
            outCategory = utilcpp.OutputTypeCategory.SimpleComplexScalar;
        elseif sizeType == DimType.Vector
            outCategory = utilcpp.OutputTypeCategory.SimpleComplexVector;
        end

    % Check for generatable enums
    elseif outputItem.MATLABArrayInfo.IsEnum && outputItem.MATLABArrayInfo.IsExternal
        if sizeType == DimType.Scalar
            outCategory = utilcpp.OutputTypeCategory.GenEnumScalar;
        elseif sizeType == DimType.Vector
            outCategory = utilcpp.OutputTypeCategory.GenEnumVector;
        end

    % Check for generatable class
    elseif outputItem.MATLABArrayInfo.IsExternal
        if sizeType == DimType.Scalar
            outCategory = utilcpp.OutputTypeCategory.GenExternalClassScalar;
        elseif sizeType == DimType.Vector
            outCategory = utilcpp.OutputTypeCategory.GenExternalClassVector;
        end
    end
    
end


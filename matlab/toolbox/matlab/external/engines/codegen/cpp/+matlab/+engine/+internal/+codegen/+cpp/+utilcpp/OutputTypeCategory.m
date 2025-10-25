classdef OutputTypeCategory
    %OutputTypeCategory The type category as mapped from MATLAB to C++
    %(e.g SimpleScalar ). Based on the category, we can process feval output
    %from MATLAB appropriately
    
    %   Copyright 2022 The MathWorks, Inc.
    
    enumeration
        SimpleScalar            % maps to scalar simple C++ native type (e.g. double, single, int8, string)
        SimpleVector            % maps to vector of simple C++ native type
        SimpleComplexScalar     % maps to complex scalar simple C++ native type
        SimpleComplexVector     % maps to vector of complex simple C++ native type
        MultiDim                % maps to N-Dimensional array (dim > 2) stored in matlab::data::Array
        GenEnumScalar           % maps to a enum class which should also be generated
        GenEnumVector
        GenExternalClassScalar  % maps to a user-authored class which should also be generated
        GenExternalClassVector
        MissingMeta             % maps to a generic matlab::data::Array because type or size metadata is missing
        MWAuthoredClass         % maps to a generic matlab::data::Array because generating MathWorks-authored classes is not yet supported
    end

end


%CODER.BLASCallback An abstract class for BLAS callback

%   Copyright 2018-2019 The MathWorks, Inc.

classdef (Abstract) BLASCallback
    methods (Static, Abstract)
         headerName = getHeaderFilename()
         updateBuildInfo(aBuildInfo, context)
         intTypeName = getBLASIntTypeName()
    end
    methods (Static)
        function doubleComplexTypeName = getBLASDoubleComplexTypeName()
        % Controls the type used for double complex types in the generated code. The default here is
        % sufficient for BLAS libraries which take double*, and void* for complex array
        % arguments. Override this if your BLAS library uses a different name.
            doubleComplexTypeName = 'double';
        end

        function singleComplexTypeName = getBLASSingleComplexTypeName()
        % Controls the type used for single complex types in the generated code. The default here is
        % sufficient for BLAS libraries which take float*, and void* for complex array
        % arguments. Override this if your BLAS library uses a different name.
            singleComplexTypeName = 'float';
        end

        function p = useEnumNameRatherThanTypedef()
        % Override this to return true if types for enumerations should include the 'enum' keyword. For
        % example, if this function returns false, the type name:
        %
        %   CBLAS_ORDER
        %
        % will be used. If this function returns true, then the name:
        %
        %   enum CBLAS_ORDER
        %
        % will be used.
            p = false;
        end
    end
end

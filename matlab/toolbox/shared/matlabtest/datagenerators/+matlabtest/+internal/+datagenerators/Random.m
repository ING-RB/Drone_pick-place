classdef (HandleCompatible) Random < matlabtest.internal.datagenerators.DataGenerator
    
   
    methods (Abstract)
        returnBoolean = isSupportedBy(obj,aDataTypeSpecification)
    end

    methods(Abstract,Access=protected)
        dataValues = generateRandomValues(obj,aDataTypeSpecification)
    end

    methods

        function dataValues = generateValues(obj,aDataTypeSpecification)
            arguments
                obj
                aDataTypeSpecification matlabtest.internal.dataspecifications.DataTypeSpecification ... 
                                       {mustBeNonempty} 
            end
            dataValues = obj.generateRandomValues(aDataTypeSpecification);
        end
    end
end
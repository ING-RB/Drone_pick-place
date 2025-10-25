classdef (HandleCompatible) RandomNumeric < matlabtest.internal.datagenerators.Random
    %

    %   Copyright 2023 The MathWorks, Inc.
    properties(Abstract)
        LowerLimit {mustBeNumeric, mustBeFinite}
        UpperLimit {mustBeNumeric, mustBeFinite}
    end

     methods (Access = protected, Abstract)
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
            if aDataTypeSpecification.IsComplex
                imaginaryValues = obj.generateRandomValues(aDataTypeSpecification);
                dataValues = complex(dataValues,imaginaryValues);
            end
        end
    end
end

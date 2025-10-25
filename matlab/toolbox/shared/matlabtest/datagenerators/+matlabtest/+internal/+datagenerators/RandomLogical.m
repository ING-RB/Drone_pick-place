classdef RandomLogical < matlabtest.internal.datagenerators.Random

    %

    %   Copyright 2023 The MathWorks, Inc.
    methods

        function returnBoolean = isSupportedBy(~,aDataTypeSpecification)
            arguments
                ~
                aDataTypeSpecification...
                    matlabtest.internal.dataspecifications.DataTypeSpecification...
                    {mustBeNonempty}
            end

            supportedTypes = {'logical','Logical','boolean','Boolean'};
            returnBoolean = ismember(aDataTypeSpecification.Type, supportedTypes);
        end
    end

    methods(Access=protected)
        function dataValues = generateRandomValues(~, aDataTypeSpecification)
            dataValues = logical(randi([0 1],aDataTypeSpecification.Dimensions,...
                'uint8'));
        end
    end
end

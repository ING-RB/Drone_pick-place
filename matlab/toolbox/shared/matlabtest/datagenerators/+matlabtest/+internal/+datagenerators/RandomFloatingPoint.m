classdef RandomFloatingPoint < matlabtest.internal.datagenerators.RandomNumeric
%

%   Copyright 2023 The MathWorks, Inc.

    properties
        LowerLimit
        UpperLimit
    end
    methods
        function obj = RandomFloatingPoint(options)
            arguments
                % The default UpperLimit and LowerLimit values are carefully
                % chosen to get better distribution. With larger limits,
                % generated data is more concentrated around limits  
                options.UpperLimit {mustBeFinite} = 1e4 
                options.LowerLimit {mustBeFinite} = -1e4
            end

            if options.LowerLimit > options.UpperLimit
                throw(MException(message(...
                   'MATLABTest:matlabtest_test_creation:DataGeneration:LimitMismatch')));
            end
            obj.LowerLimit = options.LowerLimit;
            obj.UpperLimit = options.UpperLimit;
        end

        function returnBoolean = isSupportedBy(~,aDataTypeSpecification)
            arguments
                ~
                aDataTypeSpecification matlabtest.internal.dataspecifications.DataTypeSpecification {mustBeNonempty}
            end

            supportedTypes = {'double','single'};
            returnBoolean = ismember(aDataTypeSpecification.Type, supportedTypes);
        end
    end
    methods (Access = protected)

        function dataValues = generateRandomValues(obj,aDataTypeSpecification)

            dataValues = obj.LowerLimit + ...
                (obj.UpperLimit - obj.LowerLimit).*rand(aDataTypeSpecification.Dimensions,...
                aDataTypeSpecification.Type);

            if any(isinf(dataValues))
                throw(MException(message(...
                    'MATLABTest:matlabtest_test_creation:DataGeneration:ContainingInf')));
            end
        end
 end

end

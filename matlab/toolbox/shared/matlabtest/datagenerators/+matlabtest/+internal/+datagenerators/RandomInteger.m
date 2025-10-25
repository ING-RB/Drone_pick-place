classdef RandomInteger < matlabtest.internal.datagenerators.RandomNumeric
%

%   Copyright 2023 The MathWorks, Inc.

    properties
       LowerLimit
       UpperLimit
   end
   methods
       function obj = RandomInteger(options)
           arguments
               options.UpperLimit {mustBeInteger} = [];
               options.LowerLimit {mustBeInteger} = [];
           end

           if options.LowerLimit > options.UpperLimit
               error(message(...
                   'MATLABTest:matlabtest_test_creation:DataGeneration:LimitMismatch'));
           end
           obj.LowerLimit = options.LowerLimit;
           obj.UpperLimit = options.UpperLimit;
       end

       function returnBoolean = isSupportedBy(~,aDataTypeSpecification)
           arguments
               ~
               aDataTypeSpecification matlabtest.internal.dataspecifications.DataTypeSpecification {mustBeNonempty}
           end
          
           supportedTypes = {'int8','int16','int32','uint8','uint16','uint32','int64','uint64'};
           returnBoolean = ismember(aDataTypeSpecification.Type, supportedTypes);
       end       
   end
   methods (Access = protected)
       
       function dataValues = generateRandomValues(obj,aDataTypeSpecification)
           
           % randi does not support 'int64','uint64' yet (g867209)
           if ismember(aDataTypeSpecification.Type,{'int64','uint64'})
               obj = obj.setDataLimitsFor64bitInteger(aDataTypeSpecification);
               dataValues = generateRandomValuesFor64bitInteger(obj,...
                   aDataTypeSpecification.Dimensions,aDataTypeSpecification.Type);
           else
               obj = obj.setDataLimits(aDataTypeSpecification);
               dataValues = randi([obj.LowerLimit obj.UpperLimit],...
                   aDataTypeSpecification.Dimensions,aDataTypeSpecification.Type);
           end
       end

       function obj = setDataLimits(obj,aDataTypeSpecification)
           obj.LowerLimit = obj.getMinLimit(aDataTypeSpecification.Type);
           obj.UpperLimit = obj.getMaxLimit(aDataTypeSpecification.Type);
       end
       
       function obj = setDataLimitsFor64bitInteger(obj,~)
           obj.LowerLimit = obj.getMinLimit('int32');
           obj.UpperLimit = obj.getMaxLimit('int32');
       end

       function minLimit = getMinLimit(obj, aDataType)
           dataTypeMin = intmin(aDataType);

           if isempty(obj.LowerLimit)
               minLimit = dataTypeMin;
           else
               minLimit = max(cast(obj.LowerLimit,aDataType), dataTypeMin);
           end
       end

       function maxLimit = getMaxLimit(obj, aDataType)
           dataTypeMax = intmax(aDataType);
           if isempty(obj.UpperLimit)
               maxLimit = dataTypeMax;
           else
               maxLimit = min(cast(obj.UpperLimit,aDataType), dataTypeMax);
           end
       end

       function dataValues = generateRandomValuesFor64bitInteger(obj,dimensions,dataType)
           dataValues = cast(randi([obj.LowerLimit obj.UpperLimit],dimensions,'int32'),dataType);
       end
       
   end
end

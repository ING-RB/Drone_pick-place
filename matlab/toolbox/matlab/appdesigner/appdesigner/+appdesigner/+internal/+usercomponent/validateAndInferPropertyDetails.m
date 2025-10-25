function [className, defaultValue, inferredDefaultValue, inferredRenderer] = validateAndInferPropertyDetails(propInfo)
% VALIDATEANDINFERPROPERTYDETAILS Validates the default value for and
% derives the datatype & default value from the infromation given by the
% user.
%
%   propInfo is a struct with the fields:
%       propInfo.ClassName - the class/data type for the property
%       propInfo.DefaultValue - the default value
%       propInfo.Name - the property name
%       propInfo.Size - {1x2} cell array of the property size
%       propInfo.ValidationFunctions - cell array of validation
%           function strings: {'mustBeLessThan(propName, 10)'}

% Copyright 2021 The MathWorks, Inc.

try
   appdesigner.internal.usercomponent.validatePropertyValue(propInfo);
catch exception
    throw(exception);
end

[className, defaultValue, inferredDefaultValue, inferredRenderer] = appdesigner.internal.usercomponent.UserComponentPropertyUtils.getInferredPropertyDetails(propInfo.DefaultValue, propInfo.ClassName);
end

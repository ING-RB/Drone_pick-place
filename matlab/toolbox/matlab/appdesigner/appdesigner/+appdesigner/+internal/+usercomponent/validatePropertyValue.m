function validatePropertyValue(propInfo)
    % VALIDATEPROPERTYVALIDATION Validates the default value for a property
    %   In the declaration of MATLAB object properties, the size, class
    %   name, validation functions, and default value can be specified:
    %
    %   properties
    %       Prop (dim1,dim2,...) ClassName {fcn1,fcn2...} = defaultValue
    %   end
    %
    %   This function validates the default value according to the size,
    %   class name, and validation functions specified.
    %
    %   propInfo is a struct with the fields:
    %       propInfo.ClassName - the class/data type for the property
    %       propInfo.DefaultValue - the default value
    %       propInfo.Name - the property name
    %       propInfo.Size - {1x2} cell array of the property size
    %       propInfo.ValidationFunctions - cell array of validation
    %           function strings: {'mustBeLessThan(propName, 10)'}

    % Copyright 2021 The MathWorks, Inc.

    [className, value, name, propertySize, validationFunctions] = deal(...
        propInfo.ClassName, propInfo.DefaultValue, propInfo.Name,...
        propInfo.Size, propInfo.ValidationFunctions);

    if isempty(value)
        % It is valid if the there is no default value
        return
    end

    if ischar(value)
        value = eval(value);
    end

    if isempty(className)
        className = class(value);
    end
    
    for i=1:numel(propertySize)
        if ~strcmp(propertySize(i), ':')
            propertySize{i} = str2double(propertySize{i}); 
        end
    end

    if ~isempty(validationFunctions)
        validationFunctions = cellfun(@(c)str2func(sprintf('@(%s)%s',name, c)),...
            validationFunctions,'UniformOutput',false);
    end

    validation = struct;
    validation.dimensions = propertySize';
    validation.class = className;
    validation.validators = validationFunctions';

    H = matlab.internal.validation.ValidationHelper(validation);

    % Validation order for property value (see
    % https://www.mathworks.com/help/matlab/matlab_oop/validate-property-values.html)
    % 1) Class
    % 2) Size
    % 3) Validation functions from left to right

    [value, ex] = validateClass(H, value);
    if ~isempty(ex)
        throwAsCaller(ex);
    end

    [value, ex] = validateSize(H, value);
    if ~isempty(ex)
        throwAsCaller(ex);
    end

    ex = validateUsingValidationFunctions(H, value);
    if ~isempty(ex)
        throwAsCaller(ex);
    end
end

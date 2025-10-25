function value = validateValue(validation, value)
    arguments
        validation (1,1) {mustBeA(validation, ["matlab.metadata.Validation"])}
        value
    end

%Convert and validate value using meta.Validation.

% Copyright 2016-2024 The MathWorks, Inc.

    if isempty(validation.Class)
        className = validation.ClassName;
        % handle cases like: Prop NonExistingClass
        if ~isempty(className)
            if exist(className, 'class') == 8
                msg = message('MATLAB:type:UnsupportedClassForValidation', className);
                throwAsCaller(MException('MATLAB:class:InvalidType', msg.getString));
            else
                msg = message('MATLAB:type:NotAClass', className);
                throwAsCaller(MException('MATLAB:class:InvalidType', msg.getString));
            end
        end
    end

    H = matlab.internal.validation.ValidationHelper(validation);

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

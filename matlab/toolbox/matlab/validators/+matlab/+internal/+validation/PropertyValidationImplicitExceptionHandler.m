classdef PropertyValidationImplicitExceptionHandler ...
        < matlab.internal.validation.PropertyValidationExceptionHandlerBase
%

%   Copyright 2019-2023 The MathWorks, Inc.
    
    methods
        function ex = propertyValidatorException(obj, ex, className, caller, propName, usageError)
            if usageError
                msgID = 'MATLAB:type:ErrorValidatingImplicitDefaultValueWithPostamble';
            else
                msgID = 'MATLAB:type:ErrorValidatingImplicitDefaultValue';
            end
            
            ex = MException(ex.identifier,'%s', ...
                message(msgID, propName, ...
                obj.generateClassLink(className, caller), ex.message).getString);
        end
        
        function ex = classConstructionException(obj, className, callerContext, propName, propType)
            ex = MException('MATLAB:class:DefaultPropertyValueRequired','%s',...
                message('MATLAB:type:ErrorCoercingImplicitDefaultValue',propName, ...
                obj.generateClassLink(className, callerContext),...
                message('MATLAB:type:UnableToConstructDefaultObject',propType).getString).getString);
        end
        
        function ex = classCoercionException(obj, ex, className, propName, propType, caller, ~, ~)
            switch ex.identifier
                case 'MATLAB:class:abstract'
                    id = 'MATLAB:class:DefaultPropertyValueRequired';
                    msg = message('MATLAB:type:DefaultPropertyValueRequired',propType,propName).getString;
                case 'MATLAB:undefinedVarOrClass'
                    id = 'MATLAB:type:InvalidInputClass';
                    msg = message('MATLAB:type:UnrecognizedClass',propType).getString;
                case 'MATLAB:UnableToConvert'
                    id = 'MATLAB:class:DefaultPropertyValueRequired';
                    msg = message('MATLAB:type:UnableToConstructDefaultObject',propType).getString;
                case 'MATLAB:invalidConversion'
                    id = 'MATLAB:class:DefaultPropertyValueRequired';
                    msg = message('MATLAB:type:UnableToConstructDefaultObject',propType).getString;
                case 'MATLAB:TooManyOutputs'
                    id = 'MATLAB:class:DefaultPropertyValueRequired';
                    msg = message('MATLAB:type:UnableToConstructDefaultObject',propType).getString;
                case 'MATLAB:minrhs'
                    id = 'MATLAB:class:DefaultPropertyValueRequired';
                    msg = message('MATLAB:type:UnableToConstructDefaultObject',propType).getString;
                case 'MATLAB:TooManyInputs'
                    id = 'MATLAB:class:DefaultPropertyValueRequired';
                    msg = message('MATLAB:type:UnableToConstructDefaultObject',propType).getString;
                otherwise
                    id = ex.identifier;
                    msg = ex.message;
            end
            ex = MException(id,'%s',...
                message('MATLAB:type:ErrorCoercingImplicitDefaultValue',propName,...
                obj.generateClassLink(className, caller),msg).getString);
        end
        
        function ex = sizeCoercionException(obj, ~, className, caller, propName, dimStr)
            [kind, ~] = obj.parseTargetSize(dimStr);

            switch kind
                case 1
                    msg = message('MATLAB:type:PropInitialDimMismatchScalar');
                case 2
                    msg = message('MATLAB:type:PropInitialDimMismatchScalarCompat',dimStr);
                otherwise
                    msg = message('MATLAB:type:PropInitialDimMismatchNonScalar',dimStr);
            end
            
            ex = MException('MATLAB:class:DefaultPropertyValueRequired','%s',...
                message('MATLAB:type:ErrorCoercingImplicitDefaultValue',propName,...
                obj.generateClassLink(className, caller), msg.getString).getString);
        end
    end
end

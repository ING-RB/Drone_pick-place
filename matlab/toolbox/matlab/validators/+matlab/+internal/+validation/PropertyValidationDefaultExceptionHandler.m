classdef PropertyValidationDefaultExceptionHandler ...
    < matlab.internal.validation.PropertyValidationExceptionHandlerBase
%

%   Copyright 2019-2023 The MathWorks, Inc.

    methods
        function ex = propertyValidatorException(obj, ex, className, caller, propName, usageError)
            if usageError
                msgID = 'MATLAB:type:IllegalExplicitDefaultValueWithPostamble';
            else
                msgID = 'MATLAB:type:IllegalExplicitDefaultValue';
            end
            
            ex = MException(ex.identifier,'%s', ...
                message(msgID, propName, ...
                obj.generateClassLink(className, caller), ex.message).getString);
        end
        
        function ex = classConstructionException(obj, className, caller, propName, propType)
            ex = MException('MATLAB:type:InvalidInputClass','%s', ...
                message('MATLAB:type:IllegalExplicitDefaultValue',propName, ...
                obj.generateClassLink(className, caller), ...
                message('MATLAB:type:UnableToConstructDefaultObject',propType).getString).getString);
        end
        
        function ex = classCoercionException(obj, ex, className, propName, propType, caller, functionHandleToPropType, valueBeingValidated)
            import matlab.internal.validation.Exception
            switch ex.identifier
                case 'MATLAB:UnableToConvert'
                    id = 'MATLAB:validation:UnableToConvert';
                    msg = Exception.getClassConversionMessage(propType, caller, functionHandleToPropType, valueBeingValidated);
                case 'MATLAB:class:CannotConvert'
                    id = 'MATLAB:validation:UnableToConvert';
                    msg = Exception.getClassConversionMessage(propType, caller, functionHandleToPropType, valueBeingValidated);
                case 'MATLAB:invalidConversion'
                    id = 'MATLAB:validation:UnableToConvert';
                    msg = Exception.getClassConversionMessage(propType, caller, functionHandleToPropType, valueBeingValidated);
                case 'MATLAB:TooManyOutputs'
                    id = 'MATLAB:validation:UnableToConvert';
                    msg = Exception.getClassConversionMessage(propType, caller, functionHandleToPropType, valueBeingValidated);
                case 'MATLAB:minrhs'
                    id = 'MATLAB:validation:UnableToConvert';
                    msg = Exception.getClassConversionMessage(propType, caller, functionHandleToPropType, valueBeingValidated);
                case 'MATLAB:TooManyInputs'
                    id = 'MATLAB:validation:UnableToConvert';
                    msg = Exception.getClassConversionMessage(propType, caller, functionHandleToPropType, valueBeingValidated);
                otherwise
                    id = ex.identifier;
                    msg = ex.message;
            end
            ex = MException(id,'%s', ...
                message('MATLAB:type:IllegalExplicitDefaultValue',propName,...
                obj.generateClassLink(className, caller),msg).getString);
        end
        
        function ex = sizeCoercionException(obj, ex, className, caller, propName, dimStr)
            import matlab.internal.validation.Exception
            sizeStruct = Exception.sizeStrToStruct(dimStr);
            ex = MException('MATLAB:validation:IncompatibleSize','%s', ...
                message('MATLAB:type:IllegalExplicitDefaultValue', propName,...
                obj.generateClassLink(className, caller), Exception.getSizeSpecificMessage(ex, sizeStruct)).getString);
        end
    end
end

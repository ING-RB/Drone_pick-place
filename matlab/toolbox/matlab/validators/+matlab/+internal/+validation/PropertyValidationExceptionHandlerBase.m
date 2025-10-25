classdef PropertyValidationExceptionHandlerBase
%

%   Copyright 2019-2024 The MathWorks, Inc.
    
    methods(Abstract)
        ex = propertyValidatorException(obj, ex, className, caller, propName);
        ex = classConstructionException(obj, className, caller, propName, propType);
        ex = classCoercionException(obj, ex, className, propName, propType, caller, functionHandleToPropType);
        ex = sizeCoercionException(obj, className, caller, propName, dimStr);
    end
    
    methods
        %% Only thrown in init
        function ex = classInvalidException(obj, className, caller, propertyName, propertyType)
            if exist(propertyType, "class") == 8
                ex = MException('MATLAB:class:InvalidType','%s', ...
                                message('MATLAB:type:ErrorCoercingImplicitDefaultValue',propertyName, ...
                                        obj.generateClassLink(className, caller), ...
                                        message('MATLAB:type:UnsupportedClassForValidation',propertyType).getString).getString);
            else
                ex = MException('MATLAB:class:InvalidType','%s', ...
                                message('MATLAB:type:ErrorCoercingImplicitDefaultValue',propertyName, ...
                                        obj.generateClassLink(className, caller), ...
                                        message('MATLAB:type:NotAClass',propertyType).getString).getString);
            end
        end
    end
    
    
    methods(Static, Sealed)
        function cls = generateClassLink(unresolvedClassName, ~)
            if feature('hotlinks')
                % resolvedClassName = caller.resolveClass(unresolvedClassName);
                % ClassLink does not support classID. Use
                % unresolvedClassName for now.
                cls = message('MATLAB:type:ClassLink',unresolvedClassName).getString;
            else
                cls = unresolvedClassName;
            end
        end
        
        function [kind, s] = parseTargetSize(sizestr)
            % Based on sizeConversionException.m
            persistent pattern;
            
            if isempty(pattern)
                sep = char(215);
                
                %scalar (1,1...,1)
                pattern{1} = ['^(1' sep ')+1$'];
                
                %scalarCompar (1,:,:,1...)
                compat = '[1MN(D\d+)]';
                pattern{2} = ['^(' compat sep ')+' compat '$'];
                
                %anything else
                pattern{3} = '(?<dim>[MND]\d*|\d+)';
            end
            
            for i=1:numel(pattern)
                tok = regexp(sizestr, pattern{i}, 'names');
                if ~isempty(tok)
                    kind = i;
                    s = tok;
                    return;
                end
            end
            kind = 0;
            s = struct([]);
        end
        
        function handler = getFromOrigin(origin)
            switch origin
                case 'implicit'
                    handler = matlab.internal.validation.PropertyValidationImplicitExceptionHandler;
                case 'default'
                    handler = matlab.internal.validation.PropertyValidationDefaultExceptionHandler;
                case 'user'
                    handler = matlab.internal.validation.PropertyValidationUserExceptionHandler;
                otherwise
                    error('Invalid Property Validation exception origin.');
            end
        end
    end
end

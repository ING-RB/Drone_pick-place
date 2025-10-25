function methodArray = GetMethodOverloads(methodMetaData, className, indentLevel, reportObj, isCSharp)

    %   Copyright 2023 The MathWorks, Inc.

        arguments(Input)
            methodMetaData (1,1) meta.method
            className (1,1) string % The name of the encapsulating class (may be different than the defining class through inheritance)
            indentLevel (1,1) int64
            reportObj (1,1) matlab.engine.internal.codegen.reporting.ReportData
            isCSharp (1,1) logical
        end
        arguments(Output)
            methodArray (1,:) MethodTpl
        end

        methodArray = [];
        import matlab.engine.internal.codegen.*
        import matlab.engine.internal.codegen.reporting.*
         % New metadata API for input arguments
        fullName = string([methodMetaData.DefiningClass.Name '/' methodMetaData.Name]);
        for methodData = matlab.internal.metafunction(fullName)
            
            % New metadata API for input arguments
            method = MethodTpl(methodMetaData, className, indentLevel, reportObj, isCSharp);
            rawInputArgs = [];
            if ~isempty(methodData.Signature.Inputs)
                rawInputArgs = methodData.Signature.Inputs;
            end
            method.NumArgIn = length(rawInputArgs);
            
            % Collate the Input arg data
            method.InputArgs = matlab.engine.internal.codegen.ArgumentTpl.empty();
            for i = 1 : method.NumArgIn
                method.InputArgs = [method.InputArgs matlab.engine.internal.codegen.ArgumentTpl(rawInputArgs(i), "input")];
            end

            % Determine if constructor or not
            pathParts = split(method.EncapsulatingClass, '.');
            className = string(pathParts(end));
            if(className == method.SectionName)
                method.IsConstructor = true;
            else
                method.IsConstructor = false;
            end

            location = string(which(method.DefiningClass));

            % Error if the method's defining class cannot be found for some reason
            if(~isfile(location) && ~location.contains("built-in"))
                messageObj = message("MATLAB:engine_codegen:MethodDefinitionNotFound", method.MethodPath);
                error(messageObj);
            end

            % Check if any input args are varargin
            method.IsVarargin = false;
            for i = 1:method.NumArgIn
                if method.InputArgs(i).Kind == matlab.internal.metadata.ArgumentKind.repeating
                    method.IsVarargin = true;
                end
            end

            % Record vacant input metadata for reporting
            method.VacantMeta = [];

            % Note if a method arg is missing type or size metadata
            for i = 1:method.NumArgIn
                arg = method.InputArgs(i);
                hasType = arg.MATLABArrayInfo.HasType;
                hasSize = arg.MATLABArrayInfo.HasSize;

                if(i~=1 || method.IsStatic || method.IsConstructor) % Don't list "self methodData" as having vacant metadata
                    if(~hasType || ~hasSize) % if no type or size, add to vacant metadata
                        mu = matlab.engine.internal.codegen.reporting.MetaUnit("MethodInputArgument", method.SectionName, arg.Name, hasSize, hasType);
                        method.VacantMeta = [method.VacantMeta mu];
                    end
                end
            end

            % Read logic pretaining to output args
            
            % Determine number of outputs
            rawOutputArgs = methodData.Signature.Outputs;
            method.NumArgOut = length(rawOutputArgs);
            
            % Collate the output arg data
            method.OutputArgs = matlab.engine.internal.codegen.ArgumentTpl.empty();
            for i = 1 : method.NumArgOut
                method.OutputArgs = [method.OutputArgs matlab.engine.internal.codegen.ArgumentTpl(rawOutputArgs(i), "output")];
            end

             % Check if any output args are varargout
            method.IsVarargout = false;
            for outputArg = method.OutputArgs
                if outputArg.Kind == matlab.internal.metadata.ArgumentKind.repeating
                    method.IsVarargout = true;
                end
            end

            % Don't generate the method if it is hidden, abstract, has restricted
            % access, is static, or is not public
            method.IsAccessible = true;
            if(method.IsHidden)
                method.IsAccessible = false;
                method.ReasonInaccessible = "Method is hidden";
            elseif(method.IsAbstract)
                method.IsAccessible = false;
                method.ReasonInaccessible = "Method is Abstract";
                % Remove the method.IsCSharp once C++ supports static
                % methods
            elseif(method.IsStatic && ~method.IsCSharp)
                method.IsAccessible = false;
                method.ReasonInaccessible = "Method is static";
            elseif(~isa(method.Access, 'char') && ~isa(method.Access, 'string')) % handle restricted access case
                method.IsAccessible = false;
                method.ReasonInaccessible = "Method is not public";
            elseif(string(method.Access) ~= "public") % assume convertible to string now
                method.IsAccessible = false;
                method.ReasonInaccessible = "Method is not public";
            end

            % Record missing output argument metadata if applicable
            if(~method.IsConstructor && method.NumArgOut>0)
                for i = 1 : method.NumArgOut
                    methodName = method.SectionName;
                    argName = method.OutputArgs(i).Name;
                    hasSize = method.OutputArgs(i).MATLABArrayInfo.HasSize;
                    hasType = method.OutputArgs(i).MATLABArrayInfo.HasType;
                    if(~hasType || ~hasSize) % if no type or size, add to vacant metadata
                        mu = matlab.engine.internal.codegen.reporting.MetaUnit("MethodOutputArgument", methodName, argName, hasSize, hasType);
                        method.VacantMeta = [method.VacantMeta mu];
                    end
                end
            end
            methodArray = [methodArray method];
        end
end
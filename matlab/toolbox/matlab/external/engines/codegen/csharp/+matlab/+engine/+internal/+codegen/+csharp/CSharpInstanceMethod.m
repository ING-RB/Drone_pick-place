classdef CSharpInstanceMethod < matlab.engine.internal.codegen.csharp.CSharpMethod
    % Represents a C# instance method, only useable in CSharpNonStaticClass
    
    properties
        Method matlab.engine.internal.codegen.MethodTpl;
        ThrowIfDefault = "ThrowIfDefault();" + newline
    end
    
    methods
        function obj = CSharpInstanceMethod(Method, numArgIn, numArgOut, OuterCSharpNamespace)
            obj = obj@matlab.engine.internal.codegen.csharp.CSharpMethod(Method.SectionName, numArgIn, numArgOut, Method.InputArgs, Method.OutputArgs, OuterCSharpNamespace);
            obj.Method = Method;
            obj.IsStatic = obj.Method.IsStatic;
            if obj.IsStatic
                [obj.OutputNames, obj.RefInIndices, obj.RefOutIndices] = handleRefCase(obj);
            else
                [obj.OutputNames, obj.RefInIndices, obj.RefOutIndices] = handleRefCaseInstance(obj);
            end
            obj = obj.generateBody();
            if obj.IsStatic
                obj.Body = obj.MATLABCast + obj.Body;
            end
            obj = obj.generateParameters();
        end

        function obj = generateBody(obj)
            obj = generateBody@matlab.engine.internal.codegen.csharp.CSharpMethod(obj, length(obj.Method.InputArgs), obj.Method.OutputArgs);
        end

        function obj =  generateParameters(obj)
            obj = generateParameters@matlab.engine.internal.codegen.csharp.CSharpMethod(obj, obj.Method.InputArgs, obj.Method.OutputArgs);
        end
        
        function content = string(obj)
            content = string@matlab.engine.internal.codegen.csharp.CSharpMethod(obj);
            % Case where the method is static but owned by the class
            
            if obj.Name == "le" || obj.Name == "lt" || obj.Name=="gt" ||obj.Name=="ge"
                content = obj.buildComparisonMethod();
            else
                if obj.Method.IsStatic
                    content = replace(content, "[StaticToken]","static ");
                    content = replace(content, "[CallerToken]", "_dynMatlab");
                    content = replace(content, "[throwIfDefault]", obj.ThrowIfDefault);
                    content = replace(content, "[MethodCallName]", matlab.engine.internal.codegen.csharp.util.FixFullNameKeywordConflicts(replace(obj.Method.FullName,"/",".")));
                else
                    content = replace(content, "[StaticToken]","");
                    content = replace(content, "[CallerToken]", "_objrep");
                    content = replace(content, "[MethodCallName]", obj.Name);
                    content = replace(content, "[throwIfDefault]", "");
                end
                content = replace(content, "[VoidToken]", "void");
                content = replace(content, "[rootIndent]", repmat(['[oneIndent]'], 1, obj.Method.IndentLevel-1));
            end
        end

        function methodCall = generateMethodCall(obj, maxNumArgIn)
            %write method call
            methodCall = "[MethodCallName](new RunOptions(nargout:[nargOut])[commaToken]";
            %skip the obj input
            numArgIn = maxNumArgIn - obj.NumArgInOptional;
            for i=2:numArgIn

                methodCall = methodCall + obj.InputNames(i);

                if i ~= numArgIn
                    methodCall = methodCall + ",";
                end
            end
            methodCall = methodCall + ")";
            methodCall = replace(methodCall, "[nargOut]", int2str(obj.NumArgOut));

            %add a comma if there are input arguments, skip obj
            if length(obj.InputNames)<=1
                methodCall = replace(methodCall, "[commaToken]", "");
            else
                methodCall = replace(methodCall, "[commaToken]", ",");
            end
        end


        % find all instances where a ref variable is used, this function
        % skips the first input of the method as it is dropped for instance
        % methods
        function [outputNames, refInIndices, refOutIndices] = handleRefCaseInstance(obj)
            outputNames = [];
            refInIndices = [];
            refOutIndices = [];
            for i=1:obj.NumArgOut
                isRefVaraible = false;
                for j=2:length(obj.InputNames)
                    % make sure that the names are the same
                    if obj.OutputNames(i) == obj.InputNames(j)
                        % make sure that the types are the same
                        if obj.OutputTypes(i) == obj.InputTypes(j)
                            % mark variable as a ref variable
                            outputNames = [outputNames, obj.OutputNames(i)];
                            refInIndices = [refInIndices, j];
                            refOutIndices = [refOutIndices, i];
                        else
                            % name is the same but types are different
                            % prepend underscore to avoid redefining
                            % variable
                            outputNames = [outputNames, "_"+obj.OutputNames(i)];
                        end
                        isRefVaraible = true;
                    end
                end
                % if not a reference variable add variable back to the item
                if ~isRefVaraible
                    outputNames = [outputNames, obj.OutputNames(i)];
                end
            end
        end

        function isEnum = IsEnum(obj, index)
            isEnum = obj.Method.OutputArgs(index).MATLABArrayInfo.IsEnum;
        end

        function method = buildComparisonMethod(obj)
            method = "[oneIndent]public static bool operator [operatorToken] ([className] obj1, [className] obj2){" + newline + ...
                "[oneIndent][oneIndent]bool ret = obj1._matlab.[methodName](obj1,obj2);" + newline + ...
                "[oneIndent][oneIndent]return ret;" + newline + ...
                "[oneIndent]}" + newline + newline;
            method = replace(method, "[methodName]", obj.Name);
            operator = "<";
            if obj.Name == "le"
                operator = "<=";
            elseif obj.Name == "gt"
                operator = ">";
            elseif obj.Name == "ge"
                operator = ">=";
            end
            method = replace(method, "[operatorToken]", operator);
        end
    end
end


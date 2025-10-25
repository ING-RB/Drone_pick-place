classdef CSharpStaticMethod < matlab.engine.internal.codegen.csharp.CSharpMethod
    %CSHARPSTATICMETHOD This class represents a method of a C# static
    %class.
    
    properties
        Func matlab.engine.internal.codegen.FunctionTpl;
        FullName string;
    end
    
    methods
        function obj = CSharpStaticMethod(Func, numArgInOptional, numArgOut, OuterCSharpNamespace)
            functionName =  matlab.engine.internal.codegen.util.extractFunctionNameFromNameSpace(Func.SectionName);
            obj = obj@matlab.engine.internal.codegen.csharp.CSharpMethod(functionName, numArgInOptional, numArgOut, Func.InputArgs, Func.OutputArgs, OuterCSharpNamespace);
            [obj.OutputNames, obj.RefInIndices, obj.RefOutIndices] = obj.handleRefCase();
            obj.NumArgOut = numArgOut;
            obj.Func = Func;
            obj.FullName = obj.Func.FullName;
            obj.IsStatic = true;
            obj = obj.generateBody(length(obj.Func.InputArgs),obj.Func.OutputArgs);
            obj.Body = obj.MATLABCast + obj.Body;
            obj = obj.generateParameters(obj.Func.InputArgs, obj.Func.OutputArgs);
        end

        function obj =  generateParameters(obj, InputArgs, OutputArgs)
            parameters = "[InputSection][ComaToken][OutputSection]";
            numArgIn = length(InputArgs)-obj.NumArgInOptional;
            %convert arguments to .NET types
            inputTypes = matlab.engine.internal.codegen.csharp.util.ConvertArgs(InputArgs, obj.OuterCSharpNameSpace);
            outputTypes = matlab.engine.internal.codegen.csharp.util.ConvertArgs(OutputArgs, obj.OuterCSharpNameSpace);

            %get input and output args as strings
            inputs = obj.generateInputs(numArgIn, inputTypes);
            outputs = obj.generateOutputs(outputTypes);

            %replace the general parameters with inputs and outputs
            parameters = replace(parameters, "[InputSection]", inputs);
            parameters = replace(parameters, "[OutputSection]", outputs);

            % add a comma if there are output arguments and input arguments
            % skip the obj input
            if (obj.NumArgOut ~= 0 && numArgIn >= 1 && length(obj.RefOutIndices) ~= obj.NumArgOut)
                parameters = replace(parameters, "[ComaToken]", ", ");
            else
                parameters = replace(parameters, "[ComaToken]", "");
            end
            obj.Parameters = parameters;

        end
        

        function inputs = generateInputs(obj, maxNumArgIn, inputTypes)
            inputs = "";
            numArgIn = maxNumArgIn;
            for i=1:numArgIn
                if i~= 1
                    inputs = inputs + ", ";
                end
                if ismember(obj.RefInIndices, i)
                    inputs = inputs +"ref ";
                end
                inputs = inputs + inputTypes(i) + " " + obj.InputNames(i);
            end
            %add matlab instance as first input
            inputs = "MATLABProvider _matlab[commaToken]" + inputs;
    
            % add a comma if there is more than one input or output
            if numArgIn ~= 0 || obj.NumArgOut ~= 0
                inputs = replace(inputs, "[commaToken]", ", ");
            else
                 inputs = replace(inputs, "[commaToken]", "");
            end
         end

         function methodCall = generateMethodCall(obj, maxNumArgIn)
            %write method call
            methodCall = matlab.engine.internal.codegen.csharp.util.FixFullNameKeywordConflicts(obj.FullName)+ "(new RunOptions(nargout:[nargOut])[commaToken]";
            numArgIn = maxNumArgIn - obj.NumArgInOptional;
            for i=1:numArgIn

                methodCall = methodCall + obj.InputNames(i);

                if i ~= numArgIn
                    methodCall = methodCall + ",";
                end
            end
            methodCall = methodCall + ")";
            methodCall = replace(methodCall, "[nargOut]", int2str(obj.NumArgOut));

            %add a comma if there are input arguments
            if numArgIn == 0
                methodCall = replace(methodCall, "[commaToken]", "");
            else
                methodCall = replace(methodCall, "[commaToken]", ",");
            end
         end

         function isEnum = IsEnum(obj, index)
            isEnum = obj.Func.OutputArgs(index).MATLABArrayInfo.IsEnum;
         end

        function content = string(obj)
            content = string@matlab.engine.internal.codegen.csharp.CSharpMethod(obj);
            content = replace(content, "[StaticToken]","static ");
            content = replace(content, "[CallerToken]", "_dynMatlab");
            content = replace(content, "[VoidToken]", "void");
            content = replace(content, "[MethodCallName]", matlab.engine.internal.codegen.csharp.util.FixFullNameKeywordConflicts(obj.FullName));
            content = replace(content, "[throwIfDefault]", "");
            content = replace(content, "[rootIndent]", repmat(['[oneIndent]'], 1, obj.Func.IndentLevel+1));
        end


    end
end


classdef CSharpConstructor < matlab.engine.internal.codegen.csharp.CSharpMethod
    % Represents a C# constructor, only used in CSharpNonStaticClass
    
    properties
        Constructor matlab.engine.internal.codegen.ConstructorTpl
        FullName string
    end
    
    methods
        function obj = CSharpConstructor(Constructor, numArgIn, numArgOut, fullName)
            %CSHARPCONSTRUCTOR Construct an instance of this class
            %   Detailed explanation goes here
            obj = obj@matlab.engine.internal.codegen.csharp.CSharpMethod(Constructor.SectionName, numArgIn, ...
                numArgOut, Constructor.SectionMetaData.InputArgs, ...
                Constructor.SectionMetaData.OutputArgs, "");%blank is for the outercsharpnamespace
            obj.Constructor = Constructor;
            obj.FullName = fullName;
            [obj.OutputNames, obj.RefInIndices, obj.RefOutIndices] = handleRefCase(obj);
            obj = obj.generateBody(obj.Constructor.SectionMetaData.OutputArgs);
            obj = obj.generateParameters(obj.Constructor.SectionMetaData.InputArgs, obj.Constructor.SectionMetaData.OutputArgs);
        end
        

        function obj = generateBody(obj, OutputArgs)
            obj = generateBody@matlab.engine.internal.codegen.csharp.CSharpMethod(obj, length(obj.Constructor.SectionMetaData.InputArgs), OutputArgs);
            %add matlab instance assignment
            obj.Body = "[rootIndent][oneIndent]this._matlab = _matlab;"+newline+obj.Body;
        end

        function inputs = generateInputs(obj, inputTypes, InputArgs)
            inputs = "";
            %swrite out all input args
            numArgIn = length(inputTypes) - obj.NumArgInOptional;
            for i=1:numArgIn
                inputs = inputs + inputTypes(i) + " " + matlab.engine.internal.codegen.csharp.util.fixCSharpKeywordConflict(InputArgs(i).Name);
                if i~=numArgIn
                    inputs = inputs + ", ";
                end
            end
            %add matlab instance as first input
            inputs = "MATLABProvider _matlab[commaToken]" + inputs;
    
            % add a comma if there is more than zero inputs
            if numArgIn >= 1
                inputs = replace(inputs, "[commaToken]", ", ");
            else
                 inputs = replace(inputs, "[commaToken]", "");
            end
        end

        function content = generateAssignmentSection(obj, OutputArgs)
            content = "_objrep";
            if obj.NumArgOut ~= 1
                content = content + ",";
            end
            %skip obj
            for i=2:obj.NumArgOut
                content= content + matlab.engine.internal.codegen.csharp.util.fixCSharpKeywordConflict(obj.OutputNames(i));
                %write a coma unless it is the last argument
                if i ~= obj.NumArgOut && i < obj.NumArgOut
                   content = content + ",";
                end
            end
            %add parantheses if the number of outputs is greater than 1
             if (obj.NumArgOut > 1)
                content = "(" + content + ")";
            end
        end

        function methodCall = generateMethodCall(obj, maxNumArgIn)
            %write method call
            methodCall = "[MethodCallName](new RunOptions(nargout:[nargOut])[commaToken]";
            % check is empty due to implicit varargin
            % varargin is not supported, this also allows us to generate
            % 0 input constructors
            numArgIn = 0;
            if ~isempty(obj.InputNames)
                numArgIn = maxNumArgIn - obj.NumArgInOptional;
                % this if statement is only true if one of the arguments is
                % varargin
                if numel(obj.InputTypes) < numArgIn
                    numArgIn = length(obj.InputNames);
                end
                for i=1:numArgIn

                    methodCall = methodCall + obj.InputNames(i);

                    %write a coma unless it is the last argument
                    if i ~= numArgIn 
                        methodCall = methodCall + ",";
                    end
                end
            end
            methodCall = methodCall + ")";
            methodCall = replace(methodCall, "[nargOut]", int2str(obj.NumArgOut));

            %add a comma if there are input arguments
            if numArgIn<1
                methodCall = replace(methodCall, "[commaToken]", "");
            else
                methodCall = replace(methodCall, "[commaToken]", ",");
            end
        end

        function outputs = generateOutputs(obj, outputTypes, OutputArgs)
            outputs = "";
            %skip the object output
            for i=2:obj.NumArgOut
                if i~=2
                    outputs = outputs + ", ";
                end
                 % use dynamic instead of object, for convience
                if (obj.OutputTypes(i) == "object")
                    outputs = outputs + " out dynamic " + obj.OutputNames(i);
                else
                    outputs = outputs + " out " + obj.OutputTypes(i)+ " " + obj.OutputNames(i);
                end
            end
        end

         function obj =  generateParameters(obj, InputArgs, OutputArgs)
            parameters = "[InputSection][ComaToken][OutputSection]";

            %convert arguments to .NET types
            inputTypes = matlab.engine.internal.codegen.csharp.util.ConvertArgs(InputArgs, obj.OuterCSharpNameSpace);
            outputTypes = matlab.engine.internal.codegen.csharp.util.ConvertArgs(OutputArgs, obj.OuterCSharpNameSpace);

            %get input and output args as strings
            inputs = obj.generateInputs(inputTypes, InputArgs);
            outputs = obj.generateOutputs(outputTypes, OutputArgs);

            %replace the general parameters with inputs and outputs
            parameters = replace(parameters, "[InputSection]", inputs);
            parameters = replace(parameters, "[OutputSection]", outputs);

            %add a comma if there are output arguments, skip the object
            %output
            if (obj.NumArgOut > 1)
                parameters = replace(parameters, "[ComaToken]", ", ");
            else
                parameters = replace(parameters, "[ComaToken]", "");
            end
            obj.Parameters = parameters;

        end
    
        function content = string(obj)
            content = string@matlab.engine.internal.codegen.csharp.CSharpMethod(obj);
            content = replace(content, "[StaticToken]","");
            content = replace(content, "[VoidToken]", "");
            content = replace(content, "[CallerToken]", "this._matlab");
            content = replace(content, "[MethodCallName]", matlab.engine.internal.codegen.csharp.util.FixFullNameKeywordConflicts(obj.FullName));
            content = replace(content, "[rootIndent]", repmat(['[oneIndent]'], 1, obj.Constructor.IndentLevel-1));
        end
    end
end


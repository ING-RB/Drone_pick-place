classdef CSharpMethod < matlab.mixin.Heterogeneous
    % Represents a C# method, base class for CSharpInstanceMethod and
    % CSharpStaticMethod
    
    properties
        Parameters string
        Body string
        Name string
        InputNames string
        OutputNames string
        OutputTypes
        InputTypes
        NumArgOut
        NumArgInOptional
        RefInIndices
        RefOutIndices
        OuterCSharpNameSpace
        IsStatic logical
    end

    properties(Constant)
        MATLABCast = "[rootIndent][oneIndent]" +"dynamic _dynMatlab = _matlab;" + newline;
        MATLABObjectCast = ""
    end
    
    methods
        function obj = CSharpMethod(Name, NumArgInOptional, NumArgOut, InputArgs, OutputArgs, OuterCSharpNamespace)
            obj.Name = matlab.engine.internal.codegen.csharp.util.fixCSharpKeywordConflict(Name);
            obj.NumArgInOptional = NumArgInOptional;
            obj.NumArgOut = NumArgOut;
            obj.OuterCSharpNameSpace = OuterCSharpNamespace;
            % build inputs
            obj.InputNames = [];
            % turn input args into input types
            obj.InputTypes = matlab.engine.internal.codegen.csharp.util.ConvertArgs(InputArgs, obj.OuterCSharpNameSpace);
            % args to names
            for arg = InputArgs
                %skip varargin for now
                if arg.Name == "varargin"
                    continue;
                end
                obj.InputNames = [obj.InputNames, arg.Name];
            end
            % build outputs
            obj.OutputTypes = matlab.engine.internal.codegen.csharp.util.ConvertArgs(OutputArgs, obj.OuterCSharpNameSpace);
            for arg = OutputArgs
                obj.OutputNames = [obj.OutputNames, arg.Name];
            end

            % fix keyword conflicts
            obj.InputNames = matlab.engine.internal.codegen.csharp.util.fixCSharpKeywordConflict(obj.InputNames);
            obj.OutputNames = matlab.engine.internal.codegen.csharp.util.fixCSharpKeywordConflict(obj.OutputNames);
        end
        
        function obj = generateBody(obj, maxNumArgIn, OutputArgs)
            contentSection = "[rootIndent][oneIndent][AssignmentSection][AssignmentToken][CastSection][CallerToken].[MethodCall];";   

            %replace tokens
            contentSection = replace(contentSection, "[MethodCall]", obj.generateMethodCall(maxNumArgIn));
            if (obj.NumArgOut > 0)
                contentSection = replace(contentSection, "[AssignmentToken]", " = ");
                contentSection = replace(contentSection,"[AssignmentSection]", obj.generateAssignmentSection());
                %mark the item as a tuple depending on number of outputs
                if (obj.NumArgOut == 1)
                    contentSection = replace(contentSection, "[CastSection]", "(" + obj.generateCastSection(matlab.engine.internal.codegen.csharp.util.ConvertArgs(OutputArgs, obj.OuterCSharpNameSpace)) + ")");
                else
                    contentSection = replace(contentSection, "[CastSection]", "((" + obj.generateCastSection(matlab.engine.internal.codegen.csharp.util.ConvertArgs(OutputArgs, obj.OuterCSharpNameSpace)) + "))");

                end
            else
                contentSection = replace(contentSection, "[AssignmentToken]", "");
                contentSection = replace(contentSection,"[AssignmentSection]", "");
                contentSection = replace(contentSection, "[CastSection]", "");
            end

            obj.Body = contentSection;
        end

        function assignmentSection = generateAssignmentSection(obj)
            assignmentSection = "";
            for i=1:obj.NumArgOut
                assignmentSection = assignmentSection + obj.OutputNames(i);
                %write a coma unless it is the last argument
                if i ~= obj.NumArgOut
                    assignmentSection = assignmentSection + ",";
                end
            end
            %add parantheses if the number of outputs is greater than 1
            if (obj.NumArgOut > 1)
                assignmentSection = "(" + assignmentSection + ")";
            end
        end

        function castSection = generateCastSection(obj, outputTypes)
             %write cast section
            castSection = "";
            for i=1:obj.NumArgOut
                %force cast to MATLABObject if type is a custom MATLAB type
                if contains(outputTypes(i), ".") && ~contains(outputTypes(i), "System.Numerics.Complex")&& ~obj.IsEnum(i)
                    castSection = castSection + outputTypes(i);
                elseif outputTypes(i) == "dynamic"
                    castSection = castSection + "MATLABArray";
                else
                    castSection = castSection + outputTypes(i);
                end
                %write a coma unless it is the last argument
                if i ~= obj.NumArgOut
                    castSection = castSection + ",";
                end
            end
        end

        function methodCall = generateMethodCall(obj, maxNumArgIn)
            %write method call
            methodCall = "[MethodCallName](new RunOptions(nargout:[nargOut])[commaToken]";
            %skip the obj input
            numArgIn = maxNumArgIn - obj.NumArgInOptional;
            for i=2:numArgIn
                
                methodCall = methodCall + obj.InputNames(i);

                %write a coma unless it is the last argument
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
            if (obj.NumArgOut ~= 0 && numArgIn ~= 1 && length(obj.RefOutIndices) ~= obj.NumArgOut)
                parameters = replace(parameters, "[ComaToken]", ", ");
            % Check if the first item is a reference variable in static
            % methods as the first input is not ignored
            elseif obj.IsStatic && obj.NumArgOut ~= 0 && length(obj.RefOutIndices) ~= obj.NumArgOut
                parameters = replace(parameters, "[ComaToken]", ", ");
            else
                parameters = replace(parameters, "[ComaToken]", "");
            end
            obj.Parameters = parameters;

        end

        function inputs = generateInputs(obj, maxNumArgIn, inputTypes)
            inputs = "";
            if obj.IsStatic
                inputs = "MATLABProvider _matlab[ComaToken]";
            end
            %skip the obj input
            numArgIn = maxNumArgIn - obj.NumArgInOptional;

            if numArgIn > 1 && obj.IsStatic
                inputs = replace(inputs, "[ComaToken]",", ");
            elseif obj.IsStatic
                inputs = replace(inputs, "[ComaToken]","");
            end
            for i=2:numArgIn
                if i~= 2
                    inputs = inputs + ", ";
                end
                if ismember(obj.RefInIndices, i)
                    inputs = inputs +"ref ";
                end
                inputs = inputs + inputTypes(i) + " " + obj.InputNames(i);
            end
        end

        function outputs = generateOutputs(obj, outputTypes)
            outputs = "";
            for i=1:obj.NumArgOut
                if ismember(obj.RefOutIndices,i)
                    continue;
                end
                if i~=1 && length(obj.RefOutIndices)~=obj.NumArgOut
                    outputs = outputs + ", ";
                end
                 % use dynamic instead of object, for convience
                if (outputTypes(i) == "object")
                    outputs = outputs + " out dynamic " + obj.OutputNames(i);
                else
                    outputs = outputs + " out " + outputTypes(i)+ " " + obj.OutputNames(i);
                end
            end
        end

        function content = string(obj)
            content = "[rootIndent]public [StaticToken][VoidToken] [MethodName]([Parameters]){"...
            + newline + "[Body]" + newline + "[rootIndent]}" +newline;

            content = replace(content, "[MethodName]", obj.Name);
            content = replace(content, "[Parameters]", obj.Parameters);
            content = replace(content, "[Body]", obj.Body);
        end

        function [outputNames, refInIndices, refOutIndices] = handleRefCase(obj)
            outputNames = [];
            refInIndices = [];
            refOutIndices = [];
            for i=1:obj.NumArgOut
                isRefVaraible = false;
                for j=1:length(obj.InputNames)
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
    end
end


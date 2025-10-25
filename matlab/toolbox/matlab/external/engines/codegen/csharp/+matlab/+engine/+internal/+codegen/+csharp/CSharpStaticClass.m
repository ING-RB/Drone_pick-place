classdef CSharpStaticClass < matlab.engine.internal.codegen.csharp.CSharpClass
    % Represents a static class, used for functions that are NOT memembers
    % of classes
    
    
    methods
        function obj = CSharpStaticClass(func, functionHolderClass, outerCSharpNamespace)
            arguments(Input)
                func matlab.engine.internal.codegen.FunctionTpl;
                functionHolderClass (1,1) string;
                outerCSharpNamespace string;
            end
            obj = obj@matlab.engine.internal.codegen.csharp.CSharpClass(matlab.engine.internal.codegen.ClassTpl.empty(), ...
                outerCSharpNamespace);
            obj.Name = functionHolderClass;
            %replace the . in a filename with underscores
            obj.FileName = replace(func.SectionName, ".", "_");
            %handle namespace
            obj.Namespace = matlab.engine.internal.codegen.csharp.util.generateCSharpNamespace(func.FullName);
            if outerCSharpNamespace ~= "" && obj.Namespace ~= ""
                    obj.Namespace = outerCSharpNamespace + "." + obj.Namespace;
            elseif outerCSharpNamespace ~= ""
                    obj.Namespace = outerCSharpNamespace;
            end
            obj = obj.generateMethods(func);
        end
        

         function content = string(obj)
            content = string@matlab.engine.internal.codegen.csharp.CSharpClass(obj);
            content = replace(content, "[throwIfDefault]", "");
            content = replace(content, "[DefaultConstructorSection]", "");
            content = replace(content, "[attributeToken]", "");
            content = replace(content, "[castsSection]", "");
            content = replace(content, "[privateMemberData]", "");
            content = replace(content, "[constructorSection]", "");
            content = replace(content, "[propertySection]", "");
            content = replace(content, "[staticToken]", "static partial");
            content = replace(content, "[handleMethodsSection]", "");
            content = replace (content, "[IEquatableToken]", "");
            content = replace(content , "[IEquatableMethodsSection]", "");
             % "Expand" root indents
             if obj.Namespace == ""
                content = replace(content, "[rootIndent]", repmat(['[oneIndent]'], 1, 0));
             else
                 content = replace(content, "[rootIndent]", repmat(['[oneIndent]'], 1, 1));
             end
         end

         function obj = generateMethods(obj,func)
            arguments(Input)
                obj (1,1) matlab.engine.internal.codegen.csharp.CSharpStaticClass;
                func (1,1) matlab.engine.internal.codegen.FunctionTpl;
            end
            obj.Methods = matlab.engine.internal.codegen.csharp.CSharpMethod.empty();
            numberOfOptionalInputs = matlab.engine.internal.codegen.util.CountNumberOfOptionalInputs(func.InputArgs);

            for i = 0 : numberOfOptionalInputs
                %create a method for each output as they are all optional
                for j = 0: func.NumArgOut
                    obj.Methods = [obj.Methods, matlab.engine.internal.codegen.csharp.CSharpStaticMethod(func, i, j, obj.OuterCSharpNameSpace)];
                end
            end
         end
    end
end


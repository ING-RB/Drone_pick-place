classdef CSharpClass < matlab.mixin.Heterogeneous
    % Represents a C# class, base class for both static and instance
    
    properties
        Methods matlab.engine.internal.codegen.csharp.CSharpMethod;
        Class matlab.engine.internal.codegen.ClassTpl;
        ClassOrStruct string = "class";
        FileName string;
        Name string;
        Namespace string;   
        OuterCSharpNameSpace string;
    end
    
    methods
        function obj = CSharpClass(Class, outerCSharpNameSpace)
            obj.Class = Class;
            obj.OuterCSharpNameSpace = outerCSharpNameSpace;
            if ~isempty(Class)
                obj.Name = matlab.engine.internal.codegen.csharp.util.fixCSharpKeywordConflict(Class.SectionName);
                %replace . in filename with underscores
                obj.FileName = replace(obj.Class.FullName, ".", "_");
                %handle namespace
                obj.Namespace = matlab.engine.internal.codegen.csharp.util.generateCSharpNamespace(obj.Class.FullName);
                if outerCSharpNameSpace ~= "" && obj.Namespace ~= ""
                    obj.Namespace = outerCSharpNameSpace + "." + obj.Namespace;
                elseif outerCSharpNameSpace ~= ""
                        obj.Namespace = outerCSharpNameSpace;
                end
            end
        end
        
        function content = string(obj)
            % [attributeToken] binds to MATLABClassAttribute in generated code
            content = "[namespaceSection]" + newline + ...
                "[attributeToken]" + newline + ...
                "[rootIndent]public [staticToken] [ClassOrStruct] [className][IEquatableToken] { " + newline +  ...
                "[throwIfDefault]" + ...
                "[privateMemberData]" + ...
                "[constructorSection]" + ...
                "[DefaultConstructorSection]" + ...
                "[propertySection]" + ...
                "[methodSection]" + ...
                "[IEquatableMethodsSection]" + ...
                "[castsSection]" + ...
                "[rootIndent]}" + newline + ...
                "[namespaceClose]" + newline;
            
            content = replace(content, "[ClassOrStruct]", obj.ClassOrStruct);
            content = replace(content, "[methodSection]", obj.buildMethodString);            
            % handle the namespace
            if (obj.Namespace ~= "")
                content = replace(content, "[namespaceSection]", "namespace " + obj.Namespace + "{");
                content = replace(content, "[namespaceClose]", "}");
            else  %replace the namespace with the empty string is there is none
                content = replace(content, "[namespaceSection]", "");
                content = replace(content, "[namespaceClose]", "");
            end
            
            content = replace(content, "[className]", obj.Name);
        end

        function methodString = buildMethodString(obj)
            methodString = "";
            for method = obj.Methods
                methodString = methodString + method.string();
            end
        end
    end
end


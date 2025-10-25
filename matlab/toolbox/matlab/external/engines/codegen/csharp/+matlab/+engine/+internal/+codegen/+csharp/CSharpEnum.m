classdef CSharpEnum
    % The class CSharpEnum represents a C# enum
    % Copyright 2023 The MathWorks, Inc.

    properties
        Class matlab.engine.internal.codegen.ClassTpl;
        Namespace string;
        Enumerations;
        Name string = "";
    end
    
    methods
        function obj = CSharpEnum(Class, outerCSharpNamespace)
           obj.Class = Class;
           obj.Name = matlab.engine.internal.codegen.csharp.util.fixCSharpKeywordConflict(obj.Class.SectionName);
           obj.Enumerations = [];
           for i = 1:length(obj.Class.SectionMetaData.EnumerationMemberList)
               % Disable hidden enums
               if ~obj.Class.SectionMetaData.EnumerationMemberList(i).Hidden
                    obj.Enumerations = [obj.Enumerations convertCharsToStrings(obj.Class.SectionMetaData.EnumerationMemberList(i).Name)];
               end
           end
           obj.Enumerations = matlab.engine.internal.codegen.csharp.util.fixCSharpKeywordConflict(obj.Enumerations);
           obj.Namespace = matlab.engine.internal.codegen.csharp.util.generateCSharpNamespace(obj.Class.FullName);
           if outerCSharpNamespace ~= "" && obj.Namespace ~= obj.Namespace
                obj.Namespace = outerCSharpNamespace + "." + obj.Namespace;
            elseif outerCSharpNamespace ~= ""
                obj.Namespace = outerCSharpNamespace;
            end
        end
        
        function content = string(obj)
            content = "[namespaceSection]" + newline + ... +
                "[MATLABEnum([EnumNameWithQuotes])]" + newline +...
                "[rootIndent]public enum [EnumName]{" + newline + ...
                "[EnumerationsSection]" +newline + ...
                "}" + newline + ...
				"[namespaceClose]";

            %replace enum tokens
            content = replace(content, "[EnumNameWithQuotes]", '"'+obj.Name+'"');
            content = replace(content, "[EnumName]", obj.Name);
            content = replace(content,"[EnumerationsSection]", obj.formatEnumerations());

            %namespace replacement
			if obj.Namespace~=""
                content = replace(content, "[namespaceSection]", "namespace " + obj.Namespace + "{");
                content = replace(content, "[namespaceClose]", "}");
            else  %replace the namespace with the empty string is there is none
                content = replace(content, "[namespaceSection]", "");
                content = replace(content, "[namespaceClose]", "");
            end

            content = replace(content, "[rootIndent]", repmat(['[oneIndent]'], 1, obj.Class.IndentLevel));
        end

        function enumerations = formatEnumerations(obj)
            enumerations = "";
            for i=1:length(obj.Enumerations)
                %write out enumerations
                enumerations = enumerations + "[rootIndent][oneIndent]" + obj.Enumerations(i);
                if (~(i == length(obj.Enumerations)))
                    enumerations = enumerations + ",";
                    enumerations = enumerations + newline;
                end
            end
        end
    end
end


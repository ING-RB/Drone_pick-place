classdef CSharpProperty
    %this class represents a C# property
    properties
        Get string = ""
        Set string = ""
        Name string
        Type string
        OuterCSharpNamespace string
        Property matlab.engine.internal.codegen.PropertyTpl
    end
    
    methods
        function obj = CSharpProperty(Property, OuterCSharpNamespace)
            obj.Property = Property;
            obj.OuterCSharpNamespace = OuterCSharpNamespace;
            obj.Name = matlab.engine.internal.codegen.csharp.util.fixCSharpKeywordConflict(obj.Property.SectionName);
            obj = obj.convertProperty();
            if(obj.Property.IsGetAccessible)
                obj = obj.generateGet();
            else
                obj.Get = "";
            end
            if (obj.Property.IsSetAccessible)
                obj = obj.generateSet();
            else
                obj.Set = "";
            end
        end
        
        function content = string(obj)
            content = "[rootIndent]public [DotNetPropertyClass] [PropertyName] {" +newline + "[GetSection]" + newline + "[SetSection][rootIndent]}"+newline;
            content = replace(content, "[GetSection]",obj.Get);
            content = replace(content, "[SetSection]", obj.Set);
            content = replace(content, "[rootIndent]", repmat(['[oneIndent]'], 1, obj.Property.IndentLevel - 1));
            content = replace(content, "[DotNetPropertyClass]", obj.Type);
            content = replace(content, "[PropertyName]", obj.Name);
            % The verbatim identifier is not needed within the string
            content = replace(content, "[PropertyNameNoAt]", replace(obj.Name, "@", ""));
        end

        function obj = generateGet(obj)
            obj.Get = convertCharsToStrings('[rootIndent][oneIndent]get => _matlab.matlab.@internal.engine.getProperty(_objrep, "[PropertyNameNoAt]");');
        end

        function obj = generateSet(obj)
            obj.Set = convertCharsToStrings('[rootIndent][oneIndent]set => _objrep = _matlab.matlab.@internal.engine.setProperty(_objrep,"[PropertyNameNoAt]",value);')  + newline;
        end

        function obj = convertProperty(obj)
            tc = matlab.engine.internal.codegen.csharp.CSharpTypeConverter(obj.OuterCSharpNamespace);
            obj.Type = tc.convertType2CSharp(obj.Property.MatlabPropertyClass, obj.Property.ArrayType, obj.isReal(), matlab.engine.internal.codegen.util.MATLABInfo.empty(), obj.Property.ArrayDimensions);
        end

        function real = isReal(obj)
            real = false;
            if ~isempty(obj.Property.SectionMetaData.Validation)
                for j = 1 : numel(obj.Property.SectionMetaData.Validation.ValidatorFunctions)
                    val = string(char(obj.Property.SectionMetaData.Validation.ValidatorFunctions{j}));
                    if val.matches("mustBeReal")
                        real = true;
                    end
                end
            end
        end
    end
end


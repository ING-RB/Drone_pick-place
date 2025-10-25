classdef ConstructorTpl < matlab.engine.internal.codegen.CodeGenSection
%

%   Copyright 2020-2023 The MathWorks, Inc.
    
    properties
        SectionName = "";
        SectionContent = "";
        SectionMetaData;
        IndentLevel = 0;
        HasDefaultSignature = true;
    end
    
    methods
        function obj = ConstructorTpl(constructorMethod, indentLevel)
            arguments
                constructorMethod (1,1) matlab.engine.internal.codegen.MethodTpl
                indentLevel       (1,1) uint64
            end
            
            obj.IndentLevel = indentLevel;
            
            obj.SectionMetaData = constructorMethod;
            obj = read(obj);
            
        end
        
        function obj = read(obj)
            methodObj = obj.SectionMetaData;
            pathParts = split(methodObj.SectionMetaData.DefiningClass.Name, '.');
            obj.SectionName = pathParts(end);
            
            % Determine if the constructor method has a default signature.
            % Note: Synthetic signature may appear as varargin
            if(methodObj.NumArgIn == 0 && methodObj.NumArgOut == 1)
                obj.HasDefaultSignature = true;
            else
                obj.HasDefaultSignature = false;
            end
            
        end
        
        function sectionContent = toString(obj)
            
            methodObj = obj.SectionMetaData;
            
            obj.SectionContent =  "[rootIndent][ClassName]" + ...
                "() : MATLABObject() {}" + newline + newline;
            
            % Provide empty constructor if signature is default.
            % Also provide empty constructor option if constructor is varargin (g2890342)
            if(obj.HasDefaultSignature || methodObj.IsVarargin)
                obj.SectionContent = obj.SectionContent + "[rootIndent][ClassName]" + ...
                    "(std::shared_ptr<MATLABControllerType> matlabPtr) :" + newline + ...
                    "[rootIndent][oneIndent]MATLABObject(matlabPtr, u""[classNameFull]"")" + newline + ...
                    "[rootIndent]{}" + newline;
            end

            % Non-default constructor signature. Generate specific constructor.
            if(~obj.HasDefaultSignature)
                obj.SectionContent = obj.SectionContent + methodObj.toString + newline;
            end
            
            obj.SectionContent = obj.SectionContent + "[rootIndent][copyConstructor]";
            %Disable writing a copy constructor if it would conflict with a user defined one.
            writeCopyConstructor = true;
            hasOneArgument = (obj.SectionMetaData.NumArgIn == 1);
            if (hasOneArgument)
                %make sure there is no error if ArgCppTypes is empty
                if (~isempty(obj.SectionMetaData.ArgCppTypes) && obj.SectionMetaData.ArgCppTypes(1) == "matlab::data::Array")
                    writeCopyConstructor = false;
                elseif (isempty(obj.SectionMetaData.ArgCppTypes) && obj.SectionMetaData.InputArgs(1).Kind ~= matlab.internal.metadata.ArgumentKind.repeating)
                        writeCopyConstructor = false;
                end
            end
            
            % provide a copy constructor if the constructor is does not
            % conflict with the default value.  no type also evaluates to
            % MDA
            if (writeCopyConstructor)
                obj.SectionContent = replace(obj.SectionContent, "[copyConstructor]", "[rootIndent][ClassName]" + ...
                    "(std::shared_ptr<MATLABControllerType> matlabPtr, matlab::data::Array obj) :" + newline + ...
                    "[rootIndent][oneIndent]MATLABObject(matlabPtr, obj)" + newline + ...
                    "[rootIndent]{}" + newline + newline);
            else
                obj.SectionContent = replace(obj.SectionContent, "[copyConstructor]", "");
            end
            
            % Content formatting
            obj.SectionContent = replace(obj.SectionContent, "[ClassName]", obj.SectionName);
            obj.SectionContent = replace(obj.SectionContent, "[classNameFull]", methodObj.SectionMetaData.DefiningClass.Name);
            obj.SectionContent = replace(obj.SectionContent, "[rootIndent]", repmat(['[oneIndent]'], 1, obj.IndentLevel));
            sectionContent = obj.SectionContent;
        end
    end
end

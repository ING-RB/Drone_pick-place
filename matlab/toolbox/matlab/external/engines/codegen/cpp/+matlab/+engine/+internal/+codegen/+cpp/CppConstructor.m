classdef CppConstructor
    %CppConstructor Represents a C++ constructor
    %   Represents and generates the C++ constructor, given
    %   language-agnostic MATLAB metadata
    
    %   Copyright 2023 The MathWorks, Inc.
    
    properties
        Constructor matlab.engine.internal.codegen.ConstructorTpl;
    end
    
    methods
        function obj = CppConstructor(Constructor)
            %CPPCONSTRUCTOR Construct an instance of this class
            obj.Constructor = Constructor;
        end
        
        function sectionContent = string(obj)
            
            methodObj = obj.Constructor.SectionMetaData;
            
            obj.Constructor.SectionContent =  "[rootIndent][ClassName]" + ...
                "() : [objectType]() {}" + newline + newline;
            
            % Provide empty constructor if signature is default.
            % Also provide empty constructor option if constructor is varargin (g2890342)
            if(obj.Constructor.HasDefaultSignature || methodObj.IsVarargin)
                obj.Constructor.SectionContent = obj.Constructor.SectionContent + "[rootIndent][ClassName]" + ...
                    "(std::shared_ptr<MATLABControllerType> matlabPtr) :" + newline + ...
                    "[rootIndent][oneIndent][objectType](matlabPtr, u""[classNameFull]"")" + newline + ...
                    "[rootIndent]{}" + newline;
            end

            % Non-default constructor signature. Generate specific constructor.
            if(~obj.Constructor.HasDefaultSignature)
                obj.Constructor.SectionContent = obj.Constructor.SectionContent + matlab.engine.internal.codegen.cpp.CppMethod(methodObj).string() + newline;
            end
            
            obj.Constructor.SectionContent = obj.Constructor.SectionContent + "[rootIndent][copyConstructor]";
            %Disable writing a copy constructor if it would conflict with a user defined one.
            writeCopyConstructor = true;
            hasOneArgument = (obj.Constructor.SectionMetaData.NumArgIn == 1);
            if (hasOneArgument)
                %make sure there is no error if ArgCppTypes is empty
                tc = matlab.engine.internal.codegen.cpp.CPPTypeConverter();

                cppArgType = tc.convertArg(obj.Constructor.SectionMetaData.InputArgs(1));
                if(cppArgType == "matlab::data::Array")
                    writeCopyConstructor = false; % First input conflicts with copy constructor
                elseif(cppArgType == "" && obj.Constructor.SectionMetaData.InputArgs(1).Kind ~= matlab.internal.metadata.ArgumentKind.repeating)
                    writeCopyConstructor = false; % First input conflicts with copy constructor (unknown type, but exclude varargin case)
                end
            end
            
            % provide a copy constructor if the constructor is does not
            % conflict with the default value.
            if (writeCopyConstructor)
                obj.Constructor.SectionContent = replace(obj.Constructor.SectionContent, "[copyConstructor]", "[rootIndent][ClassName]" + ...
                    "(std::shared_ptr<MATLABControllerType> matlabPtr, matlab::data::Array obj) :" + newline + ...
                    "[rootIndent][oneIndent][objectType](matlabPtr, obj)" + newline + ...
                    "[rootIndent]{}" + newline + newline);
            else
                obj.Constructor.SectionContent = replace(obj.Constructor.SectionContent, "[copyConstructor]", "");
            end
            
            % Content formatting
            obj.Constructor.SectionContent = replace(obj.Constructor.SectionContent, "[ClassName]", obj.Constructor.SectionName);
            obj.Constructor.SectionContent = replace(obj.Constructor.SectionContent, "[classNameFull]", methodObj.SectionMetaData.DefiningClass.Name);
            obj.Constructor.SectionContent = replace(obj.Constructor.SectionContent, "[rootIndent]", repmat(['[oneIndent]'], 1, obj.Constructor.IndentLevel));
            sectionContent = obj.Constructor.SectionContent;
        end
    end
end


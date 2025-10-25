classdef CppProperty
    %CppProperty Represents a C++ property
    %   Represents and generates the C++ property, given
    %   language-agnostic MATLAB metadata
    
    properties
        Property matlab.engine.internal.codegen.PropertyTpl
    end
    
    methods
        function obj = CppProperty(Property)
            %CPPPROPERTY Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property = Property;
        end
        
        function sectionContent = string(obj)
            import matlab.engine.internal.codegen.*
            tc = matlab.engine.internal.codegen.cpp.CPPTypeConverter();

            if(~obj.Property.IsGetAccessible && ~obj.Property.IsSetAccessible) % Error if property should not be generated at all
                messageObj = message("MATLAB:engine_codegen:InternalLogicError");
                error(messageObj);
            end

            scalarBaseType = ""; % will hold underlying base type without "std::vector" in it
            realNumericType = ""; % Holds the "real" type analog of complex type, if applicable

            % If the property is 1x1 or a MDA, treat it as a scalar
            if((obj.Property.ArrayType == DimType.Scalar) || obj.Property.CppPropertyClass == "matlab::data::Array" || obj.Property.CppPropertyClass == "std::u16string")
                scalarOrVector = "Scalar";
                scalarBaseType = obj.Property.CppPropertyClass;

            elseif(obj.Property.ArrayType == DimType.Vector) % Otherwise, treat it as a vector
                scalarOrVector = "Vector";
                pattern = 'std::vector<(.*)>'; % Capture anything in brackets up to last '>' encountered
                token = regexp(obj.Property.CppPropertyClass, pattern, 'tokens');

                if(numel(token) ~= 1)
                    messageObj = message("MATLAB:engine_codegen:InternalLogicError");
                    error(messageObj);
                end
                scalarBaseType = token{1};
            end

            % check if the matlab type is simple, supported
            if(sum(string(tc.ConversionTable.MATLABType).matches(obj.Property.MatlabPropertyClass)) >= 1)

                setSection = "[rootIndent]void set[PropertyName]([CppPropertyClass] value) { return MATLABSet[ScalarOrVector]Property(u""[PropertyName]"", value); }" + newline;

                % check if complex
                isComplex = obj.Property.CppPropertyClass.contains("std::complex");


                % Check if we should provide CPP overloads to set numbers that
                % can be complex in MATLAB with plain numeric reals
                if( isComplex && (obj.Property.ArrayType==DimType.Scalar || obj.Property.ArrayType==DimType.Vector) )

                    pattern = 'std::complex<(.*?)>'; % capture anything in angle brackets up to first '>' encountered
                    [token match] = regexp(obj.Property.CppPropertyClass, pattern, 'tokens', 'match');

                    realNumericType = replace(obj.Property.CppPropertyClass, match{1}, token{1});

                    % Add overload allowing set with "real" numeric
                    setSection = "[rootIndent]void set[PropertyName]([realNumericType] value) { return MATLABSet[ScalarOrVector]Property(u""[PropertyName]"", value); }" + newline + ...
                        setSection;
                end

                % Get vectors of complex data with MDA for possible space savings
                if( isComplex && (obj.Property.ArrayType==DimType.Vector))
                    getSection = "[rootIndent]matlab::data::Array get[PropertyName]() { return MATLABGetScalarProperty<matlab::data::Array>(u""[PropertyName]""); }" + newline;
                elseif( isComplex && (obj.Property.ArrayType==DimType.Scalar))
                    % Use special complex get function here
                    getSection = "[rootIndent][CppPropertyClass] get[PropertyName]() { return MATLABGetComplexScalarProperty<[realNumericType]>(u""[PropertyName]""); }" + newline;
                else % Get normally
                    getSection = "[rootIndent][CppPropertyClass] get[PropertyName]() { return MATLABGet[ScalarOrVector]Property<[scalarBaseType]>(u""[PropertyName]""); }" + newline;
                end

            elseif(obj.Property.IsEnumeration && (obj.Property.ArrayType==DimType.Scalar))
                % Create getter and setter for property that is a MATLAB enumeration scalar
                enumFullNameDot = string(obj.Property.SectionMetaData.Validation.Class.Name);

                 getSection = "[rootIndent][MatlabPropertyClass] get[PropertyName]() {" + newline + ... % using MatlabPropertyClass assumes the enum will be generated and available for use by this property
                     "[rootIndent][oneIndent]matlab::data::Array obj = MATLABGetScalarProperty<matlab::data::Array>(u""[PropertyName]"");" + newline + ...
                     "[rootIndent][oneIndent]const std::string& _str = obj[0];" + newline + ...
                     "[rootIndent][oneIndent]" + replace(enumFullNameDot, ".", "::") + " ret = ::get" + replace(enumFullNameDot, ".", "_") + "Enum(_str);" + newline + ...
                     "[rootIndent][oneIndent]return ret; " + newline + ...
                     "[rootIndent]}" + newline;

                 setSection = "[rootIndent]void set[PropertyName]([MatlabPropertyClass] enumProp) {" + newline + ... % using MatlabPropertyClass assumes the enum will be generated and available for use by this property
                     "[rootIndent][oneIndent]matlab::data::ArrayFactory _arrayFactory;" + newline + ...
                     "[rootIndent][oneIndent]matlab::data::ArrayDimensions _dims = {1, 1};" + newline + ...
                     "[rootIndent][oneIndent]std::string _str = ::get" + replace(enumFullNameDot, ".", "_") + "String(enumProp);" + newline + ...
                     "[rootIndent][oneIndent]matlab::data::Array _enum = _arrayFactory.createEnumArray(_dims, """ + enumFullNameDot + """, { _str });" + newline + ...
                     "[rootIndent][oneIndent]MATLABSetScalarProperty(u""[PropertyName]"", _enum);" + newline + ...
                     "[rootIndent]}" + newline;

            elseif(obj.Property.IsEnumeration && (obj.Property.ArrayType==DimType.Vector))
                % Create getter and setter for property that is a MATLAB enumeration vector
                enumFullNameDot = string(obj.Property.SectionMetaData.Validation.Class.Name);

                getSection = "[rootIndent]std::vector<[MatlabPropertyClass]> get[PropertyName]() {" + newline + ... % using MatlabPropertyClass assumes the enum will be generated and available for use by this property
                    "[rootIndent][oneIndent]matlab::data::Array arr = MATLABGetArrayProperty(u""[PropertyName]"");" + newline + ...
                    "[rootIndent][oneIndent]std::vector<[MatlabPropertyClass]> enum_objs;" + newline + ... %std::vector<pkg1::pkg2::class1> enum_objs;
                    "[rootIndent][oneIndent]for(size_t k=0; k<arr.getNumberOfElements(); k++){" + newline + ...
                    "[rootIndent][oneIndent][oneIndent]enum_objs.push_back(::get" + replace(enumFullNameDot, ".", "_") + "Enum(arr[k]));" + newline + ...
                    "[rootIndent][oneIndent]}" + newline + ...
                    "[rootIndent][oneIndent]return enum_objs;" + newline + ...
                    "[rootIndent]}" + newline;

                setSection = "[rootIndent]void set[PropertyName](std::vector<[MatlabPropertyClass]> enumProp) {" + newline + ...
                    "[rootIndent][oneIndent]matlab::data::ArrayFactory _arrayFactory;" + newline + ...
                    "[rootIndent][oneIndent]matlab::data::ArrayDimensions _dims = {1, enumProp.size()};" + newline + ...
                    "[rootIndent][oneIndent]std::vector<std::string> _enum_strings(enumProp.size());" + newline + ...
                    "[rootIndent][oneIndent]std::transform(enumProp.begin(), enumProp.end(), _enum_strings.begin(), ::get" + replace(enumFullNameDot, ".", "_") + "String);" + newline + ...
                    "[rootIndent][oneIndent]matlab::data::Array _enumProp_mda = _arrayFactory.createEnumArray(_dims, """ + enumFullNameDot + """, _enum_strings);" + newline + ...
                    "[rootIndent][oneIndent]MATLABSetArrayProperty(u""[PropertyName]"", _enumProp_mda);" + newline + ...
                    "[rootIndent]}" + newline;

            elseif ((obj.Property.MatlabPropertyClass == "unknown" || tc.isMathWorksRestricted(obj.Property.MatlabPropertyClass)) && obj.Property.CppPropertyClass == "matlab::data::Array") || obj.Property.ArrayType == DimType.MultiDim
                % This is a property without MATLAB type information, just put it in a general MDA
                % OR, the property is multi-dimensional in which case we just store in MDA as well
                getSection = ...
                    "[rootIndent]matlab::data::Array get[PropertyName]() {" + newline + ...
                    "[rootIndent][oneIndent]matlab::data::Array obj = MATLABGetScalarProperty<matlab::data::Array>(u""[PropertyName]"");" + newline + ...
                    "[rootIndent][oneIndent]return obj;" + newline + ...
                    "[rootIndent]}" + newline;
                setSection = ...
                    "[rootIndent]void set[PropertyName](matlab::data::Array obj) {" + newline + ...
                    "[rootIndent][oneIndent]MATLABSetScalarProperty(u""[PropertyName]"", obj);" + newline + ...
                    "[rootIndent]}" + newline;

            elseif (obj.Property.ArrayType == DimType.Scalar)
                % No match for simple type. MATLAB class is known, so assume it will be included
                % in this generation or externally supplied. Scalar gets stored in instance of the generated class
                getSection = ...
                    "[rootIndent][MatlabPropertyClass] get[PropertyName]() {" + newline + ...
                    "[rootIndent][oneIndent]matlab::data::Array obj = MATLABGetScalarProperty<matlab::data::Array>(u""[PropertyName]"");" + newline + ...
                    "[rootIndent][oneIndent]return [MatlabPropertyClass](m_matlabPtr, obj);" + newline + ...
                    "[rootIndent]}" + newline;
                setSection = ...
                    "[rootIndent]void set[PropertyName]([MatlabPropertyClass] obj) {" + newline + ...
                    "[rootIndent][oneIndent]MATLABSetScalarProperty(u""[PropertyName]"", matlab::data::Array(obj));" + newline + ...
                    "[rootIndent]}" + newline;
            elseif (obj.Property.ArrayType == DimType.Vector)
                % No match for simple type. MATLAB class is known, so assume it will be included
                % in this generation or externally supplied. Vector case: stored in vector of the generated class
                % Transforms from vector of obj and MDA happen here.
                getSection = ...
                    "[rootIndent]std::vector<[MatlabPropertyClass]> get[PropertyName]() {" + newline + ...
                    "[rootIndent][oneIndent]std::vector<matlab::data::Object> _raw_objs = MATLABGetVectorProperty<matlab::data::Object>(u""[PropertyName]"");" + newline + ...
                    "[rootIndent][oneIndent]std::vector<[MatlabPropertyClass]> _objs;" + newline + ...
                    "[rootIndent][oneIndent]matlab::data::ArrayFactory _arrayFactory;" + newline + ...
                    "[rootIndent][oneIndent]for(size_t k=0; k<_raw_objs.size(); k++){" + newline + ...
                    "[rootIndent][oneIndent][oneIndent]matlab::data::ObjectArray _obj_arr = _arrayFactory.createScalar(_raw_objs.at(k));" + newline + ...
                    "[rootIndent][oneIndent][oneIndent]_objs.push_back([MatlabPropertyClass](m_matlabPtr, _obj_arr));" + newline + ...
                    "[rootIndent][oneIndent]}" + newline + ...
                    "[rootIndent][oneIndent]return _objs;" + newline + ...
                    "[rootIndent]}" + newline;
                setSection = ...
                    "[rootIndent]void set[PropertyName](std::vector<[MatlabPropertyClass]> objs) {" + newline + ...
                    "[rootIndent][oneIndent]std::vector<matlab::data::Object> raw_objs;" + newline + ...
                    "[rootIndent][oneIndent]for(size_t k=0; k<objs.size(); k++){" + newline + ...
                    "[rootIndent][oneIndent][oneIndent]matlab::data::Array _mda = objs.at(k);" + newline + ...
                    "[rootIndent][oneIndent][oneIndent]matlab::data::ObjectArray obj_arr = _mda;" + newline + ...
                    "[rootIndent][oneIndent][oneIndent]raw_objs.push_back(obj_arr[0]);" + newline + ...
                    "[rootIndent][oneIndent]}" + newline + ...
                    "[rootIndent][oneIndent]MATLABSetVectorProperty(u""[PropertyName]"", raw_objs);" + newline + ...
                    "[rootIndent]}" + newline;
            end

            % Don't generate setter or getter if applicable
            if(~obj.Property.IsGetAccessible)
                getSection = "";
            end
            if(~obj.Property.IsSetAccessible)
                setSection = "";
            end

            obj.Property.SectionContent = getSection + setSection;

            % Perform the token substitutions
            obj.Property.SectionContent = replace(obj.Property.SectionContent, "[ScalarOrVector]", scalarOrVector);
            obj.Property.SectionContent = replace(obj.Property.SectionContent, "[rootIndent]", repmat(['[oneIndent]'], 1, obj.Property.IndentLevel));
            obj.Property.SectionContent = replace(obj.Property.SectionContent, "[CppPropertyClass]", obj.Property.CppPropertyClass);
            obj.Property.SectionContent = replace(obj.Property.SectionContent, "[MatlabPropertyClass]", replace(obj.Property.MatlabPropertyClass,".","::"));
            obj.Property.SectionContent = replace(obj.Property.SectionContent, "[realNumericType]", realNumericType);
            obj.Property.SectionContent = replace(obj.Property.SectionContent, "[scalarBaseType]", scalarBaseType);
            obj.Property.SectionContent = replace(obj.Property.SectionContent, "[PropertyName]", obj.Property.SectionName);
            sectionContent = obj.Property.SectionContent;

        end
    end
end


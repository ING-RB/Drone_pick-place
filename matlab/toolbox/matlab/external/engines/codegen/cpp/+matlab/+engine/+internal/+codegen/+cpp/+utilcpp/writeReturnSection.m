function cppOut = writeReturnSection(outputArgs, caller, cppIn)
    %writeReturnSection fills in the return section tokens of the generated
    %method or function, given the output arguments and the caller type (method or function).
    %Uses the templated output design.
    
    %   Copyright 2022 The MathWorks, Inc.

    arguments (Input)
        outputArgs (1,:) matlab.engine.internal.codegen.ArgumentTpl {mustBeNonempty} % Output arguments. There must be at least 1 output arg, otherwise this template is not needed
        caller (1,1) {mustBeA(caller, ["matlab.engine.internal.codegen.FunctionTpl" "matlab.engine.internal.codegen.MethodTpl"])} % The function or method which will use the return section
        cppIn (1,1) string
    end
    arguments (Output)
        cppOut (1,1) string
    end

    import matlab.engine.internal.codegen.cpp.*

    cppOut = cppIn; % Output will be a filled-in version of the input

    numOut = length(outputArgs);

    % Expand [returnSection0] and [returnSection1] which are always present if template design is used
    returnSection0 = "[rootIndent][oneIndent][matlabPointer]->feval(u""[MethodOrFuncName]"", 0, _args);"; % feval call for 0 outputs. matlabPointer has different variable name if function vs method
    cppOut = replace(cppOut, "[returnSection0]", returnSection0);

    complexCatchClassSection = "";
    complexTransformSection = "";
    returnSection1 = "[rootIndent][oneIndent]matlab::data::Array _result_mda = [matlabPointer]->feval(u""[MethodOrFuncName]"", _args);" + newline + ... % feval call for 1 output.  matlabPointer has different variable name if function vs method
        "[complexCatchClassSection][complexTransformSection]" + ...
        "[rootIndent][oneIndent][returnType1] _result;" + newline + ...
        "[rootIndent][oneIndent][castSection]" + newline + ...
        "[rootIndent][oneIndent]return _result;";

    castSection = "";
    useSimpleScalar = "_result = MatlabTypesInterface::convertMDAtoScalar<[out1]>(_result_mda);"; % works for simple scalars
    useMDA = "_result = _result_mda;"; % works for 1 MDA output

    cppCategory = utilcpp.getOutputTypeCategory(outputArgs(1));

    if cppCategory == utilcpp.OutputTypeCategory.MissingMeta
        % If there is missing size/type data, use plain MDA result
        castSection = useMDA;
    elseif cppCategory == utilcpp.OutputTypeCategory.MultiDim
        % If ND-array (higher dimensional array) then use matlab::data::Array
        castSection = useMDA;
    elseif cppCategory == utilcpp.OutputTypeCategory.MWAuthoredClass
        % If the class is MathWorks internal class, then use MDA. We may
        % support generating these classes later.
        castSection = useMDA;
    elseif cppCategory == utilcpp.OutputTypeCategory.SimpleComplexScalar
        % if output arg is a scalar numeric that might be complex, catch it as complex (prevents MDA from recognizing as real if there is only a real part)
        complexCatchClassSection = "[rootIndent][oneIndent]MatlabTypesInterface::ConvertToComplex _converterObj;" + newline;
        complexTransformSection = "[rootIndent][oneIndent]_result_mda = matlab::data::apply_visitor(_result_mda, _converterObj);" + newline;
        castSection = useSimpleScalar;
    elseif cppCategory == utilcpp.OutputTypeCategory.SimpleScalar
        % If real scalar, then complex conversion is not needed
        complexCatchClassSection = "";
        complexTransformSection = "";
        castSection = useSimpleScalar;
    elseif cppCategory == utilcpp.OutputTypeCategory.SimpleVector
        % If simple real vector, then use helper function to convert MDA to std::vector<T>
        % Base type "T" will replace [outX_vectorBaseType] token later
        castSection = "_result = MatlabTypesInterface::convertMDAtoVector<[out1_vectorBaseType]>(_result_mda);";
    elseif cppCategory == utilcpp.OutputTypeCategory.SimpleComplexVector
        % If simple complex vector, we still use matlab::data::Array
        % This means possible space savings in the case there are many numbers without imaginary parts
        castSection = useMDA;
    elseif cppCategory == utilcpp.OutputTypeCategory.GenEnumScalar
        enumName = outputArgs(1).MATLABArrayInfo.ClassName;
        returnSection1 = "[rootIndent][oneIndent]matlab::data::Array _result_mda = [matlabPointer]->feval(u""[MethodOrFuncName]"", _args);" + newline + ...
        "[rootIndent][oneIndent]" + replace(enumName,".","::") + " _ret;" + newline + ...
        "[rootIndent][oneIndent]const std::string& _str = _result_mda[0];" + newline + ...
        "[rootIndent][oneIndent]_ret = get"+ replace(enumName,".","_") +"Enum(_str);" + newline + ...
        "[rootIndent][oneIndent]return _ret;";
    elseif cppCategory == utilcpp.OutputTypeCategory.GenEnumVector
        getSection = replace(outputArgs(1).MATLABArrayInfo.ClassName,".","_");
        enumName = replace(outputArgs(1).MATLABArrayInfo.ClassName,".","::");
        returnSection1 = "[rootIndent][oneIndent]matlab::data::Array _result_mda = [matlabPointer]->feval(u""[MethodOrFuncName]"", _args);" + newline + ...
        "[rootIndent][oneIndent]std::vector<"+enumName+"> _objects;" + newline+...
        "[rootIndent][oneIndent]for(size_t k=0; k<_result_mda.getNumberOfElements(); k++){" + newline + ...
        "[rootIndent][oneIndent][oneIndent]_objects.push_back(get" + getSection + "Enum(_result_mda[k]));" + newline + ...
        "[rootIndent][oneIndent]}" + newline + ...
        "[rootIndent][oneIndent] return _objects;";
    elseif cppCategory == utilcpp.OutputTypeCategory.GenExternalClassScalar
        className = replace(outputArgs(1).MATLABArrayInfo.ClassName,".","::");
        returnSection1 = "[rootIndent][oneIndent]matlab::data::Array _result_mda = [matlabPointer]->feval(u""[MethodOrFuncName]"", _args);" + newline + ...
        "[rootIndent][oneIndent]" + className + " _object([matlabPointer], _result_mda);" + newline + ...
        "[rootIndent][oneIndent]return _object;";
    elseif cppCategory == utilcpp.OutputTypeCategory.GenExternalClassVector
        className = replace(outputArgs(1).MATLABArrayInfo.ClassName, ".", "::");
        returnSection1 = "[rootIndent][oneIndent]matlab::data::Array _result_mda = [matlabPointer]->feval(u""[MethodOrFuncName]"", _args);" + newline + ...
        "[rootIndent][oneIndent]matlab::data::TypedArray<matlab::data::Object> _MDAobjects = static_cast<matlab::data::TypedArray<matlab::data::Object> >(_result_mda);" + newline+...
        "[rootIndent][oneIndent]std::vector<matlab::data::Object> _vectorOfObjects (_MDAobjects.cbegin(), _MDAobjects.cend());" + newline+...
        "[rootIndent][oneIndent]std::vector<"+ className +"> _objects;" + newline+...
        "[rootIndent][oneIndent]for(size_t k=0; k<_vectorOfObjects.size(); k++){" + newline + ...
        "[rootIndent][oneIndent][oneIndent] matlab::data::ObjectArray _obj_arr = _arrayFactory.createScalar(_vectorOfObjects.at(k));" + newline + ...
        "[rootIndent][oneIndent][oneIndent]_objects.push_back("+ className +"([matlabPointer],_obj_arr));" + newline + ...
        "[rootIndent][oneIndent]}" + newline + ...
        "[rootIndent][oneIndent] return _objects;";
    end

    % Add the complex handling if applicable
    returnSection1 = replace(returnSection1, "[complexCatchClassSection]", complexCatchClassSection);
    returnSection1 = replace(returnSection1, "[complexTransformSection]", complexTransformSection);
    % Add the cast section
    returnSection1 = replace(returnSection1, "[castSection]", castSection);

    % Fill-in returnSection1
    cppOut = replace(cppOut, "[returnSection1]", returnSection1);

    % Next we will expand additional "[returnSection2], [returnSection3], ..." style tokens, which are always tuple-based
    for x = 2 : numOut
        % feval call for multiple outputs.  matlabPointer has different variable name if function vs method
        returnSectionX = "[rootIndent][oneIndent]std::vector<matlab::data::Array> _result_mda = [matlabPointer]->feval(u""[MethodOrFuncName]"","+x+", _args);" + newline + ...
            "[complexCatchClassSection]" + ...
            "[rootIndent][oneIndent][returnType"+x+"] _result;" + ...
            "[castSection]" + newline + ...
            "[rootIndent][oneIndent]return _result;";

        % Cast each element of the tuple for output. (i-1) is used for zero-based indexing in C++
        castSection = "";
        complexCatchClassSection = "";
        for i = 1 : x 

            % This way of casting MDA works for most simple types
            simpleCast = newline + "[rootIndent][oneIndent]std::get<"+(i-1)+">(_result) = MatlabTypesInterface::convertMDAtoScalar<[out"+i+"]>([complexTransformSection]);";

            castPart = simpleCast; % use simple cast by default

            % This uses the MDA and puts it directly in the tuple
            useMDA = newline + "[rootIndent][oneIndent]std::get<"+(i-1)+">(_result) = _result_mda.at("+(i-1)+");";

            cppCategory = utilcpp.getOutputTypeCategory(outputArgs(i)); % Get the category type of the output argument

            % Additional casting/handling logic for MDA based on type
            if cppCategory == utilcpp.OutputTypeCategory.MissingMeta
                % If there is missing size/type data, use plain MDA result
                castPart = useMDA;
            elseif cppCategory == utilcpp.OutputTypeCategory.MultiDim
                % If ND-array (higher dimensional array) then use matlab::data::Array
                castPart = useMDA;
            elseif cppCategory == utilcpp.OutputTypeCategory.MWAuthoredClass
                % If the class is MathWorks internal class, then use MDA. We may
                % support generating these classes later.
                castPart = useMDA;
            elseif cppCategory == utilcpp.OutputTypeCategory.SimpleComplexScalar
                % If complex scalar, then apply complex conversion
                complexTransformSection = "matlab::data::apply_visitor(_result_mda.at("+(i-1)+"), _converterObj)";
                complexCatchClassSection = "[rootIndent][oneIndent]MatlabTypesInterface::ConvertToComplex _converterObj;" + newline;
            elseif cppCategory == utilcpp.OutputTypeCategory.SimpleScalar
                % If real scalar, then complex conversion is not needed
                complexTransformSection = "_result_mda.at("+(i-1)+")";
            elseif cppCategory == utilcpp.OutputTypeCategory.SimpleVector
                % If simple real vector, then use helper function to convert MDA to std::vector<T>
                % Base type "T" will replace [outX_vectorBaseType] token later
                castPart = newline + "[rootIndent][oneIndent]std::get<"+(i-1)+">(_result) = MatlabTypesInterface::convertMDAtoVector<[out"+i+"_vectorBaseType]>(_result_mda.at("+(i-1)+"));";
            elseif cppCategory == utilcpp.OutputTypeCategory.SimpleComplexVector
                % If simple complex vector, we still use matlab::data::Array
                % This means possible space savings in the case there are many numbers without imaginary parts
                castPart = newline + "[rootIndent][oneIndent]std::get<"+(i-1)+">(_result) = _result_mda.at("+(i-1)+");";
            elseif cppCategory == utilcpp.OutputTypeCategory.GenEnumScalar
                % For now use MDA instead of generatable enum
                castPart = newline+...
                "[rootIndent][oneIndent]const std::string& _str"+i+" = _result_mda.at("+(i-1)+")[0];" + newline + ...
                "[rootIndent][oneIndent]std::get<"+(i-1)+">(_result) = get"+ replace(outputArgs(i).MATLABArrayInfo.ClassName,".","_")+"Enum(_str" + i + ");";
            elseif cppCategory == utilcpp.OutputTypeCategory.GenEnumVector
                enumName =  replace(outputArgs(i).MATLABArrayInfo.ClassName,".","_");
                enumWithScope = replace(outputArgs(i).MATLABArrayInfo.ClassName, ".","::");
                castPart = newline + ...
                "[rootIndent][oneIndent]std::vector<"+enumWithScope+"> _objects" + i + ";" + newline+...
                "[rootIndent][oneIndent] matlab::data::Array _enumValues" + i + "= _result_mda.at("+(i-1)+");" + newline+...
                "[rootIndent][oneIndent]for(size_t k=0; k<_enumValues" + i + ".getNumberOfElements(); k++){" + newline + ...
                "[rootIndent][oneIndent][oneIndent]std::string _enumString" + i + " = _enumValues" + i +"[k];" + newline + ...
                "[rootIndent][oneIndent][oneIndent]_objects" + i + ".push_back(get" + enumName + "Enum(_enumString" + i +"));" + newline + ...
                "[rootIndent][oneIndent]}" + newline + ...
                "[rootIndent][oneIndent]std::get<"+(i-1)+">(_result) = _objects"+ i +";" +newline;
            elseif cppCategory == utilcpp.OutputTypeCategory.GenExternalClassScalar
                % For now use MDA instead of generatable class
                 castPart = newline + ...
                 "[rootIndent][oneIndent]" + outputArgs(i).MATLABArrayInfo.ClassName +" _obj"+i+" ([matlabPointer], _result_mda[" + (i-1) +"]);" + newline + ...
                 "[rootIndent][oneIndent]std::get<"+(i-1)+">(_result) = _obj"+i+";"; 
                 castPart = replace(castPart, ".", "::");
            elseif cppCategory == utilcpp.OutputTypeCategory.GenExternalClassVector
                classNameWithScope = replace(outputArgs(i).MATLABArrayInfo.ClassName, ".", "::");
                castPart = newline + ...
                "[rootIndent][oneIndent]matlab::data::TypedArray<matlab::data::Object> _MDAobjects" + i + " = static_cast<matlab::data::TypedArray<matlab::data::Object> >(_result_mda["+(i-1)+"]);" + newline+...
                "[rootIndent][oneIndent]std::vector<matlab::data::Object> _vectorOfObjects"+i+" (_MDAobjects" + i + ".cbegin(), _MDAobjects" + i + ".cend());" + newline+...
                "[rootIndent][oneIndent]std::vector<"+ classNameWithScope +" > _objects" +i+ ";" + newline+...
                "[rootIndent][oneIndent]for(size_t k=0; k<_vectorOfObjects"+i+".size(); k++){" + newline + ...
                "[rootIndent][oneIndent][oneIndent] matlab::data::ObjectArray _obj_arr"+i+" = _arrayFactory.createScalar(_vectorOfObjects" + i + ".at(k));" + newline + ...
                "[rootIndent][oneIndent][oneIndent]_objects"+i+".push_back("+classNameWithScope+"([matlabPointer],_obj_arr" + i + "));" + newline + ...
                "[rootIndent][oneIndent]}" + newline + ...
                "[rootIndent][oneIndent]std::get<"+(i-1)+">(_result) = _objects" + i + ";";
            end

            castPart = replace(castPart, "[complexTransformSection]", complexTransformSection); % fill-in complex handling if applicable
            castSection = castSection + castPart;
        end

        returnSectionX = replace(returnSectionX, "[complexCatchClassSection]", complexCatchClassSection); % define complex converter object if needed
        returnSectionX = replace(returnSectionX, "[castSection]", castSection); % fill-in the cast section. Casts each MDA to the correct tuple element.

        % Fill-in the [returnSectionX] style token
        cppOut = replace(cppOut, "[returnSection"+x+"]", returnSectionX);
    end

    % Compute return type tokens. returnTypes(1) = void. returnTypes(2) = [out1]. returnTypes(3) = std::tuple<[out1], [out2]> and so on
    returnTypes = ["void" "[out1]"]; % non-tuple types
    tupleType = "[out1]";
    for i = 2 : numOut % tuple types
        tupleType = tupleType + ", [out" + i + "]";
        returnTypes = [returnTypes "std::tuple<" + tupleType + ">"];
    end

    % Expand [returnType1], [returnType1] style tokens to [out1], [out2] style tokens
    for i = 0 : length(returnTypes)-1
        cppOut = replace(cppOut, "[returnType"+i+"]", returnTypes(i+1));
    end

    % Match the outputs to C++ types, then further expand [out1], [out2] style tokens to the matched C++ types
    for i = 1 : numOut
        outarg = outputArgs(i);
        cppCategory = utilcpp.getOutputTypeCategory(outarg);
        tc = matlab.engine.internal.codegen.cpp.CPPTypeConverter;
        ctype = tc.convertArg(outarg);

        % If complex and 1-D vector, use matlab::data::Array (special case for output data)
        if cppCategory == utilcpp.OutputTypeCategory.SimpleComplexVector
            ctype = "matlab::data::Array";
        end

        if cppCategory == utilcpp.OutputTypeCategory.GenEnumScalar
            ctype = outarg.MATLABArrayInfo.ClassName;
            ctype = replace (ctype,".","::");
        end

        if cppCategory == utilcpp.OutputTypeCategory.GenExternalClassScalar
            ctype = outarg.MATLABArrayInfo.ClassName;
            ctype = replace (ctype,".","::");
        end

        if cppCategory == utilcpp.OutputTypeCategory.GenExternalClassVector || cppCategory == utilcpp.OutputTypeCategory.GenEnumVector
            ctype = "std::vector<" + outarg.MATLABArrayInfo.ClassName +">";
            ctype = replace (ctype,".","::");
        end

        % If type == "" then use MDA for the output
        if ctype == ""
            ctype = "matlab::data::Array";
        end
        
        cppOut = replace(cppOut, "[out"+i+"]", ctype); % replace [outX] token with corresponding C++ type
        
        % if C++ type has std::vector<T>, extract base type T and replace [outX_vectorBaseType] tokens with T
        if ctype.contains("std::vector")
            tokens = regexp(ctype, 'std::vector<(.*)>', 'tokens'); % (.*) catches all characters between the angle brackets
            baseType = string(tokens{1}); % Should have 1 token match with contents caught by (.*)
            cppOut = replace(cppOut, "[out"+i+"_vectorBaseType]", baseType); % replace with vector's base type
        end

    end

    % Fill-in method or function specific things accordingly
    if isa(caller, "matlab.engine.internal.codegen.MethodTpl")
        cppOut = replace(cppOut, "[matlabPointer]", "m_matlabPtr"); % member variable name for method (MATLABObject member)
        cppOut = replace(cppOut, "[MethodOrFuncName]", caller.SectionName); % for method, just the local method name is used (no namespace prefix)
    elseif isa(caller, "matlab.engine.internal.codegen.FunctionTpl")
        cppOut = replace(cppOut, "[matlabPointer]", "_matlabPtr"); % input variable name for function case
        cppOut = replace(cppOut, "[MethodOrFuncName]", caller.FullName); % for function, the full namespace with dot-notation is used in feval call
    end

end
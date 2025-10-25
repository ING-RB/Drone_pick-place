function [defaultStructDef structSpecializations] = writeTypeStruct(outputArgs, caller)
    %writeTypeStruct Writes the struct template (in 2 parts) for resolving
    % compile-time output type in C++ based on nargout. defaultStructDef will
    % go in the class while structSpecializations must be defined outside
    % the class
    
    %   Copyright 2023 The MathWorks, Inc.

    arguments (Input)
        outputArgs (1,:) matlab.engine.internal.codegen.ArgumentTpl {mustBeNonempty} % Output arguments. There must be at least 1 output arg, otherwise this template is not needed
        caller (1,1) {mustBeA(caller, ["matlab.engine.internal.codegen.FunctionTpl" "matlab.engine.internal.codegen.MethodTpl"])} % The function or method which will use the struct
    end

    import matlab.engine.internal.codegen.cpp.*

    defaultStructDef = "[private:]" + newline + ... % Private tag for methods, not functions
        "template<size_t nargout>" + newline + ... % Default template (this default type for the field is never actively used
        "struct return_type_[name] { typedef void type; };" + newline + newline + ...
        "[public:]";

    structSpecializations = "template<>" + newline + ... % specialization for nargout=0 (always void)
        "struct [prefix]return_type_[name]<0> { typedef void type; };" + newline + newline + ...
        "template<>" + newline + ... % specialization for nargout=1 (never in std::tuple)
        "struct [prefix]return_type_[name]<1> { typedef [out1] type; };" + newline + newline; % [out1] will be filled in later

    % Add specializations for nargout>1, if applicable (always in std::tuple)
    tupleType = "[out1]";
    for i = 2:length(outputArgs)
        tupleType = tupleType + ", [out" + i + "]";  % E.g. [out1], [out2], [out3]
        structSpecializations = structSpecializations + ...
            "template<>" + newline + ...
            "struct [prefix]return_type_[name]<"+i+"> { typedef std::tuple<"+tupleType+"> type; };" + newline + newline; % e.g. [out1], [out2], [out3] will be filled in later
    end

    % Determine the CPP types
    outputCPPTypes = [];
    for i = 1:length(outputArgs)
        outarg = outputArgs(i);
        cppCategory = utilcpp.getOutputTypeCategory(outarg);
        tc = matlab.engine.internal.codegen.cpp.CPPTypeConverter();
        ctype = tc.convertArg(outarg);

        % If complex and 1-D vector, use matlab::data::Array (special case for output data)
        if cppCategory == utilcpp.OutputTypeCategory.SimpleComplexVector
            ctype = "matlab::data::Array";
        end
        if cppCategory == utilcpp.OutputTypeCategory.GenExternalClassScalar
            ctype = outarg.MATLABArrayInfo.ClassName;
            ctype = replace(ctype, ".", "::");
        end

        if cppCategory == utilcpp.OutputTypeCategory.GenExternalClassVector
            ctype = "std::vector<"+outarg.MATLABArrayInfo.ClassName+">";
            ctype = replace(ctype, ".", "::");
        end

        if cppCategory == utilcpp.OutputTypeCategory.GenEnumScalar
            ctype = outarg.MATLABArrayInfo.ClassName;
            ctype = replace(ctype, ".", "::");
        end

        if cppCategory == utilcpp.OutputTypeCategory.GenEnumVector
            ctype = "std::vector<"+outarg.MATLABArrayInfo.ClassName+">";
            ctype = replace(ctype, ".", "::");
        end

        % If type == "" then use MDA for the output
        if ctype == ""
            ctype = "matlab::data::Array";
        end

        outputCPPTypes = [outputCPPTypes ctype];
    end

    % Main body of templated struct is now complete

    % Fill-in the output types tokens
    for i = 1:length(outputArgs)
        structSpecializations = replace(structSpecializations, "[out" + i + "]", outputCPPTypes(i));
    end

    % Fill-in the method-case specific tokens
    if isa(caller, "matlab.engine.internal.codegen.MethodTpl")
        % private access specifier will be used
        defaultStructDef = replace(defaultStructDef, "[private:]", "private:");
        defaultStructDef = replace(defaultStructDef, "[public:]", "public:");
        defaultStructDef = replace(defaultStructDef, "[name]", caller.SectionName); % just method name (no dot-notation prefix)
        structSpecializations = replace(structSpecializations, "[name]", caller.SectionName);
        fullClassParts = split(caller.EncapsulatingClass, ".");
        structSpecializations = replace(structSpecializations, "[prefix]", fullClassParts(end) + "::"); % Class prefix needed here for definition outside class

    % Fill-in the function-case specific tokens
    elseif isa(caller, "matlab.engine.internal.codegen.FunctionTpl")
        % private/public access specifier will NOT be used
        defaultStructDef = replace(defaultStructDef, "[private:]", "");
        defaultStructDef = replace(defaultStructDef, "[public:]", "");

        % use full function name (dot-notation periods, if present, become underscores)
        funcName = replace(caller.FullName, ".", "_");
        defaultStructDef = replace(defaultStructDef, "[name]", funcName);
        structSpecializations = replace(structSpecializations, "[name]", funcName);
        structSpecializations = replace(structSpecializations, "[prefix]", ""); % No prefix needed
    end

    % Add the indentation token to each line of the default definition
    defaultStructDef = matlab.engine.internal.codegen.util.rootIndentCode(defaultStructDef);
    defaultStructDef = defaultStructDef + newline; % spacing
    structSpecializations = matlab.engine.internal.codegen.util.rootIndentCode(structSpecializations);

end
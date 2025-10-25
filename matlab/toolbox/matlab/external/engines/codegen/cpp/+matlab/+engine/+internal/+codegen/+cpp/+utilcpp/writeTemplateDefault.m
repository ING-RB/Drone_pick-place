function cppOut = writeTemplateDefault(outputArgs, caller)
    %writeTemplateDefault Writes the default template used to error if
    %compile-time nargout is too large. This function should not be used
    %for varargout case.
    
    %   Copyright 2023 The MathWorks, Inc.

    arguments
        outputArgs (1,:) matlab.engine.internal.codegen.ArgumentTpl {mustBeNonempty} % Output arguments. There must be at least 1 output arg, otherwise this template is not needed
        caller (1,1) {mustBeA(caller, ["matlab.engine.internal.codegen.FunctionTpl" "matlab.engine.internal.codegen.MethodTpl"])} % The function or method which will use the struct
    end
    
    % Body of the default template
    cppOut = "template<size_t nargout = 1>" + newline + ...
        "typename return_type_[name]<nargout>::type [localName]([argsString]) {" + newline + ... % [argsString] to be filled in outside this function. It will contain full input arg list.
        "[oneIndent]static_assert(nargout<=[numOutputArgs], ""Too many outputs specified. Maximum outputs is [numOutputArgs]."");" + newline + ...
        "}";

    % Replace tokens
    cppOut = replace(cppOut, "[numOutputArgs]", string(length(outputArgs)));

    % Fill-in the method-case specific tokens
    if isa(caller, "matlab.engine.internal.codegen.MethodTpl")
        cppOut = replace(cppOut, "[name]", caller.SectionName); % just method name (no dot-notation prefix)
        cppOut = replace(cppOut, "[localName]", caller.SectionName); % just method name (no dot-notation prefix)

    % Fill-in the function-case specific tokens
    elseif isa(caller, "matlab.engine.internal.codegen.FunctionTpl")
        underscoreName = replace(caller.FullName, ".", "_");
        localNameParts = split(caller.FullName, ".");
        localName = localNameParts(end);
        cppOut = replace(cppOut, "[name]", underscoreName); % use full function name (dot-notation periods, if present, become underscores) to reduce conflict chance
        cppOut = replace(cppOut, "[localName]", localName);
    end

    % Add the indentation token to each line. This token will be expanded later, outside this function.
    cppOut = matlab.engine.internal.codegen.util.rootIndentCode(cppOut);

    % Lastly, add a newline at the end without indent (for spacing)
    cppOut = cppOut + newline;
end


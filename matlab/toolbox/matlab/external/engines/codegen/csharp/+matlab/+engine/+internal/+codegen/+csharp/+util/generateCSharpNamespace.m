function csharpNamespace = generateCSharpNamespace(fullClassName)
    % Split the class name by periods
    parts = strsplit(fullClassName, '.');

    % Remove the last part (the class name itself)
    parts = parts(1:end-1);

    % Fix the keyword conflicts in the namespaces
    parts = matlab.engine.internal.codegen.csharp.util.fixCSharpKeywordConflict(parts);

    % Join the remaining parts with periods
    if ~isempty(parts)
        csharpNamespace = strjoin(parts, '.');
    else
        csharpNamespace = "";
    end
end
function csharpTypes = ConvertArgs(args, OuterCSharpNamespace)
arguments(Input)
    args matlab.engine.internal.codegen.ArgumentTpl;
    OuterCSharpNamespace (1,1) string
end
    csharpTypes = [];
    tc = matlab.engine.internal.codegen.csharp.CSharpTypeConverter(OuterCSharpNamespace);
    for i=1:length(args)
        if args(i).Kind == matlab.internal.metadata.ArgumentKind.repeating
            continue
        end
        csharpTypes = [csharpTypes, tc.convertArg(args(i))];
    end
end
function generateTypedInterfaceCSharp(targetFolder, nameValuePairs)
    % generateTypedInterfaceCSharp Generate a C# code interface for given MATLAB
    % namespaces, classes, and functions

    %   Copyright 2023 The MathWorks, Inc.

    arguments
        targetFolder (1,1) string  {mustBeNonzeroLengthText}
        nameValuePairs.Namespaces (:,1) string = []
        nameValuePairs.Packages  (:,1) string = []
        nameValuePairs.Classes   (:,1) string = []
        nameValuePairs.Functions (:,1) string = []
        nameValuePairs.DisplayReport   (1,1) logical = 0
        nameValuePairs.SaveReport      {mustBeTextScalar} = ""
        nameValuePairs.FunctionHolderClass (1,1) string = "MATLABFunctions"
        nameValuePairs.OuterCSharpNamespace (1,1) string = ""
    end

    % Confirm that some material for generation has been specified
    if isempty(nameValuePairs.Namespaces) && isempty(nameValuePairs.Packages) && isempty(nameValuePairs.Classes) && isempty(nameValuePairs.Functions)
        messageObj = message("MATLAB:engine_codegen:NoInputList");
        error(messageObj);
    end


    g = matlab.engine.internal.codegen.csharp.CSharpCodeGenerator();
    g.read(Namespaces = nameValuePairs.Namespaces, ...
        Packages=nameValuePairs.Packages, ...
        Classes=nameValuePairs.Classes, ...
        Functions=nameValuePairs.Functions, ...
        FunctionHolderClass=nameValuePairs.FunctionHolderClass, ...
        OuterCSharpNamespace=nameValuePairs.OuterCSharpNamespace);
    g.write(targetFolder, nameValuePairs.DisplayReport, nameValuePairs.SaveReport);

end
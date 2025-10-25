function generateTypedInterfaceCPP(headerFile, nameValuePairs)
    % generateTypedInterfaceCPP Generate a C++ code interface for given MATLAB
    % namespaces, classes, and functions

    %   Copyright 2021-2023 The MathWorks, Inc.

    arguments
        headerFile (1,1) string  {mustBeNonzeroLengthText}
        nameValuePairs.Namespaces (:,1) string = [];
        nameValuePairs.Packages  (:,1) string = []
        nameValuePairs.Classes   (:,1) string = []
        nameValuePairs.Functions (:,1) string = []
        nameValuePairs.DisplayReport   (1,1) logical = 0
        nameValuePairs.SaveReport      {mustBeTextScalar} = ""
    end

    % Confirm that some material for generation has been specified
    if isempty(nameValuePairs.Namespaces) && isempty(nameValuePairs.Packages) && isempty(nameValuePairs.Classes) && isempty(nameValuePairs.Functions)
        messageObj = message("MATLAB:engine_codegen:NoInputList");
        error(messageObj);
    end

    % Overwrite existing files while still allowing g.write() to append in other use-cases
    if isfile(headerFile)
        delete(headerFile);
    end

    g = matlab.engine.internal.codegen.cpp.CPPCodeGenerator();
    g.read(Namespaces = nameValuePairs.Namespaces, ...
        Packages=nameValuePairs.Packages, ...
        Classes=nameValuePairs.Classes, ...
        Functions=nameValuePairs.Functions, ...
        DisplayReport=nameValuePairs.DisplayReport, ...
        SaveReport=nameValuePairs.SaveReport);
    g.write(headerFile);

end
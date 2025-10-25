function compareGeneratedCodeToFileCode (currentGeneratedCode, mlappFilePath, originalCodeDesc, currentCodeDesc)
% compares the code in currentGeneratedCode to the code in the mlapp file provided
% by mlappFilePath

% Copyright 2017-2020 The MathWorks, Inc.

    import appdesigner.internal.codegeneration.*

    % Build the titles
    [~, name, extension] = fileparts(mlappFilePath);
    titleForOriginalCode = [name,extension,' (',originalCodeDesc,')'];
    titleForCurrentCode = [name,extension,' (',currentCodeDesc,')'];

    originalGeneratedCode = getAppFileCode(mlappFilePath);

    % Create the comparison sources
    s1 = comparisons.internal.text.makeStringSource(titleForOriginalCode, originalGeneratedCode);
    s2 = comparisons.internal.text.makeStringSource(titleForCurrentCode, currentGeneratedCode );

    comparisons.internal.text.startComparison(s1, s2);

end

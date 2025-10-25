function helpStr = mlappFile(fullPath, justH1)
    %MLAPPFILE Provides the help text for MATLAB MLAPP files

    %   Copyright 2021 The MathWorks, Inc.

    if nargin < 2
        justH1 = false;
    end

    getFileTextFcn = @(fullPath) matlab.internal.getcode.mlappfile(fullPath);

    helpStr = matlab.internal.help.getMFileHelpText(fullPath, getFileTextFcn, justH1);
end
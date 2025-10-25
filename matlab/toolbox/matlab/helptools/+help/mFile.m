function helpStr = mFile(fullPath, justH1)
    %help.mFile Provides the help text for MATLAB files.

    %   Copyright 2018-2022 The MathWorks, Inc.

    if nargin < 2
        justH1 = false;
    end

    getFileTextFcn = @matlab.internal.getcode.mfile;

    helpStr = matlab.internal.help.getMFileHelpText(fullPath, getFileTextFcn, justH1);
end

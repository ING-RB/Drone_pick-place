classdef FileType
%matlab.codeanalyzer.internal.FileType represents the MATLAB file type.

%   Copyright 2020-2024 The MathWorks, Inc.

    enumeration
        ScriptFile
        FunctionFile
        ClassdefFile
        % When there is a syntax error and not enough information to
        % determine the file type
        Unknown
    end
end

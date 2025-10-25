function analysis = analyzeFile(file, options)
%matlab.codeanalyzer.internal.analyzeFile return Analysis object
%that stores MATLAB code information
%
%   analysis = matlab.codeanalyzer.internal.analyzeFile(file) analyze the
%   file and return Analysis object when there is no syntax error in the 
%   file.
%
%   analysis = matlab.codeanalyzer.internal.analyzeFile(..., 'AllowSyntaxError', true)
%   will try to analyze the file and return the Analysis object, even when
%   the input file has syntax error.

%   Copyright 2020-2024 The MathWorks, Inc.

    arguments
        % Input MATLAB file name
        file {mustBeTextScalar}
        options.AllowSyntaxError (1,1) logical = false;
    end
    code = matlab.internal.getCode(convertStringsToChars(file));
    analysis = matlab.codeanalyzer.internal.analyzeCode(code, AllowSyntaxError=options.AllowSyntaxError);
end

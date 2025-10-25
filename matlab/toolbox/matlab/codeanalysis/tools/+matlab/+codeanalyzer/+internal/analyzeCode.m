function analysis = analyzeCode(code, options)
%matlab.codeanalyzer.internal.analyzeCode return Analysis object
%that stores MATLAB code information
%
%   analysis = matlab.codeanalyzer.internal.analyzeCode(code) analyze the
%   code and return Analysis object when there is no syntax error in the 
%   code.
%
%   analysis = matlab.codeanalyzer.internal.analyzeCode(..., 'AllowSyntaxError', true)
%   will try to analyze the code and return the Analysis object, even when
%   the input code has syntax error.

%   Copyright 2020-2024 The MathWorks, Inc.

    arguments
        % Input MATLAB code string
        code {mustBeTextScalar}
        options.AllowSyntaxError (1,1) logical = false;
    end
    if (options.AllowSyntaxError)
        builtinResult = matlab.codeanalyzer.internal.analyzeCodeBuiltin(convertStringsToChars(code));
    else
        try
            builtinResult = matlab.codeanalyzer.internal.analyzeParsableCodeBuiltin(convertStringsToChars(code));
        catch cause
            errID = 'MATLAB:codeanalyzer:SyntaxError';
            msg = message(errID);
            baseException = MException(errID, msg);
            baseException = addCause(baseException, MException(cause.identifier, cause.message));
            throw(baseException);
        end
    end
    analysis = matlab.codeanalyzer.internal.Analysis(builtinResult);
end

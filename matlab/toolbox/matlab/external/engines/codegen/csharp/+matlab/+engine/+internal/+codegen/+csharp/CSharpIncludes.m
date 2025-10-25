classdef CSharpIncludes
    % This class writes the Includes and Comments for C# files
    % the comments and includes will have the following format:
    % /* File: foo.cs
    % *
    % * MATLAB Strongly Typed Interface Version: R2023b
    % * C# source code generated on: Febraurary 12 2023
    % */
    %
    % using System;
    % using MathWorks.MATLAB.Types;
    % using MathWorks.MATLAB.Exceptions;

    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties
        Comments = "/* File: [FileName]" + newline +...
        "*" + newline + ...
        "*" + " MATLAB Strongly Typed Interface Version: [VersionToken]" + newline +...
        "*" + " C# source code generated on: [DateToken]" + newline + ...
        "*/" + newline;

        Header = "using System;" + newline + ...
        "using MathWorks.MATLAB.Types;" + newline + ...
        "using MathWorks.MATLAB.Exceptions;" +newline;
    end
    
    methods
        function ret = string(obj)
            ret = obj.Comments + obj.Header;
            versionInfo = extractBetween(version, "(", ")");
            ret = replace(ret, "[VersionToken]", versionInfo);
            ret = replace(ret, "[DateToken]",string(datetime("today")));
        end
        
    end
end
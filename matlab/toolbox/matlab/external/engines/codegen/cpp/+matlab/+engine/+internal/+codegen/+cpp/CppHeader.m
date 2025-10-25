classdef CppHeader
    %HeaderTpl Holds header data

%   Copyright 2020-2023 The MathWorks, Inc.
    
    properties
        Includes = "#include ""MatlabTypesInterface.hpp""" + newline + ...
        "#include <map>" + newline;  % std::map for enum support
        Comments =  "/* File: [FileName]" + newline +...
        "*" + newline + ...
        "*" + " MATLAB Strongly Typed Interface Version: [VersionToken]" + newline +...
        "*" + " C++ source code generated on: [DateToken]" + newline + ...
        "*/" + newline;
    end
    
    methods
        function ret = string(obj, fileName)
            ret = obj.Comments + obj.Includes;
            versionInfo = extractBetween(version, "(", ")");
            ret = replace(ret, "[VersionToken]", versionInfo);
            ret = replace(ret, "[DateToken]",string(datetime("today")));
            ret = replace(ret, "[FileName]", fileName);
        end
        
    end
end


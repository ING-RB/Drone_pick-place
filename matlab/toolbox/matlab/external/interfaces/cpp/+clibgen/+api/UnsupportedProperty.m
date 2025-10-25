classdef (Sealed)UnsupportedProperty < clibgen.api.UnsupportedSymbol
%

%   Copyright 2024 The MathWorks, Inc.

    properties(GetAccess=public, SetAccess=private)
        CPPName          string        
        CPPType          string
        ClassName        string
    end
    methods
        function obj = UnsupportedProperty(fileName, filePath, lineNum, reason, className, cppName, cppType)
            obj = obj@clibgen.api.UnsupportedSymbol(fileName, filePath, lineNum, reason)
            obj.ClassName = className;
            obj.CPPName = cppName;
            obj.CPPType = cppType;
        end
    end
end
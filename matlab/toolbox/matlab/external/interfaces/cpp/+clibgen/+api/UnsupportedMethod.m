classdef (Sealed)UnsupportedMethod < clibgen.api.UnsupportedSymbol
%

%   Copyright 2024 The MathWorks, Inc.

    properties(GetAccess=public, SetAccess=private)
        ClassName        string
        CPPName          string
        CPPSignature     string
    end
    methods
        function obj = UnsupportedMethod(fileName, filePath, lineNum, reason, className, cppSignature, cppName)
            obj = obj@clibgen.api.UnsupportedSymbol(fileName, filePath, lineNum, reason)
            obj.ClassName = className;
            obj.CPPName = cppName;
            obj.CPPSignature = cppSignature;
        end
    end
end
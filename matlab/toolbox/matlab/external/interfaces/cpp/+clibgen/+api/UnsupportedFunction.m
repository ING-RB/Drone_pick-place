classdef (Sealed)UnsupportedFunction < clibgen.api.UnsupportedSymbol
%

%   Copyright 2024 The MathWorks, Inc.

    properties(GetAccess=public, SetAccess=private)
        CPPName          string
        CPPSignature     string
    end
    methods
        function obj = UnsupportedFunction(fileName, filePath, lineNum,  reason, cppSignature, cppName)
            obj = obj@clibgen.api.UnsupportedSymbol(fileName, filePath, lineNum, reason)
            obj.CPPSignature = cppSignature;
            obj.CPPName = cppName;
        end
    end
end
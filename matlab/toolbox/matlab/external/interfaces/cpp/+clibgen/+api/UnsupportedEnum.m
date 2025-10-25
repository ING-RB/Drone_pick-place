classdef (Sealed)UnsupportedEnum < clibgen.api.UnsupportedSymbol
%

%   Copyright 2024 The MathWorks, Inc.

    properties(GetAccess=public, SetAccess=private)
        CPPName          string
        CPPSignature     string
        CPPType          string
    end
    methods
        function obj = UnsupportedEnum(fileName, filePath, lineNum, cppSignature, reason, cppName, cppType)
            obj = obj@clibgen.api.UnsupportedSymbol(fileName, filePath, lineNum, reason)
            obj.CPPSignature = cppSignature;
            obj.CPPName = cppName;
            obj.CPPType = cppType;
        end
    end
end
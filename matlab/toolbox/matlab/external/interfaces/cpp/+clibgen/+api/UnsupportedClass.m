classdef (Sealed)UnsupportedClass < clibgen.api.UnsupportedSymbol
%

%   Copyright 2024 The MathWorks, Inc.

    properties(GetAccess=public, SetAccess=private)
        CPPName          string
    end
    methods
        function obj = UnsupportedClass(fileName, filePath, lineNum, reason, cppName)
            obj = obj@clibgen.api.UnsupportedSymbol(fileName, filePath, lineNum, reason)
            obj.CPPName = cppName;
        end
    end
end
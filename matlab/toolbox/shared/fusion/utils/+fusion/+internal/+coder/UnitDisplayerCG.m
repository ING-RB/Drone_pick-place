classdef (Hidden, HandleCompatible) UnitDisplayerCG
%UNITDISPLAYERCG - Codegen class for fusion.internal.UnitDisplayer
%
%   This class is for internal use only. It may be removed in the future.

%   Copyright 2020 The MathWorks, Inc.

%#codegen

    methods (Static, Hidden)
        function name = matlabCodegenUserReadableName
            name = 'fusion.internal.UnitDisplayer';
        end
    end
end

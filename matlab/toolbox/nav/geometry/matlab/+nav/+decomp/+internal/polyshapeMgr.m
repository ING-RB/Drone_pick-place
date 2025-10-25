classdef polyshapeMgr < nav.decomp.internal.valueArrayManager
%This function is for internal use only. It may be removed in the future.

%   Copyright 2024 The MathWorks, Inc.

%polyshapeMgr Container for spoofing polyshape-arrays in MATLAB

%#codegen
    properties (Hidden,Constant)
        ManagedClassType = 'polyshape';
        Ctor = 'nav.decomp.internal.polyshapeMgr';
    end
    methods (Static = true)
        function name = matlabCodegenRedirect(codegenTargetName)
            name = 'nav.decomp.internal.coder.polyshapeMgr';
        end
    end
end

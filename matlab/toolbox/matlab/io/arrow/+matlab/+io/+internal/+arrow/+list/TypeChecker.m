classdef TypeChecker < matlab.mixin.Heterogeneous
%TYPECHECKER Abstract class that defines the TypeChecker interface.

% Copyright 2022 The MathWorks, Inc.

    methods(Abstract)
        checkType(obj, array)
    end

    methods(Static, Sealed, Access = protected)
        function obj = getDefaultScalarElement()
            import matlab.io.internal.arrow.list.ClassTypeChecker
            obj = ClassTypeChecker("double");
        end
    end
end

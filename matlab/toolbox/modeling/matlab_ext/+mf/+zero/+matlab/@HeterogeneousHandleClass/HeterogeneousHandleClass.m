% Copyright 2024 The MathWorks, Inc.
classdef  HeterogeneousHandleClass < mf.zero.matlab.HandleClass & matlab.mixin.Heterogeneous
    methods (Sealed)
        function result = eq(lhs, rhs)
            % Used for heterogeneous arrays eq
            result = eq@handle(lhs,rhs);
        end
    end
end
 
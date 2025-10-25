classdef DenseLU < matlab.mixin.internal.Scalar
    % DENSELU   LU decomposition of a dense, square matrix
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    %
    
    %   Copyright 2017-2020 The MathWorks, Inc.
    
    properties (Access = private)
        LU_
        piv_
        normA1_
    end
    
    methods
        function f = DenseLU(A)
            [f.LU_,f.piv_,f.normA1_] = matlab.internal.decomposition.builtin.luFactor(A);
        end
        
        function rc = rcond(f)
            rc = matlab.internal.decomposition.builtin.luRcond(f.LU_,f.normA1_);
        end
        
        function x = solve(f,b,transposed)
            x = matlab.internal.decomposition.builtin.luSolve(f.LU_,f.piv_,b,transposed);
        end
    end
end

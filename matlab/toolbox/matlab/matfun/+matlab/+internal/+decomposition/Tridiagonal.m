classdef Tridiagonal < matlab.mixin.internal.Scalar
    % TRIDIAGONAL   LU decomposition of a tridiagonal matrix
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    %
    
    %   Copyright 2017-2024 The MathWorks, Inc.
    
    properties (Access = private)
        LU_
        U2_
        piv_
        info_
    end
    
    methods
        function f = Tridiagonal(A)
            % Input matrix must be square, and sparse. The upper and lower 
            % bandwidth must both be 1.
            [f.LU_, f.U2_, f.piv_, f.info_] = ...
                matlab.internal.decomposition.builtin.tridiagFactor(A);
        end

        function rc = rcond(f)
            if f.info_ > 0
                rc = 0;
            else
                rc = matlab.internal.decomposition.builtin.tridiagRcond(f.LU_);
            end
        end
        
        function x = solve(f,b,transposed)
            x = matlab.internal.decomposition.builtin.tridiagSolve(...
                f.LU_, f.U2_, f.piv_, b, transposed);
        end
    end
end

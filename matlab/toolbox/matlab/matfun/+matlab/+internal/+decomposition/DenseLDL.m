classdef DenseLDL < matlab.mixin.internal.Scalar
    % DENSELDL   LDL decomposition of a dense symmetric indefinite matrix
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    %
    
    %   Copyright 2017-2020 The MathWorks, Inc.
    
    properties (Access = private)
        L_
        ddfac_
        ipiv_
        normA1_
        info_
    end
    
    methods
        function f = DenseLDL(A)
            [f.L_, f.ddfac_, f.ipiv_, f.normA1_, f.info_] = ...
                matlab.internal.decomposition.builtin.ldlFactor(A);
        end
        
        function rc = rcond(f)
            if f.info_ ~= 0
                rc = zeros(class(f.L_));
            else
                rc = matlab.internal.decomposition.builtin.ldlRcond(...
                    f.L_, f.ddfac_, f.normA1_);
            end
        end
        
        function x = solve(f,b,~)
            x = matlab.internal.decomposition.builtin.ldlSolve(...
                f.L_, f.ddfac_, f.ipiv_, b);
        end
    end
end

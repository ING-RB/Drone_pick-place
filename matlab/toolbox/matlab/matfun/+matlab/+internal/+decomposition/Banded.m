classdef Banded < matlab.mixin.internal.Scalar
    % BANDED   LU decomposition of a banded matrix
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    %
    
    %   Copyright 2017-2023 The MathWorks, Inc.
    
    properties (Access = private)
        LU_
        kl_
        ku_
        piv_
        info_
    end
    
    methods
        function f = Banded(A, kl, ku)            
            f.kl_ = kl;
            f.ku_ = ku;
            
            [f.LU_, f.piv_, f.info_] = matlab.internal.decomposition.builtin.bandedFactor(A, kl, ku);
        end
        
        function rc = rcond(f)
            if f.info_ > 0
                rc = 0;
            else
                rc = matlab.internal.decomposition.builtin.bandedRcond(f.LU_, f.kl_, f.ku_);
            end
        end
        
        function x = solve(f,b,transposed)
            
            sparseOut = issparse(b);
            if sparseOut
                b = full(b);
            end
            
            x = matlab.internal.decomposition.builtin.bandedSolve(...
                f.LU_, f.kl_, f.ku_, f.piv_, b, transposed);
            
            if sparseOut
                x = sparse(x);
            end
        end
    end
end

classdef SparseLU < matlab.mixin.internal.Scalar
    % SPARSELU   LU decomposition of a sparse matrix
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    %
    
    %   Copyright 2017-2022 The MathWorks, Inc.
    
    properties (Access = private)
        n_
        umfpack_
        pivtol_
        sympivtol_
        useMinDegree_
    end
    
    methods
        function f = SparseLU(A, pivtol, sympivtol, useMinDegree, iterRef)
            f.n_ = size(A, 1);
            if iterRef
                f.umfpack_ = matlab.internal.decomposition.builtin.UMFPACKWrapper(A, pivtol, sympivtol, useMinDegree);
            else
                f.umfpack_ = matlab.internal.decomposition.builtin.UMFPACKWrapper(A, pivtol, sympivtol, useMinDegree, 0);
            end
            f.pivtol_ = pivtol;
            f.sympivtol_ = sympivtol;
            f.useMinDegree_ = useMinDegree;
        end
        
        function rc = rcond(f)
            rc = rcond(f.umfpack_);
        end
        
        function x = solve(f,b,transposed)
            x = solve(f.umfpack_, b, transposed);
        end
    end
end

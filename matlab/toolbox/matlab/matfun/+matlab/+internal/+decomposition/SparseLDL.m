classdef SparseLDL < matlab.mixin.internal.Scalar
    % SPARSELDL   LDL decomposition of a sparse symmetric indefinite matrix
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    %
    
    %   Copyright 2017-2022 The MathWorks, Inc.
    
    properties (Access = private)
        n_
        ma57_
        pivtol_
        useMinDegree_
        useIterativeRefinement_
    end
    
    methods
        function f = SparseLDL(A, pivtol, useMinDegree, useIterativeRefinement)
            f.n_ = size(A, 1);
            
            f.ma57_ = matlab.internal.decomposition.builtin.MA57Wrapper(A, pivtol, useMinDegree);
            f.pivtol_ = pivtol;
            f.useMinDegree_ = useMinDegree;
            f.useIterativeRefinement_ = useIterativeRefinement;
        end
        
        function rc = rcond(f)
            rc = rcond(f.ma57_);
        end
        
        function x = solve(f, b, ~)
            x = solve(f.ma57_, b, f.useIterativeRefinement_);
        end
    end
end

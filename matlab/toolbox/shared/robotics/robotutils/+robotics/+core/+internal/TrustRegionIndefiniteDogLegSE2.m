classdef TrustRegionIndefiniteDogLegSE2 < robotics.core.internal.TrustRegionIndefiniteDogLegInterface
    %This class is for internal use only. It may be removed in the future.
    
    %TRUSTREGIONINDEFINITEDOGLEGSE2
    
    %   Copyright 2017-2020 The MathWorks, Inc.
    
    %#codegen
    
    properties (Constant)
        TformBlockSize = [3 3]
        EpsilonBlockSize = [3 1]
    end
 
    properties (Dependent, SetAccess = protected)
        
        %Name Solver name
        Name
        
    end
    
    methods
        function obj = TrustRegionIndefiniteDogLegSE2()
            %TrustRegionIndefiniteDogLegSE2 Constructor
            obj.MaxTime = 500;
            obj.InitialTrustRegionRadius = 100;
            obj.FunctionTolerance = 1e-8;
            
            % The Hessian matrix formed thru nav.algs.internal.PoseGraphHelpers.poseGraphCost 
            % should always be positive definite
            obj.SkipPDCheck = true;
            
        end
        
        function nm = get.Name(~)
            %get.Name
            nm = 'Trust-Region-Dogleg-SE2';
        end
        
    end
                   
    
    methods (Access = protected)
        function [x, xSol] = initializeInternal(obj)
           %initializeInternal
           
           x = obj.SeedInternal; % internal state
           xSol = robotics.core.internal.BlockMatrix(x, obj.TformBlockSize); % initialize solution
            
        end
        
        function xSol = updateSolution(obj, x)
            %updateSolution
            xSol = robotics.core.internal.BlockMatrix(x, obj.TformBlockSize);
        end
        
        function xNew = incrementX(obj, x, epsilons)
            %incrementX Update optimization variable x with incremental
            %   change epsilons
            %
            %   x - internal state with size 3 x 3n
            %   epsilons - local step with size 3 x n
            %   where n is the number of poses in x

            xBlk = robotics.core.internal.BlockMatrix(x, obj.TformBlockSize);
            n = xBlk.NumRowBlocks;
            m = xBlk.NumColBlocks;
            
            xBlkNew = robotics.core.internal.BlockMatrix(n, m, obj.TformBlockSize);

            for i = 1:n
                T = xBlk.extractBlock(i, 1);
                idx = obj.ExtraArgs.nodeMap(i);
                len = obj.ExtraArgs.nodeDims(i);
                if len == 3
                    epsilon = epsilons(idx:idx+len-1);
                    ct = T(1,1);
                    st = T(2,1);
                    theta = atan2(st, ct);
                    v = [T(1:2,3); theta];
                    xBlkNew.replaceBlock(i,1, robotics.core.internal.SEHelpers.poseToTformSE2(v+epsilon));
                else
                    epsilon = epsilons(idx:idx+len-1);
                    T(1:2,3) = T(1:2,3) + epsilon;
                    xBlkNew.replaceBlock(i,1,T);
                end

            end
            
            xNew = xBlkNew.Matrix(:,1:obj.TformBlockSize(1));
        end
        
        
        function defaultObj = getDefaultObject(~)
            %getDefaultObject
            defaultObj = robotics.core.internal.TrustRegionIndefiniteDogLegSE2;
        end        
        
        function [lambda, v] = eigSmallest(~, B)
            %eigSmallest Compute the smallest eigenvalue and the corresponding eigenvector for the Hessian matrix
            
            % eig can only calculate the eigenvalues of sparse matrices
            % that are real and symmetric, but not the eigenvectors.
            
            [v, lambda] = eigs(B, 1, 'sm');
        end
    end
    

end


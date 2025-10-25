classdef TrustRegionIndefiniteDogLegSE3 < robotics.core.internal.TrustRegionIndefiniteDogLegInterface
    %This class is for internal use only. It may be removed in the future.
    
    %TRUSTREGIONINDEFINITEDOGLEGSE3
    
    %   Copyright 2017-2020 The MathWorks, Inc.
    
    %#codegen
    
    properties (Constant)
        TformBlockSize = [4 4]
        EpsilonBlockSize = [6 1]
    end
 
    properties (Dependent, SetAccess = protected)
        
        %Name Solver name
        Name
        
    end
    
    methods
        function obj = TrustRegionIndefiniteDogLegSE3()
            %TrustRegionIndefiniteDogLegSE3 Constructor
            obj.MaxTime = 500;
            obj.InitialTrustRegionRadius = 100;
            obj.FunctionTolerance = 1e-8;
            % The Hessian matrix formed thru nav.algs.internal.PoseGraphHelpers.poseGraphCost 
            % should always be positive definite
            obj.SkipPDCheck = true;
            
        end
        
        function nm = get.Name(~)
            %get.Name
            nm = 'Trust-Region-Dogleg-SE3';
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
            %   x - internal state with size 4n x 4
            %   epsilons - local step with size 6n x 1
            %   where n is the number of poses in x

            xBlk = robotics.core.internal.BlockMatrix(x, obj.TformBlockSize);
            n = xBlk.NumRowBlocks;
            m = xBlk.NumColBlocks;

            xBlkNew = robotics.core.internal.BlockMatrix(n, m, obj.TformBlockSize);

            % Defining epsilonHat as variable sized matrix to fix
            % codegen issue with expm function on windows platform. expm
            % mexed execution output is very different from interpreted
            % execution when epsilonHat is expected to be 4x4 fixed size
            % matrix at compile time.
            coder.varsize('epsilonHat',[inf,inf],[1,1]);
            for i = 1:n
                T = xBlk.extractBlock(i, 1);
                idx = obj.ExtraArgs.nodeMap(i);
                len = obj.ExtraArgs.nodeDims(i);
                epsilon = epsilons(idx:idx+len-1);
                if len == 6
                    % here T is an SE3 pose. 
                    % epsilon is the increment in the tangent space of T
                    % we need to retract it back to the manifold
                    Tepsilon = robotics.core.internal.SEHelpers.expSE3hat(epsilon(1:6));
                    xBlkNew.replaceBlock(i, 1, T*robotics.core.internal.SEHelpers.tforminvSE3(Tepsilon));
                else
                    T(1:3,4) = T(1:3,4) + epsilon;
                    xBlkNew.replaceBlock(i,1,T);
                end
            end
            
            xNew = xBlkNew.Matrix(:,1:obj.TformBlockSize(1));
        end
        
        
        function defaultObj = getDefaultObject(~)
            %getDefaultObject
            defaultObj = robotics.core.internal.TrustRegionIndefiniteDogLegSE3;
        end        
        
        function [lambda, v] = eigSmallest(~, B)
            %eigSmallest Compute the smallest eigenvalue and the corresponding eigenvector for the Hessian matrix
            
            % eig can only calculate the eigenvalues of sparse matrices
            % that are real and symmetric, but not the eigenvectors.
             
            [v, lambda] = eigs(B, 1, 'sm');
        end       
    end
    

end

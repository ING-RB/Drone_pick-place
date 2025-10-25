classdef TrustRegionIndefiniteDogLegSim3 < robotics.core.internal.TrustRegionIndefiniteDogLegInterface
    %This class is for internal use only. It may be removed in the future.
    
    %TRUSTREGIONINDEFINITEDOGLEGSIM3 class for trsut region non linear
    %   solver which minimizes sim3 cost function accepting similarity graph
    %   constraints as input.
    
    %   Copyright 2019 The MathWorks, Inc.
    
    %#codegen
    
    properties (Constant)
        TformBlockSize = [4 4]
        EpsilonBlockSize = [7 1]
    end
 
    properties (Dependent, SetAccess = protected)
        
        %Name Solver name
        Name
        
    end
    
    methods
        function obj = TrustRegionIndefiniteDogLegSim3()
            %TrustRegionIndefiniteDogLegSim3 Constructor
            obj.MaxTime = 500;
            obj.InitialTrustRegionRadius = 100;
            obj.FunctionTolerance = 1e-8;
            if coder.target('MATLAB')
                obj.SkipPDCheck = false;
            else
                obj.SkipPDCheck = true;
            end
        end
        
        function nm = get.Name(~)
            %get.Name
            nm = 'Trust-Region-Dogleg-Sim3';
        end
        
    end
                   
    methods (Access = protected)
        function [x, xSol] = initializeInternal(obj)
           %initializeInternal returns the initial guess in matrix form (x)
           %   and in Block Matrix form (xSol)
           
           x = obj.SeedInternal; % internal state
           xSol = robotics.core.internal.BlockMatrix(x, obj.TformBlockSize); % initialize solution
            
        end
        
        function xSol = updateSolution(obj, x)
            %updateSolution return the block matrix form of the updated solution x
            
            xSol = robotics.core.internal.BlockMatrix(x, obj.TformBlockSize);
        end
        
        function xNew = incrementX(obj, x, epsilons)
            %incrementX Update optimization variable x with incremental
            %   change epsilons
            %
            %   x - internal state with size 4n x 4
            %   epsilons - local step with size 7n x 1
            %   where n is the number of poses in x

            xBlk = robotics.core.internal.BlockMatrix(x, obj.TformBlockSize);
            n = xBlk.NumRowBlocks;
            m = xBlk.NumColBlocks;
            epsilonsBlk = robotics.core.internal.BlockMatrix(epsilons, obj.EpsilonBlockSize);
            xBlkNew = robotics.core.internal.BlockMatrix(n, m, obj.TformBlockSize);

            for i = 1:n
                pose = xBlk.extractBlock(i, 1);
                epsilon = epsilonsBlk.extractBlock(i,1);
                
                epsilonT = robotics.core.internal.Sim3Helpers.sim3ToSform(epsilon(1:7,1));
                xBlkNew.replaceBlock(i, 1, robotics.core.internal.Sim3Helpers.sformMultiplySim3(pose,robotics.core.internal.Sim3Helpers.sforminvSim3(epsilonT)));
            end
            
            xNew = xBlkNew.Matrix(:,1:obj.TformBlockSize(1));
        end
        
        
        function defaultObj = getDefaultObject(~)
            %getDefaultObject returns the default trust region solver 
            
            defaultObj = robotics.core.internal.TrustRegionIndefiniteDogLegSim3;
        end        
        
        function [lambda, v] = eigSmallest(~, B)
            %eigSmallest Compute the smallest eigenvalue and the corresponding eigenvector for the Hessian matrix
            
            % eig can only calculate the eigenvalues of sparse matrices
            % that are real and symmetric, but not the eigenvectors.
             
            [v, lambda] = eigs(B, 1, 'sm');
        end       
    end
    

end

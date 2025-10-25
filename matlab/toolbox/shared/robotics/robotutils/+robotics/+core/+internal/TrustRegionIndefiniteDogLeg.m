classdef TrustRegionIndefiniteDogLeg < robotics.core.internal.TrustRegionIndefiniteDogLegInterface
    %This class is for internal use only. It may be removed in the future.
    
    %TRUSTREGIONINDEFINITEDOGLEG Solver for unconstrained nonlinear problem.
    %   
    %   
    %
    %   References:
    %
    %   [1] J. Nocedal and S. Wright, Numerical Optimization (Second Ed.)
    %   Springer, New York, 2006 
    
        
    %   Copyright 2016-2019 The MathWorks, Inc.
    
    %#codegen
    
    properties (Dependent, SetAccess = protected)
        
        %Name Solver name
        Name
        
    end
    
    
    methods
        function obj = TrustRegionIndefiniteDogLeg()
            %TrustRegionIndefiniteDogLeg Constructor
            obj.SkipPDCheck = false;
        end
        
        function nm = get.Name(~)
            %get.Name
            nm = 'Trust-Region-Dogleg';
        end
        
    end

    methods (Access = protected)
                   
        function [x, xSol] = initializeInternal(obj)
           %initializeInternal
           x = obj.SeedInternal;  % internal state
           xSol = x;              % initialize solution
        end
        
        function xSol = updateSolution(~, x)
            %updateSolution
            xSol = x;
        end
       
        function xnew = incrementX(~, x, step)
            %incrementX
            xnew = x + step;
        end        
        
        function defaultObj = getDefaultObject(~)
            %getDefaultObject
            defaultObj = robotics.core.internal.TrustRegionIndefiniteDogLeg;
        end
        
        function [lambda, v] = eigSmallest(~, B)
            %eigSmallest Compute the smallest eigenvalue and the corresponding eigenvector for the Hessian matrix
            [V, D] = eig(B); % will be slow if dimension of B is large
            [lambda, idx] = min(diag(real(D)));
            v = V(:,idx);
        end
    end
    

end


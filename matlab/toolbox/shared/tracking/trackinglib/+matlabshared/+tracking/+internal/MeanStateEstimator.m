classdef MeanStateEstimator < matlabshared.tracking.internal.StateEstimator
    %MeanStateEstimator Calculate weighted mean and covariance of all particles
    %   This estimator calculates the weighted sample mean and weighted
    %   sample covariance of all particles.
    %   The mean and covariance are also the maximum-likelihood estimates
    %   for the parameters of a multi-variate Gaussian distribution, N(mean,
    %   cov). 
    %   This function estimates the unbiased covariance matrix.
    %
    %   References:
    %   [1] I.M. Rekleitis, "A particle filter tutorial for mobile robot localization," 
    %   Centre for Intelligent Machines, McGill University, Tech. Rep. 
    %   TR-CIM-04-02, 2004.
    %
    %   [2] G.R. Price, "Extension of covariance selection mathematics," 
    %   Annals of Human Genetics, vol. 35, no. 4, pp. 485-490, 1972.
    
    %   Copyright 2015-2018 The MathWorks, Inc.
    
    %#codegen

    methods
        function varargout = estimate(obj, particleManager, particles, weights, isCircVar)
            %estimate Estimate state based on set of particles and weights
            %
            %   STATEEST = ESTIMATE(OBJ, PARTICLES, WEIGHTS, ISCIRCVAR) extracts the
            %   state estimate from the set of PARTICLES (N-by-M matrix).
            %   Each particle has a corresponding weight in WEIGHTS (N-by-1 vector).
            %   The extracted state estimate will be returned in STATEEST.
            %   Use the ISCIRCVAR vector (1-by-M vector) to specify which
            %   state variables are circular.
            %   It is assumed that the WEIGHTS are normalized, so that their
            %   sum equals 1.
            %
            %   [STATEEST, STATECOV] = ESTIMATE(OBJ, ___) also returns the
            %   covariance around the state estimate in STATECOV. If the state estimation
            %   method does not support calculating covariance, STATECOV will
            %   be an empty array [].
            
            nargoutchk(0,2);           
            
            obj.assertPreconditions(particleManager, particles, weights, isCircVar); 
            
            numStateVars = length(isCircVar);
            numCircular = sum(isCircVar);
            numNonCircular = length(isCircVar) - numCircular;
            
            % Return quickly if there are no circular state variables
            if numCircular == 0
                [varargout{1:nargout}] = matlabshared.tracking.internal.NormalDistribution.fitToSamples(particles, weights, particleManager.StateOrientation);
                return;
            end
            
            % Return quickly if all state variables are circular
            if numNonCircular == 0
                [varargout{1:nargout}] = matlabshared.tracking.internal.WrappedNormalDistribution.fitToSamples(particles, weights, particleManager.StateOrientation);
                return;
            end
            
            % We have a mixture of circular and non-circular state variables
            isCircVarLogical = logical(isCircVar);
            
            % Estimate mean and covariance for non-circular state variables
            nonCircMeanCov = cell(1,nargout);
            [nonCircMeanCov{1:nargout}] = matlabshared.tracking.internal.NormalDistribution.fitToSamples(...
                particleManager.getStates(particles,~isCircVarLogical), weights, particleManager.StateOrientation);
            
            % Estimate mean and variances for circular state variables
            circMeanCov = cell(1,nargout);
            [circMeanCov{1:nargout}] = matlabshared.tracking.internal.WrappedNormalDistribution.fitToSamples(...
                particleManager.getStates(particles,isCircVarLogical), weights, particleManager.StateOrientation);
            
            assert(length(nonCircMeanCov{1}) + length(circMeanCov{1}) == numStateVars);
            
            % Assemble output
            % Always return mean
            stateEstimate = particleManager.allocateMemoryStates(numStateVars,class(particles));
            stateEstimate(~isCircVarLogical) = nonCircMeanCov{1};
            stateEstimate(isCircVarLogical) = circMeanCov{1};
            varargout{1} = stateEstimate;
            
            if nargout == 2
                % Also return covariance if there are 2 output arguments
                stateCov = eye(numStateVars,'like',particles);
                stateCov(~isCircVarLogical, ~isCircVarLogical) = nonCircMeanCov{2};
                stateCov(isCircVarLogical, isCircVarLogical) = circMeanCov{2};
                varargout{2} = stateCov;
            end           
        end
    end
    
end

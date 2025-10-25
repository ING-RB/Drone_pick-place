classdef MaxWeightStateEstimator < matlabshared.tracking.internal.StateEstimator
    %MaxWeightStateEstimator Estimate state from the particle with the highest weight
    %   Find the particle with the highest weight and use it as state
    %   estimate. Note that this estimation is only meaningful before
    %   resampling, since all weights are equal afterwards.
    %
    %   Reference:
    %   I.M. Rekleitis, "A particle filter tutorial for mobile robot localization," 
    %   Centre for Intelligent Machines, McGill University, Tech. Rep. 
    %   TR-CIM-04-02, 2004.
    
    %   Copyright 2015-2017 The MathWorks, Inc.
    
    %#codegen
    
    methods
        function [stateEstimate, stateCov] = estimate(obj, particleManager, particles, weights, isCircVar)
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

            obj.assertPreconditions(particleManager, particles, weights, isCircVar);
            
            % The covariance is not defined for a single particle
            stateCov = [];

            % Find maximum weight and extract the corresponding particle
            [~, maxIdx] = max(weights);
            stateEstimate = particleManager.getParticles(particles, maxIdx);
            
            % Wrap circular variables if necessary
            if any(isCircVar)
                stateEstimate(isCircVar) = matlabshared.tracking.internal.wrapToPi(stateEstimate(isCircVar));
            end
        end
    end
    
end


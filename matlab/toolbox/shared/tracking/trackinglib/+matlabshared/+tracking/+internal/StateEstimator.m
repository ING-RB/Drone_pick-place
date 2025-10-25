classdef (Abstract) StateEstimator < handle
    %StateEstimator Base class for all state estimation methods
    %   All derived classes need to implement an "estimate" method.
    
    %   Copyright 2015-2018 The MathWorks, Inc.
    
    %#codegen
    
    methods (Abstract)
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
        [stateEst, stateCov] = estimate(obj, particles, weights, isCircVar)
    end
    
    methods (Static, Access = protected)
        function assertPreconditions(particleManager, particles, weights, isCircVar)
            %assertPreconditions Ensure preconditions for estimation are met
            
            % Assert that inputs are non-empty
            assert(~isempty(particleManager));
            assert(~isempty(particles));
            assert(~isempty(weights));
            assert(~isempty(isCircVar));
            
            % Assert that inputs are of compatible size
            assert(isvector(weights));
            particleManager.validateSizeParticlesWeights(particles,weights);
            particleManager.validateSizeParticlesCircularVariables(particles,isCircVar);
                
            % Assert that weights are normalized
            assert(abs(sum(weights) - 1.0) < sqrt( eps(class(weights))) );
        end
    end
    
end


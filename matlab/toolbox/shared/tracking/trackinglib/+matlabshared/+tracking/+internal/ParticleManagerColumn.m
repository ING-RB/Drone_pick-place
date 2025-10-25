classdef ParticleManagerColumn < matlabshared.tracking.internal.ParticleManager
    %
    
    % Object responsible for particles' assignment operations in
    % ParticleFilter when a particle has dimensions [NumberOfStates 1]
    
    %   Copyright 2017-2018 The MathWorks, Inc.
    
    %#codegen
    properties(Constant)
        StateOrientation = 'column';
    end
    
    methods(Static)
        function particles = resampleParticles(particles, whichParticles)
            % resampleParticles Resample
            particles = particles(:, whichParticles);
        end
        
        function someParticles = getParticles(particles, whichParticles)
            % getParticles Get a subset of the particles
            someParticles = particles(:, whichParticles);
        end
        
        function particles = setParticles(particles, whichParticles, val)
            % setParticles Overwrite a subset of the particles
            particles(:, whichParticles) = val;
        end
        
        function states = getStates(particles, whichStates)
            % getStates Get a subset of the states
            states = particles(whichStates, :);
        end
        
        function particles = setStates(particles, whichStates, val)
            % setStates Overwrite a subset of the states
            particles(whichStates, :) = val;
        end
        
        function particles = allocateMemoryParticles(numParticles,numStates,dataType)
            % allocateMemoryParticles Allocate space for particles
            %
            % Note that coder.nullcopy skips initializing the values to 0.
            % Must ensure that the particles are in fact initialized in
            % initialize() method.
            particles = coder.nullcopy(zeros(numStates, numParticles, dataType));
        end
        
        function states = allocateMemoryStates(numStates,dataType)
            % allocateMemoryStates Allocate space for state estimates
            %
            % Note that coder.nullcopy skips initializing the values to 0.
            % Must ensure that the particles are in fact initialized in
            % initialize() method.
            states = coder.nullcopy(zeros(numStates,1,dataType));
        end
        
        function weights = getUniformWeights(numParticles,dataType)
            % getUniformWeights Set equal weight for all particles
            weights = ones(1,numParticles,dataType) / cast(numParticles,dataType);
        end
        
        function weights = weightTimesLikelihood(weights,lhood)
            % weightsTimesLHood Multiply weights and likelihood vectors
            %
            % weights is [1 NumberOfParticles]
            % lhood is either [1 NumberOfParticles] or [NumberOfParticles 1]
            assert(isvector(lhood));
            % lhood(:)' converts to a row vector from either orientation
            weights = weights .* lhood(:)';
        end
        
        function validSize = getValidParticlesSize(numParticles,numStates)
            % getValidParticlesSize Expected size of particles
            validSize = [numStates numParticles];
        end
        
        function validateSizeParticlesWeights(particles,weights)
            % validateSizeParticlesWeights Check if dims of Particles and Weights match
            assert(size(particles,2) == size(weights,2));
        end
        
        function validateSizeParticlesCircularVariables(particles,isCircVar)
            % validateSizeParticlesCircularVariables Check if dims of Particles and IsStateVariableCircular match
            assert(size(particles,1) == size(isCircVar,2));
        end
        
        function orientedWeights = orientWeights(weights)
            % orientedWeights Return weights in row orientation
            assert(isvector(weights));
            isColumnVector = coder.internal.isConst(iscolumn(weights)) && iscolumn(weights);
            if isColumnVector
                orientedWeights = weights.';
            else
                orientedWeights = weights;
            end
        end
    end
end

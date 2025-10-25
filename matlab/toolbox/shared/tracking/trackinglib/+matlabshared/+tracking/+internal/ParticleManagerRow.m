classdef ParticleManagerRow < matlabshared.tracking.internal.ParticleManager
    %
    
    % Object responsible for particles' assignment operations in
    % ParticleFilter when a particle has dimensions [1 NumberOfStates]
    
    %   Copyright 2017-2018 The MathWorks, Inc.
    
    %#codegen
    properties(Constant)
        StateOrientation = 'row';
    end
    
    methods(Static)
        function particles = resampleParticles(particles, whichParticles)
            % resampleParticles Resample
            particles = particles(whichParticles, :);
        end
        
        function someParticles = getParticles(particles, whichParticles)
            % getParticles Get a subset of the particles
            someParticles = particles(whichParticles, :);
        end
        
        function particles = setParticles(particles, whichParticles, val)
            % setParticles Overwrite a subset of the particles
            particles(whichParticles, :) = val;
        end
        
        function states = getStates(particles, whichStates)
            % getStates Get a subset of the states
            states = particles(:, whichStates);
        end
        
        function particles = setStates(particles, whichStates, val)
            % setStates Overwrite a subset of the states
            particles(:,whichStates) = val;
        end
        
        function particles = allocateMemoryParticles(numParticles,numStates,dataType)
            % allocateMemoryParticles Allocate space for particles
            %
            % Note that coder.nullcopy skips initializing the values to 0.
            % Must ensure that the particles are in fact initialized in
            % initialize() method.
            particles = coder.nullcopy(zeros(numParticles, numStates, dataType));
        end
        
        function states = allocateMemoryStates(numStates,dataType)
            % allocateMemoryStates Allocate space for state estimates
            %
            % Note that coder.nullcopy skips initializing the values to 0.
            % Must ensure that the particles are in fact initialized in
            % initialize() method.
            states = coder.nullcopy(zeros(1,numStates,dataType));
        end
        
        function weights = getUniformWeights(numParticles,dataType)
            % getUniformWeights Set equal weight for all particles
            weights = ones(numParticles,1,dataType) / cast(numParticles,dataType);
        end
        
        function weights = weightTimesLikelihood(weights,lhood)
            % weightsTimesLHood Multiply weights and likelihood vectors
            %
            % weights is [NumberOfParticles 1]
            % lhood is either [NumberOfParticles 1] or [1 NumberOfParticles]
            assert(isvector(lhood));
            if iscolumn(lhood)
                weights = weights .* lhood;
            else
                weights = weights .* lhood.';
            end
        end
        
        function validSize = getValidParticlesSize(numParticles,numStates)
            % getValidParticlesSize Expected size of particles
            validSize = [numParticles numStates];
        end
        
        function validateSizeParticlesWeights(particles,weights)
            % validateSizeParticlesWeights Check if dims of Particles and Weights match
            assert(size(particles,1) == size(weights,1));
        end
        
        function validateSizeParticlesCircularVariables(particles,isCircVar)
            % validateSizeParticlesCircularVariables Check if dims of Particles and IsStateVariableCircular match
            assert(size(particles,2) == size(isCircVar,2));
        end
        
        function orientedWeights = orientWeights(weights)
            % orientedWeights Return weights in column orientation
            assert(isvector(weights));
            isColumnVector = coder.internal.isConst(iscolumn(weights)) && iscolumn(weights);
            if isColumnVector
                orientedWeights = weights;
            else
                orientedWeights = weights.';
            end
        end
    end
end

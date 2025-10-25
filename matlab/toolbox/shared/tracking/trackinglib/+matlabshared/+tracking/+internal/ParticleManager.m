classdef (Abstract) ParticleManager
    %
    
    % Base class for objects that manage row versus column state
    % orientation for ParticleFilter
    
    %   Copyright 2017-2018 The MathWorks, Inc.
    
    %#codegen
    properties(Abstract,Constant)
        StateOrientation;
    end
    
    methods(Abstract,Static)
        % resampleParticles Resample
        %
        % particles = resampleParticles(particles, whichParticles) performs
        %   particles = particles(:, whichParticles)
        % if states have column orientation. Otherwise
        %   particles = particles(whichParticles, :)
        particles = resampleParticles(particles, whichParticles);
        
        % getParticles Get a subset particles
        %
        % someParticles = getParticles(particles, whichParticles) performs
        %   someParticles = particles(:, whichParticles)
        % if states have column orientation. Otherwise
        %   someParticles = particles(whichParticles, :)
        someParticles = getParticles(particles, whichParticles);
        
        % setParticles Overwrite a subset particles
        %
        % particles = setParticles(particles, whichParticles, val) performs
        %   particles(:, whichParticles) = val
        % if states have column orientation. Otherwise
        %   particles(whichParticles, :) = val
        particles = setParticles(particles, whichParticles, val);
        
        % getStates Get a subset of states
        %
        % states = getStates(particles, whichStates) performs
        %   states = particles(whichStates, :)
        % if states have column orientation. Otherwise
        %   states = particles(:, whichStates)
        particles = getStates(particles, whichStates, val);
        
        % setStates Overwrite a subset of states
        %
        % particles = setStates(particles, whichStates, val) performs
        %   particles(whichStates, :) = val
        % if states have column orientation. Otherwise
        %   particles(:, whichStates) = val
        particles = setStates(particles, whichStates, val);
               
        % allocateMemoryParticles Allocate space for all particles
        particles = allocateMemoryParticles(numParticles,numStates);        
        
        % allocateMemoryStates Allocate space for state estimate
        states = allocateMemoryStates(numStates,dataType);
        
        % getUniformWeights Set equal weight for all particles
        weights = getUniformWeights(numParticles,dataType);
        
        % weightsTimesLHood Multiply weights and likelihood vectors
        %
        % Likelihood is calculated by users and its orientation is not
        % guaranteed. This ensures that the result has the weights'
        % orientation
        weights = weightTimesLikelihood(weights,lhood);
        
        % getValidParticlesSize Expected size of particles
        validSize = getValidParticlesSize(numParticles,numStates);
        
        % validateSizeParticlesWeights Check if dims of Particles and Weights match
        validateSizeParticlesWeights(particles,weights);        
        
        % validateSizeParticlesCircularVariables Check if dims of Particles and IsStateVariableCircular match
        validateSizeParticlesCircularVariables(particles,isCircVar);        
        
        % orientWeights Return Weights in the right orientation
        orientedWeights = orientWeights(weights);
    end
    
    methods(Static,Hidden)
        function props = matlabCodegenNontunableProperties(~)
            % Let the coder know about non-tunable parameters so that it
            % can generate more efficient code.
            props = {'StateOrientation'};
        end
    end
end

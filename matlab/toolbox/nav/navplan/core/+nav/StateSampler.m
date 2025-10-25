classdef (Abstract) StateSampler < handle
% StateSampler State sampler for path planning
%   The nav.StateSampler class is an interface for all state samplers
%   used in sampling-based path planners like plannerRRT,
%   plannerRRTStar, plannerBiRRT, and plannerPRM. This representation
%   allows for implementing sampling strategies on top of existing
%   functions like sampleUniform and sampleGaussian available in the
%   StateSpace interface.
%
%   To create a sample template for generating your own state sampler
%   class, call createPlanningTemplate.
%
%
%   SAMPLER = nav.StateSampler(SPACE) creates a state sampler object,
%   SAMPLER using the specified state space, SPACE.
%
%
%   StateSampler properties:
%       StateSpace - State space for sampling
%
%
%   StateSampler methods:
%       sample     - Sample state
%       copy       - Create deep copy of StateSampler object
%
%   See also stateSamplerUniform, createPlanningTemplate

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    properties(SetAccess=?nav.algs.internal.InternalAccess)
        %StateSpace - State space object used for state sampling
        StateSpace
    end

    methods
        function obj = StateSampler(stateSpace)
            arguments
                stateSpace nav.StateSpace;
            end
            obj.StateSpace = stateSpace;
        end
    end

    methods(Abstract)

        % sample Sample state
        %   STATES = sample(SAMPLER) samples one state from the specified
        %   state sampler object SAMPLER.
        %
        %   STATES = sample(SAMPLER,NUMSAMPLES) returns a specified number
        %   of state samples NUMSAMPLES.
        state = sample(obj, numStates);

        % copy Create deep copy of StateSampler object
        sampler2 = copy(sampler1)
    end
end

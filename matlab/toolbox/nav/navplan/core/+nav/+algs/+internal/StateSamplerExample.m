%   This class defines a template for creating a custom state sampler
%   definition that can be used by the sampling-based path planners like
%   plannerRRT and plannerRRTStar. The state sampler allows you to sample
%   states from the state space according to the implemented sampling
%   algorithm.
%
%   To access documentation for how to define a state sampler, enter the
%   following at the MATLAB command prompt:
%
%    >> doc nav.StateSampler
%
%   For a concrete implementation of the same interface, see the following
%   nav.StateSampler class:
%
%    >> edit stateSamplerUniform
%
%
%   To use this custom state sampler for path planning, follow the steps
%   outlined below and complete the class definition. Then, save this file
%   somewhere on the MATLAB path. You can add a folder to the path using
%   the ADDPATH function.

%   Copyright 2023 The MathWorks, Inc.


classdef StateSamplerExample < nav.StateSampler & ...
        matlabshared.planning.internal.EnforceScalarHandle

%---------------------------------------------------------------------
% Step 1: Define properties to be used by your state sampler. These are
% user-defined properties.
    properties

        %------------------------------------------------------------------
        % Place your code here
        %------------------------------------------------------------------

    end

    %----------------------------------------------------------------------
    % Step 2: Define functions used for managing your state sampler.
    methods
        % a) Use the constructor to create the state sampler object and set
        % the StateSpace property. Add extra arguments if required for your
        % application.
        %
        function obj = StateSamplerExample(space)

            narginchk(0,1)

            if nargin == 0
                space = stateSpaceSE2;
            end

            % The state space object is validated in the StateSampler base class
            obj@nav.StateSampler(space);

            %--------------------------------------------------------------
            % Place your code here
            %--------------------------------------------------------------
        end

        % b) Define how the object is being copied (a new object is created
        %    from the current one). You have to customize this function
        %    if you define your own properties or special constructor.
        %
        %    For more help, see
        %    >> doc nav.StateSampler/copy
        %
        function copyObj = copy(obj)

        % Default behavior: Create a new object of the same type with no arguments.
            copyObj = feval(class(obj), obj.StateSpace);

            %--------------------------------------------------------------
            % Place your code here
            %--------------------------------------------------------------
        end

        % c) Define how a state samples are generated.
        %
        %    For more help, see
        %    >> doc nav.StateSampler/sample
        %
        function states = sample(obj, numSamples)

            arguments
                obj
                numSamples = 1
            end

            % Default behavior: Do uniform sampling
            states = obj.StateSpace.sampleUniform(numSamples);

            %--------------------------------------------------------------
            % Place your code here or replace default function behavior.
            %--------------------------------------------------------------
        end

    end
end

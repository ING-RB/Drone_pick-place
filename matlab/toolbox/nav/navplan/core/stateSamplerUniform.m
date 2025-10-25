classdef stateSamplerUniform < nav.StateSampler & ...
        matlabshared.planning.internal.EnforceScalarHandle & ...
        nav.algs.internal.InternalAccess
%

%   Copyright 2023 The MathWorks, Inc.

%#codegen

    methods
        function obj = stateSamplerUniform(stateSpace)
            arguments
                stateSpace = stateSpaceSE2; % default is SE(2) state space
            end
            obj@nav.StateSampler(stateSpace);
        end

        function states = sample(obj, numSamples)
            arguments
                obj
                numSamples (1,1) {mustBeNumeric, mustBeInteger, mustBePositive} = 1
            end

            if numSamples == 1
                states = obj.StateSpace.sampleUniform();
            else
                states = obj.StateSpace.sampleUniform(numSamples);
            end
        end

        function copyObj = copy(obj)
            copyObj = stateSamplerUniform(obj.StateSpace);
        end
    end
end

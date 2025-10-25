classdef stateSamplerGaussian < nav.StateSampler &...
        matlabshared.tracking.internal.CustomDisplay & ...
        matlabshared.planning.internal.EnforceScalarHandle &...
        nav.algs.internal.InternalAccess
%

% Copyright 2023 The MathWorks, Inc.

%# codegen


    properties(SetAccess = ?nav.algs.internal.InternalAccess)
        StateValidator
    end

    properties
        StandardDeviation
        MaxAttempts
    end

    properties(Access=private)
        StateSamplerUniformInternal % For uniform samples
    end

    %% Public methods for constructor, sample, copy
    methods
        function obj = stateSamplerGaussian(stateValidator, NameValueArgs)
            arguments
                stateValidator {mustBeA(stateValidator, "nav.StateValidator")} = ...
                    validatorOccupancyMap(stateSpaceSE2);
                NameValueArgs.StandardDeviation = ...
                    stateSamplerGaussian.defaultStandardDeviation(stateValidator)
                NameValueArgs.MaxAttempts = 10
            end

            obj@nav.StateSampler(stateValidator.StateSpace);
            obj.StateValidator = stateValidator;
            obj.StandardDeviation = NameValueArgs.StandardDeviation;
            obj.MaxAttempts = NameValueArgs.MaxAttempts;
            obj.StateSamplerUniformInternal = stateSamplerUniform(stateValidator.StateSpace);
        end


        function states = sample(obj, numSamples)
            arguments
                obj
                numSamples (1,1) {mustBeNumeric, mustBeInteger, mustBePositive} = 1
            end

            % Allocate memory for states
            states = nan(numSamples, obj.StateSpace.NumStateVariables);

            % Get each sample
            for i  = 1:numSamples
                states(i,:) = obj.getGaussianSample();
            end
        end

        function copyObj = copy(obj)
            stateValidator = copy(obj.StateValidator);
            copyObj = stateSamplerGaussian(stateValidator);
            copyObj.StandardDeviation = obj.StandardDeviation;
            copyObj.MaxAttempts = obj.MaxAttempts;
        end

        function set.StandardDeviation(obj, standardDeviation)
            obj.validateStandardDeviation(standardDeviation);
            obj.StandardDeviation = standardDeviation;
        end

        function set.MaxAttempts(obj, maxAttempts)
            validateattributes(maxAttempts, {'numeric'}, {'scalar', 'integer', 'positive'},...
                               'stateSamplerGaussian', 'MaxAttempts')
            obj.MaxAttempts = maxAttempts;
        end
    end

    methods(Access=private)
        function state = getGaussianSample(obj)
        % Generate a state from Gaussian sampler

            % Initialize state as coder cannot determine if its defined on
            % all execution paths based on MaxAttempts property in the for
            % loop below
            state = nan(1, obj.StateSpace.NumStateVariables);

            for attempts = 1:obj.MaxAttempts

                % First state sample from uniform distribution
                state = obj.StateSamplerUniformInternal.sample();

                % Second state sample from Gaussian distribution
                stateG = obj.StateSpace.sampleGaussian(state, obj.StandardDeviation);

                % Check validity of first and second samples - we check the
                % validity of both states together for performance
                valid = obj.StateValidator.isStateValid([state; stateG]);
                v1 = valid(1); % validity of first sample
                v2 = valid(2); % validity of second sample

                % Select valid state from the pair
                if v2~=v1 % only one state in the pair is valid
                    if ~v1 % second sample is valid
                        state = stateG;
                    end
                    break
                end
            end
        end

        function validateStandardDeviation(obj, standardDeviation)
            validateattributes(standardDeviation, {'double', 'single'},...
                               {'vector', 'positive', 'numel', obj.StateValidator.StateSpace.NumStateVariables},...
                               'stateSamplerGaussian', 'StandardDeviation')
        end
    end


    methods (Access = protected)
        function propgrp = getPropertyGroups(obj)
            proplist = struct(...
                'StateSpace',        obj.StateSpace,...
                'StateValidator',    obj.StateValidator,...
                'StandardDeviation', obj.StandardDeviation,...
                'MaxAttempts',       obj.MaxAttempts);
            propgrp = matlab.mixin.util.PropertyGroup(proplist);
        end
    end

    methods(Static, Access=private)
        function stdev = defaultStandardDeviation(stateValidator)

        % We assign a default standard deviation based on state space
        % bounds when it is provided
            stdev = 1/100*diff(stateValidator.StateSpace.StateBounds,1,2)';
        end
    end
end

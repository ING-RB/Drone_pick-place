classdef stateSamplerMPNET < nav.StateSampler &...
        matlabshared.tracking.internal.CustomDisplay & ...
        matlabshared.planning.internal.EnforceScalarHandle
%

% Copyright 2023 The MathWorks, Inc.

%#codegen

    properties(SetAccess=private)
        MotionPlanningNetwork
    end

    properties
        Environment

        StartState

        GoalState

        MaxLearnedSamples (1,1) {mustBeNumeric, mustBeInteger, mustBeNonnegative}

        GoalThreshold (1,1) {mustBeNumeric, mustBeScalar, mustBeReal, mustBeNonNan, mustBeFinite, mustBeNonnegative}
    end

    properties(Access={?nav.algs.internal.InternalAccess, ?matlab.unittest.TestCase})

        StateSamplerUniformInternal % Stores stateSamplerUniform object

        Bidirectional = false % Bidirectional sampling

        StateA % Initialized state sample in the forward direction initialized with start state

        StateB % Initialized state sample in the reverse direction initialized with goal state

        StateAIsForward % Flag to determine which state is in the forward direction
    end

    %% Public methods for constructor, sample
    methods
        function obj = stateSamplerMPNET(stateSpace, mpnet, NameValueArgs)
            arguments
                stateSpace {mustBeA(stateSpace, 'nav.StateSpace')}
                mpnet {mustBeA(mpnet, 'nav.internal.MPNET')}
                NameValueArgs.Environment       = stateSamplerMPNET.getDefaultEnviornment(stateSpace);
                NameValueArgs.StartState        = stateSamplerMPNET.getDefaultState(stateSpace);
                NameValueArgs.GoalState         = stateSamplerMPNET.getDefaultState(stateSpace);
                NameValueArgs.MaxLearnedSamples = 50;
                NameValueArgs.GoalThreshold     = 1.0;
            end
            %

            % Validate the equality of number of state variables in mpnet
            % and stateSpace objects
            coder.internal.errorIf(height(mpnet.StateBounds) ~= stateSpace.NumStateVariables,...
                                   'nav:navalgs:mpnet:IncorrectStateBoundsMPNET')

            % Constructor object
            obj@nav.StateSampler(stateSpace);
            obj.MotionPlanningNetwork = mpnet;
            obj.Environment       = NameValueArgs.Environment;
            obj.StartState        = NameValueArgs.StartState;
            obj.GoalState         = NameValueArgs.GoalState;
            obj.GoalThreshold     = NameValueArgs.GoalThreshold;
            obj.MaxLearnedSamples = NameValueArgs.MaxLearnedSamples;
            obj.StateSamplerUniformInternal = stateSamplerUniform(stateSpace);
        end

        function states = sample(obj, numSamples)
            arguments
                obj
                numSamples (1,1) {mustBeNumeric, mustBeInteger, mustBePositive} = 1
            end
            %

            % Initialize StateA & StateB for sampling
            obj.initializeMPNET();

            % Allocate memory of states
            states = nan(numSamples, obj.StateSpace.NumStateVariables);

            % Generate learned samples
            s = rng;
            numLearnedSamples = min(numSamples, obj.MaxLearnedSamples);
            obj.StateAIsForward = true;
            for i=1:numLearnedSamples
                states(i,:) = obj.sampleMPNET();
            end
            rng(s); % Reset the seed to original in order to not affect the uniform sampling

            % Generate uniform samples
            if numSamples > numLearnedSamples
                states(numLearnedSamples+1:end, :) =...
                    obj.StateSamplerUniformInternal.sample(numSamples-numLearnedSamples);
            end
        end

        function copyObj = copy(obj)
            mpnet = obj.MotionPlanningNetwork.copy();
            stateSpace = obj.StateSpace.copy();
            copyObj = stateSamplerMPNET(stateSpace, mpnet);
            copyObj.Environment       = obj.Environment;
            copyObj.StartState        = obj.StartState;
            copyObj.GoalState         = obj.GoalState;
            copyObj.MaxLearnedSamples = obj.MaxLearnedSamples;
            copyObj.GoalThreshold     = obj.GoalThreshold;
            copyObj.Bidirectional     = obj.Bidirectional;
        end
    end

    %% Property setters
    methods

        function set.Environment(obj, environment)
            obj.validateEnvironment(environment)
            obj.Environment = environment;
        end

        function set.StartState(obj, start)
            obj.validateState(start, 'StartState')
            obj.StartState = start;
        end

        function set.GoalState(obj, goal)
            obj.validateState(goal, 'GoalState')
            obj.GoalState = goal;
        end
    end

    %% Private methods for MPNet sampler algorithm
    methods(Access=private)

        function initializeMPNET(obj)
        % Initialize forward and backward states for sampling
            obj.StateA = obj.StartState;
            obj.StateB = obj.GoalState;
        end

        function state = sampleMPNET(obj)
        % sampleMPNET Get state sample from MPNet

        % Predict next state using MPNet
            state = obj.MotionPlanningNetwork.predict(obj.StateA, obj.StateB, obj.Environment);

            if obj.StateSpace.distance(obj.StateA, obj.StateB) <= obj.GoalThreshold && obj.StateAIsForward
                obj.initializeMPNET(); % Reinitialize MPNet
            else
                obj.StateA = state; % Set StateA to current MPNet sample
            end

            if obj.Bidirectional
                % Swap StateA and StateB for bidirectional sampler
                [obj.StateB, obj.StateA] = deal(obj.StateA, obj.StateB);
                obj.StateAIsForward = ~obj.StateAIsForward;
            end
        end

        function validateState(obj, state, propname)
        % validateState Validation of StartState and GoalState
        % properties
            stateSize = height(obj.MotionPlanningNetwork.StateBounds);
            validateattributes(state, {'single', 'double'}, {'nonempty', 'nonnan', 'finite', 'size', [1 stateSize]}, ...
                               obj.getClassName, propname);
        end

        function validateEnvironment(obj, environment)
        %validateEnvironment Validation of environment
            if isa(obj.MotionPlanningNetwork, 'mpnetSE2')
                % mpnetSE2 supports only occupancyMap, binaryOccupancyMap as of now
                validateattributes(environment, {'occupancyMap','binaryOccupancyMap'},...
                                   {'nonempty'}, obj.getClassName, 'Environment');
            end
        end
    end

    methods(Static, Access=private)
        function environment = getDefaultEnviornment(stateSpace)
        %getDefaultEnviornment Get default empty environment based on
        %state space
            if isa(stateSpace, 'stateSpaceSE2')
                environment = occupancyMap;
            elseif isa(stateSpace, 'stateSpaceSE3')
                environment = occupancyMap3D;
            elseif isa(stateSpace, 'manipulatorStateSpace')
                environment = occupancyMap3D;
            else
                environment = 0; % a dummy scalar value
            end
        end

        function state = getDefaultState(stateSpace)
        %getDefaultState Get default state for start and goal from the
        %stateSpace located at the center of it.
            boundLow = stateSpace.StateBounds(:,1)'; % [1, n] vector
            boundHigh = stateSpace.StateBounds(:,2)'; % [1, n] vector
            state = stateSpace.interpolate(boundLow, boundHigh, 0.5);
        end

        function name = getClassName()
            name = 'stateSamplerMPNET';
        end
    end


    %% Property groups
    methods (Hidden, Access = protected)
        function group = getPropertyGroups(obj)
            group = matlab.mixin.util.PropertyGroup;

            group.PropertyList = struct(...
                'StateSpace',             obj.StateSpace, ...
                'MotionPlanningNetwork',  obj.MotionPlanningNetwork, ...
                'Environment',            obj.Environment, ...
                'StartState',             obj.StartState, ...
                'GoalState',              obj.GoalState, ...
                'MaxLearnedSamples',      obj.MaxLearnedSamples,...
                'GoalThreshold',          obj.GoalThreshold...
                                       );
        end
    end
end

function mustBeScalar(input)
%mustBeScalar Check if the input is numeric-scalar
    validateattributes(input, {'numeric'}, {'scalar'})
end

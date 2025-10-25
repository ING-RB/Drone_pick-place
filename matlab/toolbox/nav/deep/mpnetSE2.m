classdef mpnetSE2 < nav.internal.MPNET &...
        matlabshared.planning.internal.EnforceScalarHandle &...
        nav.algs.internal.InternalAccess
%

% Copyright 2023 The MathWorks, Inc.

%#codegen

%% Public properties
    properties
        StateBounds

        LossWeights (1,3) {mustBeNumeric, mustBeReal, mustBeNonNan, mustBeFinite, mustBeNonnegative}

        EncodingSize (1,2) {mustBeNumeric, mustBeInteger, mustBeNonnegative}
    end

    properties(SetAccess=protected)
        NumInputs;

        NumOutputs;
    end

    properties(SetAccess=private, Hidden)
        %NumStateVariables - Number of state variables in the state space
        NumStateVariables = 3
    end

    %% Private properties
    properties(Access=protected)
        LossWeightTransformed

        StateBoundsTransformed
    end

    properties(Access=private)
        EnvironmentCache
        EnvironmentEncodingCache = 0
    end

    %% Public methods for constructor, loss, predict
    methods
        function obj = mpnetSE2(nvPairs)

            arguments
                nvPairs.Network = [];
                nvPairs.StateBounds = [-100,100;-100,100;-pi,pi]
                nvPairs.EncodingSize = [10, 10];
                nvPairs.LossWeights = [1,1,1];
            end
            obj.StateBounds = nvPairs.StateBounds;
            obj.LossWeights = nvPairs.LossWeights;
            obj.EncodingSize = nvPairs.EncodingSize;
            if isempty(nvPairs.Network) && isempty(obj.Network)
                obj.Network = obj.getDefaultNetwork(obj.NumInputs, obj.NumOutputs);
            else
                obj.Network = nvPairs.Network;
            end
        end

        function lossval = loss(obj, statePredicted, stateActual)

            arguments
                obj
                statePredicted   {validateStatePre(obj, statePredicted, 'loss')}
                stateActual {validateStatePre(obj, stateActual, 'loss')}
            end

            if isvector(statePredicted)
                %If state input is a vector, convert it into a column
                statePred = statePredicted(:); % store in a different variable to support codegen
                stateAct = stateActual(:);
            else
                statePred = statePredicted;
                stateAct = stateActual;
            end

            weight = obj.LossWeightTransformed(:);        % shape - [stateSize, 1]
            squaredError = (statePred - stateAct).^2;    % shape - [stateSize, batchSize]
            weightedSquaredError = squaredError.* weight; % shape - [stateSize, batchSize]
            lossval = sum(weightedSquaredError, 1);       % shape - [1, batchSize]
            lossval = mean(lossval);                      % shape - [1,1]
        end

        function statePred = predict(obj, state, goal, environment)
            arguments
                obj
                state {validateState(obj, state, 'predict')}
                goal  {validateState(obj, goal, 'predict')}
                environment {validateEnvironment(obj, environment)} = [] % when EncodingSize is zero, this is optional
            end
            %

            % Environment input must be non-empty when EncodingSize is
            % non-zero
            coder.internal.errorIf(isempty(environment) && prod(obj.EncodingSize)~=0,...
                                   'nav:navalgs:mpnet:EnvironmentMustBeSpecified')

            % Preprocess state, goal and environment at MPNet input
            envPreprocessed = obj.preprocessEnvironment(environment);
            statePreprocessed = obj.preprocessState(state);
            goalPreprocessed = obj.preprocessState(goal);

            % Get predictions after concatenating preprocessed state, goal and environment
            input = [statePreprocessed, goalPreprocessed, envPreprocessed];
            statePred = obj.predictImpl(input);
        end

        function copyobj = copy(obj)

            copyobj = mpnetSE2(Network=obj.Network, ...
                               StateBounds=obj.StateBounds,...
                               EncodingSize=obj.EncodingSize,...
                               LossWeights=obj.LossWeights);
            copyobj.NumStateVariables = obj.NumStateVariables;
        end
    end

    %% Pre/post-processing methods
    methods(Hidden)

        function statePreprocessed =  preprocessState(obj, state)
        % Preprocess states at MPNet input
            arguments
                obj
                state % Shape [N, 3]
            end

            % Encode angles from theta -> [cos(theta), sin(theta)]
            cosTheta = cos(state(:,3));
            sinTheta = sin(state(:,3));
            stateTransformed = [state(:,1:2), cosTheta, sinTheta];

            % Normalize states
            statePreprocessed = obj.normalize(stateTransformed,...
                                              obj.StateBoundsTransformed(:,1),...
                                              obj.StateBoundsTransformed(:,2));
        end

        function statePost = postprocessState(obj, state)
        % Postprocess states at MPNet output

            arguments
                obj
                state % Shape [N, 4]
            end

            % Denormalize states at MPNet output
            stateTransformed = obj.denormalize(state, ...
                                               obj.StateBoundsTransformed(:,1),...
                                               obj.StateBoundsTransformed(:,2));

            % Decode angles from [cos(theta), sin(theta)] -> theta
            cosTheta = stateTransformed(:,3);
            sinTheta = stateTransformed(:,4);
            theta = atan2(sinTheta, cosTheta);
            statePost = [stateTransformed(:,1:2), theta];
        end

        function envPreprocessed = preprocessEnvironment(obj, map)
        % Preprocess environment at MPNet input
            arguments
                obj
                map
            end

            % Empty output for empty map
            if isempty(map)
                envPreprocessed = [];
                return
            end

            % Empty output for zero EncodingSize
            if prod(obj.EncodingSize)==0
                envPreprocessed = [];
                return
            end

            % Encode map
            if ~coder.internal.is_defined(obj.EnvironmentCache) || (obj.EnvironmentCache ~= map)
                dist = nav.internal.bpsencode(map, obj.EncodingSize);
                encodedEnv = obj.normalize(dist);
                envPreprocessed = encodedEnv(:)';
                obj.EnvironmentCache = map;
                obj.EnvironmentEncodingCache = envPreprocessed;
            else
                envPreprocessed = obj.EnvironmentEncodingCache;
            end
        end
    end


    %% Property setters
    methods

        function set.StateBounds(obj, stateBounds)
            stateBounds = nav.StateSpace.validateStateBounds(stateBounds, 3, 'mpnetSE2', 'StateBounds');
            obj.StateBounds = stateBounds;
            obj.setTransformedStateBounds();
        end

        function set.LossWeights(obj, weight)
            obj.LossWeights = weight;
            obj.setTransformedLossWeights();
        end

        function set.EncodingSize(obj, encodingSize)
            obj.EncodingSize = encodingSize;
            obj.setNumInputsOutputs();
        end
    end


    %% Extra validators and internal property setters
    methods(Access=private)

        function setNumInputsOutputs(obj)
        % Set NumInputs and NumOutputs property
            obj.NumInputs = 2*(obj.NumStateVariables+1) + prod(obj.EncodingSize);
            obj.NumOutputs = obj.NumStateVariables+1;

            % Update default Network when NumInputs has changed as a result
            % of modifying EncodingSize
            if coder.target('MATLAB')
                % For codegen, all properties are non-tunable. So the
                % Network property will assigned only once inside the
                % constructor during codegen
                if ~isempty(obj.Network) &&...
                        obj.Network.Layers(1).InputSize ~= obj.NumInputs
                    obj.Network = obj.getDefaultNetwork(obj.NumInputs, obj.NumOutputs);
                end
            end

            %Reset the environment cache whenever the EncodingSize changes
            if coder.target('MATLAB')
                % The encoding params are non-tunable after compilation
                % for codegen, so we reset the environment cache only for
                % the simulation mode
                obj.EnvironmentCache = [];
            end
        end

        function setTransformedLossWeights(obj)
        % Set LossWeightTransformed property that stores the weights for
        % [x, y, cos(theta), sin(theta)] in the form of dlarray
            obj.LossWeightTransformed = dlarray([obj.LossWeights(1:3), obj.LossWeights(3)]);
        end

        function setTransformedStateBounds(obj)
        % Set StateBoundsTransformed property that stores the limits for
        % [x, y, cos(theta), sin(theta)]
            positionLimits = obj.StateBounds(1:2,:);
            thetaBounds = obj.StateBounds(3,:);
            [cosThetaLimits, sinThetaLimits] = nav.internal.encodedAngleLimits(thetaBounds);
            obj.StateBoundsTransformed = [positionLimits; cosThetaLimits; sinThetaLimits];
        end

        function validateState(obj, state, fcnName)
        %validateState Validate state

            if strcmp(fcnName, 'predict')
                firstDim = 1;
            else
                firstDim = nan;
            end

            stateSize = obj.NumStateVariables;
            nav.internal.validation.validateStateMatrix(state, firstDim, stateSize, fcnName, 'state')
        end

        function validateStatePre(obj, state, fcnName)
        %validateStatePre Validate preprocessed state

            stateSize = obj.NumStateVariables+1; % state size after preprocessing
            if isvector(state)
                % state input is a vector of length equal stateSize during simulation
                state = state(:)';
                validateattributes(state, {'single', 'double'},...
                                   {'nonempty', 'vector', 'numel', stateSize}, fcnName, 'state');
            else
                % During training, the state input is a matrix of shape [stateSize, batchSize]
                % and it is of type "single"
                % Note: nav.internal.validation.validateStateMatrix only
                % checks for type "double"
                validateattributes(state, {'single', 'double'},...
                                   {'nonempty', 'size', [stateSize nan]}, fcnName, 'state');
            end
        end

        function validateEnvironment(~, environment)
        %validateEnvironment Validate environment input if it is not
        %empty

            if ~isempty(environment)
                mustBeA(environment, {'occupancyMap', 'binaryOccupancyMap'});
            end
        end

    end

    %% Extra utility methods
    methods (Static, Hidden)
        function result = matlabCodegenSoftNontunableProperties(~)
        %matlabCodegenSoftNontunableProperties Mark properties as nontunable during codegen
        %
        % Marking properties as 'Nontunable' indicates to Coder that
        % the property should be made compile-time Constant.
            result = {'NumInputs','NumOutputs','StateBounds','EncodingSize','Network'};
        end
    end
end

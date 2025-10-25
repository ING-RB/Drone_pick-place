classdef (Abstract) MPNET < handle
% This class is for internal use only. It may be removed in the future.

% MPNET Motion Planning Network interface
%   The MPNET abstract class provides the properties and methods to train
%   and simulate Motion Planning networks for a 2D, 3D, ND state spaces.
%   Use of MPNET requires Deep Learning Toolbox.
%
%   See also mpnetSE2, stateSamplerMPNET

% Copyright 2023 The MathWorks, Inc.

%#codegen

%% Properties
    properties
        Network
    end

    properties(Abstract, SetAccess=protected)
        NumInputs
        NumOutputs
    end

    properties(Abstract, SetAccess=private, Hidden)
        %NumStateVariables - Number of state variables in the state space
        NumStateVariables
    end

    properties(Access=private)
        FastInference=false % Option to choose fast inference during simulation
        NetLayers % Store network layers for fast inference mode
    end


    %% Abstract methods to be implemented by inheriting classes
    methods(Abstract)
        % predict - Predict outputs from MPNet
        predOut = predict(obj, inputs)

        % loss - Loss computation for MPNet
        lossOut = loss(obj, statePredicted, stateActual)

        %COPY Create deep copy of state space object
        copyObj = copy(obj)
    end


    %% Public methods
    methods
        function set.Network(obj, network)
        %set.Network Set Network property

        % Validate network input
            validateattributes(network, {'dlnetwork', 'nnet.cnn.layer.Layer', 'nnet.cnn.LayerGraph'}, {}, '', 'Network')

            if isa(network, 'dlnetwork')
                %If the input is of dlnetwork type it must be a scalar
                coder.internal.errorIf(~isscalar(network),...
                                       'nav:navalgs:mpnet:DLNetworkMustBeScalar')
            else
                % If the input is of Layer or LayerGraph type, convert it
                % to dlnetwork
                network = dlnetwork(network);
            end

            if coder.target('MATLAB')
                % Validate layers in simulation mode. In the codegen
                % mode, accessing Layers property is not supported
                if length(network.Layers)<2
                    error(message('nav:navalgs:mpnet:MinimumNumLayers'))
                end
                if ~isa(network.Layers(end), 'nnet.cnn.layer.FullyConnectedLayer')
                    error(message('nav:navalgs:mpnet:IncorrectLastLayer'))
                end
                obj.validateNetworkSize(network);
            end

            % Set Network property
            obj.Network = network;

            % The dlnetwork is slow in simulation mode, so we use the
            % alternate approach for fast inference if the layers are
            % created from mpnetLayers
            if coder.target('MATLAB')
                obj.setNetLayers(); % Store network layers in NetLayers
                if obj.checkDefaultNetwork()
                    obj.setFastInference();
                end
            end
        end
    end

    %%  Utility methods

    methods(Hidden, Static)
        function output = normalize(input, minlimit, maxlimit)
        % normalize Normalize inputs

            arguments
                input % Each row is a sample
                minlimit(1,:) {mustBeReal} = min(input, [], 1);
                maxlimit(1,:) {mustBeReal} = max(input, [], 1);
            end
            % Normalize data where each sample is a row
            output = (input - minlimit)./(maxlimit - minlimit);
        end

        function output = denormalize(input, minlimit, maxlimit)
        % denormalize Denormalize inputs

            arguments
                input % Each row is a sample
                minlimit(1,:) {mustBeReal} = min(input, [], 1);
                maxlimit(1,:) {mustBeReal} = max(input, [], 1);
            end
            % Denormalize data
            output = input .* (maxlimit - minlimit) + minlimit;
        end

        function net = getDefaultNetwork(numInputs, numOutputs)
        %getDefaultNetwork Get the default network for given number of
        %inputs and outputs
            net = dlnetwork(mpnetLayers(numInputs, numOutputs));
        end
    end

    methods(Access=protected)
        function statePred = predictImpl(obj, input)
        %predictImpl Predict next state using the trained neural network

            inputS = cast(input, 'single'); % Network weights are of single precision

            if coder.target('MATLAB') && obj.FastInference
                % Use fast inference in simulation mode when we have
                % layers created from mpnetLayers
                statePred = nav.internal.mpnetPredict(obj.NetLayers, inputS(:));
            else
                % Use dlnetwork
                inputDL = dlarray(inputS, 'BC');
                statePred = predict(obj.Network, inputDL);
                statePred = gather(extractdata(statePred));
            end
            statePred = statePred(:)';
            statePred = cast(statePred, 'like', input);
            statePred = obj.postprocessState(statePred);
        end
    end

    %% Methods related to neural network
    methods(Access=private)

        function setFastInference(obj)
        %setFastInference Use fast inference
            obj.FastInference = true;
        end

        function setNetLayers(obj)
        %setNetLayers During inference with FastInference=true, its
        %expensive to get Layers property during every loop, so we
        %store it separately
            obj.NetLayers = obj.Network.Layers;
        end

        function isDefault = checkDefaultNetwork(obj)
        %checkDefaultNetwork Check if the network is the default structure

        %The network is considered to have default structure if it has
        %been created using mpnetLayers

            layers = obj.Network.Layers;
            connections = obj.Network.Connections;

            %The default structure is a series network
            layernames = arrayfun(@(x) x.Name, layers,...
                                  'UniformOutput', false);
            isSeriesNetwork = all(...
                ismember(connections.Source, layernames(1:end-1)) & ...
                ismember(connections.Destination, layernames(2:end)));

            %The default structure has only feed-forward layers
            defaultLayerClasses = {'nnet.cnn.layer.FeatureInputLayer';
                                   'nnet.cnn.layer.FullyConnectedLayer';
                                   'nnet.cnn.layer.ReLULayer';
                                   'nav.algs.mpnetDropoutLayer'};
            layerClasses = unique(arrayfun(@(x) class(x), layers,...
                                           'UniformOutput', false));
            isFeedforwardNetwork = all(ismember(layerClasses, defaultLayerClasses));

            isDefault = isSeriesNetwork && isFeedforwardNetwork;
        end

        function validateNetworkSize(obj, network)
        %validateNetworkSize Validate the size of the network

            networkInputSize = network.Layers(1).InputSize;
            networkOutputSize =  network.Layers(end).OutputSize;

            if  networkInputSize ~= obj.NumInputs
                if networkInputSize < networkOutputSize
                    error(message('nav:navalgs:mpnet:IncorrectNetworkInputSize',...
                                  2*obj.NumOutputs))
                else
                    error(message('nav:navalgs:mpnet:IncompatibleNetworkInputSizeAndEncodingSize',...
                                  networkInputSize-obj.NumOutputs*2))
                end
            end
            if  networkOutputSize ~= obj.NumOutputs
                error(message('nav:navalgs:mpnet:IncorrectNetworkOutputSize',obj.NumOutputs))
            end
        end
    end
end

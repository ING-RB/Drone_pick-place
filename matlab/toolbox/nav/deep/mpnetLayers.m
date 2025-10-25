function layers = mpnetLayers(numInputs, numOutputs, NameValueArgs)
%

% Copyright 2023-2024 The MathWorks, Inc.

arguments
    numInputs(1,1) {mustBeNumeric, mustBeInteger, mustBePositive};
    numOutputs(1,1) {mustBeNumeric, mustBeInteger, mustBePositive};
    NameValueArgs.HiddenSizes(1,:) {mustBeVector, mustBeNumeric, mustBeInteger, mustBePositive} = [256, 128, 64, 32];
    NameValueArgs.DropoutProbabilities(1,:) {mustBeVector, mustBeNumeric}
end

% Default dropout probabilities for all layers except the last two
if ~isfield(NameValueArgs, 'DropoutProbabilities')
    NameValueArgs.DropoutProbabilities = 0.1*ones(1, length(NameValueArgs.HiddenSizes)-2);
end

if length(NameValueArgs.DropoutProbabilities)>length(NameValueArgs.HiddenSizes)
    error(message('nav:navalgs:mpnet:DropoutProbabilitiesSize'))
end

% Input layer
layers = featureInputLayer(numInputs, Name="input");

% Create hidden layers
for k=1:length(NameValueArgs.HiddenSizes)

    % Create fully connected layer
    layername = ['fc', num2str(k)];
    layers(end+1) = fullyConnectedLayer(NameValueArgs.HiddenSizes(k), Name=layername); %#ok<*AGROW>

    % Apply relu activation
    layername = ['relu', num2str(k)];
    layers(end+1) = reluLayer(Name=layername);

    % Apply dropout
    if k <= length(NameValueArgs.DropoutProbabilities)
        layername = ['dropout', num2str(k)];
        layers(end+1) = nav.algs.mpnetDropoutLayer(NameValueArgs.DropoutProbabilities(k), Name=layername);
    end
end

% Output layer
layers(end+1) = fullyConnectedLayer(numOutputs, Name="output");

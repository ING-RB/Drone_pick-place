function out = mpnetPredict(layers, input)
% This class is for internal use only. It may be removed in the future.

% mpnetPredict Fast predict implementation for the default network used in
% MPNet. This implementation is about an order of magnitude faster than
% dlnetwork.predict method in the simulation mode. We do not need to use this
% for codegen mode because dlnetwork is fast in codegen mode.
%
% We use this function only when the network is a simple series network
% with feed-forward layers and no skip connections.

% Copyright 2023 The MathWorks, Inc.

%#codegen

% Predict outputs from each layer of the network
    out = [];
    for k = 1:length(layers)
        layer = layers(k);
        switch class(layer)
          case 'nnet.cnn.layer.FeatureInputLayer'
            out = input;
          case 'nnet.cnn.layer.FullyConnectedLayer'
            out = layer.Weights*out+layer.Bias;
          case 'nnet.cnn.layer.ReLULayer'
            out = relu(out);
          case 'nav.algs.mpnetDropoutLayer'
            out = dropout(out, layer.Probability);
        end
    end
end

function y = relu(x)
%relu implementation
    y  = max(0,x);
end

function out = dropout(x, prob)
%dropout implementation
    scaleFactor = 1/(1-prob);
    scaleFactor = cast(scaleFactor, superiorfloat(x));
    mask = rand(size(x), 'like', x)>prob;
    mask = mask * scaleFactor;
    out = x.*mask;
end

classdef mpnetDropoutLayer < nnet.layer.Layer & nnet.layer.Acceleratable
% mpnetDropoutLayer Create custom dropout layer for Motion Planning Networks that allows dropout during prediction
%
%    Note: This class requires Deep Learning Toolbox.
%
%    LAYER = MPNETDROPOUTLAYER creates an MPNet dropout layer that randomly
%    sets input elements to zero with a probability of 0.5 during training.
%    This can help prevent over-fitting. During prediction, the dropout is
%    enabled to generate stochastic output as required by MPNet.
%
%    LAYER = MPNETDROPOUTLAYER(probability) creates an MPNet dropout layer
%    with dropout probability specified by a nonnegative number less than
%    1.
%
%    LAYER = MPNETDROPOUTLAYER(__,'Name',name) optionally specifies a name
%    for the layer in addition to using any of the previous syntaxes. The
%    default name is ''.
%
%    The dropout layer for Motion Planning Networks differs from the
%    existing dropoutLayer in the Deep Learning Toolbox in only one aspect:
%    In Motion Planning Networks, the dropout will be enabled during
%    prediction.
%
%   Example:
%       % Create a MPNet dropout layer with dropout probability 0.4.
%       layer = nav.algs.mpnetDropoutLayer(0.4);
%
%   See also dropoutLayer, reluLayer.
%#codegen

%   Copyright 2023 The MathWorks, Inc.

    properties
        %Probability Dropout probability
        Probability (1,1) {mustBeNumeric, mustBeGreaterThanOrEqual(Probability,0.0), mustBeLessThan(Probability, 1.0)}
    end

    methods
        function layer = mpnetDropoutLayer(probability, NameValueArgs)
            arguments
                probability = 0.5;
                NameValueArgs.Name = '';
            end
            layer.Probability = probability;
            if ~isempty(NameValueArgs.Name)
                layer.Name = NameValueArgs.Name;
            end
        end


        function Z = predict(layer,X)
        % predict Forward input data through layer at prediction time
        %   Z = predict(layer,X) forwards input data through the layer at
        %   prediction time and returns the output of layer forward function.
        %
        %   Inputs:
        %       layer - Layer to forward propagate through
        %       X - Input data
        %   Outputs:
        %       Z - Output of layer forward function

            arguments
                layer
                X {mustBeNumeric, mustBeNonempty}
            end

            mask = dropoutMask(X, layer.Probability);
            Z = X.*mask;
        end

        function Z = forward(layer,X)
        % forward Forward input data through layer at training time
        %   Z = forward(layer,X) forwards input data through the layer at
        %   training time and returns the output of layer forward function.
        %
        %   Inputs:
        %       layer - Layer to forward propagate through X - Input data
        %   Outputs:
        %       Z - Output of layer forward function

            arguments
                layer
                X {mustBeNumeric, mustBeNonempty}
            end

            mask = dropoutMask(X, layer.Probability);
            Z = X.*mask;
        end

    end
end

function mask = dropoutMask(X, probability)
% dropoutMask

    if ~isa(X, 'dlarray')
        superfloatOfX = superiorfloat(X);
    else
        superfloatOfX = superiorfloat(extractdata(X));
    end
    dropoutScaleFactor = 1/ (1 - probability);
    dropoutScaleFactor = cast(dropoutScaleFactor, superfloatOfX);
    mask = (rand(size(X), 'like', X) > probability) * dropoutScaleFactor;
end

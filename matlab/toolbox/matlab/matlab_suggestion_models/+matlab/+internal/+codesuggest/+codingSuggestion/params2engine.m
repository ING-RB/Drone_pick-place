function net = params2engine(p)
% PARAMS2ENGINE  Converts a struct of parameters to a CPU engine interface.
%
%    FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%    Its behavior may change, or it may be removed in a future release.

% Copyright 2023, The MathWorks Inc.

    net = matlab.internal.math.cnn.MLFusedNetwork('single');
    nLayers = numel(p.LayerArguments);
    for k = 1:nLayers
        net.addLayer(p.LayerArguments{k}{:});
    end
    net.connect(p.EdgeList);
    net.addNetworkInput(p.InputLocations, p.InputDataDimensions);
    net.addNetworkOutput(p.OutputLocations);

end
function resetDeepNetworkDesignerState(stateFile)

% Resets the state of Deep Network Designer app based on stateFile data
% Copyright 2022 The MathWorks, Inc.

stateStruct = [];
% Check to see if the file exists
if exist(stateFile, 'file') == 2
    try
        % Load will fail if stateFile is not a mat file,
        stateStruct = load(stateFile);
    catch
    end
end

network = [];
if ~isempty(stateStruct)
    propNames = fields(stateStruct);
    for i=1:numel(propNames)
        val = stateStruct.(propNames{i});
        if isa(val, 'nnet.cnn.layer.Layer') || isa(val, 'DAGNetwork') || isa(val, 'SeriesNetwork') || isa(val, 'nnet.cnn.LayerGraph') || isa(val, 'dlnetwork')
            network = val;
            break;
        end
    end
end

% Call the SDK function to set the state on DND.
deepapp.internal.sdk.replaceNetworkInDND(network);

end
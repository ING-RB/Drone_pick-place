function globalInputIds = getAllInputIds(obj)
% Get all input Ids for the CompositeDataProcessor built by this builder.
% This will match the order of global inputs of
% CompositeDataProcessor/feval.

%   Copyright 2023 The MathWorks, Inc.

g = obj.getAsGraph();
inputBuilders = g.Nodes.Builder(g.Nodes.IsGlobalInput);
globalInputIds = {inputBuilders.InputId};
end

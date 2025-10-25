function launchExplorerForBaseCode(basecode, dduxEntryPointId)
% Utility function to launch Addons Explorer for the given basecode.

% Copyright 2021 Mathworks Inc.

matlab.internal.addons.launchers.showExplorer('ddux-id', dduxEntryPointId, basecode);

end
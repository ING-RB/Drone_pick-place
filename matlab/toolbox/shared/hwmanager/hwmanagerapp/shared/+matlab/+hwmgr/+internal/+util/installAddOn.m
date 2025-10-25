function installAddOn(app,identifier,basecode)
% matlab.hwmgr.internal.util.installAddOn - function to launch addons
% explorer for the given BASECODE. The DDUX entrypoint value is the APP.

% Copyright 2021 Mathworks Inc.

matlab.internal.addons.launchers.showExplorer(app, identifier, basecode);
end
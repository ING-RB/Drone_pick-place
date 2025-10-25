classdef TestRunnerPluginLiaison < handle
    % This class is undocumented and may change in a future release.
    
    % Copyright 2017-2018 The MathWorks, Inc.
    
    properties
        Plugins (1,:) matlab.unittest.plugins.TestRunnerPlugin;
        PluginProviderData (1,1);
    end
end

% LocalWords:  Plugins unittest plugins

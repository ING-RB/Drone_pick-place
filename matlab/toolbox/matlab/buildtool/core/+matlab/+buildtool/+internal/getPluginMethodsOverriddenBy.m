function names = getPluginMethodsOverriddenBy(plugin)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2021-2022 The MathWorks, Inc.

arguments
    plugin (1,1) matlab.buildtool.plugins.BuildRunnerPlugin
end

import matlab.buildtool.internal.allPluginMethodNames;

pluginClass = metaclass(plugin);
methodList = pluginClass.MethodList;
methodNames = string({methodList.Name});

[~,idx] = find(allPluginMethodNames()' == methodNames);
mask = [methodList(idx).DefiningClass] ~= ?matlab.buildtool.plugins.BuildRunnerPlugin;
names = methodNames(idx(mask));
end


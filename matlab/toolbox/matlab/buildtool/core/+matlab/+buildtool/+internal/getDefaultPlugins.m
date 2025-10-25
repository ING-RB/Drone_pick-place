function plugins = getDefaultPlugins(options)
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2023 The MathWorks, Inc.

arguments
    options (1,1) struct = struct
end

pluginsFcn = @matlab.buildtool.internal.getFactoryDefaultPlugins;

overrideFcn = getenv("MW_MATLAB_BUILDTOOL_DEFAULT_PLUGINS_FCN_OVERRIDE");
if ~isempty(overrideFcn)
    pluginsFcn = str2func(overrideFcn);
end

plugins = pluginsFcn(options);
end
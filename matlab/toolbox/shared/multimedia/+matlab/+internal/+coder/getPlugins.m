function [pluginsToUse, converterPlugin, nullPlugin] = getPlugins()
%GETPLUGINS Query the path to the device plugins, converter plugin and null
%plugin to be used for reading video files in generated code.

%   Authors: DI
%   Copyright 2018 The MathWorks, Inc.

vpm = matlab.internal.video.PluginManager.getInstance();

converterPlugin = vpm.CoderConverter;
pluginsToUse = getAllPluginsForRead(vpm);
nullPlugin = vpm.NullPlugin;
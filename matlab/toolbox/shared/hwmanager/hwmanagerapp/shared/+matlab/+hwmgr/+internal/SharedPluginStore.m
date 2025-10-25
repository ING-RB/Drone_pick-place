classdef SharedPluginStore < handle
    % SHAREDPLUGINSTORE - This class maintains a list of a plugins loaded
    % by all the hardware manager framework objects and their respective
    % plugin loader modules. A common, shared reference to this shared
    % plugin store is maintained by all the plugin loader module instances
    % so they can share plugins and providers whenever possible, and also
    % be informed about when new plugins are avaialable.

    %   Copyright 2021 The MathWorks, Inc.

    properties (Access = 'public')
        PluginMap
    end
    
    methods
        function obj = SharedPluginStore()
            obj.PluginMap = containers.Map();
        end
        
        function insertPlugin(obj, plugin, deviceProviders, appletProviders, module)
            % Insert plugin - add a new entry for the plugin and related
            % providers to the plugin store.
            pluginDataStruct = struct('Plugin', plugin, ...
                'DeviceProviders', deviceProviders, ...
                'AppletProviders', appletProviders, ...
                'UseModules', module);
            obj.PluginMap(class(plugin)) = pluginDataStruct;
        end

        function updatePlugin(obj, plugin, deviceProviders, appletProviders, module)
            % Update an existing entry of a plugin with a new copy of the
            % plugin object and providers, keeping the UseModule data
            
            pluginData = obj.PluginMap(class(plugin));

            [found, ~] = ismember(pluginData.UseModules, module);
            if found
                error('Plugin Store Update: Cannot add module "%s" to plugin data for plugin "%s": Module already present in UseModules!', class(module), pluginClass);
            end
            
            % Use the existing module list, and add this module to the
            % module list
            pluginData.UseModules = [pluginData.UseModules; module];
            % Replace the plugin and the providers
            pluginData.Plugin = plugin;
            pluginData.DeviceProviders = deviceProviders;
            pluginData.AppletProviders = appletProviders;

            % Update the plugin map of the store
            obj.PluginMap(class(plugin)) = pluginData;

            % TODO: Notify all the UseModules of a plugin update. The
            % plugin modules can then notify their respective
            % controllers/device list modules that a new copy of plugins
            % and providers are available. This helps the DAQ use case of
            % multi window refresh for the same plugin.            
        end
        
        function removePlugin(obj, plugin)
            if obj.PluginMap.isKey(class(plugin))
                obj.PluginMap(class(plugin)) = [];
            else
                error('Plugin Store Remove: Could not remove plugin "%s" : Plugin does not exist in store', class(plugin));
            end
        end
        
        function removeAllPlugins(obj)
           allKeys = obj.PluginMap.keys();
           for i = 1:numel(allKeys)
              obj.PluginMap.remove(allKeys{i});
           end
        end
        
        function out = isInStore(obj, pluginClass)
            out = obj.PluginMap.isKey(pluginClass);
        end
        
        function pluginData = usePlugin(obj, pluginClass, module)
            
            % Update the plugin data to add the module to the UseModules
            pluginData = obj.PluginMap(pluginClass);
            [found, ~] = ismember(pluginData.UseModules, module);
            if found
                error('Plugin Store Add: Cannot add module "%s" to plugin data for plugin "%s": Module already present in UseModules!', class(module), pluginClass);
            end
            pluginData.UseModules = [pluginData.UseModules; module];
            obj.PluginMap(pluginClass) = pluginData;
        end
        
        function releasePlugin(obj, pluginClass, module)
            % Update the plugin data to add the module to the UseModules
            pluginData = obj.PluginMap(pluginClass);
            index = ismember(pluginData.UseModules, module);
            if ~any(index)
                error('Plugin Store Remove: Cannot remove module %s from plugin data for plugin "%s": Module does not exist in UseModules!', class(module), pluginClass);
            end
            pluginData.UseModules(index) = [];
            % If this is the last module releasing the plugin, then remove
            % it from the store
            if isempty(pluginData.UseModules)
                obj.PluginMap.remove(pluginClass);
            else
                obj.PluginMap(pluginClass) = pluginData;
            end
        end

        function notifyHwmgrAppRefresh(obj)
            % This method will notify the hardware manager app plugin
            % loader to relay a message to its controller that a refresh is
            % required as store has been updated

            % Find the hardware manager app's plugin loader module instance
            % and call the notify method on it
            allPluginData = obj.PluginMap.values();
            for i = 1:numel(allPluginData)
                for j = 1:numel(allPluginData{i}.UseModules)
                    pluginLoaderInstance = allPluginData{i}.UseModules(j);
                    if pluginLoaderInstance.Context.IsHwmgrApp()
                        pluginLoaderInstance.notifyExternalRefresh();
                        return;
                    end
                end
            end
        end
        
    end
    
    
    
end
classdef PluginLoader < matlabshared.mediator.internal.Publisher &...
                        matlabshared.mediator.internal.Subscriber & ...
                        matlab.hwmgr.internal.MessageLogger
    %PLUGINLOADER - This module is responsible for finding and constructing
    %Hardware Manager client plugins on the MATLAB path and providing them
    %to the rest of the Hardware Manager application.
    
    % Copyright 2017-2021 The MathWorks, Inc.
    
    properties (Constant)
        PluginStore = matlab.hwmgr.internal.SharedPluginStore();
    end

    properties
        % CONTEXT - The context under which the Hardware Manager Framework
        % is running
       Context
       % SEARCHFORNEWPLUGINS - Flag to indicate whether hardware manager
       % plugins should be scanned for on the MATLAB path or whether to use
       % the same set of plugin class names already known to the plugin
       % loader.
       SearchForNewPlugins = true; 

       % LastRefreshSoft - Boolean indicating whether the last refresh was
       % a soft refresh
       LastRefreshSoft
    end
    
    properties (Access = private)
        % LOADEDPLUGINS - An array of all the found plugin objects
        LoadedPlugins
    end
    
    properties (SetObservable)
        % Run the following command to see listeners for these properties:
        % matlab.hwmgr.internal.util.displayPropListeners('matlab.hwmgr.internal.PluginLoader');
        FoundDeviceProviders
        FoundAppletProviders
        RefreshRequired
    end
    
    properties (Constant)
        PluginPackage = 'matlab.hwmgr.plugins';
        PluginBase = 'matlab.hwmgr.internal.plugins.PluginBase';
    end
    
    methods (Static, Hidden)
        function pluginClasses = findAllPlugins()
            % This method will find all the plugins on the MATLAB path and
            % return the meta class objects
            
            try
                % findSubClasses will throw an error if the requested
                % package is not on the MATLAB path.
                pluginClasses = internal.findSubClasses(matlab.hwmgr.internal.PluginLoader.PluginPackage, ...
                    matlab.hwmgr.internal.PluginLoader.PluginBase, false);
            catch
                pluginClasses = [];
            end
        end
        
        function out = getPropsAndCallbacks()
          out = ... % Property to listen to         % Callback function
                [   "RefreshPlugins"                "handleRefreshPlugins"; ...
                    "NotifyHwmgrAppRefresh"         "handleNotifyHwmgrAppRefresh"; ...
                ];
        end
    end
    
    methods (Access = public, Hidden)
        function plugins = getLoadedPlugins(obj)
            plugins = obj.LoadedPlugins;
        end
    end
    
    methods (Access = public) % Class API methods
        
        function obj = PluginLoader(mediator)
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);
        end
        
        function subscribeToMediatorProperties(obj, src, evt)
            eventsAndCallbacks = obj.getPropsAndCallbacks();
            obj.subscribeWithGateways(eventsAndCallbacks, @obj.subscribe);
        end

        function handleRefreshPlugins(obj, doSoftLoad)
            if obj.Context.IsClientApp || ~obj.SearchForNewPlugins
                % If we are running in a client app context, or Hardware
                % Manager is started with a single plugin class specified,
                % then reload the same plugin class by instantiating a new
                % instance of the class.
                pluginClass = {obj.Context.PluginClass};
                obj.clearLoadedPlugins();
                obj.loadPluginsByClassName(pluginClass, doSoftLoad)
            else
                % Reload all plugins by searching the MATLAB path for
                % hardware manager plugin classes and instantiating them.
                obj.clearLoadedPlugins();
                obj.loadAllPlugins(doSoftLoad);
            end

            % Set the last refresh flag
            obj.LastRefreshSoft = doSoftLoad;
        end
        
        function clearLoadedPlugins(obj)
            store = obj.PluginStore;
            for i = 1:numel(obj.LoadedPlugins)
                store.releasePlugin(class(obj.LoadedPlugins(i)), obj);    
            end
            obj.LoadedPlugins = []; 
        end
        
        function loadAllPlugins(obj, doSoftLoad)
            arguments
               obj
               doSoftLoad (1,1) logical = false;
            end
            
            % This method will construct each plugin class found on the
            % MATLAB path and keep it in the loadedPlugins array
            
            foundPlugins = obj.findAllPlugins();
            if isempty(foundPlugins)
               foundPlugins = {}; 
            end
            
            % The findAllPlugins method returns a cell array of meta
            % classes. Collect a cell array of class name strings
            pluginClassNames = cellfun(@(x)x.Name, foundPlugins, 'UniformOutput', false);
            
            obj.loadPluginsByClassName(pluginClassNames, doSoftLoad);
        end
        
        
        function softLoadPlugins(obj)
            obj.loadAllPlugins(true);
        end
        
        function hardLoadPlugins(obj)
            obj.loadAllPlugins(false);
        end
        
        function loadPluginsByClassName(obj, plugin, doSoftLoad)
            % This method will load plugins with the specified
            % PLUGINCLASSNAMES or by PLUGINOBJECTS.
            arguments
               obj
               plugin
               doSoftLoad (1,1) logical = false;
            end
            deviceProviders = [];
            appletProviders = [];
            
            for i = 1:numel(plugin)
                try
                    % Check if the plugin passed in is a class name string
                    if isstring(plugin{i}) || ischar(plugin{i})
                        % Convert to string array
                        pluginObj = feval(string(plugin{i}));
                        pluginClass = plugin{i};
                    else
                        % Assume the plugin passed in is an object
                        pluginObj = plugin{i};
                        pluginClass = class(pluginObj);
                    end
                    
                    pluginStore = obj.PluginStore;
                    
                    if doSoftLoad
                        if pluginStore.isInStore(pluginClass)
                            [currDevProviders, currAppletProviders] = usePluginAndGetCachedProviders();
                        else
                            [currDevProviders, currAppletProviders] = insertPluginAndProvidersToStore();
                        end    
                    else
                        if pluginStore.isInStore(pluginClass)
                            [currDevProviders, currAppletProviders] = updatePluginAndProvidersInStore();
                        else
                            [currDevProviders, currAppletProviders] = insertPluginAndProvidersToStore();
                        end
                    end
                    
                    obj.LoadedPlugins = [obj.LoadedPlugins; pluginObj];
                    
                    deviceProviders = [deviceProviders; currDevProviders];
                    appletProviders = [appletProviders; currAppletProviders;];
                catch ex
                    warning(ex.identifier, '%s', ex.message);
                end
                
            end

            
            % Send device providers to the device list (for enum devices)
            % and toolstrip (for non enum devices)
            obj.logAndSet("FoundDeviceProviders", deviceProviders);
            
            % Send the applet providers to the AppletRunner
            obj.logAndSet("FoundAppletProviders", appletProviders);
            

            % ------------------------ Nested Helpers --------------------%

            function [currDevProviders, currAppletProviders] = usePluginAndGetCachedProviders()
                % This method will retrieve a plugin entry from the plugin
                % store by the plugin class name by incrementing the plugin
                % use count in the plugin store, and then get the device
                % and applet providers for that plugin from the plugin
                % store entry.
                pluginData = pluginStore.usePlugin(pluginClass, obj);
                currDevProviders = pluginData.DeviceProviders;
                currAppletProviders = pluginData.AppletProviders;
            end
            
            function [currDevProviders, currAppletProviders] = insertPluginAndProvidersToStore()
                % This method will add a new plugin, device and applet
                % providers objects to the store. Used for a plugin that
                % doesn't have an entry in the store.
                currDevProviders = pluginObj.getDeviceProvider();
                currAppletProviders = pluginObj.getAppletProvider();
                pluginStore.insertPlugin(pluginObj, currDevProviders, currAppletProviders, obj);
            end
            
            function [currDevProviders, currAppletProviders] = updatePluginAndProvidersInStore()
                % This method will update an existing plugin entry in the
                % store with a new plugin, device and applet provider
                % objects while maintaining the list of modules using the
                % plugin
                currDevProviders = pluginObj.getDeviceProvider();
                currAppletProviders = pluginObj.getAppletProvider();
                pluginStore.updatePlugin(pluginObj, currDevProviders, currAppletProviders, obj);
            end
        end
        
        function appletProviders = getAppletProviders(obj)
            appletProviders = obj.getProviders(matlab.hwmgr.internal.HWManagerProviderTypes.Applet);
        end
        
        function deviceProviders = getDeviceProviders(obj)
            deviceProviders = obj.getProviders(matlab.hwmgr.internal.HWManagerProviderTypes.Device);
        end
        
        
        function providers = getProviders(obj, providerType)
            % This method will loop over all the available plugins and get
            % the requested provider types.
            
            providers = [];
            if providerType.isDeviceType()
                providers = localCallProviderMethodLoop(obj.LoadedPlugins, 'getDeviceProvider');
            elseif providerType.isAppletType()
                providers = localCallProviderMethodLoop(obj.LoadedPlugins, 'getAppletProvider');
            end
            
            function allProviders = localCallProviderMethodLoop(loadedPlugins, methodToCall)
                % Loop over all the plugins and invoke the provided
                % methodToCall
                allProviders = [];
                for i = 1:numel(loadedPlugins)
                    try
                        providerObj = loadedPlugins(i).(methodToCall)();
                        allProviders = [allProviders; providerObj]; %#ok<AGROW>
                    catch ex
                        warning(ex.identifier, '%s', ex.message);
                    end
                end
            end
            
        end

        function notifyExternalRefresh(obj)
            obj.logAndSet("RefreshRequired", true);
        end

        function handleNotifyHwmgrAppRefresh(obj, ~)
            % Notify the hardware manager app's plugin loader via the
            % plugin store that a refresh is now required
            obj.PluginStore.notifyHwmgrAppRefresh();
        end
        
        function delete(obj)
           obj.clearLoadedPlugins(); 
        end
        
    end
    
end

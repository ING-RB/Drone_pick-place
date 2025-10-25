classdef HardwareManagerFramework < handle
    %HARDWAREMANAGERFRAMEWORK The Hardware Manager Framework is the main
    %class responsible for managing the Hardware Manager application.

    %   Copyright 2016-2023 The MathWorks, Inc.

    properties (Constant)
        InstanceMap = containers.Map();
        FrameworkClassesImplMap = containers.Map();
    end

    %Framework Classes
    properties(Hidden)
        %DISPLAYMANAGER - Provides GUI functionality
        DisplayManager

        %MODULEMANAGER - Loads all of the Modules based on the
        %configuration file identified in the HardwareManagerProperties
        ModuleManager

        %MEDIATOR - A mediator that facilitates communication between
        %modules and the framework classes.
        Mediator

        %CONTEXT - The framework context (Client App or Hardware Manager
        %App)
        Context
    end

    properties (Access = 'private')
        Controller
    end

    % Framework class API methods
    methods

        function obj = HardwareManagerFramework(context)
            arguments
                context = matlab.hwmgr.internal.HwmgrAppContext("All");
            end

            obj.Context = context;

            mlock;
            
            % Determine which framework classes to use
            moduleManagerClass = matlab.hwmgr.internal.HardwareManagerFramework.getModuleManagerClass();
            displayManagerClass = matlab.hwmgr.internal.HardwareManagerFramework.getDisplayManagerClass();

            % Construct the mediator that will facilitate communication
            % between the different parts of Hardware Manager
            obj.Mediator = matlabshared.mediator.internal.Mediator;


            try
                % Initialize the Module Manager to load up the modules so
                % that we can determine what display mode to operate in
                obj.ModuleManager = feval(moduleManagerClass, obj.Mediator, context);

                % Initialize the Display Manager with all of the
                % information we have from the Module Manager about the
                % desired displays
                obj.DisplayManager = feval(displayManagerClass, obj.Mediator, context);

                % Instantiate the Application Controller Class
                if context.IsClientApp
                    obj.Controller = matlab.hwmgr.internal.ClientAppController(obj.Mediator);
                else
                    obj.Controller = matlab.hwmgr.internal.HwmgrAppController(obj.Mediator);
                end

                obj.Mediator.connect();
            catch ex
                throwAsCaller(ex);
            end

            % Update framework instance map
            map = obj.InstanceMap;
            allInstances = obj.getAllInstances();
            if isempty(allInstances)
                map("All") = obj;
            else
                map("All") = [allInstances obj];
            end

        end

        function loadPlugins(obj, pluginClasses, doSoftLoad)
            % LOADPLUGINS - method to load one or more specified plugins.
            % PLUGINCLASSES can be a cell array of class names or the
            % string "ALL" to load all plugins. "NONE" will unload plugins.

            arguments
               obj
               pluginClasses
               doSoftLoad (1,1) logical = true;
            end
            
            pluginClasses = convertStringsToChars(pluginClasses);
            % check if we need to wrap pluginClasses in a cell
            if ~iscell(pluginClasses)   
                pluginClasses = {pluginClasses};
            end

            hModule = obj.getModuleByName('PluginLoader');

            if numel(pluginClasses) == 1
                switch pluginClasses{1}
                    case 'ALL'
                        hModule.loadAllPlugins(doSoftLoad);
                    case 'NONE'
                        hModule.clearLoadedPlugins();
                    otherwise
                        hModule.loadPluginsByClassName(pluginClasses, doSoftLoad);
                end
            else
                hModule.loadPluginsByClassName(pluginClasses);
            end

        end

        function hardLoadPlugins(obj, pluginClasses)
            obj.loadPlugins(pluginClasses, false);
        end
        
        function softLoadPlugins(obj, pluginClasses)
            obj.loadPlugins(pluginClasses, true);
        end
        
        function refreshDeviceList(obj, doSoftLoad)
            % REFRESHDEVICELIST - method to refresh the devices in the
            %   device list by enumerating all devices via device providers
            %   and updating the device list view with all devices
            % 
            % NOTE: Use clickRefreshButtonOnCurrentPage instead of this
            % legacymethod. This will be deleted.
            arguments
               obj
               doSoftLoad (1,1) logical = false;
            end

            obj.Controller.refreshHwmgr(doSoftLoad);
        end

        function clickRefreshButtonOnCurrentPage(obj)
            switch obj.Controller.CurrentPage
                case "StartPage"
                    obj.getModuleByName("StartPage").clientRefresh([]);
                case "RunningAppPage"
                    obj.getModuleByName("RunningAppDeviceListPage").clientRefresh([]);
                case "DontSeeDevicePage"
                    obj.getModuleByName("DontSeeDevice").clientDontSeeDevicePageRefresh([]);
                otherwise
                    error("Controller's current screen is unknown to the framework");
            end


        end

        function selectAddNonEnumDevice(obj, tag)
        % SELECTADDNONENUMDEVICE - method to select a add non enum device
        % card to start the non enum device configuration for that device.

        % First, find the index corresponding to the provided tag. The
        % array of descriptors on the lading page is the same as it is in
        % the front end. Landing Page, Add Device Page and Device List all
        % have the same copy of the AllDeviceDescriptors array.
        descriptors = obj.getModuleByName("StartPage").AllDeviceDescriptors;

        foundIndex = [];
        for i = 1:numel(descriptors)
            % The tag provided by teams is of the format
            % NEDGALLERY_ITEM_<tag returned by descriptor>. 
            tagToFind = upper("NEDGALLERY_ITEM_" + descriptors(i).getGalleryButtonTag());
            if tagToFind == tag
                foundIndex = i-1;
                break;
            end
        end

        if isempty(foundIndex)
            error("Couldn't find button with tag " + string(tag));
        end

        switch obj.Controller.CurrentPage
            case "StartPage"
                obj.getModuleByName("StartPage").clientAddNonEnumDevice(foundIndex);
            case "RunningAppPage"
                obj.getModuleByName("RunningAppDeviceListPage").clientAddNonEnumDevice(foundIndex);
            case "DontSeeDevicePage"
                obj.getModuleByName("DontSeeDevice").clientAddNonEnumDevice(foundIndex);
            otherwise
                error("Controller's current screen is unknown to the framework");
        end


        end

        function selectDevice(obj, deviceIndex)
            % SELECTDEVICE - method to select a device in the device list
            % view based on the device index provided. Note that the device
            % will be selected from the list of devices in the view which
            % may be filtered.

            % First, determine which screen the framework is on, and call
            % the right controller method
            devInfo = struct();

            % Zero based index on the front end
            devInfo.Uuid = deviceIndex - 1;
            switch obj.Controller.CurrentPage
                case "StartPage"
                    obj.getModuleByName("StartPage").clientSelectDevice(devInfo);
                case "RunningAppPage"
                    obj.getModuleByName("RunningAppDeviceListPage").clientSelectDevice(devInfo);
                case "DontSeeDevicePage"
                    obj.getModuleByName("DontSeeDevice").clientSelectDevice(devInfo);
                otherwise
                    error("Controller's current screen is unknown to the framework");
            end
             
        end

        function configureDevice(obj, deviceIndex)
            % CONFIGUREDEVICE - method to configure a device in the device list
            % view based on the device index provided. Note that the device
            % will be selected from the list of devices in the view which
            % may be filtered.

            % First, determine which screen the framework is on, and call
            % the right controller method
            devInfo = struct();

            % Zero based index on the front end
            devInfo.Uuid = deviceIndex - 1;
            switch obj.Controller.CurrentPage
                case "StartPage"
                    obj.getModuleByName("StartPage").clientConfigureDevice(devInfo);
                case "RunningAppPage"
                    obj.getModuleByName("RunningAppDeviceListPage").clientConfigureDevice(devInfo);
                otherwise
                    error("Controller's current screen is unknown to the framework");
            end
             
        end

        function setDeviceListViewFilter(obj, filterType, filterValue)
            % SETDEVICELISTVIEWFILTER - method to filter the device list
            % based on a filter critieria, FILTERTYPE and filter value
            % FILTERVALUE. FILTERTYPE can be one of {'Applet', 'None'}
            % FILTERVALUE can be an applet class name if FILTERTYPE is
            % 'Applet', otherwise it is not used

            % Send a message to the device list module to filter the device
            % list view based on the provided filter type and value

            hModule = obj.getModuleByName('DeviceList');
            hModule.setDeviceListFilter(struct('FilterType', filterType, 'FilterValue', filterValue));
        end

        function setLaunchAppletOnDeviceChange(obj, launchFlag)
            % SETLAUNCHAPPLETONDEVICECHANGE - method to indicate to the
            % device list that on device change, whether the filtering
            % applet should also be launched
            hModule = obj.getModuleByName('DeviceList');
            hModule.setLaunchAppletOnDeviceChange(launchFlag);
        end

        function close(obj)
            % CLOSE - closes the hardware manager UI. Note that this will
            % also delete the hardware manager framework handle
            obj.DisplayManager.Window.closeDisplay();
        end

        function show(obj)
            % SHOW - show the hardware manager UI

            if obj.isShowing()
                % Only bring to front
                obj.DisplayManager.Window.show();
            else
                % Render display
                obj.DisplayManager.Window.showDisplay();
            end
        end

        function bool = isShowing(obj)
            % ISSHOWING - returns true if the application window is up
            % otherwise returns false
            bool = obj.DisplayManager.Window.isShowing();
        end

        function delete(obj)
            % Explicitly call the Display Manager destructor since it has a
            % reference to the ToolGroup, and the recommendation from the
            % ToolGroup team is to always explicitly call their destructors
            delete(obj.DisplayManager);
            delete(obj.ModuleManager);
            delete(obj.Controller);

            % Update instance map
            allInstances = obj.getAllInstances();
            for i = 1:numel(allInstances)
                if allInstances(i) == obj
                    allInstances(i) = [];
                    if isempty(allInstances)
                        obj.unlockFramework;
                    end
                    obj.InstanceMap("All") = allInstances;
                    break;
                end
            end
        end

        function setTitle(obj, newTitle)
            % SETTITLE - sets the app title.
            newTitle = convertCharsToStrings(newTitle);
            validateattributes(newTitle, {'string'}, {'nonempty', 'scalar'});
            obj.Controller.setApplicationWindowTitle(newTitle);
        end

        function controller = getMainController(obj)
            controller = obj.Controller;
        end

    end

    methods (Hidden)
        % APIs for testing and sandbox workflows
        function module = getModuleByName(obj, name)
            % Returns the requested module handle by module nameclas
            if isKey(obj.ModuleManager.ModuleMap, name)
                module = obj.ModuleManager.ModuleMap(name).handle;

            else
                error('Specified module "%s" does not exist', name);
            end
        end

    end

    methods(Static)

        function allInstances = getAllInstances()
            allInstances = [];
            map = matlab.hwmgr.internal.HardwareManagerFramework.InstanceMap;
            if map.isKey("All")
                allInstances = map("All");
            end
        end

        function obj = getInstance(varargin)
            % MLOCK the getInstance method which will in turn protect the
            % allInstances. This protects the framework from a
            % CLEAR Note that this does NOT protect the hardware manager
            % from a CLOSE ALL FORCE

            p = inputParser;
            p.addParameter("CreateInstance", true, @islogical);
            p.parse(varargin{:});

            createInstance = p.Results.CreateInstance;

            allInstances = matlab.hwmgr.internal.HardwareManagerFramework.getAllInstances();
            if isempty(allInstances) && createInstance
                try
                    obj = matlab.hwmgr.internal.HardwareManagerFramework();
                catch ex
                    throw(addCause(MException(message('hwmanagerapp:framework:InitFailure')), ex));
                end
                
            elseif numel(allInstances) >= 1
                obj = allInstances(end);
            else
                obj = allInstances;
            end
        end

        function unlockFramework()
            % UNLOCKFRAMEWORK - Unlocks the framework to allow it to be
            % cleared from memory

            munlock('matlab.hwmgr.internal.HardwareManagerFramework.getInstance');
        end

        function setModuleManagerClass(className)
            implMap = matlab.hwmgr.internal.HardwareManagerFramework.FrameworkClassesImplMap;
            implMap('ModuleManagerClass') = className;
        end

        function className = getModuleManagerClass()
            defaultClass = "matlab.hwmgr.internal.FrameworkModuleManager";
            overrideClass = matlab.hwmgr.internal.HardwareManagerFramework.getOverrideManagerImplClass('ModuleManagerClass');
            if overrideClass == ""
                className = defaultClass;
            else
                className = overrideClass;
            end
        end

        function setDisplayManagerClass(className)
            implMap = matlab.hwmgr.internal.HardwareManagerFramework.FrameworkClassesImplMap;
            implMap('ModuleManagerClass') = className;
        end

        function className = getDisplayManagerClass()
            defaultClass = "matlab.hwmgr.internal.FrameworkDisplayManager";
            overrideClass = matlab.hwmgr.internal.HardwareManagerFramework.getOverrideManagerImplClass('DisplayManagerClass');
            if overrideClass == ""
                className = defaultClass;
            else
                className = overrideClass;
            end
        end
        
    end

    methods (Static, Access = private)
        function overrideClass = getOverrideManagerImplClass(managerType)
            overrideClass = '';
            implMap = matlab.hwmgr.internal.HardwareManagerFramework.FrameworkClassesImplMap;
            if implMap.isKey(managerType)
                overrideClass = implMap(managerType);
            end
        end
    end

end


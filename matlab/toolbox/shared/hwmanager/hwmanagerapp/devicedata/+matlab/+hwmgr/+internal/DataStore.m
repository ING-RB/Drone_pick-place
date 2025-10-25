classdef DataStore < handle
    %DATASTORE - A store of all Hardware Manager app related data and APIs.
    %   Call "matlab.hwmgr.internal.DataStoreHelper.getDataStore.<method>"
    %   Example
    %   "matlab.hwmgr.internal.DataStoreHelper.getDataStore.getAllKeywords"

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (Hidden)
        ToolboxGeneralData
        SupportPackageGeneralData
        HardwareKeywordData
        AppletData
        AddOnData
        LiveTaskData
        HardwareSetupData
        ExampleData
        SimulinkModelData
        HelpDocData
    end

    properties (Hidden, Constant)
        GENERAL_DATA_PATH = fullfile("toolbox", "shared", "hwmanager", "hwmanagerapp", "devicedata", "addondata")
        TOOLBOX_FILE_NAME = "toolboxData.json"
        SPKG_FILE_NAME = "spkgData.json"
        
        PluginPackage = 'matlab.hwmgr.internal.data.plugins';
        PluginBase = 'matlab.hwmgr.internal.data.plugins.PluginBase';
    end

    methods (Access = {?matlab.hwmgr.internal.DataStoreHelper, ?matlab.unittest.TestCase})
        function obj = DataStore()
            obj.loadGeneralData();
            obj.loadDataFromPlugins();
        end
    end

    methods (Access = {?matlab.unittest.TestCase})
        function loadGeneralData(obj)
            toolboxFilePath = fullfile(matlabroot, obj.GENERAL_DATA_PATH, obj.TOOLBOX_FILE_NAME);
            toolboxTxt = fileread(toolboxFilePath);
            obj.ToolboxGeneralData = jsondecode(toolboxTxt);
            
            spkgFilePath = fullfile(matlabroot, obj.GENERAL_DATA_PATH, obj.SPKG_FILE_NAME);
            spkgTxt = fileread(spkgFilePath);
            obj.SupportPackageGeneralData = jsondecode(spkgTxt);
        end

        function loadDataFromPlugins(obj)
            pluginClassNames = obj.findAllPlugins();
            
            % Get all data from plugins
            for i = 1:length(pluginClassNames)
                try
                    plugin = feval(pluginClassNames{i});
                    obj.HardwareKeywordData = [obj.HardwareKeywordData, plugin.HardwareKeywordData];
                    obj.AppletData = [obj.AppletData, plugin.AppletData];
                    obj.AddOnData = [obj.AddOnData, plugin.AddOnData];
                    obj.LiveTaskData = [obj.LiveTaskData, plugin.LiveTaskData];
                    obj.HardwareSetupData = [obj.HardwareSetupData, plugin.HardwareSetupData];
                    obj.ExampleData = [obj.ExampleData, plugin.ExampleData];
                    obj.SimulinkModelData = [obj.SimulinkModelData, plugin.SimulinkModelData];
                    obj.HelpDocData = [obj.HelpDocData, plugin.HelpDocData];

                catch ME
                    disp(ME)
                    warning(strcat(pluginClassNames{i}, " is not valid"));
                end
            end

            if isempty(pluginClassNames)
                % Early return if no plugin found
                return
            end

            % Sort keyword data alphabetically
            [~, indices] = sort([obj.HardwareKeywordData.Keyword]);
            obj.HardwareKeywordData = obj.HardwareKeywordData(indices);            
        end
        
        function pluginClassNames = findAllPlugins(obj)
            % This method will find all the plugins on the MATLAB path and
            % return the meta class objects

            % Check for the environment variable to load different plugins
            % for testing and production environment
            if ~isempty(getenv('HARDWARE_MANAGER_MOCK_DATAPLUGIN'))
                pluginPackage = 'matlab.hwmgr.internal.data.mockplugins';
            else
                pluginPackage = matlab.hwmgr.internal.DataStore.PluginPackage;
            end

            try
                % findSubClasses will throw an error if the requested
                % package is not on the MATLAB path.
                pluginClasses = internal.findSubClasses(pluginPackage, ...
                    matlab.hwmgr.internal.DataStore.PluginBase, false);
                pluginClassNames = cellfun(@(x)x.Name, pluginClasses, 'UniformOutput', false);
            catch
                pluginClassNames = [];
            end
        end
    end

    methods
        function reloadDataStore(obj)
            obj.HardwareKeywordData = [];
            obj.AddOnData = [];
            obj.AppletData = [];
            obj.LiveTaskData = [];
            obj.HardwareSetupData = [];
            obj.ExampleData = [];
            obj.SimulinkModelData = [];
            obj.HelpDocData = [];

            obj.loadDataFromPlugins();
        end

        function addOnData = getAddOnsByBaseCodes(obj, baseCodes)
            % Base codes in the form of string array
            addOnData = [];
            for i = 1:length(baseCodes)
                addOnData = [addOnData, obj.AddOnData(arrayfun(@(x) isequal(x.BaseCode, baseCodes(i)), obj.AddOnData))];
            end
        end

        function launchableData = getLaunchableData(obj, identifier)
            launchableData = [];

            categories = string(enumeration('matlab.hwmgr.internal.data.FeatureCategory'));

            for i = 1:length(categories)
                % Retrieve all entries matching any of the identifiers.
                matchedEntries = arrayfun(@(x)ismember(x.Identifier, identifier), obj.(categories(i) + "Data"));

                % If a match is found, return the launchable data objects
                if any(matchedEntries)
                    launchableData = obj.(categories(i) + "Data")(matchedEntries);
                    return;
                end
            end
        end

        function toolboxBaseCode = getSpkgRequiredProduct(obj, spkgBaseCode)
            % Get base code of the product required by the support package
            if ~isfield(obj.SupportPackageGeneralData, spkgBaseCode)
                error("hwmanagerapp:dataStore:invalidSpkg", "Invalid support pacage base code: %s", spkgBaseCode);
            end
            spkg = obj.SupportPackageGeneralData.(spkgBaseCode);
            toolboxBaseCode = string(spkg.RequiredProducts{1});
        end

        function addOnData = getAllAddOnsWithAsyncioPlugin(obj)
            % Get all AddOns with the AsyncioDevicePlugin field set
            addOnData = obj.AddOnData(arrayfun(@(x) ~isempty(x.AsyncioDevicePlugin), obj.AddOnData));
        end

        function validAddOns = getAddOnsWithValidAsyncioPlugin(obj)
            % Get all AddOns with valid AsyncioDevicePlugin path
            % "valid" means the asyncio plugin path points to a valid file
            % A device plugin path could be invalid when the data plugin
            % has been updated but the device plugin has not reach the same
            % cluster.
            allAddOns = obj.getAllAddOnsWithAsyncioPlugin();
            validAddOns = [];
            % Define extention type by OS
            if ismac
                ext = ".dylib";
            elseif isunix
                ext = ".so";
            else % ispc
                ext = ".dll";
            end
            for i = 1:length(allAddOns)
                filePath = strcat(allAddOns(i).AsyncioDevicePlugin, ext);
                % Account for libmw prefix for library files on Linux and Mac.
                if (ismac || isunix)
                    % If libmw prefix is already added to the plugin name,
                    % skip file name manipulation.
                    if(~contains(filePath,"libmw"))
                        posArray = strfind(filePath,"/");
                        % Extract plugin name.
                        pluginName = extractAfter(filePath,posArray(end));
                        % Add prefix to the plugin name.
                        newPluginName = "libmw" + pluginName;
                        % Add updated plugin name back to full plugin file path.
                        filePath = extractBefore(filePath,posArray(end)+1) + newPluginName;
                    end
                end
                if isfile(filePath)
                   validAddOns = [validAddOns, allAddOns(i)]; 
                end
            end
        end
    end
end

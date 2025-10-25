classdef DataFactory < handle
    %DATAFACTORY Data factory for creating data objects

    % Copyright 2021-2024 The MathWorks, Inc.
    
    methods (Static)
        function hardwareKeywordData = createHardwareKeywordData(keyword, ...
                description, tooltipText, categories, nameValueArgs)

            arguments
                keyword (1, 1) string
                description (1, 1) string
                tooltipText (1, 1) string
                categories (1, :) matlab.hwmgr.internal.data.HardwareKeywordCategory {mustBeNonempty}
                nameValueArgs.KeywordRelatedBaseCodes (1, :) string = string.empty()
                nameValueArgs.Manufacturers (1, :) containers.Map = containers.Map.empty()
                nameValueArgs.AppletClasses (1, :) string = string.empty()
                nameValueArgs.ManufacturerPlaceholder (1, 1) string = ""
            end

            nameValueProps = ["KeywordRelatedBaseCodes", "Manufacturers", "AppletClasses", "ManufacturerPlaceholder"];
            parsedNameValueArgs = matlab.hwmgr.internal.data.DataFactory.parseNameValueArgsForConstructor(nameValueArgs, nameValueProps);
            hardwareKeywordData = matlab.hwmgr.internal.data.HardwareKeywordData(...
                keyword, description, tooltipText, categories, parsedNameValueArgs{:});
        end

        function appletData = createAppletData(appletDisplayName, appletClass, ...
                pluginClass, description, iconID, learnMoreLink, ...
                troubleshootingLinks, identifier, nameValueArgs)

            arguments
                appletDisplayName (1, 1) string
                appletClass (1, 1) string
                pluginClass (1, 1) string
                description (1, 1) string
                iconID (1, 1) string
                learnMoreLink (1, 1)
                troubleshootingLinks (1, :) {mustBeNonempty}
                identifier = appletClass                                    % Forward compatibility : Set identifer to appletClass
                nameValueArgs.DescriptionHeading = appletDisplayName        % Forward compatibility: Set DescriptionHeading to appletDisplayName
                nameValueArgs.BaseProductConstraints (1, :) string= string.empty()
                nameValueArgs.PlatformConstraints (1, :) string = string.empty()
                nameValueArgs.ToolboxBaseCodes (1, :) string = string.empty()
                nameValueArgs.SupportPackageBaseCodes (1, :) string = string.empty()
            end

            validateattributes(learnMoreLink, ["matlab.hwmgr.internal.data.LinkData", "matlab.hwmgr.internal.data.DocLinkData"], "scalar");
            validateattributes(troubleshootingLinks, ["matlab.hwmgr.internal.data.LinkData", "matlab.hwmgr.internal.data.DocLinkData"], "nonempty");

            nameValueProps = ["DescriptionHeading", "BaseProductConstraints", ...
                              "PlatformConstraints", "ToolboxBaseCodes", ...
                              "SupportPackageBaseCodes"];

            parsedNameValueArgs = matlab.hwmgr.internal.data.DataFactory.parseNameValueArgsForConstructor(nameValueArgs, nameValueProps);

            appletData = matlab.hwmgr.internal.data.AppletData(appletDisplayName, appletClass, ...
                                                               pluginClass, description, iconID, ...
                                                               learnMoreLink, troubleshootingLinks, ...
                                                               identifier, parsedNameValueArgs{:});
        end

        function liveTaskData = createLiveTaskData(liveTaskDisplayName, entryPoint, pluginClass, ...
                description, iconID, learnMoreLink, ...
                identifier, nameValueArgs)

            arguments
                liveTaskDisplayName (1, 1) string
                entryPoint (1, 1) string
                pluginClass (1, 1) string
                description (1, 1) string  
                iconID (1, 1) string
                learnMoreLink (1, 1)
                identifier = liveTaskDisplayName                        % Forward compatibility: Set identifer to liveTaskDisplayName
                nameValueArgs.DescriptionHeading = liveTaskDisplayName  % Forward compatibility: Set DescriptionHeading to liveTaskDisplayName
                nameValueArgs.BaseProductConstraints (1, :) string= string.empty()
                nameValueArgs.PlatformConstraints (1, :) string = string.empty()
                nameValueArgs.ToolboxBaseCodes (1, :) string = string.empty()
                nameValueArgs.SupportPackageBaseCodes (1, :) string = string.empty()
            end

            nameValueProps = ["DescriptionHeading", "BaseProductConstraints", ...
                              "PlatformConstraints","ToolboxBaseCodes", ...
                              "SupportPackageBaseCodes"];

            parsedNameValueArgs = matlab.hwmgr.internal.data.DataFactory.parseNameValueArgsForConstructor(nameValueArgs, nameValueProps);
            liveTaskData = matlab.hwmgr.internal.data.LiveTaskData(liveTaskDisplayName, ...
                entryPoint, pluginClass, description, iconID, learnMoreLink, ...
                identifier, parsedNameValueArgs{:});
        end

        function launchableData = createHelpDocData(displayName, description, iconID, ...
                helpDocLink, identifier, nameValueArgs)

            arguments
                displayName (1, 1) string
                description (1, 1) string
                iconID (1, 1) string
                helpDocLink (1, 1)
                identifier {mustBeNonempty}
                nameValueArgs.RelatedAddOnBaseCodes (1, :) string = string.empty()
                nameValueArgs.DescriptionHeading = displayName
                nameValueArgs.BaseProductConstraints (1, :) string= string.empty()
                nameValueArgs.PlatformConstraints (1, :) string = string.empty()
                nameValueArgs.ToolboxBaseCodes (1, :) string = string.empty()
                nameValueArgs.SupportPackageBaseCodes (1, :) string = string.empty()
            end

            nameValueProps = ["RelatedAddOnBaseCodes", "DescriptionHeading", ...
                              "BaseProductConstraints", ...
                              "PlatformConstraints", "ToolboxBaseCodes", ...
                              "SupportPackageBaseCodes"];

            parsedNameValueArgs = matlab.hwmgr.internal.data.DataFactory.parseNameValueArgsForConstructor(nameValueArgs, nameValueProps);
            launchableData = matlab.hwmgr.internal.data.HelpDocData(displayName, ...
                description, iconID, helpDocLink, ...
                identifier, parsedNameValueArgs{:});
        end

        function addOnData = createAddOnData(baseCode, fullName, requiredAddOnBaseCodes, nameValueArgs)
            arguments
                baseCode (1, 1) string
                fullName (1, 1) string
                requiredAddOnBaseCodes (1, :) string = string.empty();
                nameValueArgs.AsyncioDevicePlugin (1, :) string = string.empty()
                nameValueArgs.AsyncioConverterPlugin (1, :) string = string.empty()
                nameValueArgs.ClientEnumeratorAddOnSwitch (1, :) string = string.empty()
            end

            nameValueProps = ["AsyncioDevicePlugin", "AsyncioConverterPlugin", "ClientEnumeratorAddOnSwitch"];
            parsedNameValueArgs = matlab.hwmgr.internal.data.DataFactory.parseNameValueArgsForConstructor(nameValueArgs, nameValueProps);

            addOnData = matlab.hwmgr.internal.data.AddOnData(baseCode, ...
                fullName, requiredAddOnBaseCodes, parsedNameValueArgs{:});
        end

        function deviceAppletData = createDeviceAppletData(appletClass, supportingAddOnBaseCodes, skipSupportingAddonInstallation, identifierReference)
            arguments
                appletClass (1, 1) string
                supportingAddOnBaseCodes (1, :) string = string.empty();
                skipSupportingAddonInstallation = dictionary(string.empty, logical.empty)
                identifierReference = appletClass
            end

            deviceAppletData = matlab.hwmgr.internal.data.DeviceAppletData(...
                appletClass, supportingAddOnBaseCodes, skipSupportingAddonInstallation, identifierReference);
        end

        function deviceLaunchableData = createDeviceLaunchableData(identifierReference, supportingAddOnBaseCodes, skipSupportingAddonInstallation)
            arguments
                identifierReference (1, 1) string
                supportingAddOnBaseCodes (1, :) string = string.empty()
                skipSupportingAddonInstallation = dictionary(string.empty, logical.empty)
            end

            deviceLaunchableData = matlab.hwmgr.internal.data.DeviceLaunchableData(...
                identifierReference, supportingAddOnBaseCodes, skipSupportingAddonInstallation);
        end

        function deviceEnumerableConfigData = createDeviceEnumerableConfigData(appletClass, enumerableDeviceDescriptor, needsConfiguration)
            arguments
                appletClass (1, 1) string
                enumerableDeviceDescriptor (1, 1) string
                needsConfiguration (1,1) logical
            end

            deviceEnumerableConfigData = matlab.hwmgr.internal.data.DeviceEnumerableConfigData(...
                appletClass, enumerableDeviceDescriptor, needsConfiguration);
        end

        function deviceLiveTaskData = createDeviceLiveTaskData(liveTaskDisplayName, supportingAddOnBaseCodes, skipSupportingAddonInstallation, identifierReference)
            arguments
                liveTaskDisplayName (1, 1) string
                supportingAddOnBaseCodes (1, :) string = string.empty()
                skipSupportingAddonInstallation = dictionary(string.empty, logical.empty)
                identifierReference = liveTaskDisplayName
            end

            deviceLiveTaskData = matlab.hwmgr.internal.data.DeviceLiveTaskData(...
                liveTaskDisplayName, supportingAddOnBaseCodes, skipSupportingAddonInstallation, identifierReference);
        end

        function linkData = createLinkData(title, url)
            arguments
                title (1, 1) string
                url (1, 1) string
            end
            linkData = matlab.hwmgr.internal.data.LinkData(title, url);
        end

        function linkData = createDocLinkData(shortName, topicId, title, url)
            arguments
                shortName (1, 1) string
                topicId (1, 1) string
                title (1, 1) string
                url (1, 1) string = ""
            end
            linkData = matlab.hwmgr.internal.data.DocLinkData(shortName, topicId, title, url);
        end

        function hardwareSetupData = createHardwareSetupData(displayName, description, iconID, ...
            learnMoreLink, workflowName, identifier, nameValueArgs)

            arguments
                displayName (1, 1) string
                description (1, 1) string  
                iconID (1, 1) string
                learnMoreLink (1, 1)
                workflowName (1, 1) string
                identifier = displayName + workflowName;            % Forward compatibility: Set identifer to displayName + workflowName
                nameValueArgs.DescriptionHeading = displayName;     % Forward compatibility: Set DescriptionHeading to displayName
                nameValueArgs.BaseProductConstraints = string.empty();
                nameValueArgs.PlatformConstraints = string.empty();
                nameValueArgs.ToolboxBaseCodes (1, :) string = string.empty()
                nameValueArgs.SupportPackageBaseCodes (1, :) string = string.empty() 
                nameValueArgs.WorkflowArgs (1, :) string = string.empty()
            end

            nameValueProps = ["DescriptionHeading", "BaseProductConstraints",...
                              "PlatformConstraints", "ToolboxBaseCodes", ...
                              "SupportPackageBaseCodes", "WorkflowArgs"];

            parsedNameValueArgs = matlab.hwmgr.internal.data.DataFactory.parseNameValueArgsForConstructor(nameValueArgs, nameValueProps);

            hardwareSetupData = matlab.hwmgr.internal.data.HardwareSetupData(displayName, ...
                description, iconID, learnMoreLink, workflowName,...
                identifier, parsedNameValueArgs{:});
        end

        function launchableData = createExampleData(displayName, description, iconID, ...
            learnMoreLink, exampleName, relatedLinks, identifier, nameValueArgs)

            arguments
                displayName (1, 1) string
                description (1, 1) string
                iconID (1, 1) string
                learnMoreLink (1, 1)
                exampleName (1, 1) string
                relatedLinks(1, :) = []
                identifier (1, 1) string = exampleName
                nameValueArgs.DescriptionHeading = displayName
                nameValueArgs.BaseProductConstraints = string.empty();
                nameValueArgs.PlatformConstraints = string.empty();
                nameValueArgs.ToolboxBaseCodes (1, :) string = string.empty()
                nameValueArgs.SupportPackageBaseCodes (1, :) string = string.empty()
                nameValueArgs.CommandArgs (1, :) string = string.empty()
            end

            validateattributes(learnMoreLink, ["matlab.hwmgr.internal.data.LinkData", "matlab.hwmgr.internal.data.DocLinkData"], "scalar");
            
            nameValueProps = ["DescriptionHeading", "BaseProductConstraints",...
                              "PlatformConstraints", "ToolboxBaseCodes", ...
                              "SupportPackageBaseCodes", "CommandArgs"];

            parsedNameValueArgs = matlab.hwmgr.internal.data.DataFactory.parseNameValueArgsForConstructor(nameValueArgs, nameValueProps);

            launchableData = matlab.hwmgr.internal.data.ExampleData(displayName, description, ...
                                   iconID, learnMoreLink, exampleName,...
                                   relatedLinks, identifier, parsedNameValueArgs{:});
        end

        function simulinkModelData = createSimulinkModelData(displayName, description, iconID, ...
            learnMoreLink, modelToOpen, identifier, nameValueArgs)

            arguments
                displayName (1, 1) string
                description (1, 1) string  
                iconID (1, 1) string
                learnMoreLink (1, 1)
                modelToOpen (1, 1) string
                identifier  (1, 1) string = modelToOpen
                nameValueArgs.DescriptionHeading = displayName
                nameValueArgs.BaseProductConstraints = string.empty();
                nameValueArgs.PlatformConstraints = string.empty();
                nameValueArgs.ToolboxBaseCodes (1, :) string = string.empty()
                nameValueArgs.SupportPackageBaseCodes (1, :) string = string.empty() 
                nameValueArgs.CommandArgs (1, :) string = string.empty()
            end

            validateattributes(learnMoreLink, ["matlab.hwmgr.internal.data.LinkData", "matlab.hwmgr.internal.data.DocLinkData"], "scalar");

            nameValueProps = ["DescriptionHeading", "BaseProductConstraints",...
                              "PlatformConstraints", "ToolboxBaseCodes", ...
                              "SupportPackageBaseCodes", "CommandArgs"];

            parsedNameValueArgs = matlab.hwmgr.internal.data.DataFactory.parseNameValueArgsForConstructor(nameValueArgs, nameValueProps);

            simulinkModelData = matlab.hwmgr.internal.data.SimulinkModelData(displayName, description, ...
                                   iconID, learnMoreLink, ...
                                   modelToOpen, identifier, parsedNameValueArgs{:});
        end

        function deviceHardwareSetupData = createDeviceHardwareSetupData(displayName, launchMode, hardwareSetupStatus, workflowName, identifierReference, nameValueArgs)
            arguments
                displayName (1, 1) string
                launchMode matlab.hwmgr.internal.data.LaunchModeEnum
                hardwareSetupStatus matlab.hwmgr.internal.data.HardwareSetupStatusEnum
                workflowName (1, 1) string
                identifierReference = displayName + workflowName;
                nameValueArgs.SupportingAddOnBaseCodes (1, :) string = string.empty()
                nameValueArgs.WorkflowArgs (1, :) string = string.empty()
            end

            nameValueProps = ["SupportingAddOnBaseCodes", "WorkflowArgs"];
            parsedNameValueArgs = matlab.hwmgr.internal.data.DataFactory.parseNameValueArgsForConstructor(nameValueArgs, nameValueProps);

            deviceHardwareSetupData = matlab.hwmgr.internal.data.DeviceHardwareSetupData(...
                displayName, launchMode, hardwareSetupStatus, workflowName, identifierReference, parsedNameValueArgs{:});
        end

        function launchableData = createDeviceExampleData(identifierReference, nameValueArgs)
            arguments
                identifierReference (1, 1) string;
                nameValueArgs.SupportingAddOnBaseCodes (1, :) string = string.empty()
                nameValueArgs.SkipSupportingAddonInstallation = dictionary(string.empty, logical.empty)
                nameValueArgs.CommandArgs (1, :) string = string.empty()
            end

            nameValueProps = ["SupportingAddOnBaseCodes", "SkipSupportingAddonInstallation", "CommandArgs"];
            parsedNameValueArgs = matlab.hwmgr.internal.data.DataFactory.parseNameValueArgsForConstructor(nameValueArgs, nameValueProps);

            launchableData = matlab.hwmgr.internal.data.DeviceExampleData(identifierReference, parsedNameValueArgs{:});
        end

        function launchableData = createDeviceSimulinkModelData(identifierReference, nameValueArgs)
            arguments
                identifierReference (1, 1) string;
                nameValueArgs.SupportingAddOnBaseCodes (1, :) string = string.empty()
                nameValueArgs.SkipSupportingAddonInstallation = dictionary(string.empty, logical.empty)
                nameValueArgs.CommandArgs (1, :) string = string.empty()
            end

            nameValueProps = ["SupportingAddOnBaseCodes", "SkipSupportingAddonInstallation", "CommandArgs"];
            parsedNameValueArgs = matlab.hwmgr.internal.data.DataFactory.parseNameValueArgsForConstructor(nameValueArgs, nameValueProps);

            launchableData = matlab.hwmgr.internal.data.DeviceSimulinkModelData(identifierReference, parsedNameValueArgs{:});
        end

        function featureLaunchable = createFeatureLaunchable(launchableData, selectedDevice, args)
            
            validateattributes(launchableData, {'matlab.hwmgr.internal.data.LaunchableData'}, {'scalar'});
            validateattributes(launchableData.Category,  {'matlab.hwmgr.internal.data.FeatureCategory'}, {'scalar'});
            % device can only be empty or of type 'matlab.hwmgr.internal.Device'
            try
                 if (~isempty(selectedDevice) && ~isa(selectedDevice,'matlab.hwmgr.internal.Device'))
                    error('hwmanagerapp:hwmgrshared:InvalidHardwareManagerDevice', 'The device must be of type matlab.hwmgr.internal.Device or empty.');
                end
            
                % Construct the launcher instance
                launchableName = "matlab.hwmgr.internal." + string(launchableData.Category) + "Launchable";
           
                className = str2func(launchableName);
            
                featureLaunchable = className(launchableData, selectedDevice, args);
                
            catch ex
                backtraceState = warning("backtrace");
                warning("off", "backtrace");
                warning(message(ex.identifier, ex.message));
                warning(backtraceState.state, "backtrace");
            end
        end
    end

    methods (Static, Access = {?matlab.unittest.TestCase})
        function parsedNameValueArgs = parseNameValueArgsForConstructor(nameValueArgs, nameValueProps)
            parsedNameValueArgs = cell.empty();
            for i = 1 : length(nameValueProps)
                if ~isempty(nameValueArgs.(nameValueProps(i)))
                    parsedNameValueArgs = [parsedNameValueArgs, {nameValueProps(i), nameValueArgs.(nameValueProps(i))}];
                end
            end
        end
    end
end

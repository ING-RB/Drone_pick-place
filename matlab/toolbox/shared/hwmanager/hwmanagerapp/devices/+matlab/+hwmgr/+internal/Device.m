classdef Device < matlab.mixin.Heterogeneous
    % MATLAB.HWMGR.INTERNAL.DEVICE - Class for defining a hardware manager
    % device

    % Copyright 2017-2024 The MathWorks, Inc.

    properties
        %FRIENDLYNAME
        %   A user visible name to identify the device
        FriendlyName (1,1) string

        %CONNECTIONINFO
        %   A user visible description of how the device is connected to
        %   the machine
        ConnectionInfo (1,1) string

        %VENDORNAME
        %   A user visible and familiar vendor name
        VendorName (1,1) string

        %VENDORID
        %   A user visible unique vendor identifier
        VendorID (1,1) string

        %DEVICEID
        %   A user visible device identifier
        DeviceID (1,1) string

        %MODELNAME
        %   A user visible device model
        ModelName (1,1) string

        %SERIALNUMBER
        %   A user visible device serial number
        SerialNumber (1,1) string

        %CUSTOMDATA
        %   A custom data field. For example, this can hold a handle to the
        %   toolbox specific device peer object
        CustomData

        %BASECODE
        %   BaseCodes of support packages or base products that support this
        %   device
        BaseCode cell

        %HARDWARESETUPWORKFLOW
        %   Name of the hardware setup workflow class that supports this
        %   device
        HardwareSetupWorkflowClass

        %SUPPORTPACKAGENAME
        %   Names of support packages related to this device
        SupportPackageName cell

        %HARDWARESUPPORTURL
        %   Url of the Hardware Support page to display in brower for this
        %   device
        HardwareSupportUrl (1,1) string

        %ISNONENUMERABLE
        %   Boolean flag indicating whether this device is a user created
        %   non-enumerable device with constructor parameters associated
        IsNonEnumerable (1,1) logical

        %CAPABILITIES
        %   String array of capabilities that can be custom, unique
        %   strings. These string values can be inspected in the Applet
        %   provider's getAppletsByDevice method to determine which applets
        %   can support the device based on the capabilities of the
        %   device
        Capabilities (1,:) string

        %ICONID
        %   Icon ID for the device to display in device list card.
        IconID (1,1) string

        %DEVICECARDDISPLAYINFO
        %   A n-by-2 string array for information to display on device card
        %   Each row contains the display name and the value Example:
        %   ["Device Address", "127.0.0.1"; "Vendor", "ni"];
        DeviceCardDisplayInfo (:, 2) string

        %DEVICEAPPLETDATA
        %   A matlab.hwmgr.internal.data.DeviceAppletData object created by
        %   the matlab.hwmgr.internal.data.DataFactory describing apps
        %   related to this device
        DeviceAppletData (1, :) matlab.hwmgr.internal.data.DeviceAppletData

        %DEVICELIVETASKDATA 
        %   a matlab.hwmgr.internal.data.DeviceLiveTaskData object created
        %   by the matlab.hwmgr.internal.data.DataFactory describing live
        %   tasks related to this device
        DeviceLiveTaskData (1, :) matlab.hwmgr.internal.data.DeviceLiveTaskData

        %DEVICEHARDWARESETUPDATA
        %   a matlab.hwmgr.internal.data.DeviceHardwareSetupData object created
        %   by the matlab.hwmgr.internal.data.DataFactory describing
        %   hardware setup app assoicated with this device
        DeviceHardwareSetupData (1, :) matlab.hwmgr.internal.data.DeviceHardwareSetupData

        %DEVICEEXAMPLEDATA
        %   a matlab.hwmgr.internal.data.DeviceExampleData object created
        %   by the matlab.hwmgr.internal.data.DataFactory describing
        %   example(s) assoicated with this device
        DeviceExampleData (1, :) matlab.hwmgr.internal.data.DeviceExampleData

        %DEVICESIMULINKMODELDATA
        %   a matlab.hwmgr.internal.data.DeviceSimulinkModelData object created
        %   by the matlab.hwmgr.internal.data.DataFactory describing
        %   Simulink Model(s) assoicated with this device
        DeviceSimulinkModelData (1, :) matlab.hwmgr.internal.data.DeviceSimulinkModelData

        %DEVICEHELPDOCDATA
        %   a matlab.hwmgr.internal.data.DeviceLaunchableData object created
        %   by the matlab.hwmgr.internal.data.DataFactory describing
        %   a help document assoicated with this device
        DeviceHelpDocData (1, :) matlab.hwmgr.internal.data.DeviceLaunchableData

        %DEVICEENUMERABLECONFIGDATA
        %   A matlab.hwmgr.internal.data.DeviceEnumerableConfigData object created
        %   by the matlab.hwmgr.internal.data.DataFactory describing
        %   required configuration / reconfiguration capabilities related 
        %   to this device per applet
        DeviceEnumerableConfigData (1, :) matlab.hwmgr.internal.data.DeviceEnumerableConfigData

    end

    properties(GetAccess = public, SetAccess = ?matlab.hwmgr.internal.DeviceParamsDescriptor)
        % DESCRIPTOR string identifying the device descriptor
        % class that created this device object
        Descriptor
    end

    properties(GetAccess = public, SetAccess = {?matlab.hwmgr.internal.DeviceParamsDescriptor, ...
            ?matlab.hwmgr.internal.DeviceProviderBase, ...
            ?matlab.hwmgr.internal.DeviceList, ...
            ?hwmgr.test.internal.TestCase})
        % PROVIDERCLASS the device provider class that created this device
        % object
        ProviderClass
    end

    properties
        % UUID - Unique Identifier for the device
        UUID (1,1) string
    end

    properties (Hidden, SetAccess = {?matlab.hwmgr.internal.DeviceList, ...
            ?hwmgr.test.internal.TestCase})
        % Private properties used to manipulate the device card to show
        % options and cache device when valid
        ShowConfigWarning (1,1) logical = false
        ShowConfigOption (1,1) logical = false
        CacheDevice (1,1) logical = false
    end

    methods
        % Constructor
        function obj = Device(friendlyName)
            % Constructor takes a friendly name. The friendly name is the
            % label shown for the device within the Device List view. This
            % is a user visible string.
            obj.FriendlyName = friendlyName;
        end

        function uuid = generateDefaultUUID(obj)
                % Concat the visibleprops
                visiblePropStr = "";
                for i = 1:size(obj.DeviceCardDisplayInfo,1)
                    visiblePropStr = visiblePropStr + obj.DeviceCardDisplayInfo(i,1) + obj.DeviceCardDisplayInfo(i, 2);
                end

                uuid = obj.FriendlyName + visiblePropStr;
                uuid = uuid.replace(" ", "");
        end

        function workflow = getHardwareSetupWorkflow(obj, varargin)
            % This method will return the hardware setup workflow for this
            % device based on the basecode or the hardware setup workflow
            % specified for this device
            if ~isempty(varargin)
                basecodeToUse = varargin{1};
            else
                basecodeToUse = obj.BaseCode;
            end
            if isempty(obj.HardwareSetupWorkflowClass) && ~isempty(basecodeToUse)

                % Place the call to the registry plugin API in a try catch
                % as a support package may not be installed yet
                try
                    sppkgObj = matlabshared.supportpkg.internal.getSpPkgInfoForBaseCode(basecodeToUse);

                    % Find the name of the firmware update class
                    workflow = sppkgObj.FwUpdate;
                catch
                    workflow = '';
                end

                if isempty(workflow)
                    return;
                end

                % If the workflow class is a LEGACY targetupdater class
                % then no hardware setup
                try

                    metaClass = meta.class.fromName(workflow);
                    superClasses = {metaClass.SuperclassList.Name};

                    if ismember('hwconnectinstaller.FirmwareUpdate', superClasses)
                        workflow = '';
                    end
                catch
                    workflow = '';
                end

            else
                workflow = char(obj.HardwareSetupWorkflowClass);
            end
        end

        function bool = hasHardwareSetup(obj)
            % This method will return a boolean indicating whether the
            % device has a hardware setup workflow
            bool = ~isempty(obj.getHardwareSetupWorkflow());
        end


        function bool = eq(obj, otherDevice)
            % Handle the following cases
            % [] == device
            % device == []
            if isempty(obj) || isempty(otherDevice)
                bool = false;
                return
            end
            bool = isequal(obj.UUID, otherDevice.UUID);
        end

    end

    methods (Hidden)

        function outStruct = toDeviceCardStruct(obj)
            % This method is used to construct the struct to be sent to
            % device list JS for display on device card.
            
            outStruct.FriendlyName = obj.FriendlyName;
            outStruct.IsNonEnumerable = obj.IsNonEnumerable;

            outStruct.IconID = obj.IconID;
            displayInfo = [];
            if isempty(obj.DeviceCardDisplayInfo)
                displayInfo = obj.getDefaultDisplayInfo();
            else
                displayInfo = obj.DeviceCardDisplayInfo;
            end
            visiblePropStruct = struct("PropLabel", {}, "PropValue", {});
            for i =  1:size(displayInfo, 1)
                visiblePropStruct(i).PropLabel = displayInfo(i, 1);
                visiblePropStruct(i).PropValue = displayInfo(i, 2);
            end
            outStruct.VisibleProperties = visiblePropStruct;
            outStruct.DeviceAppletData = arrayfun(@(x) struct("IdentifierReference", x.IdentifierReference, ...
                "AppletClass", x.AppletClass, ...
                "SupportingAddOnBaseCodes", x.SupportingAddOnBaseCodes, ...
                "SkipSupportingAddonInstallation", entries(x.SkipSupportingAddonInstallation,"struct")), ...
                obj.DeviceAppletData);

            outStruct.DeviceLiveTaskData = arrayfun(@(x) struct("LiveTaskDisplayName", x.LiveTaskDisplayName, ...
                "IdentifierReference", x.IdentifierReference, ...
                "SupportingAddOnBaseCodes", x.SupportingAddOnBaseCodes, ...
                "SkipSupportingAddonInstallation", entries(x.SkipSupportingAddonInstallation,"struct")), ...
                obj.DeviceLiveTaskData);

            outStruct.DeviceExampleData = arrayfun(@(x) struct("IdentifierReference", x.IdentifierReference, ...
                "SupportingAddOnBaseCodes", x.SupportingAddOnBaseCodes, ...
                "SkipSupportingAddonInstallation", entries(x.SkipSupportingAddonInstallation,"struct"), ...
                "CommandArgs", x.CommandArgs), ...
                obj.DeviceExampleData);

            outStruct.DeviceSimulinkModelData = arrayfun(@(x) struct("IdentifierReference", x.IdentifierReference, ...
                "SupportingAddOnBaseCodes", x.SupportingAddOnBaseCodes, ...
                "SkipSupportingAddonInstallation", entries(x.SkipSupportingAddonInstallation,"struct"), ...
                "CommandArgs", x.CommandArgs), ...
                obj.DeviceSimulinkModelData);

             outStruct.DeviceHelpDocData = arrayfun(@(x) struct("IdentifierReference", x.IdentifierReference, ...
                "SupportingAddOnBaseCodes", x.SupportingAddOnBaseCodes, ...
                "SkipSupportingAddonInstallation", entries(x.SkipSupportingAddonInstallation,"struct")), ...
                obj.DeviceHelpDocData);

            outStruct.DeviceHardwareSetupData = [];
            outStruct.ShowHardwareSetupWarning = [];

            for i = 1:numel(obj.DeviceHardwareSetupData)
                deviceHardwareSetupData = struct( ...
                        "DisplayName", obj.DeviceHardwareSetupData(i).DisplayName, ...
                        "IdentifierReference", obj.DeviceHardwareSetupData(i).IdentifierReference, ...
                        "LaunchMode", char(obj.DeviceHardwareSetupData(i).LaunchMode), ...
                        "HardwareSetupStatus", char(obj.DeviceHardwareSetupData(i).HardwareSetupStatus), ...
                        "WorkflowName", obj.DeviceHardwareSetupData(i).WorkflowName, ...
                        "SupportingAddOnBaseCodes", obj.DeviceHardwareSetupData(i).SupportingAddOnBaseCodes, ...
                        "SkipSupportingAddonInstallation", obj.DeviceHardwareSetupData(i).SkipSupportingAddonInstallation, ...
                        "WorkflowArgs", obj.DeviceHardwareSetupData(i).WorkflowArgs);

                outStruct.DeviceHardwareSetupData = [outStruct.DeviceHardwareSetupData deviceHardwareSetupData];

                % Show the option to launch Hardware setup from the deviceCard only if all conditions are met:
                % 1. The required HSPKG is installed or HSPKG is not required
                % 2. DeviceHardwareSetupData LaunchMode is 'Required'
                % 3. DeviceHardwareSetupData HardwareSetupStatus is 'DidNotRun'
                if ((isempty(obj.DeviceHardwareSetupData(i).SupportingAddOnBaseCodes) || ...
                       matlab.hwmgr.internal.util.isInstalled(obj.DeviceHardwareSetupData(i).SupportingAddOnBaseCodes)) && ...
                     obj.DeviceHardwareSetupData(i).LaunchMode == matlab.hwmgr.internal.data.LaunchModeEnum.Required && ...
                     obj.DeviceHardwareSetupData(i).HardwareSetupStatus == matlab.hwmgr.internal.data.HardwareSetupStatusEnum.DidNotRun)

                    outStruct.ShowHardwareSetupWarning = [outStruct.ShowHardwareSetupWarning true];
                else
                    outStruct.ShowHardwareSetupWarning = [outStruct.ShowHardwareSetupWarning false];
                end
            end

            outStruct.ShowConfigWarning = obj.ShowConfigWarning;
            outStruct.ShowConfigOption = obj.ShowConfigOption;
        end

        function defaultInfo = getDefaultDisplayInfo(obj)
            defaultInfo = [];

            if obj.VendorID ~= ""
                defaultInfo = [defaultInfo; "Vendor", obj.VendorID];
            end

            if obj.DeviceID ~= ""
                defaultInfo = [defaultInfo; "Device ID", obj.DeviceID];
            end
        end

    end

    methods (Static)
        function str = getUSBConnectionInfoString()
            % This is a utility method to return a standard string to be
            % used to describe devices connected via USB. This string can
            % be used to specify the ConnectionInfo property of this class

            str = message('hwmanagerapp:framework:USBConnectionInfoString').getString();
        end
    end
end

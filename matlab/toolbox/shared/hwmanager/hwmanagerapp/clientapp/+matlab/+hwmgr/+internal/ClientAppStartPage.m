classdef ClientAppStartPage < matlabshared.mediator.internal.Publisher &...
        matlabshared.mediator.internal.Subscriber & ...
        matlab.hwmgr.internal.MessageLogger
    % This is the Client App Start Page back-end class

    % Copyright 2021-2024 The MathWorks, Inc.

    properties 
        % STATICCHANNEL - the name of the static channel being used in the
        % connector message service
        StaticChannel = '/HWF/devicelist'

        % DOCUMENT - Handle to the document that will host the page
        Document (1,1) matlab.ui.container.internal.appcontainer.Document

        % MESSAGEHANDLER - Handler of connector communication with client (JS)
        MessageHandler (1,1) 
        % SELECTEDDEVICE - Current selected device
        SelectedDevice (1,1) 
        % ALLDEVICES - All the enumerable and cached non enumerable devices
        % that were loaded on refresh
        AllDevices (1,:) 
        % ViewLoaded - Flag indicating if Landing Page url is loaded
        ViewLoaded (1,1) logical

        % ALLDEVICEDESCRIPTORS - All the device descriptors that were found
        % and loaded on refresh
        AllDeviceDescriptors (1,:) 
        % CONTEXT - The context under which the Hardware Manager Framework
        % is running
        Context (1,1) 
        % DONTSEEDEVICEHELPER - Handle to the DontSeeDeviceDialog helper
        % class used to show the don't see my device dialog and handle its
        % callbacks
        DontSeeDeviceHelper  (1,1) 
        
        % SHOWWINDOWCONFIRMATIONRESPONSE - the response from the user for a
        % confirmation dialog showed by the ClientAppWindow
        ShowWindowConfirmationResponse

        % ServiceLauncher - The class that launches the different links,
        % Add Ons Explorer and SSI window.
        ServiceLauncher
    end

    properties (SetObservable)
        UserSelectDeviceOnStartPage
        UserRefreshingHwmgrStartPage
        UserRemoveDeviceOnStartPage
        UserAddNonEnumDeviceStartPage
        UserConfigureDeviceStartPage
        MakeWindowBusy
        RemoveWindowBusy
        ShowWindowConfirmationDlg
        RegistrationFrameworkRefresh
        StartPageClientId
    end

    methods (Static)
        function out = getPropsAndCallbacks()
            out =  ... % Property to listen to         % Callback function
                [...
                "SelectedDeviceUpdate"              "setSelectedDevice"; ...
                "WebAppDocReady"                    "setDocument"; ...
                "DevicesAvailableToShow"            "handleDevicesAvailableToShow";...
                "FoundDeviceDescriptors"            "handleFoundDeviceDescriptors"; ...
                "ShowStartPage"                   	"handleShowStartPage"; ...
                "ShowWindowConfirmationResponse"    "handleShowWindowConfirmationResponse"
                ];
        end

        function out = getPropsAndCallbacksNoArgs()
            out  = ...
                ... % Property to listen to         % Callback function
                [
                "RequestStartPageClientId"          "setStartPageClientId"
                ];
        end
    end

    methods
        function obj = ClientAppStartPage(mediator)
            obj@matlabshared.mediator.internal.Publisher(mediator);
            obj@matlabshared.mediator.internal.Subscriber(mediator);

            obj.ServiceLauncher = matlab.hwmgr.internal.ServiceLauncher();
            obj.MessageHandler = matlab.hwmgr.internal.MessageHandler(obj.StaticChannel);
            obj.MessageHandler.setSubject(obj);
            obj.subscribeToClientActions();
        end

        function set.Context(obj, newVal)
            % Set function for the context. Once we have the context,
            % initialize the DontSeeDeviceDialog helper class
            obj.Context = newVal;
            obj.DontSeeDeviceHelper = matlab.hwmgr.internal.DontSeeDeviceDialog(obj.Context.AppletClass); %#ok<MCSUP> 
        end

        function subscribeToMediatorProperties(obj, ~, ~)
            eventsAndCallbacks = obj.getPropsAndCallbacks();
            obj.subscribeWithGateways(eventsAndCallbacks, @obj.subscribe);

            eventsAndCallbacksNoArgs = obj.getPropsAndCallbacksNoArgs();
            obj.subscribeWithGatewaysNoArgs(eventsAndCallbacksNoArgs, @obj.subscribe);
        end

        function loadView(obj)
            obj.MessageHandler.clearCachedMessages();
            obj.MessageHandler.resetPubSubReady();

            % Set the front end mode to landing page since the front end is
            % shared between the device list and landing page
            obj.setViewMode();

            % Send the latest copy of the datastore to the front end
            pageData = obj.DontSeeDeviceHelper.getPageData();
            obj.MessageHandler.publish('setDontSeeDeviceDialogData', struct("PageData", pageData));

            % Load devices and descriptors on front-end view
            obj.refreshDevicesView();
            obj.refreshDescriptorsView();
        end


        function setViewMode(obj)
            % Update "ShowInstalledAddOns" based on context
            obj.MessageHandler.publish('setViewModes', struct("ShowInPanel", false));
        end

        % ------------BEGIN--Mediator callbacks --------------------------%

        function handleDevicesAvailableToShow(obj, devicesToShow)
            obj.setAllDevices(devicesToShow);

            obj.refreshDevicesView();
        end

        function handleFoundDeviceDescriptors(obj, descriptors)
            obj.setAllDescriptors(descriptors);

            obj.refreshDescriptorsView();
        end

        function handleShowStartPage(obj, view)
            obj.loadView();
            obj.ViewLoaded = true;
        end

        function handleShowWindowConfirmationResponse(obj, response)
            obj.ShowWindowConfirmationResponse = response;
        end

        function setDocument(obj, msg)
            obj.Document = msg.Document;
        end

        function setSelectedDevice(obj, device)
            obj.SelectedDevice = device;
        end

        function refreshDescriptorsView(obj)
            messageElementCount = numel(obj.AllDeviceDescriptors);
            listToSend = cell(1, messageElementCount);

            for i = 1: messageElementCount
                listToSend{i} = obj.AllDeviceDescriptors(i).toDeviceCardStruct();
            end
            % Update device cards on front-end
            obj.MessageHandler.publish("refreshDescriptors", listToSend);
        end

        function refreshDevicesView(obj)

            messageElementCount = numel(obj.AllDevices);
            listToSend = cell(1, messageElementCount);

            for i = 1: messageElementCount
                listToSend{i} = obj.AllDevices(i).toDeviceCardStruct();

                % If we are in the ClientApp context, don't show Hardware Setup warning
                for j = 1:numel(listToSend{i}.ShowHardwareSetupWarning)
                    listToSend{i}.ShowHardwareSetupWarning(j) = false;
                end
            end

            % Update device cards on front-end
            obj.MessageHandler.publish("refreshDevices", listToSend);
        end

        function setAllDevices(obj, devices)
            obj.AllDevices = devices;
        end

        function setAllDescriptors(obj, descriptors)
            obj.AllDeviceDescriptors = descriptors;
        end

        % -----------END----Mediator callbacks ---------------------------%

        function subscribeToClientActions(obj)
            % Start page callbacks
            obj.MessageHandler.subscribe("clientSelectDevice");
            obj.MessageHandler.subscribe("clientAddNonEnumDevice");
            obj.MessageHandler.subscribe("clientRemoveDevice");
            obj.MessageHandler.subscribe("clientRefresh");
            obj.MessageHandler.subscribe("clientGettingStarted");
            obj.MessageHandler.subscribe("clientConfigureDevice");

            % Dont see my device dialog callbacks
            obj.MessageHandler.subscribe("clientInstallAddon");
            obj.MessageHandler.subscribe("clientOpenTsLink");
            obj.MessageHandler.subscribe("clientOpenHwmgrApp");
            obj.MessageHandler.subscribe("clientRegFwkAddonInstalled");
            obj.MessageHandler.subscribe("clientRegFwkAddonUninstalled");
        end


        % ------------BEGIN --- FRONT-END CALLBACK -----------------------%

        function clientSelectDevice(obj, msg)
            % Send a message to the controller that the user has selected a
            % device. The controller will change the layout and then select
            % the device on the device list
            obj.logAndSet("UserSelectDeviceOnStartPage", msg.Uuid + 1);
        end

        function clientAddNonEnumDevice(obj, id)
            % Send message to the controller that the user wants to add and
            % configure a new non enumerable device
            descriptorIndex = id+1;
            descriptor = obj.AllDeviceDescriptors(descriptorIndex);

            obj.logAndSet("UserAddNonEnumDeviceStartPage", descriptor);
        end

        function clientConfigureDevice(obj, msg)
            % Send message to the controller that the user wants to
            % configure a device
            % The index is msg.Uuid+1 since the java script layer used a
            % index starting at 0 to point to device cards, and we need to 
            % add 1 to point to the same device in MATLAB
            obj.logAndSet("UserConfigureDeviceStartPage", {msg.Uuid + 1; obj.Context.AppletClass});
        end

        function clientRemoveDevice(obj, msg)
            % Confirm device removal
            deviceName = obj.AllDevices(msg.Uuid+1).FriendlyName;
            appName  = feval(obj.Context.AppletClass).DisplayName;
            dialogData = struct;
            dialogData.DlgTitle = string(message('hwmanagerapp:devicelist:RemoveHardware').getString());
            dialogData.DlgMessage = string(message('hwmanagerapp:devicelist:RemoveHardwareMessage', deviceName, appName).getString());
            dialogData.DlgOptions = [string(message('hwmanagerapp:devicelist:Remove').getString), string(message('hwmanagerapp:devicelist:Cancel').getString())];
            dialogData.DlgDefaultOption = string(message('hwmanagerapp:devicelist:Cancel').getString());

            obj.logAndSet("ShowWindowConfirmationDlg", dialogData);

            if obj.ShowWindowConfirmationResponse == string(message('hwmanagerapp:devicelist:Remove').getString())
                % Send a message to the controller that the user is trying to
                % remove a device from the device list on the start page.
                % The start page needs to send a message to the controller
                % instead of the device list directly because the
                % controller may need to take some additional action such
                % as making the window busy
                obj.logAndSet("UserRemoveDeviceOnStartPage", msg.Uuid+1);
            else
                obj.MessageHandler.publish('removeDeviceBeingDeletedHighlight', msg.Uuid);
            end
        end

        function clientRefresh(obj, ~)
            % Send the controller a message to indicate the user is trying
            % to refresh the device list on the start page
            obj.logAndSet("UserRefreshingHwmgrStartPage", true);
        end

        function clientDontSeeDevice(obj, ~)
            % The user clicked on the "I don't see my device link".

            % Send the data to be shown in the dialog back to the front
            % end for display
            pageData = obj.DontSeeDeviceHelper.getPageData();

            obj.MessageHandler.publish('showDontSeeDeviceDialog', struct("PageData", pageData));
        end

        function clientGettingStarted(obj, ~)
            % The user clicks on the "Getting Started" link. Open the
            % learn more link for the current app
            dataStore = matlab.hwmgr.internal.DataStoreHelper().getDataStore();
            appletData = dataStore.getLaunchableData(string(obj.Context.AppletClass));
            if isempty(appletData)
                error("Internal Error: Applet Data must be specified");
            end

            linkData = appletData.LearnMoreLink;

            if isprop(linkData, "TopicId")
                obj.ServiceLauncher.openWithHelpView(linkData.ShortName, linkData.TopicId);
            else
                obj.ServiceLauncher.openUrlInBrowser(linkData.Url);
            end
        end

        function clientInstallAddon(obj, basecode)
            % The user clicked on the install addon link in the don't my
            % see device dialog.
            installerType = obj.ServiceLauncher.getInstallerTypeForBaseCode(basecode);
            ssiCloseFcn = function_handle.empty;
            if installerType == "SSI"
                ssiCloseFcn = @(~,~)obj.ssiWindowClosedCallback;
                obj.logAndSet("MakeWindowBusy", true);
            end
            obj.DontSeeDeviceHelper.clientInstallAddon(basecode, ssiCloseFcn);
        end

        function clientOpenTsLink(obj, linkData)
            % The user clicked on the troubleshooting link
            obj.DontSeeDeviceHelper.clientOpenTsLink(linkData)
        end

        function clientOpenHwmgrApp(~, ~)
            matlab.hwmgr.internal.launchHardwareManager();
        end

        function clientRegFwkAddonInstalled(obj, basecode)
            % Close the dialog
            obj.hideDontSeeDeviceDialog();
            % Send the latest version of the data store to the front
            % end.
            pageData = obj.DontSeeDeviceHelper.getPageData();
            obj.MessageHandler.publish('setDontSeeDeviceDialogData', struct("PageData", pageData));

            % Remove the modal busy
            obj.logAndSet("RemoveWindowBusy", true);
            % Refresh the device list
            obj.logAndSet("RegistrationFrameworkRefresh", true);
        end

        function clientRegFwkAddonUninstalled(obj, basecode)
            % Refresh the device list
            obj.logAndSet("RegistrationFrameworkRefresh", true);
        end

        function setStartPageClientId(obj)
            % Publish ClientId for MessageClient to be used for
            % communication with front end (needed by Device List)
            obj.StartPageClientId = obj.MessageHandler.ClientId;
        end

        % --------------END --- FRONT-END CALLBACK -----------------------%

        function hideDontSeeDeviceDialog(obj)
            obj.MessageHandler.publish('hideDontSeeDeviceDialog', '');
        end

        function ssiWindowClosedCallback(obj)
            % It's possible the client app window was closed before SSI was
            % closed, so check if the object is valid
            if ~isvalid(obj)
                return;
            end
            obj.logAndSet("RemoveWindowBusy", true);
        end

        function delete(obj)
            delete(obj.MessageHandler);
        end
    end


end

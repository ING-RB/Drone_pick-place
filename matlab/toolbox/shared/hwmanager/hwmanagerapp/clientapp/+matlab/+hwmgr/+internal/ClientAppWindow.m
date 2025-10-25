classdef ClientAppWindow < matlab.hwmgr.internal.HwmgrWindow
    % CLIENTAPPWINDOW - Hardware Manager Window class (appcontainer wrapper)
    % specialization for the client app framework.

    % Copyright 2021-2022 The Mathworks, Inc.

    properties (SetObservable)
        ReloadDeviceListFrontEnd
        ShowWindowConfirmationResponse
    end

    methods (Static)
        function out = getPropsAndCallbacks()
            outSuper = matlab.hwmgr.internal.HwmgrWindow.getPropsAndCallbacks();
            out =  ... % Property to listen to         % Callback function
                [
                    "ShowWindowConfirmationDlg"         "handleShowWindowConfirmationDlg";
                ];
            out = [outSuper; out];
        end

        function out = getPropsAndCallbacksNoArgs()
            outSuper = matlab.hwmgr.internal.HwmgrWindow.getPropsAndCallbacksNoArgs();
            out =  ... % Property to listen to         % Callback function
                [ "ShowDeviceListToolstripLayout"     "handleShowDeviceListToolstripLayout"; ...
                  "RemoveClientSidePanels"            "handleRemoveClientSidePanels";
                ];
            out = [outSuper; out];
        end
    end

    methods

        function obj = ClientAppWindow(mediator, context)
            obj = obj@matlab.hwmgr.internal.HwmgrWindow(mediator, context);
        end

        function handleShowSingleDocumentLayout(obj)
            handleShowSingleDocumentLayout@matlab.hwmgr.internal.HwmgrWindow(obj);
            
            obj.createWebAppDoc('ClientAppSinglePageDocumentGroup');
            
            % Send the document to all the modules interested
            obj.logAndSet("WebAppDocReady", obj.WebAppDocumentUihtml);
        end

        function handleShowDeviceListToolstripLayout(obj)
            % The client app layout consists of a device list panel on the
            % left and a document on the right which contains a uigrid and
            % uipanel inside which the client app is rendered

            % Remove the single document. The client app document is added
            % later
            obj.removeAllDocuments();

            % Show the toolstrip
            obj.collapseToolstrip(false);

            % Add the device list panel and load it
            if isempty(obj.AppContainer.getPanel('deviceListPanel'))
                obj.constructDeviceListPanel();
            end
        end

        function handleShowWindowConfirmationDlg(obj, msg)
            parent = obj.AppContainer;
            message = msg.DlgMessage;
            title = msg.DlgTitle;
            options = msg.DlgOptions;
            defaultOption = msg.DlgDefaultOption;
            response = matlab.hwmgr.internal.DialogFactory.constructConfirmationDialog(parent, message, title, 'Options', options, 'DefaultOption', defaultOption);

            obj.logAndSet("ShowWindowConfirmationResponse", response)
        end

        function handleRemoveClientSidePanels(obj)
            allPanels = obj.AppContainer.getPanels();

            for i = 1:numel(allPanels)
                if allPanels{i}.Tag ~= "deviceListPanel"
                    obj.AppContainer.removePanel(allPanels{i}.Tag);
                end
            end

        end

    end

end
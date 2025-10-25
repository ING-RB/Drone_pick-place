classdef (Abstract) SharedApp < matlabshared.testmeasapps.internal.dialoghandler.DialogMixin & ...
        matlab.hwmgr.internal.AppletBase & ...
        matlabshared.transportapp.internal.ISharedApp & ...
        matlabshared.transportapp.internal.utilities.ITestable

    % SHAREDAPP abstract class is the entry point into the Shared_App
    % Infrastructure. This provides custom implementation for HwMgr
    % AppletBase abstract methods like init, construct, run, destroy, and
    % canClose. Client apps must inherit from this class to use the
    % Shared_App infrastructure

    % Copyright 2020-2023 The MathWorks, Inc.

    properties (Access = {?matlabshared.transportapp.internal.utilities.ITestable,...
            ?matlabshared.transportapp.internal.ISharedApp})
        Mediator

        ToolstripManager

        AppSpaceManager

        TransportProperties

        WorkspaceVariableHandler

        CodeGenerator
    end

    %% Dialog Listeners
    properties
        ServerDisconnectedListener
    end

    properties (Constant)
        YesOption = string(message("transportapp:sharedapp:YesOption").getString)
        NoOption = string(message("transportapp:sharedapp:NoOption").getString)
    end

    %% Hook Methods
    methods
        function tabName = getAppTabName(~)
            % This is a hook that may be overridden by the implementing
            % client apps.

            tabName = "TRANSPORT APP";
        end

        function codeGenerator = getCodeGenerator(obj)
            % Construct instance of MATLABCodeGenerator to be used.
            % Subclasses should override this method to provide custom code
            % generator.
            codeGenerator = matlabshared.transportapp.internal.utilities.MATLABCodeGenerator ...
                (obj.Mediator, obj.DisplayName, obj.TransportName, obj.TransportInstance);
        end
    end

    methods (Access = protected)
        function transportProperties = getTransportProperties(~, hwMgrHandles)
            if ~isfield(hwMgrHandles.DeviceInfo.CustomData, "TransportProperties")
                throw(MException(message("transportapp:sharedapp:NoTransportPropertiesField")));
            end

            transportProperties = hwMgrHandles.DeviceInfo.CustomData.TransportProperties;
        end
    end

    %% LIFETIME
    methods
        function obj = SharedApp()
            mediator = matlabshared.mediator.internal.Mediator();
            obj@matlabshared.testmeasapps.internal.dialoghandler.DialogMixin(mediator);
            obj.Mediator = mediator;
        end
    end
    %% Overridden methods (AppletBase)
    methods
        function init(obj, hwMgrHandles)

            % Set the title text for all dialog types
            errorTitle = message("transportapp:utilities:ErrorDialogTitle", obj.DisplayName).string;
            warningTitle = message("transportapp:utilities:WarningDialogTitle", obj.DisplayName).string;
            optionTitle = message("transportapp:utilities:OptionDialogTitle", obj.DisplayName).string;

            obj.setDialogTitles(errorTitle, warningTitle, optionTitle);

            obj.TransportProperties = obj.getTransportProperties(hwMgrHandles);

            % Setting the app title before the connection is attempted
            % so that app has the correct app title even if the connection
            % errors out.
            hwMgrHandles.ToolstripTabHandle.Title = getAppTabName(obj);
            try
                transport = obj.getTransportProxy();
            catch
                % If the app fails to launch because connecting to the
                % resource failed, close the current applet using Hardware
                % Manager's closeApplet api. This will show a "device busy"
                % message in the document space of the app.
                obj.closeApplet(matlab.hwmgr.internal.AppletClosingReason.AppError);
                return
            end

            % Error if the transport is not an InspectorProxyMixin type.
            if ~isa(transport, "internal.matlab.inspector.InspectorProxyMixin")
                throw(MException(message("transportapp:sharedapp:IncorrectTransportType")));
            end

            obj.WorkspaceVariableHandler = ...
                matlabshared.transportapp.internal.utilities.WorkspaceVariableHandler(obj.Mediator);

            obj.CodeGenerator = obj.getCodeGenerator();

            toolstripForm = prepareToolstripForm(obj, hwMgrHandles);
            obj.ToolstripManager = matlabshared.transportapp.internal.toolstrip.Manager(toolstripForm);

            appSpaceForm = prepareAppspaceForm(obj, hwMgrHandles);
            obj.AppSpaceManager = matlabshared.transportapp.internal.appspace.Manager(appSpaceForm);

            % Pass along the transportproxy class to the
            % PropertiesInspector Manager class.
            setTransportProxy(obj.AppSpaceManager, transport);

            % Create the listener for when the server disconnects. This is
            % done to ensure that the app closes gracefully.
            createDisconnectedListeners(obj);
        end

        function construct(obj)
            connect(obj.Mediator);
            connect(obj.AppSpaceManager);

            [constructorComment, constructorCode] = obj.getConstructorCommentAndCode();
            connect(obj.CodeGenerator, constructorComment, constructorCode);
        end

        function run(~)
        end

        function destroy(obj)
            % Clear listeners under the App Space before the mediator is
            % cleaned up.

            delete(obj.ServerDisconnectedListener);

            if ~isempty(obj.CodeGenerator)
                disconnect(obj.CodeGenerator);
            end

            if ~isempty(obj.AppSpaceManager)
                disconnect(obj.AppSpaceManager);
            end

            disconnect(obj.Mediator);

            % Clear DialogDisplayManager listeners
            delete(obj.AppSpaceManager);
            delete(obj.WorkspaceVariableHandler);
            delete(obj.ToolstripManager);
            delete(obj.CodeGenerator);
            delete(obj.Mediator);
        end

        function flag = canClose(obj, closeReason)
            % Wait for user input before closing the app.

            arguments
                obj
                closeReason (1, 1) string
            end
            flag = false;
            % Get the app closing message.
            switch char(closeReason)
                case 'DeviceChange'
                    msgID = "transportapp:sharedapp:DeviceChange";

                case {'AppClosing', 'CloseRunningApplet'}
                    msgID = "transportapp:sharedapp:ClosingApp";

                case 'RefreshHardware'
                    msgID = "transportapp:sharedapp:AppRefresh";

                case 'DeviceRemove'
                    msgID = "transportapp:sharedapp:DeviceRemove";

                otherwise
                    % Unknown app error - return true and exit.
                    flag = true;
                    return
            end

            % The final message to be shown to the user.
            msgID = string(message(msgID, obj.TransportName).getString);

            % Present the app-closing option dialog to the user.

            % Create the options form class
            option = matlabshared.testmeasapps.internal.dialoghandler.forms.OptionsForm;

            % Fill in the Message, Options, and DefaultOption properties of the form class.
            option.Message = msgID;
            option.Options = [obj.YesOption, obj.NoOption];
            option.DefaultOption = option.Options(2);

            % Show the confirmation dialog. Execution is blocked till the user clicks on "Yes" or "No".
            result = obj.showConfirmationDialog(option);

            if result == string(obj.YesOption)
                flag = true;
            end
        end
    end

    %% HELPER METHODS
    methods (Access = protected)
        function form = prepareToolstripForm(obj, hwMgrHandles)
            % Get the toolstrip form from the getToolstripForm hook method
            % and populate other needed fields.

            form = getToolstripForm(obj, hwMgrHandles);
            if ~isa(form, "matlabshared.transportapp.internal.utilities.forms.ToolstripForm")
                throw(MException(message("transportapp:sharedapp:InvalidFormType", ...
                    "getToolstripForm", "matlabshared.transportapp.internal.utilities.forms.ToolstripForm")));
            end

            form = setCommonFormProperties(obj, form);
            form.Parent = hwMgrHandles.ToolstripTabHandle;
        end

        function form = prepareAppspaceForm(obj, hwMgrHandles)
            % Get the appspace form from the getAppSpaceForm hook method
            % and populate other needed fields.

            form = getAppSpaceForm(obj, hwMgrHandles);

            if ~isa(form, "matlabshared.transportapp.internal.utilities.forms.AppSpaceForm")
                throw(MException(message("transportapp:sharedapp:InvalidFormType", ...
                    "getAppSpaceForm", "matlabshared.transportapp.internal.utilities.forms.AppSpaceForm")));
            end
            form.Parent = hwMgrHandles.RootWindow;
            form = setCommonFormProperties(obj, form);
            sidePanel = ...
                matlabshared.transportapp.internal.utilities.factories.AppSpaceElementsFactory.createHwMgrSidePanel ...
                (obj, form.PropertyInspectorSidePanelProperties);

            form.PropertyInspectorSidePanel = sidePanel;
        end

        function form = setCommonFormProperties(obj, form)
            % Set the common appspace and toolstrip form properties.

            form.Mediator = obj.Mediator;
            form.TransportName = obj.TransportName;
        end

        function createDisconnectedListeners(obj)
            % Create the listener for the ServerDisconnected property on
            % the BaseTransportProxy (PropertyInspector.InspectedObjects)
            % that denotes that a server has dropped and to gracefully exit
            % out of the client app.
            obj.ServerDisconnectedListener = listener(obj.AppSpaceManager.PropertyInspectorManager.PropertyInspector.InspectedObjects, 'ServerDisconnected',...
                'PostSet', ...
                @(src,event)obj.handleServerDisconnected(obj.DisplayName));
        end

        function handleServerDisconnected(obj, ~)
            ex = MException(message("transportapp:sharedapp:ServerDisconnected"));
            errorObj = matlabshared.testmeasapps.internal.dialoghandler.forms.ErrorForm(ex);
            showErrorDialog(obj, errorObj);
            obj.closeApplet(matlab.hwmgr.internal.AppletClosingReason.AppError);
            return
        end
    end
end

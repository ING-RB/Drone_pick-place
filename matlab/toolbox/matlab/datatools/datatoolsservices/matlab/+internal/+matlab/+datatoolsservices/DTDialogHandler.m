classdef DTDialogHandler < handle
    % CONFIRMATIONDIALOGHANDLER launches a confirmation dialog along with an
    % optional setting for the confirmation dialog.

    % Copyright 2021-2024 The MathWorks, Inc.
    
    properties(Constant, Access='private')
        CHANNEL = '/DTConfirmDlg';
        CONFIRMATION_DIALOG_TYPE = "ConfirmationDialog";
        INPUT_DIALOG_TYPE = "InputDialog";
    end
    
    properties(Access='private')
        dialogSubscriptionHandle;
        dialogResponseCallbacks;
    end

    methods
        %   showConfirmationDialog (dialogMessage, dialogTitle) requests the client to
        %   display a confirmation dialog with the 'dialogMessage' and 'dialogTitle'
        %
        %   showConfirmationDialog(...,Name, Value) specifies additional
        %   name-value pairs as described below:
        %
        %   'Source'        A string value containing a unique identifier
        %                   representing the caller. By default, the
        %                   service will assign an identifier
        %   'CallbackFcn'   A function handle representing the callback to
        %                   be fired when a response is received on the dialog. The
        %                   response could be from a button click or if the user dismissed
        %                   the dialog (which is treated as cancel)
        %   'Icon'          String value that must be one of ["error","warning","info","question","success","none"]
        %                   By default, "question" will be displayed.
        %   'DialogButtons' A string array of button texts to be displayed
        %                   in the dialog. Max of 5 button texts will be honored and the
        %                   response will correspond to the order of these dialog button
        %                   actions. Defaults to [OK, Cancel]
        %   'SettingPath'   If the dialog is to display a confirmation
        %                   checkbox (allowing users to opt out of this dialog), A comma
        %                   separated settingsPath is provided as string
        %   'SettingVal'    Setting value from the previous SettingPath as
        %                   string.
        %   'DialogType'    Type of Dialog to be launched (Either modal or modeless)
        function showConfirmationDialog(this, dialogMessage, dialogTitle, dialogArgs)
            arguments
                this
                dialogMessage string
                dialogTitle string
                dialogArgs.Source string = "__dialogHandler"
                dialogArgs.CallbackFcn function_handle = function_handle.empty
                dialogArgs.DialogType {mustBeMember(dialogArgs.DialogType,["modal","modeless"])} = "modeless"
                dialogArgs.Icon {mustBeMember(dialogArgs.Icon,["error","warning","info","question","success","none"])} = "question"
                dialogArgs.DialogButtons string = []
                dialogArgs.SettingPath string = ""
                dialogArgs.SettingVal string = ""
            end
            if ~isempty(dialogArgs.CallbackFcn)
                this.dialogResponseCallbacks(dialogArgs.Source) = dialogArgs.CallbackFcn;
            end
            dialogArgs = rmfield(dialogArgs, 'CallbackFcn');
            dialogArgs.message = dialogMessage;
            dialogArgs.title = dialogTitle;
            dialogArgs.type = this.CONFIRMATION_DIALOG_TYPE;
            this.publishMessage(dialogArgs);
        end

        %   showInputDialog (dialogMessage, dialogTitle) requests the client to
        %   display an input dialog with the 'dialogMessage' and 'dialogTitle'
        %
        %   showInputDialog(...,Name, Value) specifies additional
        %   name-value pairs as described below:
        %
        %   'Source'        A string value containing a unique identifier
        %                   representing the caller. By default, the
        %                   service will assign an identifier
        %   'CallbackFcn'   A function handle representing the callback to
        %                   be fired when a response is received on the dialog. The
        %                   response could be from a button click or if the user dismissed
        %                   the dialog (which is treated as cancel)
        %   'DialogButtons' A struct array of button type and button texts to be displayed
        %                   in the dialog. E.g [struct('type', "DoIt", 'text', 'Proceed')] Defaults to [OK, Cancel]
        %   'DialogType'    Type of Dialog to be launched (Either modal or modeless)
        function showInputDialog(this, dialogMessage, dialogTitle, dialogArgs)
            arguments
                this
                dialogMessage string
                dialogTitle string
                dialogArgs.Source string = "__dialogHandler"
                dialogArgs.CallbackFcn function_handle = function_handle.empty
                dialogArgs.DialogButtons struct
                dialogArgs.DialogType {mustBeMember(dialogArgs.DialogType,["modal","modeless"])} = "modeless"
            end
            if ~isempty(dialogArgs.CallbackFcn)
                this.dialogResponseCallbacks(dialogArgs.Source) = dialogArgs.CallbackFcn;
            end
            dialogArgs = rmfield(dialogArgs, 'CallbackFcn');
            dialogArgs.message = dialogMessage;
            dialogArgs.title = dialogTitle;
            dialogArgs.type = this.INPUT_DIALOG_TYPE;
            this.publishMessage(dialogArgs);
        end

        function delete(this)
            message.unsubscribe(this.dialogSubscriptionHandle);
            this.dialogSubscriptionHandle = [];
        end
    end
    
    methods(Access=?matlab.unittest.TestCase)

        % Handles dialog response from the confirmation dialog. 
        % msg   struct containing the following fields:
        %       
        % 'response'   Integer number corresponding to the order of DialogButton 
        %       values provided. Defaults are 1 = ok, 2 = cancel. 
        % 'buttonText' String value of the button clicked on. 
        % 'src'        Unique identifier matching the Source of the dialog request
        %              dispatcher. Defaults to "__dialogHandler"
        function handleMessageReceived(this, msg)
            if ~isempty(msg) && isfield(msg, 'response')
                if (this.dialogResponseCallbacks.isKey(msg.src))
                    responseCallback = this.dialogResponseCallbacks(msg.src);
                    responseCallback(msg);
                    remove(this.dialogResponseCallbacks, msg.src);
                end
            end 
        end
    end

    methods(Access='protected')
        function publishMessage(this, clientMsg) 
            message.publish(this.CHANNEL, clientMsg);
        end

        function obj = DTDialogHandler()
            obj.dialogSubscriptionHandle = message.subscribe(obj.CHANNEL, @(msg) obj.handleMessageReceived(msg), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
            obj.dialogResponseCallbacks = containers.Map;
        end
    end

    methods(Static)
        % Get an instance of the confirmation dialog handler
        function obj = getInstance()
            mlock;  % Keep persistent variables until MATLAB exits
            persistent DTdlgInstance;
            if isempty(DTdlgInstance) || ~isvalid(DTdlgInstance)
                DTdlgInstance = internal.matlab.datatoolsservices.DTDialogHandler;
            end
            obj = DTdlgInstance;
        end
    end 
end


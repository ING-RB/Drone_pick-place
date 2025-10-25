classdef (Abstract) DialogMixin < handle
    %DIALOGMIXIN is the mixin class responsible for interacting with
    %Hardware Manager's dialog mechanism, via the main Applet class.

    %   Copyright 2021-2023 The MathWorks, Inc.

    properties
        DialogRequestReceiver
    end

    properties
        ErrorTitle (1, 1) string
        WarningTitle (1, 1) string
        OptionsTitle (1, 1) string
    end

    properties (Hidden, Constant)
        ValidFormClass = ["matlabshared.testmeasapps.internal.dialoghandler.forms.ErrorForm", ...
            "matlabshared.testmeasapps.internal.dialoghandler.forms.WarningForm", ...
            "matlabshared.testmeasapps.internal.dialoghandler.forms.OptionsForm"]
    end

    properties (Access = ?matlabshared.testmeasapps.internal.ITestable)
        ErrorObjListener
        WarningObjListener
        OptionObjListener
    end

    properties (Access = ?matlabshared.testmeasapps.internal.ITestable)
        % Internal property used to disable actual dialog display
        % mechanisms for unit-tests. This is needed because request to
        % HwMgr's dialog mechanism will error for unit tests, as there is
        % no app running.
        ShowDialog (1, 1) logical = true
    end

    methods
        function obj = DialogMixin(mediator)
            arguments
                mediator (1, 1) matlabshared.mediator.internal.Mediator
            end

            obj.DialogRequestReceiver = ...
                matlabshared.testmeasapps.internal.dialoghandler.DialogRequestReceiver(mediator);
            obj.setDefaultTitles();
            obj.setupListeners();

        end
    end

    %% PUBLIC API
    methods
        function setDialogTitles(obj, errorTitle, warningTitle, optionsTitle)
            % Set the Error, Warning, and Dialog Titles.

            obj.ErrorTitle = errorTitle;
            obj.WarningTitle = warningTitle;
            obj.OptionsTitle = optionsTitle;
        end

        function showErrorDialog(obj, errorObj)
            % Show the error dialog.
            arguments
                obj
                errorObj (1, 1) matlabshared.testmeasapps.internal.dialoghandler.forms.ErrorForm
            end

            title = obj.getTitle(errorObj);

            if obj.ShowDialog
                obj.showError(title, errorObj.Exception.message);
            end
        end

        function showWarningDialog(obj, warningObj)
            % Show the warning dialog.
            arguments
                obj
                warningObj (1, 1) matlabshared.testmeasapps.internal.dialoghandler.forms.WarningForm
            end

            title = obj.getTitle(warningObj);

            if obj.ShowDialog
                obj.showWarning(title, warningObj.Message);
            end
        end

        function optionsResponse = showConfirmationDialog(obj, confirmationObj)
            % Show the options dialog and returns the user's selection as
            % an output.
            arguments
                obj
                confirmationObj (1, 1) matlabshared.testmeasapps.internal.dialoghandler.forms.OptionsForm
            end

            optionsResponse = "";

            title = obj.getTitle(confirmationObj);
            validateDefaultOption(obj, confirmationObj);

            if obj.ShowDialog
                optionsResponse = ...
                    string(showConfirm(obj, title, confirmationObj.Message, confirmationObj.Options, confirmationObj.DefaultOption));
            end

            obj.DialogRequestReceiver.setOptionsResponse(optionsResponse);
        end
    end

    %% Implementing Abstract Methods
    methods
        function subscribeToMediatorProperties(obj, ~, ~)
            obj.subscribe("OptionsResponse", ...
                @(src, event)obj.setOptionsResponse(event.AffectedObject.OptionsResponse));
        end
    end

    %% Helper Methods
    methods (Access = ?matlabshared.testmeasapps.internal.ITestable)
        function title = getTitle(obj, form)
            % Returns the title from the form. If the form does not have a
            % title, this function returns the default titles set for the
            % class.

            arguments
                obj
                form (1, 1) matlabshared.testmeasapps.internal.dialoghandler.forms.BaseForm
            end
            if form.Title ~= ""
                title = form.Title;
            else
                title = getDefaultTitle(obj, form);
            end

            %% NESTED FUNCTION
            function title = getDefaultTitle(obj, form)
                switch string(class(form))
                    case "matlabshared.testmeasapps.internal.dialoghandler.forms.ErrorForm"
                        title = obj.ErrorTitle;
                    case "matlabshared.testmeasapps.internal.dialoghandler.forms.WarningForm"
                        title = obj.WarningTitle;
                    case "matlabshared.testmeasapps.internal.dialoghandler.forms.OptionsForm"
                        title = obj.OptionsTitle;
                    otherwise
                        throw(MException(message("shared_testmeaslib_apps:dialog:InvalidForm")));
                end
            end
        end

        function setDefaultTitles(obj)
            % Set the default title values for the 3 dialog titles - error,
            % warning, and confirmation.
            arguments
                 obj {mustBeA(obj, ["matlab.hwmgr.internal.AppletBase", "matlab.hwmgr.internal.DeviceParamsDescriptor"])}
            end
            obj.ErrorTitle = message("shared_testmeaslib_apps:dialog:ErrorTitle", obj.DisplayName).getString(); %#ok<*MCNPN>
            obj.WarningTitle = message("shared_testmeaslib_apps:dialog:WarningTitle", obj.DisplayName).getString();
            obj.OptionsTitle = message("shared_testmeaslib_apps:dialog:ConfirmationTitle", obj.DisplayName).getString();
        end

        function obj = validateDefaultOption(obj, optionObj)
            % Verify that the default option is valid, i.e. it needs to be
            % one of the options. E.g., if the options are "Yes" and "No",
            % the default option has to be either "Yes" or "No".

            defaultOption = optionObj.DefaultOption;
            allOptions = optionObj.Options;

            % If the default option is not one of the possible option
            % values provided - error.
            if ~ismember(defaultOption, allOptions)
                listString = strjoin(allOptions, ", "); %#ok<*MCSUP>
                throw(MException(message("shared_testmeaslib_apps:dialog:InvalidDefaultOption", ...
                    defaultOption, listString)));
            end
        end

        function setupListeners(obj, ~, ~)
            obj.ErrorObjListener = listener(obj.DialogRequestReceiver, "ErrorObject", ...
                "PostSet",  @(src,event)obj.showErrorDialog(event.AffectedObject.ErrorObject));

            obj.WarningObjListener = listener(obj.DialogRequestReceiver, "WarningObject", ...
                "PostSet",  @(src,event)obj.showWarningDialog(event.AffectedObject.WarningObject));

            obj.OptionObjListener = listener(obj.DialogRequestReceiver, "OptionObject", ...
                "PostSet",  @(src,event)obj.showConfirmationDialog(event.AffectedObject.OptionObject));
        end
    end
end

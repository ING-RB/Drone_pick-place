classdef (Abstract) DialogSource < handle
    %DIALOGSOURCE exposes shared_dialog infrastructure's API's to show
    %dialogs in HwMgr based T&M apps.

    %   Copyright 2021-2022 The MathWorks, Inc.

    properties (Hidden, Dependent)
        ErrorObj
        WarningObj
        OptionObj
    end

    properties (Access = ?matlabshared.testmeasapps.internal.ITestable)
        DialogSourceSubscriber
        DialogSourcePublisher
    end

    properties (Dependent, Access = ?matlabshared.testmeasapps.internal.ITestable)
        % The user's response to a confirmation dialog.
        OptionsResponse
    end

    methods
        function obj = DialogSource(mediator)
            arguments
                mediator (1, 1) matlabshared.mediator.internal.Mediator
            end
            obj.DialogSourcePublisher = ...
                matlabshared.testmeasapps.internal.dialoghandler.DialogSourcePublisher(mediator);
            obj.DialogSourceSubscriber = ...
                matlabshared.testmeasapps.internal.dialoghandler.DialogSourceSubscriber(mediator);
        end
    end

    %% Dialog Handlers
    methods
        %% For ERROR DIALOGS
        function showErrorDialog(obj, errObj)
            if ~isa(errObj, "matlabshared.testmeasapps.internal.dialoghandler.forms.ErrorForm")
                errObj = matlabshared.testmeasapps.internal.dialoghandler.forms.ErrorForm(errObj);
            end
            obj.ErrorObj = errObj;
        end

        %% For WARNING DIALOGS
        function showWarningDialog(obj, warningObj)
            arguments
                obj
                warningObj (1, 1) matlabshared.testmeasapps.internal.dialoghandler.forms.WarningForm
            end
            obj.WarningObj = warningObj;
        end

        %% For CONFIRMATION DIALOGS
        function result = showConfirmationDialog(obj, optionObj)
            arguments
                obj
                optionObj (1, 1) matlabshared.testmeasapps.internal.dialoghandler.forms.OptionsForm
            end

            obj.OptionObj = optionObj;
            result = obj.OptionsResponse;
        end
    end

    %% Getters and Setters
    methods
        %% Getters
        function val = get.OptionsResponse(obj)
            val = obj.DialogSourceSubscriber.OptionsResponse;
        end

        function val = get.ErrorObj(obj)
            val = obj.DialogSourcePublisher.ErrorObj;
        end

        function val = get.WarningObj(obj)
            val = obj.DialogSourcePublisher.WarningObj;
        end

        function val = get.OptionObj(obj)
            val = obj.DialogSourcePublisher.OptionObj;
        end

        %% Setters
        function set.OptionsResponse(obj, val)
            obj.DialogSourceSubscriber.OptionsResponse = val;
        end

        function set.ErrorObj(obj, val)
            obj.DialogSourcePublisher.ErrorObj = val;
        end

        function set.WarningObj(obj, val)
            obj.DialogSourcePublisher.WarningObj = val;
        end

        function set.OptionObj(obj, val)
            obj.DialogSourcePublisher.OptionObj = val;
        end
    end
end

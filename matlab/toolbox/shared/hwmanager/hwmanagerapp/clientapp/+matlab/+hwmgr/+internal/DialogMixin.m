classdef DialogMixin < handle
    % matlab.hwmgr.internal.DialogMixin - mixin class providing client app
    % interfaces with utilities to show dialogs

    % Copyright 2021-2022 Mathworks Inc.

    properties (Access = private)
        BringToFrontFcn = function_handle.empty;
        MakeWindowBusyFcn = function_handle.empty;
    end

    methods (Sealed, Hidden)

        function setBringToFrontFcn(obj, fcnHandle)
            validateattributes(fcnHandle, {'function_handle'}, {});
            obj.BringToFrontFcn = fcnHandle;
        end

        function setMakeWindowBusyFcn(obj, fcnHandle)
            validateattributes(fcnHandle, {'function_handle'}, {});
            obj.MakeWindowBusyFcn = fcnHandle;
        end

        function out = showDialog(obj,title, message, dlgType, options, defaultOption)
            arguments
                obj
                title
                message
                dlgType
                options = [];
                defaultOption = [];
            end
            view = obj.BringToFrontFcn(obj);
            out = showDialogImpl();


            % -------------Nested Helpers ---------------%
            function out = showDialogImpl()
                out = [];
                parent = view;
                waitfor(parent, 'Visible', true);
                if dlgType == "error"
                    matlab.hwmgr.internal.DialogFactory.constructErrorDialog(parent, message, title);
                elseif dlgType == "warning"
                    matlab.hwmgr.internal.DialogFactory.constructWarningDialog(parent, message, title);
                elseif dlgType == "confirm"
                    out = matlab.hwmgr.internal.DialogFactory.constructConfirmationDialog(parent, message, title, 'Options', options, 'DefaultOption', defaultOption);
                end
            end
        end


    end

    methods (Sealed)

        function showError(obj, title, message)
            obj.showDialog(title, message, 'error');
        end

        function showWarning(obj, title, message)
            obj.showDialog(title, message, 'warning');
        end

        function out = showConfirm(obj, title, message, options, defaultOption)
            out = obj.showDialog(title, message, 'confirm', options, defaultOption);
        end

        function makeWindowBusy(obj, isBusy)
            obj.MakeWindowBusyFcn(isBusy);
        end

    end

end
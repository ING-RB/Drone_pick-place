classdef SocketDialog < matlabshared.transportapp.internal.visamodaldialog.BaseDialog
    %VXI11DIALOGBUILDER is the specialized BaseDialog class for generating
    %a Modal Dialog Window for a Socket resource.

    % Copyright 2022-2023 The MathWorks, Inc.

    properties
        BuilderConstants = matlabshared.transportapp.internal.visamodaldialog.GenerateResource5FieldConstants
    end

    %% Abstract Methods Impl
    methods
        function form = getDialogBuilderForm(~)
            form = matlabshared.transportapp.internal.visamodaldialog.DialogBuilderForm;
            form.ResourceType = message("transportapp:visadevapp:SocketResource").getString;
            form.BoardNumberRowIndex = 1;
            form.IPAddressRowIndex = 2;
            form.PortRowIndex = 3;
            form.GenerateResourceRowIndex = 4;
            form.ResourceNameRowIndex = 5;
        end

        function resourceString = getResourceString(~, form)
            resourceString = ...
                transportapp.visadev.internal.VisadevIdentification.getSocketResourceString(form);
        end
    end
end

classdef HiSlipDialog < matlabshared.transportapp.internal.visamodaldialog.BaseDialog
    %VXI11DIALOGBUILDER is the specialized BaseDialog class for generating
    %a Modal Dialog Window for a HISLIP resource.

    % Copyright 2022-2023 The MathWorks, Inc.

    properties
        BuilderConstants = matlabshared.transportapp.internal.visamodaldialog.GenerateResource6FieldConstants
    end

    %% Abstract Methods Impl
    methods
        function form = getDialogBuilderForm(~)
            form = matlabshared.transportapp.internal.visamodaldialog.DialogBuilderForm;
            form.ResourceType = message("transportapp:visadevapp:HiSlipResource").getString;
            form.BoardNumberRowIndex = 1;
            form.IPAddressRowIndex = 2;
            form.DeviceIDRowIndex = 3;
            form.PortRowIndex = 4;
            form.GenerateResourceRowIndex = 5;
            form.ResourceNameRowIndex = 6;
        end

        function resourceString = getResourceString(~, form)
            resourceString = ...
                transportapp.visadev.internal.VisadevIdentification.getHiSlipResourceString(form);
        end
    end
end

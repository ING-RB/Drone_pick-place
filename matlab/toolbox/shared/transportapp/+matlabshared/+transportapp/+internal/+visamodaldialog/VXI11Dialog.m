classdef VXI11Dialog < matlabshared.transportapp.internal.visamodaldialog.BaseDialog
    %VXI11DIALOGBUILDER is the specialized BaseDialog class for generating
    %a Modal Dialog Window for a VXI-11 resource.

    % Copyright 2022-2023 The MathWorks, Inc.

    properties
        BuilderConstants = matlabshared.transportapp.internal.visamodaldialog.GenerateResource5FieldConstants
    end

    %% Abstract Methods Impl
    methods
        function form = getDialogBuilderForm(~)
            form = matlabshared.transportapp.internal.visamodaldialog.DialogBuilderForm;
            form.ResourceType = message("transportapp:visadevapp:VXI11Resource").getString;
            form.BoardNumberRowIndex = 1;
            form.IPAddressRowIndex = 2;
            form.DeviceIDRowIndex = 3;
            form.GenerateResourceRowIndex = 4;
            form.ResourceNameRowIndex = 5;
        end

        function resourceString = getResourceString(~, form)
            resourceString = ...
                transportapp.visadev.internal.VisadevIdentification.getVXI11ResourceString(form);
        end
    end
end


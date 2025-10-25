classdef DescriptorDialogCompatibleMixin < handle
    % DESCRIPTORDIALOGCOMPATIBLEMIXIN class fetches the DisplayName
    % for the respective apps

    %   Copyright 2023 The MathWorks, Inc.

    properties
        DisplayName (1, 1) string
        ErrorObj
        ShowErrorDialog (1, 1) logical = true
    end

    methods
        function handleErrorProxy(obj, ex)
            obj.ErrorObj = ex;
            errorObj =  matlabshared.testmeasapps.internal.dialoghandler.forms.ErrorForm(ex);
            if obj.ShowErrorDialog
                showErrorDialog(obj, errorObj);
            end
        end
    end
end

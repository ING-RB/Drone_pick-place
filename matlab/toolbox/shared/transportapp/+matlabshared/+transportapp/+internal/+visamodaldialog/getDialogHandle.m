function dialogHandle = getDialogHandle(dialogHandle, clearDialog)
% GETDIALOGHANDLE is a helper function that provides access to the VISA
% app's modal dialog window outside of the VISA App.

%    Copyright 2022-2023 The MathWorks, Inc.

arguments
    dialogHandle = []
    clearDialog (1, 1) logical = false
end

persistent val

if isempty(val) && isempty(dialogHandle)
    error(message("transportapp:visadevapp:ModalDialogNotSet").string);
end

if isempty(val)
    val = dialogHandle;
end

if clearDialog
    val = [];
end

dialogHandle = val;
end
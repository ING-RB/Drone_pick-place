classdef DlgImplInterface < handle
% Abstract base interface class for dialog implementations. Hardware
% Manager implements this interface for showing dialogs. Addtionally, this
% interface enables the MATLAB Mocking Framework to mock dialogs in test.

% Copyright 2019-2021 Mathworks Inc.

    methods (Abstract)
        constructErrorDialog(obj)
        constructWarningDialog(obj)
        constructInfoDialog(obj)
        constructSuccessDialog(obj)
        constructConfirmationDialog(obj)
    end
    
end
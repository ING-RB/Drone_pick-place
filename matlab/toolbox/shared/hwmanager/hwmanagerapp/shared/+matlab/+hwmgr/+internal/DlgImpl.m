classdef DlgImpl < matlab.hwmgr.internal.DlgImplInterface
% Default dialog implementation class. This class implements the hardware
% manager dialogs using the UI* dialog APIs compatible with UIFIGURE

% Copyright 2019-2021 Mathworks Inc.
    
    methods
        function constructErrorDialog(~, parent, message, title)
            uialert(parent, message, title);
            
            % An error dialog is used, capture the error with DDUX
            dataStruct = struct("errorId", string(title), "errorMsg", string(message));
            usageLogger = matlab.hwmgr.internal.UsageLogger();
            try
                usageLogger.logErrorDisplayed(dataStruct);
            catch
                % Do nothing if we could not collect usage data
            end
        end
        
        function constructWarningDialog(~, parent, message, title)
            uialert(parent, message, title, 'Icon', 'warning');
        end
        
        function constructInfoDialog(~, parent, message, title)
            uialert(parent, message, title, 'Icon', 'info');
        end
        
        function constructSuccessDialog(~, parent, message, title)
            uialert(parent, message, title, 'Icon', 'success');
        end
        
        function selection = constructConfirmationDialog(~, varargin)
            % Invoke uiconfirm to create option dialog
            selection = uiconfirm(varargin{:});
        end
    end
    
    
end
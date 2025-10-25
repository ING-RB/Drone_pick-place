classdef DialogFactory
    %DIALOGFACTORY Provides the factory methods to construct dialogs in
    %Hardware Manager.
    % 
    % This class is a wrapper of uialert and uiconfirm. The reason for
    % having this class is to also provide DDUX logging capability for
    % dialogs used in Hardware Manager. Currently, only error dialogs are
    % logged. 

    % This class also allows dialogs to be mocked via an impl pattern.
    
    % Copyright 2019-2022 The MathWorks, Inc.
    
    properties (Constant, Access = {?hwmgr.MockingTester, ?matlab.hwmgr.internal.DialogFactory, ?hwmgr.test.TestCase})
        ImplSwitcher = matlab.hwmgr.internal.DlgImplSwitcher;
    end
    
    methods(Static)
        
        function constructErrorDialog(parent, message, title)
            dlgImpl = matlab.hwmgr.internal.DialogFactory.ImplSwitcher.ImplToUse;
            dlgImpl.constructErrorDialog(parent, message, title);
        end
        
        function constructWarningDialog(parent, message, title)
            dlgImpl = matlab.hwmgr.internal.DialogFactory.ImplSwitcher.ImplToUse;
            dlgImpl.constructWarningDialog(parent, message, title);
        end
        
        function constructInfoDialog(parent, message, title)
            dlgImpl = matlab.hwmgr.internal.DialogFactory.ImplSwitcher.ImplToUse;
            dlgImpl.constructInfoDialog(parent, message, title);
        end
        
        function constructSuccessDialog(parent, message, title)
            dlgImpl = matlab.hwmgr.internal.DialogFactory.ImplSwitcher.ImplToUse;
            dlgImpl.constructSuccessDialog(parent, message, title);
        end
        
        function selection = constructConfirmationDialog(varargin)
            % Invoke uiconfirm to create option dialog
            dlgImpl = matlab.hwmgr.internal.DialogFactory.ImplSwitcher.ImplToUse;
            selection = dlgImpl.constructConfirmationDialog(varargin{:});
        end
    end
end
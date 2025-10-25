classdef DlgImplSwitcher < handle
% DLGIMPLSWITCHER is a handle class that references the Hardware Manager
% dialog implementation to use. This class is used by the Hardware Manager
% Tester to inject a mock DlgImpl that is exercised during tests by all
% clients of matlab.hwmgr.internal.DialogFactory

% Copyright 2019 Mathworks Inc.
    
    properties
        ImplToUse
    end
    
    methods
        
        function obj = DlgImplSwitcher()
            obj.ImplToUse = matlab.hwmgr.internal.DlgImpl;
        end
    end
end
classdef (Hidden) BasicScopeImplementation < matlab.hwmgr.scopes.BaseHardwareManagerScope
    %BASICSCOPEIMPLEMENTATION This class provides implementations specific
    %for the BasicScope
    
    % Copyright 2019 The MathWorks, Inc.  
    
    methods(Access = protected)
        function h = getMessageHandler(~)
            h = matlab.hwmgr.scopes.BasicScopeMessageHandler;
        end
    end
end
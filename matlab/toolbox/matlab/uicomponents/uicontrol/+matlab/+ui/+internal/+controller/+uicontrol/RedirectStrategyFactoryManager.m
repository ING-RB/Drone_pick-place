classdef (Hidden) RedirectStrategyFactoryManager < handle
    % REDIRECTSTRATEGYFACTORYMANAGER is a singleton which manages the current
    % instance of which RedirectStrategyFactory is used by WebUIControlController.
    
    % Copyright 2019 The MathWorks, Inc.
    
    properties (Constant)
        % Singleton instance of this class
        Instance = matlab.ui.internal.controller.uicontrol.RedirectStrategyFactoryManager;
    end
    
    properties
        RedirectStrategyFactory
    end
    
    properties (Access = private)
        % Storage for the RedirectStrategyFactory field
        PrivateRedirectStrategyFactory
    end
    
    methods (Access = private)
        function obj = RedirectStrategyFactoryManager()
            obj.RedirectStrategyFactory = matlab.ui.internal.controller.uicontrol.RedirectStrategyFactory();
            
            % put an mlock in this constructor to avoid any of the "clear"
            % commands from freeing up the Instance of this class.
            mlock;
        end
    end
end
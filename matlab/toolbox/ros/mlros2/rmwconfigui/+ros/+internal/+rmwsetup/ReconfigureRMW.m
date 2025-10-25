classdef ReconfigureRMW < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    % RMWReConfigure - Screen implementation to enable users to skip configuration or
    % reconfigure the selected RMW Implementation.
    
    % Copyright 2022 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase, ...
            ?hwsetuptest.util.TemplateBaseTester})
        % Description in the screen
        Description
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner
    end
    
    methods
        function obj = ReconfigureRMW(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})
            
            % Set the Title Text
            obj.Title.Text = message('ros:mlros2:rmwsetup:RMWReconfigurationTitle').getString();
            obj.Description = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.Description.Text = message('ros:mlros2:rmwsetup:RMWConfigurationAvailable',obj.Workflow.RMWImplementation).getString();
            obj.Description.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            obj.Description.Position = [20 110 430 270];

            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';

            obj.setScreenProperty();
            %Set Busy Spinner Properties
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';

        end
        
        function setScreenProperty(obj)
            % Set Description Properties
            obj.ConfigurationInstructions.Text = '';
            obj.HelpText.AboutSelection = message("ros:mlros2:rmwsetup:RMWAvailableConfigurationAboutSelection").getString();

            obj.NextButton.Enable = 'on';

        end %End of setScreenProperty method

        
        function reinit(obj)
            
            obj.BusySpinner.Visible = 'off';
            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';
            obj.enableScreen();

            obj.Description.Text = message('ros:mlros2:rmwsetup:RMWConfigurationAvailable',obj.Workflow.RMWImplementation).getString();
            
            obj.setScreenProperty();
        end
        
        
        function out = getPreviousScreenID(~)
            out = 'ros.internal.rmwsetup.SelectRMWImplementation';
        end

        function out = getNextScreenID(obj)
            if strcmpi(obj.Workflow.RMWImplementation, 'rmw_connextdds')
                out = 'ros.internal.rmwsetup.ValidateRTIDDSInstallation';
            elseif strcmpi(obj.Workflow.RMWImplementation, 'rmw_iceoryx_cpp')
                out = 'ros.internal.rmwsetup.ValidateIceoryxInstallation';
            end
        end
    end
end
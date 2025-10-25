classdef TestRMWImplementation < matlab.hwmgr.internal.hwsetup.ManualConfiguration
    % TestRMWImplementation - Screen implementation to enable users to test the
    % creation of ros2node with selected RMW Implementation.
    
    % Copyright 2022 The MathWorks, Inc.
    
    properties(Access={?matlab.hwmgr.internal.hwsetup.TemplateBase, ...
            ?hwsetuptest.util.TemplateBaseTester})
        % Test Status Table to show the status of test
        TestStatusTable
        % Test Button to validate the node creation
        TestButton
        % Description in the screen
        Description
    end
    
    properties (Access = private)
        % Spinner widget
        BusySpinner
    end
    
    methods
        function obj = TestRMWImplementation(varargin)
            % Call to the base class constructor
            obj@matlab.hwmgr.internal.hwsetup.ManualConfiguration(varargin{:})
            
            % Set the Title Text
            obj.Title.Text = message('ros:mlros2:rmwsetup:TestRMWImplementationTitle').getString();
            obj.Description = matlab.hwmgr.internal.hwsetup.HTMLText.getInstance(obj.ContentPanel);
            obj.Description.Text = message('ros:mlros2:rmwsetup:TestRMWImplementationWithBuiltinDDS',obj.Workflow.RMWImplementation).getString();
            obj.Description.Position = [20 325 400 50];

            %Set Image Properties
            obj.ConfigurationImage.ImageFile = '';
            
            % Create button widget and parent it to the content panel
            %Set TestButton Properties
            obj.TestButton = matlab.hwmgr.internal.hwsetup.Button.getInstance(obj.ContentPanel); % Button
            obj.TestButton.Text = message('ros:mlros2:rmwsetup:TestRMWButton').getString();
            obj.TestButton.Enable = 'on';
            obj.TestButton.Visible = 'on';
            obj.TestButton.ButtonPushedFcn = @obj.testRMWImplementation;
            obj.TestButton.Color = matlab.hwmgr.internal.hwsetup.util.Color.MWBLUE;
            obj.TestButton.FontColor = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;

            obj.TestStatusTable = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(obj.ContentPanel);
            obj.TestStatusTable.Visible = 'off';
            obj.TestStatusTable.Enable = 'off';
            obj.TestStatusTable.Status = {''};
            obj.TestStatusTable.Steps = {''};
            obj.TestStatusTable.Border='off';

            obj.setScreenProperty();
            %Set Busy Spinner Properties
            obj.BusySpinner = matlab.hwmgr.internal.hwsetup.BusyOverlay.getInstance(obj.ContentPanel);
            obj.BusySpinner.Visible = 'off';

        end
        
        function setScreenProperty(obj)
            obj.TestButton.Position = [20 280 130 25];
            obj.TestStatusTable.ColumnWidth = [20 400];
            obj.TestStatusTable.Position = [20 180 450 70];

            % Set Description Properties
            obj.ConfigurationInstructions.Text = '';
            obj.HelpText.AboutSelection = message("ros:mlros2:rmwsetup:AboutFinishSelection").getString();

            obj.NextButton.Enable = 'off';

        end %End of setScreenProperty method

        
        function reinit(obj)
            
            obj.BusySpinner.Visible = 'off';
            obj.enableScreen();

            obj.Description.Text = message('ros:mlros2:rmwsetup:TestRMWImplementationWithBuiltinDDS',obj.Workflow.RMWImplementation).getString();
            
            obj.setScreenProperty();
            obj.SetTestStatusTable('off');
        end
        
        
        function out = getPreviousScreenID(obj)
            if strcmpi(obj.Workflow.RMWImplementation, 'rmw_connextdds')
                out = 'ros.internal.rmwsetup.BuildRMWConnextPackage';
            elseif strcmpi(obj.Workflow.RMWImplementation, 'rmw_iceoryx_cpp')
                out = 'ros.internal.rmwsetup.BuildRMWIceoryxPackage';
            else
                session = obj.Workflow.getSession;
                pkgLocationToRMWMap = session('RMWLocationToPackagesMap');
                rmwImpls = pkgLocationToRMWMap.values;

                typesupportMap = session('RMWTypeSupportMap');
                hasStatic = false;

                if ~ismember('PkgSelectionMap',session.keys)
                    if isequal(typesupportMap(rmwImpls{1}{:}), 'static')
                        hasStatic = true;
                    end
                else
                    rmwImplSelections = session('PkgSelectionMap').keys;
                    if isequal(rmwImplSelections{:}, 'all')
                        for i=1:numel(rmwImpls{1})
                            if isequal(typesupportMap(rmwImpls{1}{i}), 'static')
                                hasStatic = true;
                                break;
                            end
                        end
                    else
                        if isequal(typesupportMap(rmwImplSelections{:}), 'static')
                            hasStatic = true;
                        end
                    end

                end
                if hasStatic
                    out = 'ros.internal.rmwsetup.BuildROSMessagePackages';
                else
                    out = 'ros.internal.rmwsetup.BuildCustomRMWPackage';
                end
            end
        end
    end

    methods (Static)
       function testButtonCallback(obj,~,~)
            %% testButtonCallback - Callback function when user clicks the 
            % Test RMW button on the screen 
            
            %Disable the screen before starting BusySpinner
            obj.SetTestStatusTable('off');
            obj.disableScreen();
            %Enable the BusySpinner while testing the node creation with the middleware implementation
            %place
            obj.BusySpinner.Text = message('ros:mlros2:rmwsetup:TestRMWBusySpinnerLabel',obj.Workflow.RMWImplementation).getString();
            obj.BusySpinner.show();
            drawnow;

            try
                %test middleware implementation by creating a ros2node
                rmwEnv = ros.internal.ros2.RMWEnvironment;
                rmwEnv.RMWImplementation = obj.Workflow.RMWImplementation;
                node = ros2node('/test');
                TestSuccess = true;
            catch ME
                TestSuccess = false;
                Exception = ME.message;
            end

            %Disable the BusySpinner after build complete
            obj.BusySpinner.Visible = 'off';
            obj.enableScreen();

            %Enable the Status table to show the status of Build
            obj.SetTestStatusTable('on');

            if TestSuccess
                clear node;
                obj.TestStatusTable.Steps = { message('ros:mlros2:rmwsetup:NodeCreationSuccess', obj.Workflow.RMWImplementation).getString() };
                obj.TestStatusTable.Status = { matlab.hwmgr.internal.hwsetup.StatusIcon.Pass };
                obj.NextButton.Enable = 'on';
            else
                obj.TestStatusTable.Steps = { message('ros:mlros2:rmwsetup:NodeCreationFailed',Exception).getString() };
                obj.TestStatusTable.Status = { matlab.hwmgr.internal.hwsetup.StatusIcon.Fail };
                obj.NextButton.Enable = 'off';
            end
            
        end
    end

    methods(Access = private)
        function testRMWImplementation(obj,~,~)
            %% testRMWImplementation - Callback function when user clicks the
            % Test RMW button on the screen
            ros.internal.rmwsetup.TestRMWImplementation.testButtonCallback(obj);
        end

        function SetTestStatusTable(obj,status)
            if strcmpi(status,'on')
                % Show all these widgets
                obj.TestStatusTable.Visible = 'on';
                obj.TestStatusTable.Enable = 'on';
            elseif strcmpi(status,'off')
                obj.TestStatusTable.Visible = 'off';
                obj.TestStatusTable.Enable = 'off';
            end
        end
    end
end

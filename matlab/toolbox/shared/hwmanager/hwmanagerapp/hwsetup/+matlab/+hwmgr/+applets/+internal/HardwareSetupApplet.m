classdef HardwareSetupApplet < matlab.hwmgr.internal.AppletBase
    % HARDWARESETUPAPPLET - Applet class implementation for the hardware
    % setup app. This class manages hosting a hardware setup app within
    % hardware manager as a traditionally hosted hardware manager app.
    
    % HardwareSetupApplet is a very special Hardware Manager applet. It
    % should not be used as an example for developing other Hardware
    % Manager applets
    
    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties (Constant)
        % DISPLAYNAME - The name of the applet shown to the user
        DisplayName = "Setup";
    end
    
    properties (Hidden)
        % WORKFLOW - The hardware setup workflow object being hosted in
        % hardware manager
        Workflow
    end
    
    properties (Access = private) 
        % CANCELBUTTON - Handle to the "Cancel" button
        CancelButton
        % BACKBUTTON - Handle to the "Back" button
        BackButton
        % NEXTBUTTON - Handle to the "Next" button
        NextButton
        % OVERRIDEBASECODE 
        OverrideBaseCode
    end
    
    methods
        
        function obj = HardwareSetupApplet(varargin)
            if nargin == 1
               obj.OverrideBaseCode = varargin{1};
            end
        end
        
        function constructorOptions = getConstructorOptions(obj, device)
            % Return cell array of function handles to this class's constructors with
            % optional argument input
            validateattributes(device, {'matlab.hwmgr.internal.Device'}, {});
            constructorOptions = {};
            className = class(obj);
            
            if isempty(device.BaseCode)
                 constructorOptions = str2func(className);
                 return;
            end
            
            for i = 1:length(device.BaseCode)
                funcStr = ['@()', className, '(''', device.BaseCode{i}, ''')'];
                constructorOptions = [constructorOptions, {str2func(funcStr)}];                
            end
        end     
                
        function init(obj, hwmgrHandles)
            % Call superclass init method to assign handles to class
            % properties
            init@matlab.hwmgr.internal.AppletBase(obj, hwmgrHandles)
        end
        
        function construct(obj)
            % Construct the hardware setup workflow object
            workflowClass = obj.getWorkflow(obj.DeviceInfo);
            
            % Set the units of the root panel to pixels for positioning
            % compatibility with hardware setup (which is in pixel units)
            obj.RootWindow.Units = 'pixels';
            
            % Create a panel window object
            panelWindow = matlab.hwmgr.internal.hwsetup.WindowPanelAdaptor(obj.RootWindow);
            
            % Create the hardware setup workflow object
            obj.Workflow = feval(workflowClass, 'parent', panelWindow);
            
            % Set the hardware manager figure window's size changed
            % callback to resize hardware setup
            parentFigure = obj.getMainFigure();
            parentFigure.AutoResizeChildren = "off";
            parentFigure.SizeChangedFcn = @(o,e)obj.resizeHardwareSetup();
        end
        
        function run(obj)
            % The run method will launch the hardware setup applet
            obj.preLaunchHook();
            obj.Workflow.launch();
            
            % Check if the hardware setup workflow was launched
            % successfully within hardware manager's figure, otherwise
            % close. Consider changing the close reason to "Hardware Setup
            % already open"
            if ~obj.isWorkflowOpenInHardwareManager()
                parentFigure = obj.getMainFigure();
                % Stop the resize function
                parentFigure.SizeChangedFcn = function_handle.empty;
                obj.closeApplet(matlab.hwmgr.internal.AppletClosingReason.AppError);
                return;
            end
            obj.resizeHardwareSetup();
            obj.Workflow.HardwareManagerCloseAppFcn = @()obj.closeApplet(matlab.hwmgr.internal.AppletClosingReason.AppClosing);
            obj.Workflow.HardwareManagerAppResizeFcn = @()obj.resizeHardwareSetup;
        end
        
        function destroy(obj)
            % Destroy the currently running applet
            
            % Get the main figure
            parentFigure = obj.getMainFigure();
            % Stop the resize function
            parentFigure.SizeChangedFcn = function_handle.empty;
            % Call hardware setup workflow destructor
            delete(obj.Workflow);
        end
        
        function okayToClose = canClose(obj, closeReason)
            % Default okay to close. Consider adding confirmation in the
            % future
            okayToClose = true;
        end
        
        function preLaunchHook(obj)
            % Intentionally left blank
        end
        
        function visible = isAppletTabVisible(~)
            % Hardware seutp applet does not use the App Tab
           visible = false; 
        end
        
        function tag = getTagForGalleryButton(obj, device)
            % The tag fragement for the Hardware Setup applet is
            % constructed as
            %
            %
            % HARDWARE_SETUP_<WORKFLOW_NAME>
            %
            % 
            % Why adding the workflow name to the tag is important:
            % 
            % When creating buttons in the device tab app gallery for the
            % hardware setup applet, the tag of the applet button  in the
            % gallery has to be unique. If a single device has multiple
            % hardware setup workflows, then the
            % buttons can only be differentiated via the tag. Since we have
            % access to the basecode via the overrideBaseCode property, we
            % add it to the tag to uniquefy it.
            
            workflowClass = char(obj.getWorkflow(device));
            
            classTag = upper(strrep(workflowClass, '.', '_'));
            tag = [upper(char(obj.DisplayName)) '_' classTag];
            
        end
        
        function name = getDisplayName(obj, varargin)
           % Return the hardware setup applet display name. This is of the
           % form:
           % 
           % Hardware Setup - <Workflow Name>
           
           if nargin ~= 2
               firstLine = 'Hardware';
           else
               % Get the device
               device = varargin{1};
               workflowClass = obj.getWorkflow(device);
               workflowObj = eval(workflowClass);
               firstLine = char(workflowObj.Name);
               delete(workflowObj);
           end
           
           name = sprintf([ firstLine  '\n' char(obj.DisplayName) ]);
        end
        
        function workflow = getWorkflow(obj, device)
            % Get the hardware setup workflow name
               workflow = device.getHardwareSetupWorkflow(obj.OverrideBaseCode);
        end
        
         function isOpen = isWorkflowOpenInHardwareManager(obj)
            % Helper to determine if a hardware setup workflow is already
            % open
            
            % Get the handle to the hardware setup panel hosted inside the
            % hardware manager figure
            hwSetupPanel = obj.getHardwareSetupPanel();
            isOpen = ~isempty(hwSetupPanel.Children);
         end
        
         function hwSetupPanel = getHardwareSetupPanel(obj)
             % The Hardware Setup Panel is the root panel that the app was
             % initialized with.
             hwSetupPanel = obj.RootWindow;
         end
         
         function mainFigure = getMainFigure(obj)
             % Helper to return the main fugure
             mainFigure = obj.RootWindow.Parent.Parent;
         end
         
         
         function resizeHardwareSetup(obj)
            % This is a static helper method to resize all primary hardware
            % setup panels for correct display within the hardware manager
            % root pane.
            
            % The hardware setup panels being resized are the content
            % panel, help panel and banner panel. The navigation panel is
            % hidden as the buttons are displayed in the hardware setup
            % applet toolstrip tab
            mainFigure = obj.getMainFigure();
            hwSetupPanel = obj.getHardwareSetupPanel();
            
            hwSetupClientPanel = [];
            % Select the current screen
            for i = 1:numel(hwSetupPanel.Children)
                hwSetupClientPanel = hwSetupPanel.Children(i);
                if strcmp(hwSetupClientPanel.Visible, 'on')
                    break;
                end
            end
            
            if isempty(hwSetupClientPanel)
               return; 
            end
            
            % Initialize the hardware setup client panel positions
            hwSetupClientPanel.Position = mainFigure.Position;
            
            % Set the hardware setup banner panel position
            banner = hwSetupClientPanel.Children(2);
            banner.Position = [1 mainFigure.Position(4)-banner.Position(4) mainFigure.Position(3) banner.Position(4)];
            
            % Set the hardware setup help panel position
            helpPanel = hwSetupClientPanel.Children(3);
            helpPanel.Position = [mainFigure.Position(3)-helpPanel.Position(3) 1 helpPanel.Position(3) mainFigure.Position(4)-banner.Position(4)];
            
            % Set the hardware setup navigation bar to be invisible
            navBar = hwSetupClientPanel.Children(1);
            
            % Get the cancel button handle, initialize its callback to the
            % applet close callback with the right close reason, and
            % calculate the pixel offset relative to the current nav pane
            % width
            cancelButton = navBar.Children(1);
            cancelButton.ButtonPushedFcn = @(o,e)obj.closeApplet(matlab.hwmgr.internal.AppletClosingReason.AppClosing);
            cancelButtonOffset = navBar.Position(3) - cancelButton.Position(1);
                        
            % Get the next button and get the pixel offset relative to the
            % current nav pane width
            nextButton = navBar.Children(2);
            nextButtonOffset = navBar.Position(3) - nextButton.Position(1);
            
            % Set the new nav pane width to be the same as the main figure
            % width
            navBar.Position(3) = mainFigure.Position(3);
            
            % Move the cancel and next buttons to the right, maintaining
            % the offsets relative to the initial nav pane width
            cancelButton.Position(1) = navBar.Position(3) - cancelButtonOffset;
            nextButton.Position(1) = navBar.Position(3) - nextButtonOffset;
            
            % Set the content panel position
            contentPanel = hwSetupClientPanel.Children(4);
            contentPanel.Position(2) = mainFigure.Position(4)-banner.Position(4) - contentPanel.Position(4);
        end       

    end
       
end

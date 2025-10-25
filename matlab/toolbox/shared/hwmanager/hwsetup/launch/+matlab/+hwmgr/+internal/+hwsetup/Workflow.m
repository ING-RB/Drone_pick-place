classdef Workflow < handle
    % WORKFLOW - Workflow defines a Hardware Setup App and provides a way
    % to share data between the screens.
    %
    % w = matlab.hwmgr.internal.hwsetup.Workflow() creates a
    % workflow object with a default log file. The logfile lives
    % inside the tempdir and derives its name from the "Name"
    % property of the Workflow class
    % logFile = [tempname '.txt'];
    % logger = matlab.hwmgr.internal.logger.Logger(logFile);
    % w = matlab.hwmgr.internal.hwsetup.Workflow('logger', logger);
    % creates a workflow object with a temporary log file.
    %
    %   WORKFLOW Properties
    %   Name          Name of the Hardware Setup App
    %   BaseCode      (Obsolete)Base Code of the product for which the
    %                 Hardware Setup App is defined
    %   FirstScreenID ID (fullname) of the first screen in the workflow
    %
    %   WORKFLOW Methods
    %   launch        Launch the Hardware Setup App
    
    %   Copyright 2017-2024 The MathWorks, Inc.
    
    properties(Constant)
        % BaseCode(Obsolete) - The base code of the product from the product XML file
        % specified as character array.
        % BaseCode
    end
    
    properties(SetAccess = immutable, GetAccess = private)
        % BaseCode - The base code of the product from the product XML file
        % specified as character array
        LauncherBaseCode
        
        % Flag to indicate whether parent can be deleted
        DeleteFigureOnClose
    end
    
    
    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % HWSetupLogger - The logger object that will be used to log and
        % optionally print diagnostics messages to a file and command
        % prompt respectively
        HWSetupLogger
    end
    
    properties(Access = ?matlab.hwmgr.internal.hwsetup.TemplateBase)
        % ScreenMap - ScreenMap is a containers.Map where the keys are the
        % names of the screens (id) and the value is the actual screen
        % object. When a user navigates away from a screen, the screen map
        % is updated so that the latest screen object gets saved. This data
        % structure is used to implement the load-save functionality i.e.
        % if a user navigates back to a screen he had previously interacted
        % with the widget values should be maintained i.e. not reverted
        % back to the defaults
        ScreenMap
    end
    
    properties(Access = {?matlab.hwmgr.applets.internal.HardwareSetupApplet, ...
            ?matlab.hwmgr.internal.hwsetup.TemplateBase})
        % Function handle that is invoked at the end of the next button
        % callback to resize the hardware setup widgets to fit the hardware
        % manager window
        HardwareManagerAppResizeFcn
        % Function handle that is invoked instead of the standard close
        % callback
        HardwareManagerCloseAppFcn
    end
    
    properties(Access = public)
        % Window - The HW Setup Window within which the templates/screen
        % will be rendered
        Window
        
        % CancelConfirmationDlg - Decide behavior of the Cancel button.
        % off - exit the Hardware Setup App.
        % on - present a confirmation dialog to explicitly ask users if
        % they want to exit.
        CancelConfirmationDlg
        
        % Logging - Gives the flexibility to enable 
        % or disable logging when required and also provides ability to 
        % set LogOutput
        % Enable - 
        % off - Disable logging.
        % on - Enable logging.
        % Output - {'console', 'file'}
        % Ex- should be of format struct('Enable', 'on', 'Output', {'console', 'file'})
        Logging

        % Steps- steps registered as part of the workflow
        Steps = {};

        % LaunchExamplesFcn - custom function to launch examples page
        LaunchExamplesFcn
    end
    
    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?matlab.hwmgr.applets.internal.HardwareSetupApplet})
        % CurrentScreen - Screen object that specifies the screen that is
        % being currently active/ visible
        CurrentScreen

        % ActiveStep - Index of the step within Steps property, first entry
        % is selected by default
        ActiveStep = 1;
    end
    
    properties(Abstract)
        % Name - Customer facing name for the HW Setup workflow. In case
        % multiple HW Setup workflows are available for a single base code,
        % the customer will see a selection screen and given an option to
        % select one of the two workflows. This string identifies each
        % workflow
        Name
        % FirstScreen - The full name of the class that defines the first
        % screen in the HW Setup Workflow specified as a character array
        FirstScreenID
    end
    
    methods
        function obj = Workflow(varargin)
            % Workflow - The Workflow class constructor creates a HW Setup
            %   Window for displaying the HW Setup screens and a ScreenMap to
            %   save the screens in a workflow to reload them when the user
            %   navigates back-and-forth.
            %
            % w = matlab.hwmgr.internal.hwsetup.Workflow() creates a
            % workflow object with a default log file. The logfile lives
            % inside the tempdir and derives its name from the "Name"
            % property of the Workflow class
            % logFile = [tempname '.txt'];
            % logger = matlab.hwmgr.internal.logger.Logger(logFile);
            % w = matlab.hwmgr.internal.hwsetup.Workflow('logger', logger);
            % creates a workflow object with a temporary log file.
            
            % Parse the logger input
            p = inputParser;
            loggerValidationFcn = @(x)isa(x, 'matlab.hwmgr.internal.logger.Logger');
            baseCodeValidationFcn = @(x)(ischar(x) || isstring(x));
            addParameter(p, 'logger', [], loggerValidationFcn);
            addParameter(p, 'basecode', '', baseCodeValidationFcn);
            addParameter(p, 'parent', '');
            % Ignore any other parameter inputs that the derived classes
            % might have defined
            p.KeepUnmatched = true;
            p.parse(varargin{:});
            obj.HWSetupLogger = p.Results.logger;
            obj.LauncherBaseCode = p.Results.basecode;
            overrideParent = p.Results.parent;
            % BaseCode was an Abstract, Constant property defined for the
            % Workflow class. This property was removed, however for tests
            % and internal validation to continue to work, reassigning this
            % to LauncherBaseCode property
            
            if isempty(obj.LauncherBaseCode) && isprop(obj, 'BaseCode')
                obj.LauncherBaseCode = obj.BaseCode; %#ok<MCNPN>
            end
            if isempty(overrideParent)
                obj.Window = matlab.hwmgr.internal.hwsetup.Window.getInstance();
                obj.DeleteFigureOnClose = true;
            else
                obj.Window = overrideParent;
                obj.DeleteFigureOnClose = false;
            end
            obj.Window.Visible = 'off';
            % Initialize the ScreenMap property.
            obj.ScreenMap = containers.Map();
            
            % Listen for the workflow to be deleted and perform a cleanup
            addlistener(obj, 'ObjectBeingDestroyed', @obj.handleWfDelete);
            
            % defaults for optional properties
            obj.CancelConfirmationDlg = 'off';  
           
            % enable logging by default, and enable output to file only
            % console is disabled by default
            obj.Logging = struct('Enable', matlab.lang.OnOffSwitchState.on, 'Output', {'file'});
        end
        
        function handleWfDelete(obj, ~, ~)
            %HANDLEWINDOWDELETE - window delete callback that allows the
            %Workflow to be aware of when the user has closed the Window
            %Peer so that the Workflow can be cleaned up.
            
            obj.delete();
        end
        
        function delete(obj)
            % delete() - Discard the HW Setup Workflow.
            %      The class destructor deletes the current screen, logger
            %      object as well as all the screens saved on the screen
            %      map. Lastly, it also deletes the HW Setup window.
            
            obj.logMessage(['Exiting workflow -- ' obj.Name]);
            % Delete the current screen object
            if ~isempty(obj.CurrentScreen)
                obj.CurrentScreen.delete();
            end
            % Delete Logger
            if  ~isempty(obj.HWSetupLogger)
                obj.HWSetupLogger.delete();
            end
            % Delete the screens saved onto the Map
            screenObjs = values(obj.ScreenMap);
            for i = 1:numel(screenObjs)
                screenObjs{i}.delete();
            end
            % Delete window
            if obj.DeleteFigureOnClose
                if obj.Window.isvalid()
                    obj.Window.delete();
                end
            end
            % Remove workflow
            manageWorkflowForOpenApp(obj, 'remove');
        end
        
        function set.Logging(obj,value)
            % Set the value of the Logging Property.
            
            validateattributes(value, {'matlab.lang.OnOffSwitchState', 'struct'},...
                               {'nonempty'});
            requiredFields = {'Enable', 'Output'};
            assert(~isstruct(value) || all(isfield(value, requiredFields)), ...
                'The struct must contain the Enable and Output fields.');

            obj.Logging = value;
        end
        
        function launch(obj)
            % launch() - Launch the HW Setup workflow
            %       The launch method creates the first screen in the HW
            %       Setup workflow specified by the FirstScreenID property
            %       and displays the screen. The method also creates a
            %       log file inside tempdir for diagnostics and debugging
            %       purposes
            
            % Get the workflow class if an App for it is already open.
            storedWorkflowObj = manageWorkflowForOpenApp(obj, 'get');
            if ~isempty(storedWorkflowObj) && storedWorkflowObj.Window.isvalid()
                storedWorkflowObj.Window.bringToFront();
                return;
            end
            if ~isvalid(obj)
                manageWorkflowForOpenApp(obj, 'remove');
                error(message('hwsetup:workflow:InvalidObject', metaclass(obj).Name));
            end
            try
                obj.configureLogger();
                obj.logMessage(['Launching HW Setup: ' obj.Name ' for base code ' obj.LauncherBaseCode]);
                obj.logMessage(['Initializing screen -- ' ...
                    obj.Name ':' obj.FirstScreenID]);
                firstScreenObj = feval(obj.FirstScreenID, obj);
                firstScreenObj.show();
            catch ex
                manageWorkflowForOpenApp(obj, 'remove');
                if obj.Window.isvalid
                    obj.Window.delete();
                end
                error(message('hwsetup:workflow:ErrorInWorkflowLaunch', obj.Name,...
                    obj.LauncherBaseCode, ex.getReport('extended'))) ;
            end
        end
        
        function set.CancelConfirmationDlg(obj, value)
            validatestring(value, {'on', 'off'});
            obj.CancelConfirmationDlg = value;
        end
    end
    
    methods(Access = private)
        function logMessage(obj, str)
            validateattributes(str, {'char', 'string'},...
                {'nonempty'});

            % Check if Logging is a struct or a simple on/off switch
            if isstruct(obj.Logging)
                loggingEnabled = strcmp(obj.Logging.Enable, 'on');
            else
                loggingEnabled = strcmp(obj.Logging, 'on');
            end

            if loggingEnabled && ~isempty(obj.HWSetupLogger)
                obj.HWSetupLogger.log(str);
            end
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester,...
            ?hwsetup.testtool.TesterBase})
        
        function out = getBaseCode(obj)
            % getBaseCode - Returns the base code
            out = obj.LauncherBaseCode;
        end
        
        function out = getCurrentScreen(obj)
            % getCurrentScreen - Returns the screen object for the current
            % active screen
            out = obj.CurrentScreen;
        end
        
        function out = getLogFile(obj)
            out = obj.HWSetupLogger.FilePath;
        end

        function out = getActiveStep(obj)
            out = obj.ActiveStep;
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Workflow,...
            ?hwsetup.testtool.TesterBase})
        function setWindowTitle(obj, title)
            validateattributes(title, {'char', 'string'},...
                {'nonempty'});
            obj.Window.Title = title;
        end
        
        function windowTitle = getWindowTitle(obj)
            windowTitle = obj.Window.Title;
        end
        
        function configureLogger(obj)
            % configureLogger - Creates a default logger with log file name
            % that corresponds to the HW Setup Name + HW Setup BaseCode
            % inside tempdir
            
            % LogFile will be created in a user specific folder
            % Unix: /home/<username>
            % Windows: Temporary directory as defined by the TMP or TEMP
            % environment variable
            if ~isa(obj.HWSetupLogger, 'matlab.hwmgr.internal.logger.Logger')
                if isunix
                    logFileDir = deblank(evalc('!echo $HOME'));
                else
                    logFileDir = tempdir;
                end
                logFileName = fullfile(logFileDir, ...
                    [matlab.hwmgr.internal.hwsetup.getNameTag(obj.Name), '.txt']);

                % Create a Logger object if the Logging Property is enabled           
                if isstruct(obj.Logging)
                    loggingEnabled = strcmp(obj.Logging.Enable, 'on');
                    consoleLogging = ismember('console', obj.Logging.Output);
                    fileLogging = ismember('file', obj.Logging.Output);
                else
                    loggingEnabled = strcmp(obj.Logging, 'on');
                     consoleLogging = false; % Default to false 
                     fileLogging = true;     % Default to true
                end

                if loggingEnabled
                    try
                        obj.HWSetupLogger = matlab.hwmgr.internal.logger.Logger(logFileName);
                        obj.HWSetupLogger.ConsoleEnable = consoleLogging;
                        obj.HWSetupLogger.FileEnable = fileLogging;
                    catch
                        % if there is an error in creating the Logger instance
                        % catch the exception and ignore the errors
                    end
                end
            end
        end
    end
end

function out = manageWorkflowForOpenApp(workflowObj, cmd)
% When cmd = 'get', manageWorkflowForOpenApp returns the instance
% of the workflow class already in use if the app is open. If not, it returns empty.
% When cmd = 'remove', manageWorkflowForOpenApp clears the stored object.
%
% invokeWorkflows is a container Map that stores the name of
% the workflow object and its instance that is currently in use
% as a key value pair.

out = [];
validatestring(cmd, {'get', 'remove'});
persistent invokedWorkflows;
mobject = metaclass(workflowObj);
className = mobject.Name;
switch(cmd)
    case 'get'
        if isempty(invokedWorkflows)
            % Initialize the invokedWorkflows variable
            invokedWorkflows = containers.Map;
        else
            % If the workflow is already invoked then return true with
            % the instance of the workflow class that is already in use
            if any(ismember(invokedWorkflows.keys, className))
                storedWorkflowObj = invokedWorkflows(className);
                % If the stored workflow object is valid and the App Window is open
                % then return the stored object
                if isvalid(storedWorkflowObj)
                    out = storedWorkflowObj;
                    return;
                end
            end
        end
        invokedWorkflows(className) = workflowObj;
    case 'remove'
        if ~isempty(invokedWorkflows) && isKey(invokedWorkflows, className)
            remove(invokedWorkflows, className);
        end
end
end

% LocalWords:  logfile fullname TMP HANDLEWINDOWDELETE basecode

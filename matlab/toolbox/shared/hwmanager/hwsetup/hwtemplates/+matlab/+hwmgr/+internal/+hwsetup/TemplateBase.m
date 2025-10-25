classdef(Abstract) TemplateBase < handle
    % TEMPLATEBASE defines the common widgets and methods required for
    % rendering and interacting with the HW Setup screens
    %
    %   TEMPLATEBASE Properties
    %   ContentPanel    Contains template/screen-specific widgets
    %   ContentGrid     Contains template/screen-specific widgets arranged
    %                   using a grid inside ContentPanel
    %   HelpText        Contains the Help Text to aid the user
    %   BackButton      Back Button widget to navigate to previous screen
    %   NextButton      Next Button widget to navigate to Next screen
    %   CancelButton    Cancel Button widget t exit out of the workflow
    %   Title           Title for the screen specified as a Label widget
    %   Workflow        Workflow object that contains data that need to be
    %                   maintained across the workflow
    %
    %   TEMPLATEBASE Methods
    %   show                Display the template/screen
    %   logMessage          log diagnostic messages to a file
    %   getNextScreenID     Return the Next Screen ID (name of the class)
    %   getPreviousScreenID Return the Previous Screen ID (name of the class)

    % Copyright 2023-2024 The MathWorks, Inc.

    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase, ...
            ?matlab.hwmgr.internal.hwsetup.util.TemplateLayoutManager,...
            ?hwsetuptest.util.TemplateBaseTester,...
            ?hwsetup.testtool.TesterBase})
        % HelpText - The panel that contains information for the customers
        % to successfully interact with the screen
        HelpText
        % Banner - UI Banner
        Banner
        % NavigationGrid - The grid which contains buttons to navigate
        % back and forth and cancel out of the HW Setup workflow
        NavigationGrid
        %ParentGrid- The outermost grid that includes the Content,
        %Navigation, Help and Banner sections.
        ParentGrid
        % ContentPanel - HW Setup Panel widget that contains the template
        % specific widgets. These widgets are defined by the individual
        % Template classes. The properties for these widgets should be
        % specified in the initializeScreen() method
        ContentPanel
        % ContentGrid - HW Setup Panel widget that contains the template
        % specific widgets. These widgets are defined by the individual
        % Template classes. The properties for these widgets should be
        % specified in the initializeScreen() method
        ContentGrid
        % BackButton - HW Setup Button widget that on clicking navigates the user
        % to the previous screen.
        BackButton
        % NextButton - HW Setup Button widget that on clicking navigates the user
        % to the next screen.
        NextButton
        % CancelButton - HW Setup Button widget that on clicking exits out of the
        % HW Setup workflow
        CancelButton
        % Workflow - Class of type matlab.hwmr.internal.hwsetup.Workflow
        % that stores data required to be maintained across the life-time
        % of the HW Setup workflow
        Workflow
        % Title - HW Setup Label widget that defines the title of the
        % screen
        Title
    end

    properties (Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?hwsetuptest.util.TemplateBaseTester})
        % TemplateLayout enum that specifies which layout type is used to
        % arrange widgets inside ContentPanel
        TemplateLayout
    end

    properties (Access = ?hwsetuptest.util.TemplateBaseTester)
        % WorkflowSteps - Area in the banner that displays the steps in the
        % workflow. To control the display, refer to Steps property of
        % Workflow class.
        WorkflowSteps
    end

    methods
        function obj = TemplateBase(varargin)
            % TEMPLATEBASE constructor
            narginchk(1, 2);
            validateattributes(varargin{1}, {'matlab.hwmgr.internal.hwsetup.Workflow'}, {'nonempty'});

            % Set the Workflow property
            obj.Workflow = varargin{1};
            if nargin == 1
                obj.TemplateLayout = matlab.hwmgr.internal.hwsetup.TemplateLayout.MANUAL;
            else
                obj.TemplateLayout = varargin{2};
            end

            % Get all the widgets that need to be created as a part of the
            % Base Template
            widgetList = matlab.hwmgr.internal.hwsetup.TemplateBase.getAllTemplateWidgetLayoutDetails();
            % Get the specifications i.e Position, Color etc. for each of the widgets
            widgetPropertyMap = matlab.hwmgr.internal.hwsetup.util.TemplateLayoutManager.getAllTemplateWidgetLayoutDetails();
            for i = 1:numel(widgetList)
                % Create the widgets and parent them
                if strcmpi(widgetList(i).Parent, 'DEFAULT')
                    parent = obj.Workflow.Window;
                else
                    parent = obj.(widgetList(i).Parent);
                end
                obj.(widgetList(i).Name) = matlab.hwmgr.internal.hwsetup.util.TemplateLayoutManager.addWidget(...
                    widgetList(i).Type, parent);

                % Assert if the widget property defaults are not predefined
                if ~widgetPropertyMap.isKey(widgetList(i).Name)
                    assert(['Widget properties for ' widgetList(i).Name ...
                        ' not defined in matlab.hwmgr.internal.hwsetup.util.TemplateLayoutManager.getAllTemplateWidgetLayoutDetails']);
                end

                % Set widget properties
                matlab.hwmgr.internal.hwsetup.util.TemplateLayoutManager.setWidgetProperties(...
                    widgetPropertyMap(widgetList(i).Name), obj.(widgetList(i).Name));
            end

            % Add callbacks to the Back, Next and Cancel Buttons
            obj.BackButton.ButtonPushedFcn = {@matlab.hwmgr.internal.hwsetup.TemplateBase.backButtonCallback, obj};
            obj.NextButton.ButtonPushedFcn = {@matlab.hwmgr.internal.hwsetup.TemplateBase.nextButtonCallback, obj};
            % If the screen is the Last one in the workflow, set the "Next"
            % Button text to "Finish" and update the callback for the
            % Button
            if obj.isScreenLast
                obj.NextButton.Text = message('hwsetup:template:FinishButtonText').getString;
                obj.NextButton.ButtonPushedFcn = {@matlab.hwmgr.internal.hwsetup.TemplateBase.finish, obj};
            end
            obj.CancelButton.ButtonPushedFcn = {@matlab.hwmgr.internal.hwsetup.TemplateBase.finish, obj};
            % Set the Current screen property on the Workflow object
            obj.Workflow.CurrentScreen = obj;
            % hide ContentPanel to prevent users from seeing initial
            % properties before the updated values are rendered
            obj.ContentPanel.Visible = 'off';

            if obj.TemplateLayout == matlab.hwmgr.internal.hwsetup.TemplateLayout.GRID
                % enable grid layout if set for screen or template
                obj.ContentGrid.Visible = 'on';
            end

            % if no steps are registered, hide the widget and center align
            % the title
            if isempty(obj.Workflow.Steps)
                obj.WorkflowSteps.Visible = 'off';
                obj.Banner.RowHeight = {'1x', 'fit', '1x'};
            else
                obj.setActiveStep(obj.Workflow.ActiveStep);
            end
        end

        function show(obj)
            %SHOW - Display the HW Setup Screen
            %   show(obj) displays the HW Setup window and the widgets
            %   contained within it.

            obj.logMessage(['Displaying -- ' obj.Workflow.Name ':' class(obj)])
            % If screen is the First one in workflow, set the "Back" button
            % visibility to off
            if obj.isScreenFirst
                % Set the Tag for the Window
                obj.Workflow.Window.Tag = matlab.hwmgr.internal.hwsetup.getNameTag(...
                    [obj.Workflow.Name '_HWSetupWindow']);
                % Set visibility of Back button to off
                obj.BackButton.Visible = 'off';
            end

            % TODO: Remove these updates to Banner once downstream teams
            % transition to use infrastructure to register steps.
            if numel(obj.Banner.Children) == 3
                obj.Banner.Children{3}.Row = 1;
                obj.Banner.RowHeight = {'fit', '1x'};
            end

            % Display the Window
            obj.Workflow.Window.show();
            % Set widget tags
            matlab.hwmgr.internal.hwsetup.TemplateBase.setWidgetTags(obj);
            % Display the widgets
            obj.showAllWidgets();

            % the current visible screen, if different, needs to be hidden
            % before displaying the screen that called show
            if ~isequal(class(obj), class(obj.Workflow.CurrentScreen))
                obj.Workflow.CurrentScreen.ParentGrid.Visible = 'off';
            end

            obj.ParentGrid.Visible = 'on';
        end

        function delete(obj)
            % DELETE - Deletes the widget properties
            obj.deleteAllWidgets();
        end
    end

    methods(Access = protected)
        function disableScreen(obj, widgetsToEnable)
            % DISABLESCREEN - Disables all widgets on the screen

            if ~exist('widgetsToEnable', 'var')
                widgetsToEnable = {};
            end

            if ~iscellstr(widgetsToEnable)
                error(message('hwsetup:widget:InvalidDataType', 'Input to customDisableScreen method',...
                    'cell array of character vectors'))
            end

            widgetNames = matlab.hwmgr.internal.hwsetup.TemplateBase.getWidgetPropertyNames(obj);

            for i = 1:numel(widgetNames)
                widget = obj.(widgetNames{i});

                if(isa(widget, 'matlab.hwmgr.internal.hwsetup.mixin.EnableWidget') && ...
                        isprop(widget, 'Enable')) && ~ismember(widgetNames{i}, widgetsToEnable)
                    widget.Enable = 'off';

                end
            end

            drawnow;
        end

        function enableScreen(obj)
            % ENABLESCREEN - Enables all widgets on the screen

            obj.ParentGrid.enable();
            widgetNames = matlab.hwmgr.internal.hwsetup.TemplateBase.getWidgetPropertyNames(obj);
            for i = 1:numel(widgetNames)
                widget = obj.(widgetNames{i});
                if(isa(widget, 'matlab.hwmgr.internal.hwsetup.mixin.EnableWidget') && ...
                        isprop(widget, 'Enable'))
                    widget.Enable = 'on';
                end
            end
            drawnow;
        end

        function logMessage(screen, str)
            % LOGMESSAGE - logs message specified by STR in the logfile

            validateattributes(str, {'char', 'string'},...
                {'nonempty'});

            if ~isempty(screen.Workflow.HWSetupLogger)
                screen.Workflow.HWSetupLogger.log(str);
            end
        end

         function setActiveStep(obj, index)
            % setActiveStep Highlights the given step in the workflow.
            %
            % This function highlights the step in the workflow at the index
            % specified by the input.

            validateattributes(index, {'double'}, {'>', 0, '<=' numel(obj.Workflow.Steps)});

            steps = obj.Workflow.Steps;
            obj.Workflow.ActiveStep = index;

            % format text for display
            steps{index} = ['<font color="white"><b>', steps{index}, '</b></font>'];
            obj.WorkflowSteps.Text = sprintf('<font color="#9A9A9A">%s</font>',...
                strjoin(steps, ' > '));
        end

        function showErrorDlg(obj, title, msg)
            % showErrorDlg Displays an embedded alert dialog with a given 
            % title and message. This method delegates the creation of the 
            % dialog to the Window object.

            obj.Workflow.Window.showErrorDlg(title, msg);
        end

        function choice = showConfirmDlg(obj, title, msg, options)
            % showConfirmDlg Displays an embedded confirmation dialog with 
            % specified options.
            % This method delegates the creation of the dialog to the Window 
            % object.

            choice = obj.Workflow.Window.showConfirmDlg(title, msg, options);
        end
    end

    methods(Access = private)
        function hide(obj)
            obj.ParentGrid.Visible = 'off';
        end

        function showAllWidgets(obj)
            % SHOWALLWIDGETS - iterates through the specified widgets and
            % calls the "show" method on each one to display the widgets

            % Get all the widgets
            allWidgets = matlab.hwmgr.internal.hwsetup.TemplateBase.getWidgetPropertyNames(obj);
            for i = 1:numel(allWidgets)
                if isvalid(obj.(allWidgets{i})) && isequal(obj.(allWidgets{i}).Visible, 'on')
                    obj.(allWidgets{i}).show();
                end
            end
            obj.ContentPanel.Visible = 'on';
        end

        function deleteAllWidgets(obj)
            % DELETEALLWIDGETS - Method that deletes the top-level container -
            % parentPanel that will trigger the deletion of all contained
            % widgets
            if ~isempty(obj.ParentGrid)
                obj.ParentGrid.delete();
            end
        end
    end

    % Methods to be over-ridden in the screen class
    methods

        function reinit(obj) %#ok<MANU>
            % REINIT - Method to set the widget state when a screen is
            %   redisplayed. The screen object will be saved in a map that
            %   lives withing the Workflow class. If a screen is being
            %   redisplayed, the screen object is retrieved from this map.
            %   Additional widget settings can be done using this method
            %

        end

        function screenid = getNextScreenID(obj) %#ok<MANU>
            % GETNEXTSCREENID - Get the screen ID for the next screen in
            % workflow
            %   screenid = getNextScreenID(obj) is a method used to define
            %   the screenid i.e. name of the screen class that comes next
            %   in the workflow. If this is the last screen in the workflow
            %   then the screen class should not override this method
            screenid = [];
        end

        function screenid = getPreviousScreenID(obj) %#ok<MANU>
            % GETPREVIOUSSCREENID - Get the screen ID for the next screen
            % in workflow
            %   screenid = getPreviousScreenID(obj) is a method used to define
            %   the screenid i.e. name of the screen class that comes
            %   before the current screen in the workflow. If this is the
            %   first screen in the workflow then the screen class should
            %   not override this method
            screenid = [];
        end
    end

    % Methods used to determine the Screen sequence, navigation etc.
    methods(Access = {?hwsetuptest.util.TemplateBaseTester, ?matlab.hwmgr.applets.internal.HardwareSetupApplet})

        function out = isScreenFirst(obj)
            % ISSCREENFIRST - Method that determines if a screen is
            % First in the workflow based on if getPreviousScreenID is
            % overridden in the screen class

            out = false;
            mc = metaclass(obj);
            % Get the names for all the methods of the class
            allMethods = {mc.MethodList.Name};
            % Array of if the method was implemented in the base class (TemplateBase)
            % or in the derived class
            definingClasses = {mc.MethodList.DefiningClass};
            idx = ismember(allMethods, 'getPreviousScreenID');
            % If the getPreviousScreenID method is not defined in any of
            % TemplateBase subclasses, this is the first screen.
            if isequal(definingClasses{idx}.Name, 'matlab.hwmgr.internal.hwsetup.TemplateBase')
                out = true;
            end
        end

        function out = isScreenLast(obj)
            % ISSCREENLast - Method that determines if a screen is
            % Last in the workflow based on if getNextScreenID is
            % overridden in the screen class

            out = false;
            mc = metaclass(obj);
            % Get the names for all the methods of the class
            allMethods = {mc.MethodList.Name};
            % Array of if the method was implemented in the base class (TemplateBase)
            % or in the derived class
            definingClasses = {mc.MethodList.DefiningClass};
            idx = ismember(allMethods, 'getNextScreenID');
            % If the getNextScreenID method is not defined in any of
            % TemplateBase subclasses, this is the last screen.
            if isequal(definingClasses{idx}.Name, 'matlab.hwmgr.internal.hwsetup.TemplateBase')
                out = true;
            end
        end

        function out = getNextScreenObj(obj)
            % getNextScreenObj - Method for tests to get the object for the
            % next screen. This method invokes the getNextScreenID method
            % to find the next screen id and creates the screen object for
            % it. The method also saves the current screen object onto the
            % ScreenMap property. If there is not next screen then this
            % method returns []

            out = obj.getScreenObj('next');
        end

        function out = getPreviousScreenObj(obj)
            % getPreviousScreenObj - Method for tests to get the object for the
            % previous screen. This method invokes the getPreviousScreenID method
            % to find the next screen id and creates the screen object for
            % it. The method also saves the current screen object onto the
            % ScreenMap property. If there is not next screen then this
            % method returns []

            out = obj.getScreenObj('previous');
        end
    end

    methods(Access = private)
        function out = getScreenObj(obj, opts)
            validateattributes(obj, {'matlab.hwmgr.internal.hwsetup.TemplateBase'},...
                {'nonempty'});
            opts = validatestring(opts, {'next', 'previous'});

            out = [];

            % Store the context for the existing screen
            obj.Workflow.ScreenMap(class(obj)) = obj;

            switch lower(opts)
                case 'next'
                    screen = obj.getNextScreenID();
                case 'previous'
                    screen = obj.getPreviousScreenID();
            end

            if isempty(screen)
                return
            end

            % Code to save the context of the current screen
            try

                if isKey(obj.Workflow.ScreenMap, screen)
                    % If the screen is available in the map, retrieve the
                    % screen object
                    obj.logMessage(['Loading screen from memory -- ' ...
                        obj.Workflow.Name ':' screen]);
                    out = obj.Workflow.ScreenMap(screen);
                    % call the reinit method to update the settings
                    out.reinit();
                else
                    % Construct the object
                    obj.logMessage(['Initializing screen -- ' ...
                        obj.Workflow.Name ':' screen]);
                    out = feval(screen, obj.Workflow);
                end

                out.Workflow.CurrentScreen = out;
            catch ex
                obj.logMessage(['Error in creating/displaying screen -- ' ...
                    obj.Workflow.Name ':' screen newline 'Details:' ex.message]);
                error(message('hwsetup:template:ScreenLoadError', screen, ex.message));
            end
        end
    end

    methods(Static)

        function nextButtonCallback(src, evt, currentScreen)
            % nextButtonCallback - Callback Handler for the Next Button
            % widget. The activities performed during the "Next" Button
            % Callback
            % 1. Get the ID for the Next Screen
            % 2. Create the screen object for the next screen
            % 3. Save the context of the current screen
            % 4. Delete the current screen
            % 5. Display the next screen

            nextScreenObj = currentScreen.getNextScreenObj();

            if isempty(nextScreenObj)
                return
            end

            try
                % Display Next Screen
                nextScreenObj.show();
                currentScreen.hide();

                % If hardware setup is running inside hardware manager,
                % then resize
                if ~isempty(currentScreen.Workflow.HardwareManagerAppResizeFcn)
                    currentScreen.Workflow.HardwareManagerAppResizeFcn();
                end
            catch ex
                currentScreen.logMessage(['Error navigating to the next screen -- ' ...
                    currentScreen.Workflow.Name ':' class(nextScreenObj) newline 'Details:' ex.message]);
                error(message('hwsetup:template:NavigationFailureNext', ex.message));
            end
        end

        function backButtonCallback(~, ~, currentScreen)
            % backButtonCallback - Callback Handler for the Back Button
            % widget.The activities performed during the "Back" Button
            % Callback
            % 1. Get the ID for the Previous Screen
            % 2. Create the screen object for the previous screen
            % 3. Save the context of the current screen
            % 4. Delete the current screen
            % 5. Display the previous screen

            backScreenObj = currentScreen.getPreviousScreenObj();
            try
                currentScreen.hide();
                backScreenObj.show();
                % If hardware setup is running inside hardware manager,
                % then resize
                if ~isempty(currentScreen.Workflow.HardwareManagerAppResizeFcn)
                    currentScreen.Workflow.HardwareManagerAppResizeFcn();
                end
            catch ex
                currentScreen.logMessage(['Error navigating to the previous screen -- ' ...
                    currentScreen.Workflow.Name ':' class(backScreenObj) newline 'Details:' ex.message]);
                error(message('hwsetup:template:NavigationFailureBack', ex.message));
            end
        end

        function finish(src, ~, screen)
            % finish() will be called on Finish or Cancel button clicks

            finishText = message('hwsetup:template:CancelButtonDlgExitText').getString();
            cancelText = message('hwsetup:template:CancelButtonText').getString();

            choice = finishText; % default

            if ~isempty(src) && isequal(screen.Workflow.CancelConfirmationDlg, 'on')
                if  isprop(src, 'Text') && isequal(src.Text, cancelText)
                    options = {message('hwsetup:template:CancelButtonDlgExitText').getString(),... option 1
                               message('hwsetup:template:CancelButtonDlgBackText').getString()... option 2
                              };

                    choice = screen.showConfirmDlg(message('hwsetup:template:CancelButtonDlgTitle').getString(),...
                        message('hwsetup:template:CancelButtonDlgText').getString(), options);
                end
            end

            if isequal(choice, finishText)
                % if hardware setup is running inside hardware manager
                if ~isempty(screen.Workflow.HardwareManagerCloseAppFcn)
                    screen.Workflow.HardwareManagerCloseAppFcn();
                else
                    screen.Workflow.delete();
                end
            end
        end

        function setWidgetTags(screen)
            % SETWIDGETTAGS - Sets the Tag property for the all properties
            % of the screen object that are of type

            validateattributes(screen, {'matlab.hwmgr.internal.hwsetup.TemplateBase'}, {'nonempty'});

            % Get all the widgets
            widgetNames = matlab.hwmgr.internal.hwsetup.TemplateBase.getWidgetPropertyNames(screen);
            for i = 1:numel(widgetNames)
                tag = screen.(widgetNames{i}).Tag;
                if isempty(tag) || contains(tag, 'ContentPanel')
                    screen.(widgetNames{i}).Tag = matlab.hwmgr.internal.hwsetup.getNameTag([class(screen), '_', widgetNames{i}]);
                end
            end
            screen.Workflow.Window.Tag =  matlab.hwmgr.internal.hwsetup.getNameTag([class(screen), '_Window' ]);
        end

        function widgetNames = getWidgetPropertyNames(screen)
            % GETWIDGETPROPERTYNAMES - Returns the names of properties for
            % a given object that are of type
            % matlab.hwmgr.internal.hwsetup.Widget or
            % matlab.hwmgr.internal.hwsetup.DerivedWidget
            % The widget properties must be valid i.e. not a handle to a
            % deleted object

            validateattributes(screen, {'matlab.hwmgr.internal.hwsetup.TemplateBase'}, {'nonempty'});
            
            % Find all properties
            mco = metaclass(screen);
            propNames = {mco.PropertyList.Name};
            % Find superclasses for the properties
            propSuperClasses = {};
            filterIdx = zeros(1, numel(propNames));
            for i = 1:numel(propNames)
                try
                    % If widget-property has a method isvalid, check if
                    % widget is valid. Widget properties might be deleted
                    % by screen methods.
                    if ismethod(screen.(propNames{i}), 'isvalid')
                        filterIdx(i) = ~screen.(propNames{i}).isvalid;
                    end
                    propSuperClasses{i} = superclasses(screen.(propNames{i})); %#ok<*AGROW>
                catch
                    % Error for properties that do not have access to
                    % TemplateBase class
                    propSuperClasses{i} = {};
                end
            end
            propNames = propNames(~filterIdx);
            propSuperClasses = propSuperClasses(~filterIdx);
            % If the superclass list contains
            % matlab.hwmgr.internal.hwsetup.Widget, property is a widget
            isPropWidgetIdx = cellfun(@(x)any(ismember(x,...
                {'matlab.hwmgr.internal.hwsetup.Widget', 'matlab.hwmgr.internal.hwsetup.DerivedWidget'})),...
                propSuperClasses);
            widgetNames = propNames(isPropWidgetIdx);

        end

        function widgetList = getAllTemplateWidgetLayoutDetails()
            % GETALLTEMPLATEWIDGETLAYOUTDETAILS - Get the type, name and
            % parent for the widget that are rendered in the Base Template

            panelType = 'matlab.hwmgr.internal.hwsetup.Panel';
            gridType = 'matlab.hwmgr.internal.hwsetup.Grid';
            buttonType = 'matlab.hwmgr.internal.hwsetup.Button';
            labelType = 'matlab.hwmgr.internal.hwsetup.Label';
            htmlTextType = 'matlab.hwmgr.internal.hwsetup.HTMLText';
            helpTextType = 'matlab.hwmgr.internal.hwsetup.HelpText';

            w = 1;

            widgetList(w).Name = 'ParentGrid';
            widgetList(w).Type = gridType;
            widgetList(w).Parent = 'DEFAULT';
            w = w + 1;

            widgetList(w).Name = 'Banner';
            widgetList(w).Type = gridType;
            widgetList(w).Parent = 'ParentGrid';
            w = w + 1;

            widgetList(w).Name = 'WorkflowSteps';
            widgetList(w).Type = htmlTextType;
            widgetList(w).Parent = 'Banner';
            w = w + 1;

            widgetList(w).Name = 'Title';
            widgetList(w).Type = labelType;
            widgetList(w).Parent = 'Banner';
            w = w + 1;

            widgetList(w).Name = 'ContentPanel';
            widgetList(w).Type = panelType;
            widgetList(w).Parent = 'ParentGrid';
            w = w + 1;

            widgetList(w).Name = 'ContentGrid';
            widgetList(w).Type = gridType;
            widgetList(w).Parent = 'ContentPanel';
            w = w + 1;

            widgetList(w).Name = 'HelpText';
            widgetList(w).Type = helpTextType;
            widgetList(w).Parent = 'ParentGrid';
            w = w +1 ;

            widgetList(w).Name = 'NavigationGrid';
            widgetList(w).Type = gridType;
            widgetList(w).Parent = 'ParentGrid';
            w = w + 1;

            widgetList(w).Name = 'BackButton';
            widgetList(w).Type = buttonType;
            widgetList(w).Parent = 'NavigationGrid';
            w = w + 1;

            widgetList(w).Name = 'CancelButton';
            widgetList(w).Type = buttonType;
            widgetList(w).Parent = 'NavigationGrid';
            w = w + 1;

            widgetList(w).Name = 'NextButton';
            widgetList(w).Type = buttonType;
            widgetList(w).Parent = 'NavigationGrid';
        end
    end

    % Methods to enable testing of screens and templates
    methods(Access = {?hwsetuptest.util.TemplateBaseTester,...
            ?hwsetup.testtool.TesterBase})
        function out = getWidgetTypeAndTag(obj)
            allWidgetNames = matlab.hwmgr.internal.hwsetup.TemplateBase.getWidgetPropertyNames(obj);
            out = containers.Map();
            for i = 1:numel(allWidgetNames)
                widgetTag = obj.(allWidgetNames{i}).Tag;
                if ~isempty(widgetTag)
                    [~, ~, widgetType] = fileparts(class(obj.(allWidgetNames{i})));
                    widgetType = regexprep(widgetType, '\.','');
                    out(widgetTag) = widgetType;
                end
            end
            out(obj.Workflow.Window.Tag) = 'Window';
        end
    end
end
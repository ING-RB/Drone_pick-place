classdef SLBookDialog < handle
    %SLBookDialog Dialog used by slbook to display print options and generate details report
    % This class defines a schema and callbacks used in the Simulink 'Print
    % Details' dialog. Dialog layout is defined in the 'getDialogSchema'
    % method and supporting methods.
    
    %   Copyright 2021-2024 The MathWorks, Inc.

    properties (SetAccess = private)
        % System Current system to be reported
        %  Name of the model, subsystem, or Stateflow chart to be reported,
        %  specified as a string. This property is set by the
        %  setCurrentSystem and setCurrentChart methods.
        System = '';
        
        % ChartId ID of the Stateflow chart to be reported
        %  If System specifies a Stateflow chart, this property holds the
        %  ID of the chart. Otherwise, this property is -1. This property
        %  is set by the setCurrentChart method.
        ChartId = -1;
        
        % Position Pixel coordinates of the top left corner of the dialog
        %  Location of the top left corner of the dialog, specified as a
        %  vector [x, y].
        Position = [];
    end
    
    properties (Access = public)
        % DirectoryOption Option to specify directory in which to save the report
        %  This property is set by a combo box on the print dialog.
        %  Acceptable values are:
        %       0 - Save to current directory (pwd)
        %       1 - Save to temporary directory (tempdir)
        %       2 - Save to other directory specified by DirectoryPath
        DirectoryOption (1,1) double = 1;
        
        % DirectoryPath Path to directory in which to save the report
        %  This property is set by an edit field on the print dialog box or
        %  by a file system browse opened via a button on the dialog. This
        %  property is used only if the DirectoryOption is set to 2 (Other
        %  directory)
        DirectoryPath char;
        
        % IncrementFilename Whether to increment the report file name
        %  If true, the report file name is incremented to prevent
        %  overwriting of an existing report of the same name. This
        %  property is set by a checkbox in the print dialog.
        IncrementFilename (1, 1) logical = false;
        
        % SystemScope Option specifying scope of reported systems
        %  The scope determines the systems on which to report relative to
        %  the current system, e.g., the current system and above, the
        %  current system and below, etc. This property is set by a radio
        %  button group in the print dialog.
        %
        %  Acceptable values are:
        %       0 - (Current) Report only the current system
        %       1 - (Current and above) Report the current system and its
        %           ancestors. This option is not available for Stateflow
        %           charts.
        %       2 - (Current and below) Report the current system and its
        %           decsendants
        %       3 - (Entire model) Report the entire model in which the
        %           system resides
        SystemScope (1,1) double = 1;
        
        % LookUnderMasks Whether to look under mask dialogs when reporting
        %  If true, the report includes details about blocks in masked
        %  subsystems. Otherwise, the report treats masked subsystems as
        %  normal blocks. This property is set by a checkbox in the print
        %  dialog.
        LookUnderMasks (1, 1) logical = false;
        
        % FollowLibraryLinks Whether to expand unique library links
        %  If true, the report includes blocks in linked libraries. This
        %  property is set by a checkbox in the print dialog.
        FollowLibraryLinks (1, 1) logical = false;
        
    end
    
    properties (Access = private)
        % Property used to determine which widgets should be visible/active
        % Mode values are:
        %   0 - Display options. This is the default mode that appears when
        %       opening the dialog. All print options are displayed. Moves
        %       to next mode (1) when user pushes 'Print' button.
        %   1 - Generating report. This mode switches to a panel that
        %       displays report generation messages. Moves to next mode (2)
        %       when user pushes 'Stop' button or when reporting is
        %       complete.
        %   2 - Report finished. This mode still displays the messages
        %       from generating the report. Moves back to first mode (0)
        %       when user pushes 'Options' button.
        DialogMode = 0; % 0=display options; 1=Generating report; 2=After generating report
        
        % Property to hold instance of GenerationMessageList class used to
        % display report generation messages in the dialog
        MessageList;
    end

    methods
        function this = SLBookDialog(varargin)
            %SLBOOKDIALOG Construct an instance of this class
            %   Detailed explanation goes here
            
            % Initiate the GenerationMessageList
            this.MessageList = rptgen.internal.gui.GenerationMessageList;
            this.MessageList.setPriorityFilter(3);
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % DAStudio overridden methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function varType = getPropDataType(~, varName)
            % Specify property types of properties that are directly
            % associated with widget values. DDG uses this method instead
            % of any property validation done by this class.
            switch(varName)
                case 'DirectoryPath'
                    % Edit box
                    varType = 'string';
                case {'DirectoryOption', 'SystemScope'}
                    % Combobox and radiobutton
                    varType = 'int';
                case {'LookUnderMasks', 'FollowLibraryLinks', 'IncrementFilename'}
                    % Checkboxes
                    varType = 'bool';
                otherwise
                    varType = 'other';
            end
        end
        
        function schema = getDialogSchema(this)
            %Constructing DDG
            tag_prefix = 'slbook_';
            
            % Get group containing file selection options
            fileSelectGroup = getFileSelectSchema(this, tag_prefix);
            % Get group containing hierarchy options
            hierarchyOptsGroup = getHierarchyOptionsSchema(this, tag_prefix);
            
            % Create print options panel that includes file selection and
            % hierarchy options
            printOptsPanel.Type = 'panel';
            printOptsPanel.Tag = tag_prefix + "printOptionsPanel";
            printOptsPanel.Items = {fileSelectGroup, hierarchyOptsGroup};
            
            % Create message list panel
            msgList = this.MessageList.createMessageListPanel();
            msgList.Tag = tag_prefix + "msgListPanel";
            msgList.Source = this.MessageList;
            
            % Create message panel
            msgPanel.Type = 'panel';
            msgPanel.Tag = tag_prefix + "messagePanel";
            msgPanel.LayoutGrid = [3 1];
            msgPanel.Items = {msgList};
            
            % Create widget stack to alternate between print options and
            % message list
            widgetStack.Type = 'widgetstack';
            widgetStack.Items = {printOptsPanel, msgPanel};
            if this.DialogMode == 0
                widgetStack.ActiveWidget = 0;
            else
                widgetStack.ActiveWidget = 1;
            end
            

            % Main action button. This button switches between Print,
            % Stop, and Options depending on the dialog mode
            printButton.Type = 'pushbutton';
            printButton.RowSpan = [1 1];
            printButton.ColSpan = [2 2];
            printButton.Tag = tag_prefix + "actionButton";
            printButton.ObjectMethod = 'actionButtonCallback';
            printButton.DialogRefresh = true;
            switch this.DialogMode
                case 0
                    % Dialog is displaying print options. This button
                    % should be print button
                    printButton.Name = getString(message("rptgen:SLBookDialog:printLabel"));
                    printButton.ToolTip = getString(message("rptgen:SLBookDialog:printTooltip"));
                case 1
                    % Report is being generated and dialog is displaying
                    % messages. This button should be stop button
                    printButton.Name = getString(message("rptgen:SLBookDialog:stopLabel"));
                    printButton.ToolTip = getString(message("rptgen:SLBookDialog:stopTooltip"));
                otherwise %case 2
                    % Report generation is complete and dialog is
                    % displaying messages. This button should be options
                    % button to go back to print options
                    printButton.Name = getString(message("rptgen:SLBookDialog:optionsLabel"));
                    printButton.ToolTip = getString(message("rptgen:SLBookDialog:optionsTooltip"));
            end

            % Cancel button
            cancelButton.Type = 'pushbutton';
            cancelButton.Name = getString(message("rptgen:SLBookDialog:cancelLabel"));
            cancelButton.ToolTip = getString(message("rptgen:SLBookDialog:cancelTooltip"));
            cancelButton.RowSpan = [1 1];
            cancelButton.ColSpan = [3 3];
            cancelButton.ObjectMethod = 'closeCallback';
            cancelButton.MethodArgs = {'%dialog'};
            cancelButton.ArgDataTypes = {'handle'};
            cancelButton.Tag = tag_prefix + "cancelButton";
            % Disable this button when report is being generated
            cancelButton.Enabled = this.DialogMode ~= 1;
            
            % Help
            helpButton.Type = 'pushbutton';
            helpButton.Name = getString(message("rptgen:SLBookDialog:helpLabel"));
            helpButton.RowSpan = [1 1];
            helpButton.ColSpan = [4 4 ];
            helpButton.ObjectMethod = 'helpCallback';
            helpButton.Tag = tag_prefix + "helpButton";

            % Button panel
            standaloneButtonPanel.Type = 'panel'; %similar to group but without title or border
            standaloneButtonPanel.LayoutGrid = [1 4];
            standaloneButtonPanel.ColStretch = [0, 0, 0, 0]; %buttons' horizontal spacing should not alter with resize of dialog window
            standaloneButtonPanel.Items = {printButton, cancelButton, helpButton};


            % Add items to overall dialog schema
            schema.DialogTitle = getString(message("rptgen:SLBookDialog:dialogTitle")) + " - " + this.System;
            schema.DialogTag = "slbook."+this.System;
            schema.StandaloneButtonSet = standaloneButtonPanel;
            schema.IsScrollable = false;
            schema.Items = {widgetStack};
            % Set position, if specified
            if ~isempty(this.Position)
                schema.Geometry = this.Position;
            end
            % Set close callback
            schema.CloseMethod = 'closeCallback';
            schema.CloseMethodArgs = {'%dialog'};
            schema.CloseMethodArgsDT = {'handle'};
        end
        
        function fileSelectGroup = getFileSelectSchema(this, tag_prefix)
            % Combobox to choose report directory
            directorySelect.Type = 'combobox';
            directorySelect.Tag = tag_prefix + "directorySelect";
            directorySelect.Name = getString(message("rptgen:SLBookDialog:directoryLabel"));
            directorySelect.RowSpan = [1 1];
            directorySelect.ColSpan = [1 1];
            directorySelect.Mode = true; % Update source object property with user input
            directorySelect.DialogRefresh = true; % Refresh dialog after user input
            directorySelect.ObjectProperty = 'DirectoryOption';
            directorySelect.Values = 0:2;
            directorySelect.Entries = {...
                getString(message("rptgen:SLBookDialog:currentDir")), ...
                getString(message("rptgen:SLBookDialog:temporary")), ...
                getString(message("rptgen:SLBookDialog:other"))};
            directorySelect.Graphical = true;

            % Directory path edit area
            editTextField.Type = 'edit';
            editTextField.Tag = tag_prefix + "directoryPath";
            editTextField.RowSpan = [1 1];
            editTextField.ColSpan = [2 2];
            editTextField.Mode = true;
            editTextField.ObjectProperty = 'DirectoryPath';
            % Only enable edit field if user selects 'Other' option for
            % directory
            editTextField.Enabled = this.DirectoryOption == 2;
            editTextField.Graphical = true;

            % Path browse button
            browsePathButton.Type = 'pushbutton';
            browsePathButton.Tag = tag_prefix + "browsePathButton";
            browsePathButton.Name = getString(message("rptgen:SLBookDialog:browseLabel"));
            browsePathButton.ToolTip = getString(message("rptgen:SLBookDialog:browseTooltip"));
            browsePathButton.RowSpan = [1 1];
            browsePathButton.ColSpan = [3 3];
            browsePathButton.ObjectMethod = 'browseCallback';
            browsePathButton.MethodArgs = {'%dialog'};
            browsePathButton.ArgDataTypes = {'handle'};
            % Only enable browse button if user selects 'Other' option for
            % directory
            browsePathButton.Enabled = this.DirectoryOption == 2;

            % Increment option
            incrementCheckbox.Type = 'checkbox';
            incrementCheckbox.Tag = tag_prefix + "incrementFilename";
            incrementCheckbox.Name = getString(message("rptgen:SLBookDialog:isIncrement"));
            incrementCheckbox.RowSpan = [2 2];
            incrementCheckbox.ColSpan = [1 3];
            incrementCheckbox.Mode = true;
            incrementCheckbox.ObjectProperty = 'IncrementFilename';
            incrementCheckbox.Graphical = true;

            % Add all widgets to filename options group
            fileSelectGroup.Type = 'group';
            fileSelectGroup.Name = getString(message("rptgen:SLBookDialog:filenameOptionsLabel"));
            fileSelectGroup.LayoutGrid = [2 3];
            fileSelectGroup.Tag = tag_prefix + "fileSelectGroup";
            items = {directorySelect, editTextField, browsePathButton, incrementCheckbox};
            fileSelectGroup.Items = items;
        end
        
        function hierarchyOptsGroup = getHierarchyOptionsSchema(this, tag_prefix)
            % System scope options for non Stateflow system
            hierarchyOptions.Type = 'radiobutton';
            hierarchyOptions.Tag = tag_prefix + "hierarchyOptions";
            hierarchyOptions.Name = '';
            hierarchyOptions.Mode = true; % Update source object property with user input
            hierarchyOptions.DialogRefresh = true; % Refresh dialog after user input
            hierarchyOptions.Alignment = 5; % Center left
            hierarchyOptions.Entries = {...
                getString(message("rptgen:SLBookDialog:currentSys")), ...
                getString(message("rptgen:SLBookDialog:currentAbove")), ...
                getString(message("rptgen:SLBookDialog:currentBelow")), ...
                getString(message("rptgen:SLBookDialog:allSys"))};
            hierarchyOptions.Values = 0:3;
            hierarchyOptions.RowSpan = [1 1];
            hierarchyOptions.ColSpan = [2 2];
            hierarchyOptions.ObjectProperty = 'SystemScope';
            hierarchyOptions.Graphical = true;

            % If system is a Stateflow system, remove current and above
            % option
            if this.ChartId > 0
                hierarchyOptions.Values(2) = [];
                hierarchyOptions.Entries(2) = [];
            end

            % Images for different system scope options
            currentObjectImg.Type = 'image';
            currentObjectImg.FilePath = fullfile(matlabroot, ...
                'toolbox', 'shared', 'rptgen', 'resources', 'icons', 'IconCurrent.gif');
            
            currentAboveImg.Type = 'image';
            currentAboveImg.FilePath = fullfile(matlabroot, ...
                'toolbox', 'shared', 'rptgen', 'resources', 'icons', 'IconCurrentAbove.gif');
            
            currentBelowImg.Type = 'image';
            currentBelowImg.FilePath = fullfile(matlabroot, ...
                'toolbox', 'shared', 'rptgen', 'resources', 'icons', 'IconCurrentBelow.gif');
            
            entireModelImg.Type = 'image';
            entireModelImg.FilePath = fullfile(matlabroot, ...
                'toolbox', 'shared', 'rptgen', 'resources', 'icons', 'IconAll.gif');
            
            % Widgetstack to display the correct image for the currently
            % selected system scope option
            imgStack.Type = 'widgetstack';
            imgStack.Tag = tag_prefix + "hierarchyOptionsImages";
            imgStack.Items = {currentObjectImg, currentAboveImg, currentBelowImg, entireModelImg};
            % Active widget depends on the system scope option selected.
            imgStack.ActiveWidget = this.SystemScope;
            imgStack.RowSpan = [1 1];
            imgStack.ColSpan = [1 1];
            imgStack.Alignment =5; % Center left
            
            % Panel for system scope options and images
            sysOpts.Type = 'panel';
            sysOpts.ColSpan = [1 1];
            sysOpts.RowSpan = [1 1];
            sysOpts.LayoutGrid = [1 2];
            sysOpts.Items = {hierarchyOptions,imgStack};
            
            % Look under mask option
            lookUnderMask.Type = 'checkbox';
            lookUnderMask.Tag = tag_prefix + "lookUnderMask";
            lookUnderMask.Name = getString(message("rptgen:SLBookDialog:isMask"));
            lookUnderMask.RowSpan = [1 1];
            lookUnderMask.ColSpan = [1 1];
            % For SF systems, only enable this option if system scope is
            % set to include entire model. For Simulink systems, enable if
            % scope is set to entire model or current system and ancestors
            lookUnderMask.Enabled = (this.SystemScope == 3) || ...
                (this.SystemScope == 2 && this.ChartId < 0);
            lookUnderMask.ObjectProperty = 'LookUnderMasks';
            lookUnderMask.Mode = true;
            lookUnderMask.Graphical = true;
            
            % Library links option
            expandLibraryLinks.Type = 'checkbox';
            expandLibraryLinks.Tag = tag_prefix + "followLibraryLinks";
            expandLibraryLinks.Name = getString(message("rptgen:SLBookDialog:isLibrary"));
            expandLibraryLinks.RowSpan = [2 2];
            expandLibraryLinks.ColSpan = [1 1];
            % For SF systems, only enable this option if system scope is
            % set to include entire model. For Simulink systems, enable if
            % scope is set to entire model or current system and ancestors
            expandLibraryLinks.Enabled = (this.SystemScope == 3) || ...
                (this.SystemScope == 2 && this.ChartId < 0);
            expandLibraryLinks.ObjectProperty = 'FollowLibraryLinks';
            expandLibraryLinks.Mode = true;
            expandLibraryLinks.Graphical = true;
            
            % Panel for mask and library options
            includeOpts.Type = 'panel';
            includeOpts.RowSpan = [1 1];
            includeOpts.ColSpan = [2 2];
            includeOpts.LayoutGrid = [2 1];
            includeOpts.Items = {lookUnderMask, expandLibraryLinks};
            
            % Group for all widgets
            hierarchyOptsGroup.Type = 'group';
            hierarchyOptsGroup.Tag = tag_prefix + "hierarchyOptionsGroup";
            hierarchyOptsGroup.Name = getString(message("rptgen:SLBookDialog:systemReportingLabel"));
            hierarchyOptsGroup.LayoutGrid = [1 2];
            items = {sysOpts,includeOpts};
            hierarchyOptsGroup.Items = items;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Callback methods
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function actionButtonCallback(this)
            % This method performs a different action based on the current
            % dialog mode
            switch this.DialogMode
                case 0 % Displaying options
                    % Move to report generation mode and start report
                    this.DialogMode = 1;
                    doCreate(this);
                case 1 % Generating report
                    % Next mode is generation complete mode
                    this.DialogMode = 2;
                    % Halt reporting
                    rptgen.internal.gui.GenerationDisplayClient.staticAddMessage(...
                        getString(message("rptgen:SLBookDialog:stoppingMessage")),1)
                    try
                        rptgen.haltGenerate
                    catch me
                        error(message("rptgen:SLBookDialog:haltError"));
                    end
                otherwise % case 2: Generation complete
                    % Move to displaying options mode
                    this.DialogMode = 0;                
            end
        end
        
        function closeCallback(this, dlg)
            % Reset dialog mode to display options
            this.DialogMode = 0;
            % Close dialog
            delete(dlg);
        end

        function helpCallback(~)
            % Open help for print details
            helpview('simulink','printdetails');
        end

        function browseCallback(this, dlg)
            % Get initial path
            initPath = this.DirectoryPath;
            initPath=strtrim(initPath); % remove trailing or leading white space
            if ~exist(initPath,'dir')
                initPath = fullfile(matlabroot,'..');
            end

            % Open file browse dialog and get path that user selects
            newPath = uigetdir(initPath, getString(message("rptgen:SLBookDialog:selectDir")));
            
            % Update directory path to be user-selected path
            if ~isequal(newPath, 0)
                this.DirectoryPath = newPath;
                dlg.refresh;
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Public methods used by slbook and callbacks
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function doClose(this)
            % Find dialogs associated with this source object and close
            % them
            dlg = DAStudio.ToolRoot.getOpenDialogs(this);
            closeCallback(this, dlg);
        end
        
        function doCreate(this)
            % Use call to slbook to create the report based on
            % user-specified options
            
            % Set message client to display messages in dialog
            rptgen.internal.gui.GenerationDisplayClient.setMessageClient(this.MessageList);
            rptgen.internal.gui.GenerationDisplayClient.staticClearMessages();
            rptgen.internal.gui.GenerationDisplayClient.staticAddMessage('Loading report',2);
            
            dlg = DAStudio.ToolRoot.getOpenDialogs(this);
            if ~isempty(dlg)
                dlg.refresh;
            end
            
            % Get arguments
            args = getFlagArguments(this);
            
            %No button actions will fire when in the callback of another button
            %action. We run the report asynchronously in order to get it out of
            %the DAStudio UI call stack and allow the "stop" button to work.
            t = timer;
            t.TimerFcn = {@locCallbackRunReport,this, args};
            t.stopFcn = {@dlgStopTimer};
            t.StartDelay = 0.1;
            start(t);
        end
        
        function frameify(~)
            % Function called by slbook. Can be removed once Java option is
            % removed
        end
        
        function setVisible(this)
            % Create a dialog for this source object. If a dialog already
            % exists, refresh it.
            dlg = DAStudio.ToolRoot.getOpenDialogs(this);
            if isempty(dlg)
                dlg = DAStudio.Dialog(this);
            else
                dlg.refresh;
            end
            % getDialogSchema only sets the position of the top left corner
            % of the dialog, not the width or height. Reset the size of the
            % dialog in case there was an issue with determining the height
            % and width
            dlg.resetSize;
        end
        
        function setCurrentSystem(this, sys, x, y)
            % Set source object to report on specified system. Also set
            % dialog's position.
            this.System = sys;
            this.ChartId = -1;
            this.Position = [x y];
            
            % Display the dialog
            setVisible(this);
        end
        
        function setCurrentChart(this, sfChart, sfId, x, y)
            % Set source object to report on specified chart. Also set
            % dialog's position
            this.System = sfChart;
            this.ChartId = sfId;
            this.Position = [x y];
            
            % Specifying a chart removes the 'Current and above' option
            % from available system scope options. If this option was
            % already selected, change it to the 'Current' option.
            if this.SystemScope == 1
                this.SystemScope = 0;
            end
            
            % Display dialog
            setVisible(this);
        end
        
        function reportStart(~)
            % Empty for now. Called by slbook
        end
        
        function reportEnd(this)
            % Method called when report generation ends.
            
            % Switch to 'Generation complete' dialog mode and refresh
            % dialog
            this.DialogMode = 2;
            dlg = DAStudio.ToolRoot.getOpenDialogs(this);
            if ~isempty(dlg)
                dlg.refresh;
            end
            
            % Reset display client to default message list
            rptgen.internal.gui.GenerationDisplayClient.reset();
        end

        function height = getHeight(this)
            % Get height of dialog if dialog is open
            dlg = DAStudio.ToolRoot.getOpenDialogs(this);
            if ~isempty(dlg)
                height = dlg.position(4);
            else
                height = 0;
            end
        end
        
        function width = getWidth(this)
            % Get width of dialog if dialog is open
            dlg = DAStudio.ToolRoot.getOpenDialogs(this);
            if ~isempty(dlg)
                width = dlg.position(3);
            else
                width = 0;
            end
        end

    end
    
    methods (Access = private)
        function opts = getFlagArguments(this)
            % Returns cell array of options used as arguments for slbook.
            
            % Specify system to report
            if this.ChartId > 0
                systemReferenceName = '-UseChart';
                systemReference = this.ChartId;
            else
                systemReferenceName = '-UseSystem';
                systemReference     = this.System;
            end
            
            % Specify system scope
            switch this.SystemScope
                case 0
                    sysReportingOpt = 'current';
                case 1
                    % For Stateflow charts, currentAbove is not an option
                    if this.ChartId > 0
                        sysReportingOpt = 'current';
                    else
                        sysReportingOpt = 'currentAbove';
                    end
                case 2
                    sysReportingOpt = 'currentBelow';
                otherwise
                    sysReportingOpt = 'all';
            end
            
            % Specify directory path
            switch this.DirectoryOption
                case 0
                    dirName = '%<pwd>';
                case 1
                    dirName = '%<tempdir>';
                otherwise
                    dirName = this.DirectoryPath;
            end
            
            % Specify mask option
            if this.LookUnderMasks
                maskOpt = 'all';
            else
                maskOpt = 'graphical';
            end
            
            % Specify library link option
            if this.FollowLibraryLinks
                libOpt = 'unique';
            else
                libOpt = 'off';
            end
            
            % Combine options into cell array of arguments
            opts = {'-SysLoopType', sysReportingOpt, ...
                '-isMask', maskOpt, ...
                '-isLibrary', libOpt, ...
                '-DirectoryName', dirName, ...
                '-isIncrementFilename', this.IncrementFilename, ...
                '-Dialog', this, ...
                systemReferenceName,    systemReference};
      
        end
    end
end

% Report generation callback for timer
function locCallbackRunReport(~, ~, this, args)
try
    rptgen_sl.slbook(args{:});
catch me
    this.DialogMode = 2;
    error(message("rptgen:SLBookDialog:createError"));
end
end

% Timer cleanup callback
function dlgStopTimer(obj, event) %#ok
delete(obj);
end
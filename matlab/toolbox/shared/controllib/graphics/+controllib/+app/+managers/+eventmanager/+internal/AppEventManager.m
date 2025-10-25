classdef AppEventManager < controllib.app.managers.eventmanager.internal.AbstractEventManager
    % Class that manages the display of status messages in a toolstrip
    % frame.
    
    % Copyright 2014-2024 The MathWorks, Inc.
    
    properties (Access = protected)
        ActionStatusBar         % Action status message display (bottom right)
        StatusProgressBar       % Action status progress bar (bottom right)
        StatusLabel             % Action status label (bottom right)
        StatusButton            % Action status button (bottom right)
        Widgets                 % Undo and Redo buttons, History Widgets
        
        StatusBarTags
        ProgressBarContext
        StatusLabelContext
        StatusButtonContext
        LastActionStatusMessage
    end

    properties (Access = protected, WeakHandle)
        AppContainer (1,1) matlab.ui.container.internal.AppContainer  % AppContainer that has the frame for the status bar
    end

    properties (Access=protected,Transient)
        UndoStackListener       % Listens to undo stack to enable/disable buttons
        RedoStackListener       % Listens to redo stack to enable/disable buttons
    end
    
    methods (Access = public)
        % Public API        
        function this = AppEventManager(AppContainer)
            arguments
                AppContainer (1,1) matlab.ui.container.internal.AppContainer
            end
            this = this@controllib.app.managers.eventmanager.internal.AbstractEventManager;
            this.AppContainer = AppContainer;
            % Initialize StatusBar tags based on AppContainer tag
            createStatusBarTags(this);
            % Create status bar
            createActionStatusBar(this);
            % Create undo and redo buttons
            createWidgets(this);
        end

        %% Status bar        
        function [actionStatusLabel, progressBar, statusButton] = getActionStatusBar(this)
            % Status bar to display action status message and progress bar
            actionStatusLabel = this.StatusLabel;
            progressBar = this.StatusProgressBar;
            statusButton = this.StatusButton;
        end

        %% Undo and Redo
        function undo(this)
            % Clear previous status messages that are no longer valid
            clearActionStatus(this);
            % Call superclass undo
            undo@controllib.app.managers.eventmanager.internal.AbstractEventManager(this);
        end

        function redo(this)
            % Clear previous status messages that are no longer valid
            clearActionStatus(this);
            % Call superclass redo
            redo@controllib.app.managers.eventmanager.internal.AbstractEventManager(this);
        end
        
        %% Create quick-access toolbar buttons for undo and redo
        function createWidgets(this)
            % REVISIT: This method corrupts the contextual help callback
            % set using setContextualHelpCallback method on the toolgroup.
            weakThis = matlab.lang.WeakReference(this);
            redoAction = matlab.ui.internal.toolstrip.qab.QABRedoButton;
            redoAction.ButtonPushedFcn = @(es,ed) redo(weakThis.Handle);
            add(this.AppContainer,redoAction);
            this.Widgets.RedoButton = redoAction;
            localRedoStackChanged(this);

            % Set undo button to Quick-Access Bar
            undoAction = matlab.ui.internal.toolstrip.qab.QABUndoButton;
            undoAction.ButtonPushedFcn = @(es,ed) undo(weakThis.Handle);
            add(this.AppContainer,undoAction);
            this.Widgets.UndoButton = undoAction;
            localUndoStackChanged(this);

            % Add listeners to enable/ disable listeners as stack length
            % changes
            localAddStackListeners(this);
        end

        %% Posting status messages
        function postActionStatus(this, Value, Text, ButtonText)
            arguments
                this (1,1) controllib.app.managers.eventmanager.internal.AppEventManager
                Value 
                Text (1,1) string = ""
                ButtonText (1,1) string = ""
            end
            if ~strcmp(this.AppContainer.State,'TERMINATED')
                % Using MATLAB Icon as placeholder. Need 'info' icon for
                % AppContainer Status Bar
                contexts = this.AppContainer.ActiveContexts;
                if isempty(contexts)
                    contexts = string.empty;
                else
                    contexts = setdiff(contexts,[this.StatusLabelContext.Tag this.ProgressBarContext.Tag this.StatusButtonContext.Tag]);
                end
                if ~isempty(this.StatusLabel)
                    this.StatusLabel.Text = Text;
                    if Text ~= ""
                        contexts = [contexts,this.StatusLabelContext.Tag];
                    end
                end
                if ~isempty(this.StatusProgressBar) && ~isempty(this.StatusButton)
                    if isa(Value,'function_handle')
                        contexts = [contexts,this.StatusButtonContext.Tag];
                        this.StatusButton.Text = ButtonText;
                        this.StatusButton.ButtonPushedFcn = Value;
                        this.StatusProgressBar.Indeterminate = false;
                        this.StatusProgressBar.Value = 0;
                    elseif isnumeric(Value)
                        contexts = [contexts,this.ProgressBarContext.Tag];
                        this.StatusProgressBar.Indeterminate = false;
                        this.StatusProgressBar.Value = Value;
                        this.StatusButton.Text = "";
                        this.StatusButton.ButtonPushedFcn = [];
                    else
                        if strcmp(Value,'on')
                            contexts= [contexts,this.ProgressBarContext.Tag];
                            this.StatusProgressBar.Indeterminate = true;
                            this.StatusButton.Text = "";
                            this.StatusButton.ButtonPushedFcn = [];
                        else
                            this.StatusProgressBar.Indeterminate = false;
                            this.StatusProgressBar.Value = 0;
                            this.StatusButton.Text = "";
                            this.StatusButton.ButtonPushedFcn = [];
                        end
                    end
                end
                this.AppContainer.ActiveContexts = contexts;
            end
            if Text ~= ""
                this.LastActionStatusMessage = Text;
            end
        end
        
        function clearActionStatus(this)
            % Clears the action status status (at location: east)
            if ~strcmp(this.AppContainer.State,'TERMINATED')
                contexts = this.AppContainer.ActiveContexts;
                if isempty(contexts)
                    contexts = string.empty;
                else
                    contexts = setdiff(contexts,[this.StatusLabelContext.Tag this.ProgressBarContext.Tag this.StatusButtonContext.Tag]);
                end
                this.AppContainer.ActiveContexts = contexts;
            end
            if ~isempty(this.StatusLabel)
                this.StatusLabel.Text = "";
            end
            if ~isempty(this.StatusProgressBar)
                this.StatusProgressBar.Value = 0;
                this.StatusProgressBar.Indeterminate = false;
            end
            if ~isempty(this.StatusButton)
                this.StatusButton.Text = "";
                this.StatusButton.ButtonPushedFcn = [];
            end
        end

        function msg = getLastActionStatusMessage(this)
            msg = this.LastActionStatusMessage;
        end
        
        function add2Hist(this, HistoryLine)
            % Record text to history stack
            this.Recorder.History = [this.Recorder.History ; {HistoryLine}];
        end
    end
    
    methods (Hidden)
        function wdgts = getWidgets(this)
            wdgts = this.Widgets;
        end
        
        function AppContainer = getAppContainer(this)
            AppContainer = this.AppContainer;
        end
    end
    
    methods (Access = private)       
        function createActionStatusBar(this)
            import matlab.ui.internal.toolstrip.*
            
            % Add StatusBar
            statusBar = matlab.ui.internal.statusbar.StatusBar();
            statusBar.Tag = this.StatusBarTags.ActionStatusBar;
            add(this.AppContainer,statusBar);
            this.ActionStatusBar = statusBar;
            
            % Add ProgressBar
            statusProgressBar = matlab.ui.internal.statusbar.StatusProgressBar();
            statusProgressBar.Tag = this.StatusBarTags.ProgressBar;
            statusProgressBar.Region = "right";
            add(this.AppContainer,statusProgressBar);
            this.StatusProgressBar = statusProgressBar;
            
             % Add StatusLabel
            statusLabel = matlab.ui.internal.statusbar.StatusLabel();
            statusLabel.Tag = this.StatusBarTags.ActionStatusLabel;
            statusLabel.Region = "right";
            add(this.AppContainer,statusLabel);
            this.StatusLabel = statusLabel;      

            % Add StatusButton
            statusButton = matlab.ui.internal.statusbar.StatusButton();
            statusButton.Tag = this.StatusBarTags.StatusButton;
            statusButton.Region = "right";
            add(this.AppContainer,statusButton)
            this.StatusButton = statusButton;      
            
            % Add contexts
            statusLabelContext = matlab.ui.container.internal.appcontainer.ContextDefinition();
            statusLabelContext.Tag = "showStatusLabel";
            statusLabelContext.StatusComponentTags = this.StatusBarTags.ActionStatusLabel;
            this.StatusLabelContext = statusLabelContext;

            progressbarContext = matlab.ui.container.internal.appcontainer.ContextDefinition();
            progressbarContext.Tag = "showProgressBar";
            progressbarContext.StatusComponentTags = this.StatusBarTags.ProgressBar;
            this.ProgressBarContext = progressbarContext;

            statusButtonContext = matlab.ui.container.internal.appcontainer.ContextDefinition();
            statusButtonContext.Tag = "showStatusButton";
            statusButtonContext.StatusComponentTags = this.StatusBarTags.StatusButton;
            this.StatusButtonContext = statusButtonContext;

            this.AppContainer.Contexts = {statusLabelContext,progressbarContext,statusButtonContext};
        end
        
        %% Local methods
        function localAddStackListeners(this)
            weakThis = matlab.lang.WeakReference(this);
            this.UndoStackListener = addlistener(this.Recorder, 'UndoStackChanged', @(es, ed) localUndoStackChanged(weakThis.Handle));
            this.RedoStackListener = addlistener(this.Recorder, 'RedoStackChanged', @(es, ed) localRedoStackChanged(weakThis.Handle));
        end
        
        function localUndoStackChanged(this)
            len = getUndoStackLength(this.Recorder);
            this.Widgets.UndoButton.Enabled = len >= 1;
        end
        
        function localRedoStackChanged(this)
            len = getRedoStackLength(this.Recorder);
            this.Widgets.RedoButton.Enabled = len >= 1;
        end
        
        function createStatusBarTags(this)
            this.StatusBarTags.ActionStatusBar = this.AppContainer.Tag + "_ActionStatusBar";
            this.StatusBarTags.ActionStatusLabel = this.AppContainer.Tag + "_ActionStatusLabel";
            this.StatusBarTags.ProgressBar = this.AppContainer.Tag + "_ProgressBar";
            this.StatusBarTags.StatusButton = this.AppContainer.Tag + "_StatusButton";
        end
    end
end

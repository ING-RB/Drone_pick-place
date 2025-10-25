classdef (ConstructOnLoad) VariableEditorPanel < controllib.ui.internal.dialog.AbstractContainer
    % Panel to edit or view a variable
    %
    % Use a variable name and variable value, or a variable name and
    % workspace to construct the panel.
    %
    % Construction:
    %
    %   import controllib.widget.internal.variableeditor.VariableEditorPanel;
    %   pnl = VariableEditorPanel("G",rss(3));
    %   pnl = VariableEditorPanel("G","Workspace","base");
    %   pnl = VariableEditorPanel("G","Workspace",localWorkspaceObject);
    %
    % Optional Inputs:
    %
    %   pnl = VariableEditorPanel("G",rss(3),"Editable",true,"ShowVariableName",false);
    %   pnl = VariableEditorPanel("G",rss(3),"Parent",uifigure);
    %
    % Update:
    %
    %   pnl.VariableValue = rss(4);
    %   pnl.Parent = uigridlayout;
    %   pnl.ShowVariableName = false;
    %
    % Methods:
    %
    %   wdgt = getWidget(pnl);
    %   variableWidget = getVariableWidget(pnl);
    %
    %
    % Events:
    %
    %   VariableChanged
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    properties(Access = public, AbortSet)
        % VariableValue
        %   Set property value to update the panel.
        VariableValue
        % Parent
        %   Set Parent to place panel in a dialog.
        Parent
        % ShowVariableName (logical, default is true)
        %   Set to true to show variable name in display.
        ShowVariableName
    end
    
    properties(Dependent, AbortSet)
        % VariableName (string or char array)
        %   Cannot change after construction when Editable is true
        VariableName
    end
    
    properties(GetAccess = public, SetAccess = private)
        % Editable (logical, default is false)
        %   Set to true to edit the  variable using the dialog. Set to
        %   false to see a read-only view that shows command line display
        %   of the variable.
        Editable
        % WorkspaceType ("Local" | "Base" | "None")
        %   Indicates the type of workspace used by client. Changing
        %   variable value or name will also change the corresponding
        %   variable in the workspace
        WorkspaceType
    end
    
    properties(Access = private, Transient)
        VariableNameInternal
        VariableWidget
    end
    
    properties(Hidden)
        Workspace
        BaseWorkspaceListener
    end
    
    events
        VariableChanged
    end
    
    methods % Constructor, Update, Destructor
        function this = VariableEditorPanel(variableName,variableValue,optionalArguments)
            arguments
                variableName
                variableValue = []
                optionalArguments.Workspace = "base"
                optionalArguments.Editable = false
                optionalArguments.Parent = []
                optionalArguments.ShowVariableName = true
            end
            % Set optional aruments
            this.Editable = optionalArguments.Editable;
            this.Parent = optionalArguments.Parent;
            this.ShowVariableName = optionalArguments.ShowVariableName;
            % Variable Name (assign to internal property)
            this.VariableNameInternal = string(variableName);
            if ~isempty(variableValue)
                % Create local workspace
                this.Workspace = matlab.internal.datatoolsservices.AppWorkspace;
                assignin(this.Workspace,variableName,variableValue);
                this.VariableValue = variableValue;
                this.WorkspaceType = "None";
            else
                this.Workspace = optionalArguments.Workspace;
                if strcmpi(this.Workspace,"base")
                    this.WorkspaceType = "Base";
                else
                    this.WorkspaceType = "Local";
                end
            end
            % Assign initial variable value
            if strcmp(this.Workspace,"base")
                % From base workspace
                this.VariableValue = evalin("base",this.VariableName+";");
                if ~this.Editable
                    addBaseWorkspaceListener(this);
                end
            else
                % From local workspace
                this.VariableValue = this.Workspace.(this.VariableName);
            end
        end
        
        function updateUI(this)
            % Update variable value
            this.VariableValue = getVariableValueInWorkspace(this);
        end
        
        function delete(this)
            % Clean up VariablePanel and base workspace listener
            if ~isempty(this.VariableWidget) && isvalid(this.VariableWidget) && this.IsWidgetValid
                delete(this.VariableWidget);
            end
            delete(this.BaseWorkspaceListener);
        end

        function setWorkspace(this,workspace,optionalArguments)
            % setWorkspace updates the workspace used by VariableEditorPanel
            %
            % setWorkspace(this,ws)
            % setWorkspace(this,ws,VariableName="G")
            arguments
                this
                workspace
                optionalArguments.VariableName = this.VariableName
            end
            
            delete(this.BaseWorkspaceListener);
            this.VariableNameInternal = optionalArguments.VariableName;
            this.Workspace = workspace;
            if strcmp(workspace,"base")
                addBaseWorkspaceListener(this);
            end
            updateUI(this);
        end
    end
    
    methods % set/get
        % Variable Name
        function variableName = get.VariableName(this)
            variableName = this.VariableNameInternal;
        end
        
        function set.VariableName(this,variableName)
            arguments
                this
                variableName string
            end
            if ~this.Editable
                % Create new variable in workspace and clear old variable
                updateVariableNameInWorkspace(this,variableName);
                % Update view
                updateWidget(this);
                notify(this,'VariableChanged');
            else
                % Modifying VariableName is not supported when Editable is
                % true
                ctrlMsgUtils.error('Controllib:gui:errModifyVariableNameEditable');
            end
        end
        
        % Variable Value
        function variableValue = get.VariableValue(this)
            variableValue = this.VariableValue;
        end
        
        function set.VariableValue(this,variableValue)
            % Update variable value in workspace
            updateVariableValueInWorkspace(this,variableValue);
            this.VariableValue = variableValue;
            % Update view
            updateWidget(this);
            % Notify
            notify(this,'VariableChanged');
        end
        
        % Parent
        function Parent = get.Parent(this)
            Parent = this.Parent;
        end
        
        function set.Parent(this,Parent)
            % Reparent widget
            if this.IsWidgetValid
                w = getWidget(this);
                w.Parent = Parent;
            end
            this.Parent = Parent;
        end
        
        % ShowVariableName
        function ShowVariableName = get.ShowVariableName(this)
            ShowVariableName = this.ShowVariableName;
        end
        
        function set.ShowVariableName(this,ShowVariableName)
            this.ShowVariableName = ShowVariableName;
            if this.IsWidgetValid
                updateWidget(this);
            end
        end
        
        % Variable Widget
        function variableWidget = getVariableWidget(this)
            variableWidget = this.VariableWidget;
        end
    end
    
    methods (Access = protected, Sealed)
        function gridLayout = createContainer(this)
            % Container
            gridLayout = uigridlayout('Parent',this.Parent);
            gridLayout.Padding = 0;
            gridLayout.Scrollable = true;
            if this.Editable
                gridLayout.RowHeight = {'1x'};
                gridLayout.ColumnWidth = {'1x'};
                % uivariableeditor
                h = matlab.ui.control.internal.VariableEditor(...
                    'Variable',this.VariableName,'Workspace',this.Workspace,...
                    'DataEditable',true,'Parent',gridLayout);
                h.DataEditCallbackFcn = @(ed) cbVariableWidgetDataEdited(this);
                this.VariableWidget = h;
            else
                gridLayout.RowHeight = {'fit'};
                gridLayout.ColumnWidth = {'fit'};
                % Panel(for border) > GridLayout > Label
                p = uipanel(gridLayout);
                g = uigridlayout(p,[1 1]);
                g.RowHeight = {'fit'};
                g.ColumnWidth = {'fit'};
                g.Scrollable = true;
                % Label
                variableWidget = uilabel(g,'FontName','Courier New');
                variableWidget.WordWrap = 'off';
                this.VariableWidget = variableWidget;
            end
            updateWidget(this);
        end
    end
    
    methods (Access = private)
        function createVariableEditorWidget(this)
            h = matlab.ui.control.internal.VariableEditor(...
                'Variable',this.VariableName,'Workspace',this.Workspace,...
                'Parent',gridLayout);
            h.DataEditCallbackFcn = @(ed) cbVariableWidgetDataEdited(this);
            this.VariableWidget = h;
        end
        
        function displayText = getDisplayText(this)
            % Get command line display for non-editable panel
            if strcmp(this.Workspace,"base")
                workspaceName = "'base'";
            else
                workspaceName = "this.Workspace";
            end
            textToReplace = this.VariableName + " =\n";
            % Use evalin and evalc to get commandline display
            displayCommand = "evalin(" + workspaceName + ",'" + this.VariableName + "');";
            displayText = evalc(displayCommand);
            % Remove header
            displayText = strsplit(displayText,textToReplace);
            displayText = displayText(end);
            % Remove hyperlinks to show model properties
            displayText = eraseBetween(displayText,'<a href','/a>','Boundaries','inclusive');
            % Check if variable name should be displayed
            if this.ShowVariableName
                % Add "VariableName = "
                displayText = [{char(this.VariableName),'=',newline},displayText];
                displayText = strjoin(displayText);
            else
                displayText = displayText{1};
            end
        end
        
        function cbVariableWidgetDataEdited(this)
            % Update variable value
            this.VariableValue = getVariableValueInWorkspace(this);
            notify(this,'VariableChanged');
        end
        
        function variableValue = getVariableValueInWorkspace(this)
            % Get current value in workspace
            variableValue = evalin(this.Workspace,this.VariableName+";");
        end
        
        function updateVariableValueInWorkspace(this,variableValue)
            % Update workspace
            assignin(this.Workspace,this.VariableName,variableValue);
        end
        
        function updateVariableNameInWorkspace(this,variableName)
            if ~isempty(this.Workspace)
                % Add variable with new variable name and clear old
                % variable
                assignin(this.Workspace,variableName,this.VariableValue);
                evalin(this.Workspace,"clear " + this.VariableName);
                this.VariableNameInternal = variableName;
            end
        end
        
        function updateWidget(this)
            if ~this.Editable
                this.VariableWidget.Text = getDisplayText(this);
            end
        end
        
        function addBaseWorkspaceListener(this)
            this.BaseWorkspaceListener = ...
                controllib.widget.internal.variableeditor.BaseWorkspaceListener(this);
        end
    end
    
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            widgets.VariableWidget = this.VariableWidget;
        end
    end
end
classdef VariableEditorDialog < controllib.ui.internal.dialog.AbstractDialog
    % Dialog to edit or view a variable
    %
    % Use a variable name and variable value, or a variable name and
    % workspace to construct dialog. 
    %
    % Construction:
    %
    %   import controllib.widget.internal.variableeditor.VariableEditorDialog;
    %   dlg = VariableEditorDialog("G",rss(3));
    %   dlg = VariableEditorDialog("G","Workspace","base");
    %   dlg = VariableEditorDialog("G","Workspace",localWorkspaceObject);
    %
    % Optional Inputs:
    %
    %   dlg = VariableEditorDialog("G",rss(3),"Editable",true,"ShowVariableName",false);
    %
    % Update:
    %
    %   dlg.VariableValue = rss(4);
    %   dlg.ShowVariableName = false;
    %
    % Methods:
    %
    %   show(dlg);
    %   hide(dlg);
    %   pack(dlg);
    %   addHeaderWidget(dlg,uilabel('Parent',[],'Text','Custom Label'));
    %   addFooterWidget(dlg,uicheckbox('Parent',[],'Text','Custom checkbox'));
    %   variableWidget = getVariableWidget(dlg);
    %
    % Events:
    %
    %   VariableChanged    
    
    % Copyright 2021 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = private)
        % Editable (logical, default is false)
        %   Set to true to edit the  variable using the dialog. Set to
        %   false to see a read-only view that shows command line display
        %   of the variable.
        Editable
        % DialogSize ([width height], default is [])
        %   Set dialog size in constructor. If empty, then show() uses
        %   pack() to size the dialog.
        DialogSize = []
    end

    properties (GetAccess = public, SetAccess = protected)
        
    end
    
    properties (Dependent)
        % VariableName (string or char array)
        %   Cannot change after construction when Editable is true
        VariableName
        % VariableValue
        %   Set property value to update the dialog.
        VariableValue
        % ShowVariableName (logical, default is true)
        %   Set to true to show variable name in display.
        ShowVariableName
    end
    
    properties (Access = private)
        Parent
        GridLayout
        HeaderWidget
        FooterWidget
    end
    
    properties (Hidden)
        VariableEditorPanel
    end
    
    events
        VariableChanged
    end
    
    methods
        function this = VariableEditorDialog(variableName,variableValue,optionalArguments)
            arguments
                variableName string
                variableValue = []
                optionalArguments.Workspace = "base"
                optionalArguments.Editable = false
                optionalArguments.ShowVariableName = true
                optionalArguments.DialogSize = []
            end
            if isempty(variableValue)
                % Construct VariableEditorPanel with workspace argument
                this.VariableEditorPanel = ...
                    controllib.widget.internal.variableeditor.VariableEditorPanel(...
                        variableName,"Workspace",optionalArguments.Workspace,...
                        "Editable",optionalArguments.Editable,"ShowVariableName",...
                        optionalArguments.ShowVariableName);
            else
                % Construct VariableEditorPanel with variable value
                this.VariableEditorPanel = ...
                    controllib.widget.internal.variableeditor.VariableEditorPanel(...
                        variableName,variableValue,"Editable",optionalArguments.Editable,...
                        "ShowVariableName",optionalArguments.ShowVariableName);
            end
            this.Editable = optionalArguments.Editable;
            this.DialogSize = optionalArguments.DialogSize;
            this.Name = 'VariableEditorDialog';
        end
        
        function updateUI(this)
            updateUI(this.VariableEditorPanel);
        end
        
        function delete(this)
            delete(this.VariableEditorPanel);
        end
        
        function show(this,varargin)
            show@controllib.ui.internal.dialog.AbstractDialog(this,varargin{:});
            if isempty(this.DialogSize)
                %% BUG: pack + scrollable creates a dancing dialog, sizing must be done manually for now
                % Fit dialog to content
                %pack(this)
            end
        end
    
        function setWorkspace(this,varargin)
            setWorkspace(this.VariableEditorPanel,varargin{:});
        end
    end
    
    methods % Custom header/footer
        function addHeaderWidget(this,headerWidget)
            % addHeaderWidget(dlg,headerWidget)
            %   addHeaderWidget(dlg,uilabel('Parent',[]);
            %   widget is placed in dialog above the variable widget.
            if ~isempty(this.HeaderWidget)
                delete(this.HeaderWidget);
            end
            headerWidget.Parent = this.GridLayout;
            headerWidget.Layout.Row = 1;
            headerWidget.Layout.Column = 1;
            this.HeaderWidget = headerWidget;
        end
        
        function addFooterWidget(this,footerWidget)
            % addFooterWidget(dlg,headerWidget)
            %   addFooterWidget(dlg,uilabel('Parent',[]);
            %   widget is placed in dialog below the variable widget.
            if ~isempty(this.FooterWidget)
                delete(this.FooterWidget);
            end
            footerWidget.Parent = this.GridLayout;
            footerWidget.Layout.Row = 3;
            footerWidget.Layout.Column = 1;
            this.FooterWidget = footerWidget;
        end
    end
    
    methods %set/get
        % VariableName
        function variableName = get.VariableName(this)
            variableName = this.VariableEditorPanel.VariableName;
        end
        
        function set.VariableName(this,variableName)
            this.VariableEditorPanel.VariableName = variableName;
        end
        
        % Variable Value
        function variableValue = get.VariableValue(this)
            variableValue = this.VariableEditorPanel.VariableValue;
        end
        
        function set.VariableValue(this,variableValue)
            this.VariableEditorPanel.VariableValue = variableValue;
        end

        % Show Variable Name
        function ShowVariableName = get.ShowVariableName(this)
            ShowVariableName = this.VariableEditorPanel.ShowVariableName;
        end
        
        function set.ShowVariableName(this,ShowVariableName)
            this.VariableEditorPanel.ShowVariableName = ShowVariableName;
        end
        
        % Variable Widget
        function variableWidget = getVariableWidget(this)
            variableWidget = getVariableWidget(this.VariableEditorPanel);
        end
        
        % Grid Layout
        function gridLayout = getGridLayout(this)
            gridLayout = this.GridLayout;
        end
    end
    
    methods (Access = protected)
        function buildUI(this)
            % Dialog Size
            if ~isempty(this.DialogSize)
                this.UIFigure.Position(3:4) = this.DialogSize;
            end
            % Grid Layout (add rows for header and footer if needed)
            this.GridLayout = uigridlayout(this.UIFigure,[3 1]);
            this.GridLayout.RowHeight = {'fit','1x','fit'};
            this.GridLayout.Scrollable = true;
            % Variable Widget
            this.VariableEditorPanel.Parent = this.GridLayout;
            variableWidgetContainer = getWidget(this.VariableEditorPanel);
            variableWidgetContainer.Layout.Row = 2;
        end
        
        function connectUI(this)
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(this.VariableEditorPanel,'VariableChanged',@(es,ed) cbVariableChanged(weakThis.Handle));
            registerUIListeners(this,L,'VariableChanged');
        end
    end
    
    methods (Access = private)
        function cbVariableChanged(this)
            notify(this,'VariableChanged');
        end
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.Header = this.HeaderWidget;
            widgets.Footer = this.FooterWidget;
            widgets.VariableWidget = getVariableWidget(this);
        end
    end
end

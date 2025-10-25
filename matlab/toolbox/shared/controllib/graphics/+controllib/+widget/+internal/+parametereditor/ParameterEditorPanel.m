classdef ParameterEditorPanel < controllib.ui.internal.dialog.AbstractContainer
    % Panel to edit or view array of parameters
    % (controllib.widget.internal.parametereditor.ParameterData)
    %
    % Example:
    %
    % data = [controllib.widget.internal.parametereditor.ParameterData("P1",param.Continuous('P1',[1 2 3])),...
    %         controllib.widget.internal.parametereditor.ParameterData("P2",param.Continuous('P2',[1 4; 9 16]))];
    % f = uifigure;
    % g = uigridlayout(f,[1 1]);
    % pnl = controllib.widget.internal.parametereditor.ParameterEditorPanel(data,...
    %         "ShowScale",true,"ShowFree",true,"ShowEstimate",true,"Parent",g);
    % pnl.TableWidth = 275;
    % getWidget(pnl);

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Access = protected)
        pnlContainingTable
        pnlParamEditor

        Data
        DropdownData

        Type % Either 'all' for all experiments or 'parameters'/'states' for a particular experiment
        ColumnSortable

        DialogObject       

        InitialValueVariableEditor
        MinimumVariableEditor
        MaximumVariableEditor
        ScaleVariableEditor
        FreeVariableEditor

        Widgets
    end

    % Public properties
    properties
        SelectedRow

        ShowScale
        ShowFree
        ShowEstimate

        Parent
        TableWidth = 230
        TableHeight = 155

        VariableEditorLocation
    end

    methods
        % Constructor
        function this = ParameterEditorPanel(data,optionalInputs)
            arguments
                data controllib.widget.internal.parametereditor.ParameterData = ...
                    controllib.widget.internal.variableeditor.ParameterData.empty
                optionalInputs.ShowScale (1,1) logical = false
                optionalInputs.ShowFree (1,1) logical = false
                optionalInputs.ShowEstimate (1,1) logical = true
                optionalInputs.Type string = "parameters"
                optionalInputs.Parent = []
                optionalInputs.VariableEditorLocation = []
                optionalInputs.ColumnSortable logical = true
            end
            this.Data                     = data;
            this.Type                     = optionalInputs.Type;
            this.ShowScale                = optionalInputs.ShowScale;
            this.ShowFree                 = optionalInputs.ShowFree;
            this.ShowEstimate             = optionalInputs.ShowEstimate;
            this.Parent                   = optionalInputs.Parent;
            this.VariableEditorLocation   = optionalInputs.VariableEditorLocation;
            this.SelectedRow  = 1;
            this.DropdownData = [];
            this.ColumnSortable = optionalInputs.ColumnSortable;
        end

        function update(this,data)
            arguments
                this
                data controllib.widget.internal.parametereditor.ParameterData
            end
            this.Data = data;
            createDropdownData(this);
            updateUI(this);
        end

        function updateUI(this)
            % Data to view sync
            updateEditorWidgets(this);
            updateTable(this);
            updateDropdownEntries(this);
        end

        function uit = getTable(this)
            % Return table with parameters
            if isfield(this.Widgets, 'ParametersTable')
                uit = this.Widgets.ParametersTable;
            else
                uit = [];
            end
        end

        function delete(this)
            localDeleteIfValid(this.InitialValueVariableEditor);
            localDeleteIfValid(this.MinimumVariableEditor);
            localDeleteIfValid(this.MaximumVariableEditor);
            localDeleteIfValid(this.ScaleVariableEditor);
            localDeleteIfValid(this.FreeVariableEditor);
        end
    end

    methods %Set/Get
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

        % TableWidth
        function set.TableWidth(this,TableWidth)
            if this.IsWidgetValid
                this.Widgets.ParametersTable.Parent.ColumnWidth = {TableWidth};
            end
            this.TableWidth = TableWidth;
        end

        % TableHeight
        function set.TableHeight(this,TableHeight)
            if this.IsWidgetValid
                this.Widgets.ParametersTable.Parent.RowHeight = {TableHeight};
            end
            this.TableHeight = TableHeight;
        end
    end

    methods (Access = protected)
        % Build panel 
        function pnl = createContainer(this)

            % Build components
            pnlWithTable = buildPanelContainingTable(this);
            pnlParamEdit = buildParamEditorPanel(this);
            buildVariableEditors(this);

            % Assign objects to properties
            this.pnlContainingTable = pnlWithTable;
            this.pnlParamEditor = pnlParamEdit;

            % Create top panel
            pnl = uigridlayout("Parent",this.Parent);
            pnl.RowHeight = {'fit'};
            pnl.ColumnWidth = {'fit', '1x'};
            pnl.Padding = 0;

            % Assign respective columns
            pnlWithTable.Parent = pnl;
            pnlWithTable.Layout.Column = 1;

            pnlParamEdit.Parent = pnl;
            pnlParamEdit.Layout.Column = 2;

            % Update
            updateUI(this);
        end

        function connectUI(this)
            % Connect widgets to listeners
            L = [addlistener(this.Widgets.ParametersTable,'CellSelection',@(es,ed) cbTableCellSelected(this,ed));...
                 addlistener(this.Widgets.DeleteButton,'ButtonPushed',@(es,ed)cbDeleteButtonPushed(this));...
                 addlistener(this.Widgets.EstimateCheckBox,'ValueChanged',@(es,ed)cbEstimateCheckboxValueChanged(this,ed));...
                 addlistener(this.Widgets.InitialValueDropDown,'ValueChanged',@(es,ed)cbInitialValueDropdownChanged(this,ed));...
                 addlistener(this.Widgets.MinimumDropDown,'ValueChanged',@(es,ed)cbMinimumDropdownChanged(this,ed));...
                 addlistener(this.Widgets.MaximumDropDown,'ValueChanged',@(es,ed)cbMaximumDropdownChanged(this,ed));...
                 addlistener(this.Widgets.ScaleDropDown,'ValueChanged',@(es,ed)cbScaleDropdownChanged(this,ed));...
                 addlistener(this.Widgets.FreeDropDown,'ValueChanged',@(es,ed)cbFreeDropdownChanged(this,ed));...
                 addlistener(this.Widgets.InitialValueButton,'ButtonPushed',@(es,ed)cbInitialValueButtonPushed(this));...
                 addlistener(this.Widgets.MinimumButton,'ButtonPushed',@(es,ed)cbMinimumButtonPushed(this));...
                 addlistener(this.Widgets.MaximumButton,'ButtonPushed',@(es,ed)cbMaximumButtonPushed(this));...
                 addlistener(this.Widgets.ScaleButton,'ButtonPushed',@(es,ed)cbScaleButtonPushed(this));...
                 addlistener(this.Widgets.FreeButton,'ButtonPushed',@(es,ed)cbFreeButtonPushed(this));...
                 addlistener(this.InitialValueVariableEditor,'VariableChanged',@(es,ed)cbInitialValueVariableChanged(this,ed));...
                 addlistener(this.MinimumVariableEditor,'VariableChanged',@(es,ed)cbMinimumVariableChanged(this,ed));...
                 addlistener(this.MaximumVariableEditor,'VariableChanged',@(es,ed)cbMaximumVariableChanged(this,ed));...
                 addlistener(this.ScaleVariableEditor,'VariableChanged',@(es,ed)cbScaleVariableChanged(this,ed));...
                 addlistener(this.FreeVariableEditor,'VariableChanged',@(es,ed)cbFreeVariableChanged(this,ed))];

            % Register UI listeners
            registerUIListeners(this,L);

            % Add data listeners
            L = addlistener(this.Data,'ParameterChanged',@(es,ed) updateUI(this));
            registerDataListeners(this,L,'ParameterChangedListener');

            % Add figure size changed listener
%             f = ancestor(getWidget(this),'figure');
%             if ~isempty(f)
%                 f.AutoResizeChildren = 'off';
%                 L = addlistener(f,'SizeChanged',@(es,ed) updateEditorWidgets(this));
%                 registerUIListeners(this,L,'FigureSizeChangedListener');
%             end
        end

        function pnlWithTable = buildPanelContainingTable(this)
            % Create widgets
            pnlWithTable = uigridlayout([1 1],'Parent',[]);
            pnlWithTable.Padding = zeros(1,4);
            pnlWithTable.RowHeight = {this.TableHeight};
            pnlWithTable.ColumnWidth = {this.TableWidth};
            % Create UITable
            ParametersTable = uitable(pnlWithTable);
            ParametersTable.ColumnEditable = false;
            ParametersTable.ColumnSortable = this.ColumnSortable;
            ParametersTable.SelectionType = 'row';
            ParametersTable.Multiselect = 'off';

            ParametersTable.RowName = {};
            ParametersTable.RowStriping = 'off';
            ParametersTable.Layout.Column = 1;

            % Store widgets
            this.Widgets.ParametersTable = ParametersTable; %#ok<*STRNU>
        end

        function pnlParamEdit = buildParamEditorPanel(this)
            % Create GridLayout
            pnlParamEdit = uigridlayout('Parent',[]);
            pnlParamEdit.Padding = zeros(1,4);
            pnlParamEdit.ColumnWidth = {'fit', '1x', 'fit'};
            pnlParamEdit.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit'};

            % Create ConfigureLabel
            ConfigureLabel = uilabel(pnlParamEdit,"Text",...
                [getString(message('Controllib:gui:strConfigure')),':']);
            ConfigureLabel.Layout.Row = 1;
            ConfigureLabel.Layout.Column = 1;
            ConfigureLabel.FontWeight = 'bold';
            ConfigureParameterLabel = uilabel(pnlParamEdit);
            ConfigureParameterLabel.Layout.Row = 1;
            ConfigureParameterLabel.Layout.Column = 2;
            
            % Create EstimateCheckBox
            EstimateCheckBox = uicheckbox(pnlParamEdit);
            EstimateCheckBox.Text = getString(message('sldo:dialogs:lblEstimatedParameters_Free'));
            EstimateCheckBox.Layout.Row = 2;
            EstimateCheckBox.Layout.Column = 1;
            
            % Create DeleteButton
            DeleteButton = uibutton(pnlParamEdit, 'push');
            DeleteButton.Layout.Row = 2;
            DeleteButton.Layout.Column = 3;
            DeleteButton.Text = '';
            DeleteButton.Icon = matlab.ui.internal.toolstrip.Icon.DELETE_24.getIconFile;
            
            if ~this.ShowEstimate
                % Unparent Estimate widgets
                EstimateCheckBox.Parent = [];
                DeleteButton.Parent = [];
            end

            % Create InitialValueDropDownLabel
            InitialValueDropDownLabel = uilabel(pnlParamEdit);
            InitialValueDropDownLabel.Layout.Row = 3;
            InitialValueDropDownLabel.Layout.Column = 1;
            InitialValueDropDownLabel.Text = getString(message('Controllib:gui:sentenceInitialValue'));

            % Create InitialValueDropDown
            InitialValueDropDown = uidropdown(pnlParamEdit);
            InitialValueDropDown.Layout.Row = 3;
            InitialValueDropDown.Layout.Column = 2;
            InitialValueDropDown.Editable = true;
            InitialValueDropDown.Items = {};

            % Create InitialValueButton
            InitialValueButton = uibutton(pnlParamEdit, 'push');
            InitialValueButton.Layout.Row = 3;
            InitialValueButton.Layout.Column = 3;
            InitialValueButton.Text = '';
            InitialValueButton.Icon = fullfile(matlabroot,'toolbox','shared','controllib',...
                'graphics','resources','Edit_Parameter_24.png');

            % Create MinimumDropDownLabel
            MinimumDropDownLabel = uilabel(pnlParamEdit);
            MinimumDropDownLabel.Layout.Row = 4;
            MinimumDropDownLabel.Layout.Column = 1;
            MinimumDropDownLabel.Text = getString(message('Controllib:gui:lblParameterEditor_Minimum'));

            % Create MinimumDropDown
            MinimumDropDown = uidropdown(pnlParamEdit);
            MinimumDropDown.Layout.Row = 4;
            MinimumDropDown.Layout.Column = 2;
            MinimumDropDown.Editable = true;
            MinimumDropDown.Items = {};

            % Create MinimumButton
            MinimumButton = uibutton(pnlParamEdit, 'push');
            MinimumButton.Layout.Row = 4;
            MinimumButton.Layout.Column = 3;
            MinimumButton.Text = '';
            MinimumButton.Icon = fullfile(matlabroot,'toolbox','shared','controllib',...
                'graphics','resources','Edit_Parameter_24.png');

            % Create MaximumDropDownLabel
            MaximumDropDownLabel = uilabel(pnlParamEdit);
            MaximumDropDownLabel.Layout.Row = 5;
            MaximumDropDownLabel.Layout.Column = 1;
            MaximumDropDownLabel.Text = getString(message('Controllib:gui:lblParameterEditor_Maximum'));

            % Create MaximumDropDown
            MaximumDropDown = uidropdown(pnlParamEdit);
            MaximumDropDown.Layout.Row = 5;
            MaximumDropDown.Layout.Column = 2;
            MaximumDropDown.Editable = true;
            MaximumDropDown.Items = {};

            % Create MaximumButton
            MaximumButton = uibutton(pnlParamEdit, 'push');
            MaximumButton.Layout.Row = 5;
            MaximumButton.Layout.Column = 3;
            MaximumButton.Text = '';
            MaximumButton.Icon = fullfile(matlabroot,'toolbox','shared','controllib',...
                'graphics','resources','Edit_Parameter_24.png');

            % Create ScaleDropDownLabel
            ScaleDropDownLabel = uilabel(pnlParamEdit);
            ScaleDropDownLabel.Layout.Row = 6;
            ScaleDropDownLabel.Layout.Column = 1;
            ScaleDropDownLabel.Text = getString(message('Controllib:gui:lblParameterEditor_Scale'));

            % Create ScaleDropDown
            ScaleDropDown = uidropdown(pnlParamEdit);
            ScaleDropDown.Layout.Row = 6;
            ScaleDropDown.Layout.Column = 2;
            ScaleDropDown.Editable = true;
            ScaleDropDown.Items = {};

            % Create ScaleButton
            ScaleButton = uibutton(pnlParamEdit, 'push');
            ScaleButton.Layout.Row = 6;
            ScaleButton.Layout.Column = 3;
            ScaleButton.Text = '';
            ScaleButton.Icon = fullfile(matlabroot,'toolbox','shared','controllib',...
                'graphics','resources','Edit_Parameter_24.png');
            if ~this.ShowScale
                % Unparent Scale widgets
                ScaleDropDownLabel.Parent = [];
                ScaleDropDown.Parent = [];
                ScaleButton.Parent = [];
            end

            % Create FreeDropDownLabel
            FreeDropDownLabel = uilabel(pnlParamEdit);
            FreeDropDownLabel.Layout.Row = 7;
            FreeDropDownLabel.Layout.Column = 1;
            FreeDropDownLabel.Text = getString(message('Controllib:gui:lblParameterEditor_Free'));

            % Create ScaleDropDown
            FreeDropDown = uidropdown(pnlParamEdit);
            FreeDropDown.Layout.Row = 7;
            FreeDropDown.Layout.Column = 2;
            FreeDropDown.Editable = true;
            FreeDropDown.Items = {};

            % Create ScaleButton
            FreeButton = uibutton(pnlParamEdit, 'push');
            FreeButton.Layout.Row = 7;
            FreeButton.Layout.Column = 3;
            FreeButton.Text = '';
            FreeButton.Icon = fullfile(matlabroot,'toolbox','shared','controllib',...
                'graphics','resources','Edit_Parameter_24.png');
            
            if ~this.ShowFree
                % Unparent Scale widgets
                FreeDropDownLabel.Parent = [];
                FreeDropDown.Parent = [];
                FreeButton.Parent = [];
            end

            % Store widgets
            this.Widgets.ConfigureLabel = ConfigureLabel;
            this.Widgets.ConfigureParameterLabel = ConfigureParameterLabel;
            this.Widgets.EstimateCheckBox = EstimateCheckBox;
            this.Widgets.DeleteButton = DeleteButton;
            this.Widgets.InitialValueDropDownLabel = InitialValueDropDownLabel;
            this.Widgets.InitialValueDropDown = InitialValueDropDown;
            this.Widgets.InitialValueButton = InitialValueButton;
            this.Widgets.MinimumDropDownLabel = MinimumDropDownLabel;
            this.Widgets.MinimumDropDown = MinimumDropDown;
            this.Widgets.MinimumButton = MinimumButton;
            this.Widgets.MaximumDropDownLabel = MaximumDropDownLabel;
            this.Widgets.MaximumDropDown = MaximumDropDown;
            this.Widgets.MaximumButton = MaximumButton;
            this.Widgets.ScaleDropDownLabel = ScaleDropDownLabel;
            this.Widgets.ScaleDropDown = ScaleDropDown;
            this.Widgets.ScaleButton = ScaleButton;
            this.Widgets.FreeDropDownLabel = FreeDropDownLabel;
            this.Widgets.FreeDropDown = FreeDropDown;
            this.Widgets.FreeButton = FreeButton;
        end

        function buildVariableEditors(this)
            % Build the variable editors
            this.InitialValueVariableEditor = ...
                controllib.widget.internal.variableeditor.VariableEditorDialog(...
                'InitialValue',1,'Editable',true,'DialogSize',[400 200]);
            this.MinimumVariableEditor = ...
                controllib.widget.internal.variableeditor.VariableEditorDialog(...
                'Minimum',-Inf,'Editable',true,'DialogSize',[400 200]);
            this.MaximumVariableEditor = ...
                controllib.widget.internal.variableeditor.VariableEditorDialog(...
                'Maximum',Inf,'Editable',true,'DialogSize',[400 200]);
            this.ScaleVariableEditor = ...
                controllib.widget.internal.variableeditor.VariableEditorDialog(...
                'Scale',1,'Editable',true,'DialogSize',[400 200]);
            this.FreeVariableEditor = ...
                controllib.widget.internal.variableeditor.VariableEditorDialog(...
                'Free',true,'Editable',true,'DialogSize',[400 200]);
        end

        function parameters = getAllParameters(this)
           % Returns all parameters of a particular type from the TCPeer
           parameters = this.Data;
        end
    end

    % Callbacks
    methods (Access = protected)

        function cbTableCellSelected(this,ed)
            % Callback when table cell is selected
            drawnow;
            if isempty(ed.Indices)
                this.Widgets.ParametersTable.Selection = this.SelectedRow;
            else
                this.SelectedRow = ed.Indices(1);
            end
            updateUI(this);
        end

        function cbDeleteButtonPushed(this)
            %CBDELETEPARAMETER Manage parameter deletion events
            if ~isempty(this.Data)
                index = this.SelectedRow;
                this.SelectedRow = max(1, this.SelectedRow - 1);
                this.Data(index) = [];
                updateUI(this);
            end
        end

        function cbEstimateCheckboxValueChanged(this,ed)
            % Callback when estimate checkbox is toggled
            value = ed.Value;
            
            if ~isempty(this.SelectedRow)
                % Fetch TC parameter
                parameter = getSpecificParameter(this,this.SelectedRow);
                parameter.Free = value;
                updateUI(this);
            end
        end

        function cbInitialValueDropdownChanged(this,ed)
            % Callback when value in 'Initial Value' dropdown is changed
            helperDropdownChanged(this,ed.Value,'Value',2);
        end         

        function cbMinimumDropdownChanged(this,ed)
            % Callback when value in 'Minimum' dropdown is changed
            helperDropdownChanged(this,ed.Value,'Minimum',3);
        end       

        function cbMaximumDropdownChanged(this,ed)
            % Callback when value in 'Minimum' dropdown is changed
            helperDropdownChanged(this,ed.Value,'Maximum',4);
        end       

        function cbScaleDropdownChanged(this,ed)
            % Callback when value in 'Scale' dropdown is changed
            helperDropdownChanged(this,ed.Value,'Scale',5);
        end

        function cbFreeDropdownChanged(this,ed)
            % Callback when value in 'Scale' dropdown is changed
            helperDropdownChanged(this,ed.Value,'Free',6);
        end  

        function cbInitialValueButtonPushed(this)
            % Change pointer to busy
            currentPointer = controllib.widget.internal.utils.setPointer(getParentFigure(this),'watch');
            drawnow('nocallbacks');
            % Callback when Initial Value Button is pushed
            this.InitialValueVariableEditor.VariableValue = evalin('base',this.Widgets.InitialValueDropDown.Items{1});
            data = getSpecificParameter(this,this.SelectedRow);
            this.InitialValueVariableEditor.Title = ...
                getString(message('Controllib:gui:strEditParameter')) + " - " + data.Name + ".Value";
            if isempty(this.VariableEditorLocation) || this.InitialValueVariableEditor.IsWidgetValid
                show(this.InitialValueVariableEditor);
            else
                show(this.InitialValueVariableEditor,getParentFigure(this),this.VariableEditorLocation);
            end
            % Add listener to update variable editor
            L = addlistener(data,'ParameterChanged',...
                @(es,ed) localInitialValueChanged(es,this.InitialValueVariableEditor));
            registerDataListeners(this,L,'InitialValueChanged');
            function localInitialValueChanged(es,dlg)
                dlg.VariableValue = es.Value;
            end
            % Change pointer back
            controllib.widget.internal.utils.setPointer(getParentFigure(this),currentPointer);
            drawnow('nocallbacks');
        end

        function cbMinimumButtonPushed(this)
            % Change pointer to busy
            currentPointer = controllib.widget.internal.utils.setPointer(getParentFigure(this),'watch');
            drawnow('nocallbacks');
            % Callback when Minimum Button is pushed
            this.MinimumVariableEditor.VariableValue = evalin('base',this.Widgets.MinimumDropDown.Items{1});
            data = getSpecificParameter(this,this.SelectedRow);
            this.MinimumVariableEditor.Title = ...
                getString(message('Controllib:gui:strEditParameter')) + " - " + data.Name + ".Minimum";
            if isempty(this.VariableEditorLocation) || this.MinimumVariableEditor.IsWidgetValid
                show(this.MinimumVariableEditor);
            else
                show(this.MinimumVariableEditor,getParentFigure(this),this.VariableEditorLocation);
            end
            % Add listener to update variable editor
            L = addlistener(data,'ParameterChanged',...
                @(es,ed) localMinimumValueChanged(es,this.MinimumVariableEditor));
            registerDataListeners(this,L,'MinimumChanged');
            function localMinimumValueChanged(es,dlg)
                dlg.VariableValue = es.Minimum;
            end
            % Change pointer back
            controllib.widget.internal.utils.setPointer(getParentFigure(this),currentPointer);
            drawnow('nocallbacks');
        end

        function cbMaximumButtonPushed(this)
            % Change pointer to busy
            currentPointer = controllib.widget.internal.utils.setPointer(getParentFigure(this),'watch');
            drawnow('nocallbacks');
            % Callback when Maximum Button is pushed
            this.MaximumVariableEditor.VariableValue = evalin('base',this.Widgets.MaximumDropDown.Items{1});
            data = getSpecificParameter(this,this.SelectedRow);
            this.MaximumVariableEditor.Title = ...
                getString(message('Controllib:gui:strEditParameter')) + " - " + data.Name + ".Maximum";
            if isempty(this.VariableEditorLocation) || this.MaximumVariableEditor.IsWidgetValid
                show(this.MaximumVariableEditor);
            else
                show(this.MaximumVariableEditor,getParentFigure(this),this.VariableEditorLocation);
            end
            % Add listener to update variable editor
            L = addlistener(data,'ParameterChanged',...
                @(es,ed) localMaximumValueChanged(es,this.MaximumVariableEditor));
            registerDataListeners(this,L,'MaximumChanged');
            function localMaximumValueChanged(es,dlg)
                dlg.VariableValue = es.Maximum;
            end
            % Change pointer back
            controllib.widget.internal.utils.setPointer(getParentFigure(this),currentPointer);
            drawnow('nocallbacks');
        end

        function cbScaleButtonPushed(this)
            % Change pointer to busy
            currentPointer = controllib.widget.internal.utils.setPointer(getParentFigure(this),'watch');
            drawnow('nocallbacks');
            % Callback when Scale Button is pushed
            this.ScaleVariableEditor.VariableValue = evalin('base',this.Widgets.ScaleDropDown.Items{1});
            data = getSpecificParameter(this,this.SelectedRow);
            this.ScaleVariableEditor.Title = ...
                getString(message('Controllib:gui:strEditParameter')) + " - " + data.Name + ".Scale";
            if isempty(this.VariableEditorLocation) || this.ScaleVariableEditor.IsWidgetValid
                show(this.ScaleVariableEditor);
            else
                show(this.ScaleVariableEditor,getParentFigure(this),this.VariableEditorLocation);
            end
            % Add listener to update variable editor
            L = addlistener(data,'ParameterChanged',...
                @(es,ed) localScaleChanged(es,this.ScaleVariableEditor));
            registerDataListeners(this,L,'MaximumChanged');
            function localScaleChanged(es,dlg)
                dlg.VariableValue = es.Scale;
            end
            % Change pointer back
            controllib.widget.internal.utils.setPointer(getParentFigure(this),currentPointer);
            drawnow('nocallbacks');
        end

        function cbFreeButtonPushed(this)
            % Change pointer to busy
            currentPointer = controllib.widget.internal.utils.setPointer(getParentFigure(this),'watch');
            drawnow('nocallbacks');
            % Callback when Free Button is pushed
            this.FreeVariableEditor.VariableValue = evalin('base',this.Widgets.FreeDropDown.Items{1});
            data = getSpecificParameter(this,this.SelectedRow);
            this.FreeVariableEditor.Title = ...
                getString(message('Controllib:gui:strEditParameter')) + " - " + data.Name + ".Free";
            if isempty(this.VariableEditorLocation) || this.FreeVariableEditor.IsWidgetValid
                show(this.FreeVariableEditor);
            else
                show(this.FreeVariableEditor,getParentFigure(this),this.VariableEditorLocation);
            end
            % Add listener to update variable editor
            L = addlistener(data,'ParameterChanged',...
                @(es,ed) localFreeChanged(es,this.FreeVariableEditor));
            registerDataListeners(this,L,'MaximumChanged');
            function localFreeChanged(es,dlg)
                dlg.VariableValue = es.Free;
            end
            % Change pointer back
            controllib.widget.internal.utils.setPointer(getParentFigure(this),currentPointer);
            drawnow('nocallbacks');
        end

        function cbInitialValueVariableChanged(this,ed)
            % Callback when variable is changed in InitialValueVariableEditor
            value = mat2str(ed.Source.VariableValue);
            helperDropdownChanged(this,value,'Value',2);
        end

        function cbMinimumVariableChanged(this,ed)
            % Callback when variable is changed in MinimumVariableEditor
            value = mat2str(ed.Source.VariableValue);
            helperDropdownChanged(this,value,'Minimum',3);
        end

        function cbMaximumVariableChanged(this,ed)
            % Callback when variable is changed in MaximumVariableEditor
            value = mat2str(ed.Source.VariableValue);
            helperDropdownChanged(this,value,'Maximum',4);
        end

        function cbScaleVariableChanged(this,ed)
            % Callback when variable is changed in MaximumVariableEditor
            value = mat2str(ed.Source.VariableValue);
            helperDropdownChanged(this,value,'Scale',5);
        end

        function cbFreeVariableChanged(this,ed)
            % Callback when variable is changed in MaximumVariableEditor
            value = mat2str(ed.Source.VariableValue);
            helperDropdownChanged(this,value,'Free',6);
        end
        
        function helperDropdownChanged(this,value,type,index)
           % Helper for changes in dropdown values
            try
                value = evalin('base',value);
                
                % Fetch TC parameter
                parameter = getSpecificParameter(this,this.SelectedRow);
                
                % Evaluate data Value and set it
                disableDataListeners(this);
                parameter.(type) = value;
                enableDataListeners(this);
                modifyDropdownDataItems(this,index,value);
                updateUI(this);
            catch
                updateUI(this);
                resetVariableEditorValues(this);
                return;
            end
        end
    end

    % Helper methods
    methods (Access = protected)

        function updateEditorWidgets(this)
            % Update editor widgets based on data
            disableUIListeners(this,'FigureSizeChangedListener');
            drawnow;
            % Different experiments may have different number of active
            % parameters. This is to safeguard against a scenario where
            % this.SelectedRow exceeds the number of active parameters.
            numberOfParameters = getNumberOfParameters(this);
            if numberOfParameters < this.SelectedRow
                this.SelectedRow = numberOfParameters;
            end
            if numberOfParameters > 0
                data = getSpecificParameter(this,this.SelectedRow);
                if this.ShowEstimate
                    this.Widgets.EstimateCheckBox.Value = any(data.Free(:));
                end

                this.Widgets.ConfigureParameterLabel.Text = data.Name;

                maxLength = floor(this.Widgets.InitialValueDropDown.Position(3)/7);
                this.Widgets.InitialValueDropDown.Value = ...
                    localComputeValueForDropdown(data.Value,maxLength);
                this.Widgets.MinimumDropDown.Value = ...
                    localComputeValueForDropdown(data.Minimum,maxLength);
                this.Widgets.MaximumDropDown.Value = ...
                    localComputeValueForDropdown(data.Maximum,maxLength);
                if this.ShowScale
                    this.Widgets.ScaleDropDown.Value = ...
                        localComputeValueForDropdown(data.Scale,maxLength);
                end
                this.Widgets.FreeDropDown.Value = mat2str(data.Free);
                enableUIListeners(this,'FigureSizeChangedListener');
            else
                if this.ShowEstimate
                    this.Widgets.EstimateCheckBox.Value = false;
                end
                this.Widgets.ConfigureParameterLabel.Text = '';
                this.Widgets.InitialValueDropDown.Value = '';
                this.Widgets.MinimumDropDown.Value = '';
                this.Widgets.MaximumDropDown.Value = '';
                if this.ShowScale
                    this.Widgets.ScaleDropDown.Value = '';
                end
                this.Widgets.FreeDropDown.Value = '';
            end
        end

        function updateTable(this)
            % Update table based on data
            numberOfParameters = getNumberOfParameters(this);
            if this.ShowEstimate
                variableNames = {getParameterLabel(this),...
                     getString(message('Controllib:gui:sentenceInitialValue')),...
                     getString(message('sldo:dialogs:lblEstimatedParameters_Free'))};
                cellData = cell(numberOfParameters,3);
            else
                variableNames = {getParameterLabel(this),...
                     getString(message('Controllib:gui:sentenceInitialValue'))};
                cellData = cell(numberOfParameters,2);
            end
            
            for i = 1:numberOfParameters
                data = getSpecificParameter(this,i);
                cellData{i,1} = data.Name;
                cellData{i,2} = data.Value;    
                if this.ShowEstimate
                    cellData{i,3} = computeEstimateString(this,data.Free);
                end
            end
            
            this.Widgets.ParametersTable.Data = cell2table(cellData,"VariableNames",variableNames);
            if numberOfParameters > 0
                this.Widgets.ParametersTable.Selection = this.SelectedRow;
            end

        end

        function param = getSpecificParameter(this,index)
            param = this.Data(index);
        end

        function numberOfParameters = getNumberOfParameters(this)
            % Compute number of parameters
            numberOfParameters = numel(this.Data);
        end

        function label = getParameterLabel(this)
            % Fetch label of parameters to be used in table
            switch this.Type
                case 'all'
                    label = getString(message('Controllib:gui:strParameters'));
                case 'states'
                    label = getString(message('sldo:dialogs:lblStateSelector_State'));
                case 'parameters'
                    label = getString(message('Controllib:gui:strParameters'));
            end
        end

        function estimateString = computeEstimateString(~,free)
            % Fetch string to be pushed into entry in table
            if all(free)
                estimateString = getString(message('sldo:dialogs:lblYes'));
            else
                estimateString = getString(message('sldo:dialogs:lblNo'));
            end
        end

        function updateDropdownEntries(this)
            % Update 'DropdownData' property

            updateDropdownData(this);
            if ~isempty(this.Data)
                updateDropdownItems(this);
            end
        end

        function updateDropdownData(this)
            % Update 'DropdownData' property

            if isempty(this.DropdownData) || isempty(this.Data)
                createDropdownData(this);
            else
                addEntryToDropdownData(this);
            end
        end

        function updateDropdownItems(this)
            % Update dropdown widgets
            index = findEntryFromTableForDropdownUpdate(this);
            this.Widgets.InitialValueDropDown.Items = this.DropdownData{index,2};
            this.Widgets.MinimumDropDown.Items = this.DropdownData{index,3};
            this.Widgets.MaximumDropDown.Items = this.DropdownData{index,4};
            if this.ShowScale
                this.Widgets.ScaleDropDown.Items = this.DropdownData{index,5};
            end
            this.Widgets.FreeDropDown.Items = this.DropdownData{index,6};
        end

        function createDropdownData(this)
            % Create 'DropdownData' property

            numberOfParameters = getNumberOfParameters(this);
            this.DropdownData = cell(numberOfParameters,6);

            for i = 1:numberOfParameters
                data = getSpecificParameter(this,i);
                setDropDownData(this,data,i);
            end
        end

        function addEntryToDropdownData(this)
            % Add entry to 'DropdownData', if already not present

            numberOfParameters = getNumberOfParameters(this);
            for i = 1:numberOfParameters
                data = getSpecificParameter(this,i);

                % Check if this variable exists in dropdown entry
                dropdownItemsName = this.DropdownData(:,1);
                index = find(strcmpi(dropdownItemsName,data.Name)); %#ok<*EFIND>

                if isempty(index)
                    % If not, then add it to 'DropdownData'
                    index = numel(dropdownItemsName) + 1;
                    setDropDownData(this,data,index);
                end
            end
        end

        function setDropDownData(this,data,index)
            % Set 'DropdownData' (Add to existing data)
            this.DropdownData{index,1} = data.Name;
            this.DropdownData{index,2} = {mat2str(data.Value)};
            this.DropdownData{index,3} = {mat2str(data.Minimum)};
            this.DropdownData{index,4} = {mat2str(data.Maximum)};
            if this.ShowScale
                this.DropdownData{index,5} = {mat2str(data.Scale)};
            end
            this.DropdownData{index,6} = {mat2str(data.Free)};
        end

        function index = findEntryFromTableForDropdownUpdate(this)
            % Find index of entry in 'DropdownData' by comparing it with name
            % of parameter from 'SelectedRow'
            nameOfEntry = this.Widgets.ParametersTable.Data{this.SelectedRow,1};
            dropdownItemsName = this.DropdownData(:,1);

            index = find(strcmpi(nameOfEntry,dropdownItemsName));
        end

        function  modifyDropdownDataItems(this,columnIndex,value)
            % When callbacks add a new value, add it to the respective entry
            % in 'DropdownData'
            value = {mat2str(value)};
            entryIndex = findEntryFromTableForDropdownUpdate(this);

            dropdownDataItems = this.DropdownData{entryIndex,columnIndex};
            dropdownDataItems = unique([value dropdownDataItems],'stable');

            this.DropdownData{entryIndex,columnIndex} = dropdownDataItems;
        end
        
        function resetVariableEditorValues(this)
           % Reset variable editor values according to valuue of TC Peer
           this.InitialValueVariableEditor.VariableValue = evalin('base',this.Widgets.InitialValueDropDown.Value);
           this.MinimumVariableEditor.VariableValue = evalin('base',this.Widgets.MinimumDropDown.Value);
           this.MaximumVariableEditor.VariableValue = evalin('base',this.Widgets.MaximumDropDown.Value);
           if this.ShowScale
               this.ScaleVariableEditor.VariableValue = evalin('base',this.Widgets.ScaleDropDown.Value);
           end
           this.FreeVariableEditor.VariableValue = evalin('base',this.Widgets.FreeDropDown.Value);
        end

        function fig = getParentFigure(this)
            fig = ancestor(getWidget(this),'figure');
        end
    end
    
    % QE Helper methods
    methods (Hidden = true)
       function tcpeer = qeGetTCPeer(this)
          tcpeer = this.Data;
       end
       
       function varEditors = qeGetVariableEditors(this)
        varEditors.InitialValueVariableEditor = this.InitialValueVariableEditor;
        varEditors.MinimumVariableEditor = this.MinimumVariableEditor;
        varEditors.MaximumVariableEditor = this.MaximumVariableEditor;
        varEditors.ScaleVariableEditor  = this.ScaleVariableEditor;
        varEditors.FreeVariableEditor = this.FreeVariableEditor;
       end
        
       function widgets = qeGetWidgets(this)
           widgets = this.Widgets;
       end
    end
end

function localDeleteIfValid(obj)
if ~isempty(obj) && isvalid(obj)
    delete(obj);
end
end

function strValue = localComputeValueForDropdown(value,maxLength)
strValue = mat2str(double(string(value)));
if length(strValue) >= maxLength
    dim = size(value);
    strValue = ['<',num2str(dim(1)),' x ',num2str(dim(2)),' double>'];
end
end

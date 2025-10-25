classdef ArraySelectorDialog < controllib.ui.internal.dialog.AbstractDialog & ...
        matlab.mixin.SetGet
    % FrequencyInputDialog
    %
    % dlg = controllib.chart.internal.widget.FrequencyInputDialog(System=sys)

    % Copyright 2022 The MathWorks, Inc.

    %% Properties
    properties (GetAccess=public,SetAccess=private)
        SystemNames
        ArrayDimensions
        CharacteristicBoundsExpression  string
    end

    properties (Dependent)
        SelectedSystem                  string
        SelectedIndices
        ArrayIndicesToShow
        IsIndexSelectionEnabled
        ShowMode
    end

    properties (Access = private)
        SelectedSystemIdx
        AllArrayDimensions

        GridLayout
        SystemDropDown                      matlab.ui.control.DropDown
        SelectionCriteriaListBox            matlab.ui.control.ListBox

        IndexSelectionLayout
        SelectIndicesListBox                matlab.ui.control.ListBox
        SelectIndicesEditField              matlab.ui.control.EditField
        ShowModeDropDown                    matlab.ui.control.DropDown

        CharacteristicBoundsLayout
        CharacteristicBoundsCheckbox    matlab.ui.control.CheckBox
        CharacteristicBoundsEditfield   matlab.ui.control.EditField

        MessagePanel
        ButtonPanel                     controllib.widget.internal.buttonpanel.ButtonPanel
        
        ShowMode_I
        SelectedSystem_I
        SelectedIndices_I
        CharacteristicLabels            string
        CharacteristicTags              string

        CommittedSystemIdx
    end

    events
        ArraySelectionChanged
    end

    %% Public methods
    methods
        function this = ArraySelectorDialog(systemNames,systemDimensions,optionalArguments)
            arguments
                systemNames (1,:) string = ""
                systemDimensions cell = {[2 1]}
                optionalArguments.Systems controllib.chart.internal.foundation.BaseResponse = ...
                    controllib.chart.internal.foundation.BaseResponse.empty
                optionalArguments.CharacteristicLabels string = string.empty
                optionalArguments.CharacteristicTags string = string.empty
            end
            this.Title = getString(message('Controllib:gui:strModelSelectorForLTIArrays'));

            if isempty(optionalArguments.Systems)
                this.SystemNames = string(systemNames);
                this.AllArrayDimensions = systemDimensions;
            else
                n = length(optionalArguments.Systems);
                this.SystemNames = repmat("",1,n);
                this.AllArrayDimensions = cell(1,n);
                for k = 1:n
                    this.SystemNames(k) = optionalArguments.Systems(k).Name;
                    this.AllArrayDimensions{k} = size(optionalArguments.Systems(k).ArrayVisible);
                end
            end
            this.SelectedSystem_I = this.SystemNames(1);
            
            this.ShowMode_I = repmat("selected",1,length(this.SystemNames));

            this.SelectedIndices_I = cell(1,length(this.AllArrayDimensions));
            for k = 1:length(this.AllArrayDimensions)
                for k2 = 1:length(this.AllArrayDimensions{k})
                    this.SelectedIndices_I{k}{k2} = 1:this.AllArrayDimensions{k}(k2);
                end
            end

            this.CharacteristicLabels = optionalArguments.CharacteristicLabels;
            this.CharacteristicBoundsExpression = repmat("",1,length(optionalArguments.CharacteristicLabels));
            this.CharacteristicTags = optionalArguments.CharacteristicTags;

            this.CloseMode = "destroy";
        end

        function updateUI(this)
            this.SystemDropDown.Value = this.SelectedSystem_I;
            this.ShowModeDropDown.Value = this.ShowMode_I(this.CommittedSystemIdx);
            cbShowModeDropDownValueChanged(this);

            if this.IsIndexSelectionEnabled
                % Update listbox and editfield widgets based on DimensionSelected property value
                updateSelectIndicesEditField(this);
                updateSelectIndicesListBox(this);
            else
                % Set DimensionSelected to empty and update character bound expressions
            end
        end

        function isTrue = isCharacteristicWithinBounds(this,tag,value)
            arguments
                this
                tag (1,1) string
                value double
            end

            isTrue = true(size(value));
            idx = find(this.CharacteristicTags==tag);
            if this.CharacteristicBoundsCheckbox(idx).Value && this.CharacteristicBoundsExpression(idx)~=""
                value = value(:);
                expression = this.CharacteristicBoundsExpression(idx);
                for k = 1:length(value)
                    isTrue(k) = eval(replace(expression,"$",string(value(k))));
                end
            end
        end

        function updateCharacteristicLabel(this,tag,label)
            idx = find(this.CharacteristicTags==tag);
            this.CharacteristicLabels(idx) = label;
            if this.IsWidgetValid
                this.CharacteristicBoundsCheckbox(idx).Text = label;
            end
        end
    end

    methods %set/get
        % IsIndexSelectionEnabled
        function IsIndexSelectionEnabled = get.IsIndexSelectionEnabled(this)
            % Flag specifying if selection criteria is based on indices for
            % each dimension or is based on bounds for characteristic values
            IsIndexSelectionEnabled = strcmp(this.SelectionCriteriaListBox.Value,'dimensionIndex');
        end

        % SelectedSystem
        function SelectedSystem = get.SelectedSystem(this)
            SelectedSystem = this.SelectedSystem_I;
        end
        
        % SelectedIndices
        function SelectedIndices = get.SelectedIndices(this)
            if strcmp(this.ShowMode,'all')
                SelectedIndices = this.SelectedIndices_I{this.CommittedSystemIdx};
                for k = 1:length(this.ArrayDimensions)
                    SelectedIndices{k} = 1:this.ArrayDimensions(k);
                end
            else
                SelectedIndices = this.SelectedIndices_I{this.CommittedSystemIdx};
            end
            
        end

        % SelectionMode
        function ShowMode = get.ShowMode(this)
            ShowMode = this.ShowMode_I(this.CommittedSystemIdx);
        end

        % ArrayIndicesToShow
        function ArrayIndicesToShow = get.ArrayIndicesToShow(this)
            if strcmp(this.ShowMode,'unselected')
                ArrayIndicesToShow = cell(1,length(this.ArrayDimensions));
                for k = 1:length(this.ArrayDimensions)
                    if this.ArrayDimensions(k) == 1
                        % If dimension has one element, then cannot be unselected.
                        ArrayIndicesToShow{k} = this.ArrayDimensions(k);
                    else
                        ArrayIndicesToShow{k} = setdiff(1:this.ArrayDimensions(k),this.SelectedIndices{k});
                    end
                end
            else
                ArrayIndicesToShow = this.SelectedIndices;
            end
        end

        function SelectedSystemIdx = get.SelectedSystemIdx(this)
            if this.IsWidgetValid
                SelectedSystemIdx = find(this.SystemDropDown.Value == this.SystemNames);
            else
                SelectedSystemIdx = 1;
            end
        end

        function ArrayDimensions = get.ArrayDimensions(this)
            ArrayDimensions = this.AllArrayDimensions{this.SelectedSystemIdx};
        end
    end

    %% Protected methods
    methods (Access = protected)
        function buildUI(this)
            gridLayout = uigridlayout(this.UIFigure,[3 2],RowHeight={'1x','fit','fit'},ColumnWidth={'fit','1x'});
            gridLayout.Scrollable = true;
            this.GridLayout = gridLayout;

            % Create left column
            leftColumnLayout = uigridlayout(gridLayout,[4 2],...
                RowHeight={'fit','fit','1x'},ColumnWidth={'fit','1x'},Padding=[0 10 10 0]);

            % Create system label and dropdown
            systemLabel = uilabel(leftColumnLayout,Text=getString(message('Controllib:gui:lblArrays')));
            systemLabel.FontWeight = 'bold';
            systemLabel.Layout.Row = 1;
            systemLabel.Layout.Column = 1;
            systemDropdown = uidropdown(leftColumnLayout,Items=this.SystemNames);
            systemDropdown.Value = this.SelectedSystem_I;
            this.CommittedSystemIdx = 1;
            systemDropdown.Layout.Row = 1;
            systemDropdown.Layout.Column = 2;
            this.SystemDropDown = systemDropdown;

            % Selection criteria
            selectionLabel = uilabel(leftColumnLayout,Text=getString(message('Controllib:gui:strSelectionCriteria')));
            selectionLabel.FontWeight = 'bold';
            selectionLabel.Layout.Row = 2;
            selectionLabel.Layout.Column = [1 2];

            % Selection criteria list box
            selectionListbox = uilistbox(leftColumnLayout);
            selectionListbox.Items = {getString(message('Controllib:gui:strIndexIntoDimensions')),...
                getString(message('Controllib:gui:strBoundOnCharacteristics'))};
            selectionListbox.ItemsData = {'dimensionIndex','characteristicBounds'};
            selectionListbox.Layout.Row = 3;
            selectionListbox.Layout.Column = [1 2];
            this.SelectionCriteriaListBox = selectionListbox;

            % Selection criteria setup
            rightColumnLayout = uigridlayout(gridLayout,[2 1],RowHeight={'fit','1x','fit'},...
                ColumnWidth={'fit','1x'},Padding=[10 10 0 0]);
            rightColumnLayout.Scrollable = true;
            selectionCriteriaLabel = uilabel(rightColumnLayout,...
                Text=getString(message('Controllib:gui:strSelectionCriterionSetup')));
            selectionCriteriaLabel.FontWeight = 'bold';
            selectionCriteriaLabel.Layout.Row = 1;
            selectionCriteriaLabel.Layout.Column = 1;

            % Selection criteria dropdown
            showModeDropDown = uidropdown(rightColumnLayout);
            showModeDropDown.Items = {getString(message('Controllib:gui:strShowAll')),...
                getString(message('Controllib:gui:strShowSelected')),...
                getString(message('Controllib:gui:strHideSelected'))};
            showModeDropDown.ItemsData = ["all","selected","unselected"];
            showModeDropDown.Value = this.ShowMode_I(this.SelectedSystemIdx);
            showModeDropDown.Layout.Row = 1;
            showModeDropDown.Layout.Column = 2;
            this.ShowModeDropDown = showModeDropDown;

            % Dimension Selection Layout
            indexSelectionLayout = uigridlayout(rightColumnLayout,Padding=0);
            indexSelectionLayout.RowHeight={'fit',100,'fit'};
            indexSelectionLayout.ColumnWidth = repmat(70,1,length(this.ArrayDimensions));
            indexSelectionLayout.Layout.Row = 2;
            indexSelectionLayout.Layout.Column = [1 2];
            this.IndexSelectionLayout = indexSelectionLayout;
            
            % Dimension selection widgets
            buildDimensionSelectionWidgets(this);

            % Characteristic Bounds
            this.CharacteristicBoundsLayout = uigridlayout(rightColumnLayout,Padding=0,Visible='off');
            this.CharacteristicBoundsLayout.Layout.Row = 2;
            this.CharacteristicBoundsLayout.Layout.Column = [1 2];
            if ~isempty(this.CharacteristicLabels)
                % Create as many rows as number of characteristics
                nCharacteristics = length(this.CharacteristicLabels);
                this.CharacteristicBoundsLayout.RowHeight = repmat({'fit'},1,nCharacteristics);
                this.CharacteristicBoundsLayout.ColumnWidth = {'fit','1x'};
                for k = 1:nCharacteristics
                    % Checkboxes
                    characteristicBoundsCheckbox = uicheckbox(this.CharacteristicBoundsLayout);
                    characteristicBoundsCheckbox.Text = this.CharacteristicLabels(k);
                    characteristicBoundsCheckbox.Layout.Row = k;
                    characteristicBoundsCheckbox.Layout.Column = 1;
                    this.CharacteristicBoundsCheckbox(k) = handle(characteristicBoundsCheckbox);

                    % Editfields
                    characteristicBoundsEditField = uieditfield(this.CharacteristicBoundsLayout);
                    characteristicBoundsEditField.Layout.Row = k;
                    characteristicBoundsEditField.Layout.Column = 2;
                    characteristicBoundsEditField.Enable = false;
                    characteristicBoundsEditField.Value = this.CharacteristicBoundsExpression(k);
                    this.CharacteristicBoundsEditfield(k) = characteristicBoundsEditField;
                end
            end
            

            % MessagePanel
            messagePanel = uitextarea(gridLayout,Value=getString(message('Controllib:gui:strShowSelectedPlots')));
            messagePanel.Layout.Row = 2;
            messagePanel.Layout.Column = [1 2];
            messagePanel.Editable = 'off';
            this.MessagePanel = messagePanel;

            % ButtonPanel
            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(gridLayout,...
                ["OK","Cancel","Apply","Help"]);
            bp = getWidget(this.ButtonPanel);
            bp.Parent = gridLayout;
            bp.Layout.Row = 3;
            bp.Layout.Column = [1 2];
        end

        function connectUI(this)
            % Add callbacks for system selection
            this.SystemDropDown.ValueChangedFcn = @(es,ed) cbSystemDropDownValueChanged(this);
            
            % Add callbacks for selecting indices via listbox and editfields
            addDimensionSelectionListeners(this);

            % Add callbacks for selection dropdown
            this.ShowModeDropDown.ValueChangedFcn = ...
                @(es,ed) cbShowModeDropDownValueChanged(this);

            % Add callbacks for selection criteria listbox
            this.SelectionCriteriaListBox.ValueChangedFcn = ...
                @(es,ed) cbSelectionCriteriaListBoxValueChanged(this);

            % Add callbacks for characteristic bound checkboxes and edit fields
            for k = 1:length(this.CharacteristicLabels)
                this.CharacteristicBoundsCheckbox(k).ValueChangedFcn = ...
                    @(es,ed) cbCharacteristicBoundsCheckBoxValueChanged(this,k);
                this.CharacteristicBoundsEditfield(k).ValueChangedFcn = ...
                    @(es,ed) cbCharacteristicBoundsEditFieldValueChanged(this,k);
            end

            % Add callbacks for buttons
            this.ButtonPanel.OKButton.ButtonPushedFcn = @(es,ed) cbOKButtonPushed(this);
            this.ButtonPanel.ApplyButton.ButtonPushedFcn = @(es,ed) cbApplyButtonPushed(this);
            this.ButtonPanel.CancelButton.ButtonPushedFcn = @(es,ed) cbCancelButtonPushed(this);
        end

        function cbApplyButtonPushed(this)
            % Update SelectedSystem
            this.SelectedSystem_I = this.SystemDropDown.Value;
            this.ShowMode_I(this.SelectedSystemIdx) = this.ShowModeDropDown.Value;

            % Update ArrayDimensions
            for k = 1:length(this.ArrayDimensions)
                this.SelectedIndices_I{this.SelectedSystemIdx}{k} = this.SelectIndicesListBox(k).Value;
            end
            this.CommittedSystemIdx = this.SelectedSystemIdx;

            % Update CharacteristicBoundExpressions
            for k = 1:length(this.CharacteristicTags)
                if this.CharacteristicBoundsCheckbox(k).Value
                    this.CharacteristicBoundsExpression(k) = this.CharacteristicBoundsEditfield(k).Value;
                else
                    this.CharacteristicBoundsExpression(k) = "";
                end
            end
            notify(this,"ArraySelectionChanged");
        end

        function cbOKButtonPushed(this)
            cbApplyButtonPushed(this);
            close(this);
        end

        function cbCancelButtonPushed(this)
            close(this);
        end
    end

    methods (Access = private)
        function buildDimensionSelectionWidgets(this)
            delete(allchild(this.IndexSelectionLayout));
            this.IndexSelectionLayout.ColumnWidth = repmat(70,1,length(this.ArrayDimensions));

            for k = 1:length(this.ArrayDimensions)
                % Label
                dimensionLabel = uilabel(this.IndexSelectionLayout,Text=string(k));
                dimensionLabel.Layout.Row = 1;
                dimensionLabel.Layout.Column = k;
                dimensionLabel.HorizontalAlignment = 'center';

                % Listbox
                dimensionSelectionListbox = uilistbox(this.IndexSelectionLayout);
                dimensionSelectionListbox.Items = string(1:this.ArrayDimensions(k));
                dimensionSelectionListbox.ItemsData = 1:this.ArrayDimensions(k);
                dimensionSelectionListbox.Multiselect = 'on';
                dimensionSelectionListbox.Layout.Row = 2;
                dimensionSelectionListbox.Layout.Column = k;
                this.SelectIndicesListBox(k) = handle(dimensionSelectionListbox);

                % Editfield
                dimensionSelectionEditfield = uieditfield(this.IndexSelectionLayout);
                dimensionSelectionEditfield.Layout.Row = 3;
                dimensionSelectionEditfield.Layout.Column = k;
                this.SelectIndicesEditField(k) = dimensionSelectionEditfield;
            end

            addDimensionSelectionListeners(this);
        end

        function cbSystemDropDownValueChanged(this)
            idx = this.SystemDropDown.Value==this.SystemNames;
            this.ArrayDimensions = this.AllArrayDimensions{idx};
            % 
            % this.SelectedIndices_I{idx} = cell(1,length(this.ArrayDimensions));
            % for k = 1:length(this.ArrayDimensions)
            %     this.SelectedIndices_I{idx}{k} = 1;
            % end

            buildDimensionSelectionWidgets(this);
            
            updateSelectIndicesEditField(this);
            updateSelectIndicesListBox(this);

            this.ShowModeDropDown.Value = this.ShowMode_I(idx);
            cbShowModeDropDownValueChanged(this);
        end

        function cbSelectIndicesListBoxValueChanged(this,idx)
            updateSelectIndicesEditField(this,idx,Value=this.SelectIndicesListBox(idx).Value);
        end

        function cbSelectIndicesEditFieldValueChanged(this,idx)
            try
                value = eval(this.SelectIndicesEditField(idx).Value);
                this.SelectedIndices_I{idx} = value;
                updateSelectIndicesListBox(this,idx);
            catch ME
                uialert(this.UIFigure,ME.message,this.Title);
            end
        end

        function cbShowModeDropDownValueChanged(this)
            % this.ShowMode_I = this.ShowModeDropDown.Value;
            if strcmp(this.ShowModeDropDown.Value,"all")
                % Disable selection listbox and editfield widgets. Do
                % not update widget values.
                for k = 1:length(this.ArrayDimensions)
                    this.SelectIndicesListBox(k).Enable = false;
                    this.SelectIndicesEditField(k).Enable = false;
                end
                this.MessagePanel.Value = "Show all plots";
            else
                % Enable listbox and editfield widgets. Update
                % SelectedIndices based on listbox values.
                for k = 1:length(this.ArrayDimensions)
                    this.SelectIndicesListBox(k).Enable = true;
                    this.SelectIndicesEditField(k).Enable = true;
                end

                % Update message panel
                if strcmp(this.ShowModeDropDown.Value,"selected")
                    this.MessagePanel.Value = getString(message('Controllib:gui:strShowSelectedPlots'));
                else
                    this.MessagePanel.Value = getString(message('Controllib:gui:msgShowUnselectedPlots'));
                end
            end
        end

        function cbSelectionCriteriaListBoxValueChanged(this)
            if this.IsIndexSelectionEnabled
                this.IndexSelectionLayout.Visible = 'on';
                this.ShowModeDropDown.Visible = 'on';
                this.CharacteristicBoundsLayout.Visible = 'off';
                cbShowModeDropDownValueChanged(this);
            else
                this.IndexSelectionLayout.Visible = 'off';
                this.ShowModeDropDown.Visible = 'off';
                this.CharacteristicBoundsLayout.Visible = 'on';
                this.MessagePanel.Value = getString(message('Controllib:gui:msgEnterMatlabExpressionInstruct'));
            end
        end

        function cbCharacteristicBoundsCheckBoxValueChanged(this,idx)
            arguments
                this
                idx = 1:length(this.CharacteristicLabels)
            end
            for k = idx(:)'
                if this.CharacteristicBoundsCheckbox(k).Value
                    this.CharacteristicBoundsEditfield(k).Enable = true;
                else
                    this.CharacteristicBoundsEditfield(k).Enable = false;
                    this.CharacteristicBoundsEditfield(k).Value = "";
                end
            end
        end

        function cbCharacteristicBoundsEditFieldValueChanged(this,k)
            
        end

        function updateSelectIndicesEditField(this,idx,optionalArgument)
            % Updates editfields for specifying selected indices based on
            % SelectedIndices
            arguments
                this
                idx = 1:length(this.ArrayDimensions)
                optionalArgument.Value = this.SelectedIndices_I{this.SelectedSystemIdx}(idx)
            end
            
            value = optionalArgument.Value;
            if ~iscell(value)
                value = {value};
            end

            for k = 1:length(idx)
                editfield = this.SelectIndicesEditField(idx(k));
                if isscalar(value{k})
                    editfield.Value = num2str(value{k});
                else
                    editfield.Value = ['[',num2str(sort(value{k}(:)')),']'];
                end
            end
        end

        function updateSelectIndicesListBox(this,idx,optionalArgument)
            % Updates listboxes for specifying selected indices based on
            % SelectedIndices
            arguments
                this
                idx = 1:length(this.ArrayDimensions)
                optionalArgument.Value = this.SelectedIndices_I{this.SelectedSystemIdx}(idx)
            end

            value = optionalArgument.Value;
            if ~iscell(value)
                value = {value};
            end

            for k = 1:length(idx)
                this.SelectIndicesListBox(idx(k)).Value = value{k}(:)';
            end
        end

        function addDimensionSelectionListeners(this)
            for k = 1:length(this.ArrayDimensions)
                this.SelectIndicesListBox(k).ValueChangedFcn = ...
                    @(es,ed) cbSelectIndicesListBoxValueChanged(this,k);
                this.SelectIndicesEditField(k).ValueChangedFcn = ...
                    @(es,ed) cbSelectIndicesEditFieldValueChanged(this,k);
            end
        end
    end

    %% Hidden (QE) methods
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.SystemDropdown = this.SystemDropDown;
            widgets.SelectionCriteriaListbox = this.SelectionCriteriaListBox;
            widgets.SelectionListbox = this.SelectIndicesListBox;
            widgets.SelectionEditfield = this.SelectIndicesEditField;
            widgets.ShowModeDropdown = this.ShowModeDropDown;
            widgets.MessagePanel = this.MessagePanel;
        end
    end
end
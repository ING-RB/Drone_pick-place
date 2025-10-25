classdef GenerateParamValueDialog < controllib.ui.internal.dialog.AbstractDialog
    % Dialog to generate gridded parameter values

    % Copyright 2022 The MathWorks, Inc.

    properties (Access = private, Dependent)
        Data % Setting this property fires event
    end

    properties (Access = private)
        ParentTab
        Parameters % Structure
        TableModel
        Data_ = cell(0,2) % Internal Data Cell {'ParamName', ParamStringValue}
        TableChangedListener
        ProductShortNameForHelp

        % Widgets
        Table
        GridSelector
        GridAll
        GridMinMax
        GridPair
        OverwriteRadioButton
        AppendRadioButton
        ButtonPanel
        OKButton
        ApplyButton
        HelpButton
        CloseButton
    end

    methods (Access = public)
        function this = GenerateParamValueDialog(parent, optionalArguments)
            arguments
                parent
                optionalArguments.Title = getString(message('Controllib:gui:EditParamValue_Title'))
                optionalArguments.ProductName = 'slcontrol';
            end
            % Optional argument has dialog title, otherwise use default
            this.Title = optionalArguments.Title;
            this.Name = 'ParameterValueDlg';

            % Process parameters
            this.ParentTab = parent;
            setParameterData(this,getParameterData(this.ParentTab));

            % Product name for help
            this.ProductShortNameForHelp = optionalArguments.ProductName;
        end

        function setParameterData(this,params)
            % Params is raw, linearization friendly data
            % Remove all and add again
            this.Data = cell(0,2);

            for ct = 1:numel(params)
                addParameter(this,params(ct).Name,...
                    unique(params(ct).Value,'stable'));
            end
            initRadioLabels(this);
            updateUI(this);
        end

        function updateParameterList(this,params)
            if isempty(params)
                % Remove all
                this.Data = cell(0,2);
            else
                % Remove those that are to be removed
                paramnames = {params.Name};
                param2remove = {};
                for ct = 1:size(this.Data,1)
                    if ~any(strcmp(this.Data{ct,1},paramnames))
                        param2remove(end+1) = this.Data(ct,1); %#ok<AGROW>
                    end
                end
                for ct = 1:numel(param2remove)
                    removeParameter(this,param2remove(ct));
                end
                % Add those that are to be added
                for ct = 1:numel(params)
                    if ~any(strcmp(params(ct).Name,this.Data(:,1)))
                        addParameter(this,params(ct).Name,...
                            unique(params(ct).Value,'stable'));
                    end
                end
            end
            initRadioLabels(this);
            updateUI(this);
        end

        function ParamStruct = getParamStruct(this)
            % Returns values from table using evalin('base')
            TData = this.Data;
            if isempty(TData)
                ParamStruct = [];
            else
                for ct = size(TData,1):-1:1
                    try
                        ParamStruct(ct).Name = TData{ct,1};
                        val = evalin('base',TData{ct,2});
                        if isnumeric(val)
                            ParamStruct(ct).Value = val;
                        else
                            error(message('Controllib:gui:EditParamValue_EvalError', TData{ct,1}))
                        end
                    catch
                        error(message('Controllib:gui:EditParamValue_EvalError', TData{ct,1}))
                    end
                end
            end
        end
    end

    methods (Access = private)
        function addParameter(this,ParamName, ParamValue)
            % Add a parameter to the data list
            % ParamName - string
            % ParamValue - numeric
            if isempty(this.Data)
                b = false;
            else
                [b,idx] = ismember(ParamName,this.Data(:,1));
            end
            if b
                this.Data{idx,2} = mat2str(ParamValue);
            else
                this.Data(end+1,:) = {ParamName,mat2str(ParamValue)};
            end
        end

        function removeParameter(this,ParamName)
            % Remove a parameter from the data list
            % ParamName - string
            if ~isempty(this.Data)
                [b,idx] = ismember(ParamName,this.Data(:,1));
                if b
                    this.Data(idx,:) = [];
                end
            end
        end
    end

    methods
        %% Set and Get functions
        function set.Data(this,Value)
            this.Data_ = Value;
            updateUI(this);
        end

        function Value = get.Data(this)
            Value = this.Data_;
        end

    end

    methods
        %% Implementation of abstract methods
        function updateUI(this)
            % Update Table
            if this.IsWidgetValid
                if isempty(this.Data)
                    this.Table.Data = table();
                else
                    this.TableModel = table(this.Data(:,1),this.Data(:,2));
                    this.Table.Data = this.TableModel;
                end
            end
        end
    end

    methods (Access = protected)
        %% Implementation of abstract methods
        function buildUI(this)
            MainLayout = uigridlayout(this.UIFigure,[4 1],RowHeight={'fit','1x',50,'fit'},ColumnWidth={'1x'});

            % Grid panel
            GridLayout = uigridlayout(MainLayout,[2 1],RowHeight={'fit',75},ColumnWidth={420});
            GridLayout.Padding = 0;
            GridLabel = uilabel(GridLayout,...
                Text=getString(message('Controllib:gui:ParamGenerateTabSamplingLabel')),...
                FontWeight='bold');
            GridLabel.Layout.Row = 1;
            GridLabel.Layout.Column = 1;

            gridButtonGroup = uibuttongroup(GridLayout,BorderType="none");
            gridButtonGroup.Layout.Row = 2;
            gridButtonGroup.Layout.Column = 1;
            this.GridAll = uiradiobutton(gridButtonGroup,Position=[10 55 410 20]);
            this.GridMinMax = uiradiobutton(gridButtonGroup,Position=[10 30 410 20]);
            this.GridPair = uiradiobutton(gridButtonGroup,Position=[10 5 410 20]);

            initRadioLabels(this);
            this.GridAll.Value = true;

            % Table
            tableLayout = uigridlayout(MainLayout,[2 1],RowHeight={'fit','fit'},ColumnWidth={'1x'});
            tableLayout.Padding = 0;
            Label = uilabel(tableLayout,...
                Text=getString(message('Controllib:gui:EditParamValue_TableTitle')),...
                FontWeight="bold"); %#ok<NASGU>
            this.Table = createTable(this,tableLayout);
            this.Table.Layout.Row = 2;
            this.Table.Layout.Column = 1;

            % Radio buttons for overwrite/append
            overwriteLayout = uigridlayout(MainLayout,[2 1],RowHeight={'fit',25},Padding=0);
            overwriteLayout.Layout.Row = 3;
            overwriteLayout.Layout.Column = 1;
            overwriteTitle = uilabel(overwriteLayout,...
                Text=getString(message('sldo:dialogs:lblGenerateRandom_RadioBtnDesc')));
            overwriteTitle.Layout.Row = 1;
            overwriteTitle.Layout.Column = 1;
            overwriteButtonGroup = uibuttongroup(overwriteLayout,Title='',BorderType='none');
            overwriteButtonGroup.Layout.Row = 2;
            overwriteButtonGroup.Layout.Column = 1;
            overwriteRadioButton = uiradiobutton(overwriteButtonGroup,Position=[10,5,200,20]);
            overwriteRadioButton.Text = ...
                getString(message('sldo:dialogs:lblGenerateRandom_OverwriteRadioBtn'));
            appendRadioButton = uiradiobutton(overwriteButtonGroup,Position=[210,5,200,20]);
            appendRadioButton.Text = getString(message('sldo:dialogs:lblGenerateRandom_AppendRadioBtn'));
            this.OverwriteRadioButton = overwriteRadioButton;
            this.AppendRadioButton = appendRadioButton;
            % Buttons
            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(MainLayout,...
                ["OK","Apply","Help","Close"]);
            buttonPanelWidget = getWidget(this.ButtonPanel);
            buttonPanelWidget.Layout.Row = 4;
            buttonPanelWidget.Layout.Column = 1;
            this.HelpButton = this.ButtonPanel.HelpButton;
            this.CloseButton = this.ButtonPanel.CloseButton;
            this.OKButton = this.ButtonPanel.OKButton;
            this.ApplyButton = this.ButtonPanel.ApplyButton;
            this.UIFigure.Position(3:4) = [430, 390];
        end

        function tableWidget = createTable(this,layout)
            this.TableModel = table("","");

            tableWidget = uitable(layout,Data=this.TableModel);
            tableWidget.ColumnName = {getString(message('Controllib:gui:EditParamValue_Parameter')),...
                getString(message('Controllib:gui:EditParamValue_Values'))};
            tableWidget.ColumnEditable = [false, true];
            tableWidget.RowStriping = 'off';
            tableWidget.SelectionType = 'row';
        end

        function connectUI(this)
            % Table
            this.Table.CellEditCallback = @(es,ed) tableChanged(this);
            % Buttons
            this.OKButton.ButtonPushedFcn = @(es,ed) cbOKButtonPushed(this);
            this.ApplyButton.ButtonPushedFcn = @(es,ed) cbApplyButtonPushed(this);
            this.HelpButton.ButtonPushedFcn = @(es,ed) help(this);
            this.CloseButton.ButtonPushedFcn = @(es,ed) close(this);
        end

        function tableChanged(this,~,~)
            try
                % Table changed callback
                currentData = this.Data_;
                TData = table2cell(this.Table.Data);
                if isempty(TData)
                    this.Data_ = cell(0,2);
                else
                    this.Data_ = TData;
                end

                % Update parameter (to check if input is valid)
                getParamStruct(this);
                % Update radio button labels
                initRadioLabels(this);
            catch Ex
                this.Data_ = currentData;
                initRadioLabels(this);
                updateUI(this);
                uialert(this.UIFigure,Ex.message,...
                    getString(message('Controllib:gui:AddParamTable_ErrorTitle')));
            end
        end

        function out = generateData(this)
            try
                params = getParamStruct(this);
            catch Ex
                uialert(this.UIFigure,Ex.message,...
                    getString(message('Controllib:gui:AddParamTable_ErrorTitle')));
                params = [];
            end
            if isempty(params)
                out = [];
                return;
            end
            out = struct('Name',[],'Value',[]);
            numparam = numel(params);

            if this.GridAll.Value
                % Generate N-D combination
                I = cell(numparam,1);
                for ct = 1:numparam
                    val = params(ct).Value;
                    I{ct} = unique(val(:)','stable');
                end
                [I{1:numparam}] = ndgrid(I{:});
                for ct = 1:numparam
                    out(ct).Name = params(ct).Name;
                    out(ct).Value = I{ct}(:);
                end
            elseif this.GridMinMax.Value
                % Min-Max
                I = cell(numparam,1);
                for ct = 1:numparam
                    val = params(ct).Value(:);
                    minval = min(val);
                    maxval = max(val);
                    if minval == maxval
                        I{ct} = minval;
                    else
                        I{ct} = [minval maxval];
                    end
                end
                [I{1:numparam}] = ndgrid(I{:});
                for ct = 1:numparam
                    out(ct).Name = params(ct).Name;
                    out(ct).Value = I{ct}(:);
                end
            else
                % All pairs
                for ctp = 1:numparam
                    out(ctp).Name = params(ctp).Name;
                    out(ctp).Value = params(ctp).Value(:);
                end
            end
        end

        function overwrite(this)
            out = generateData(this);
            if isempty(out)
                return;
            end

            setParameterData(this.ParentTab,out);

        end

        function append(this)
            out = generateData(this);
            if isempty(out)
                return;
            end
            appendParameterData(this.ParentTab,out);
        end

        function help(this)
            helpview(this.ProductShortNameForHelp,'generate_parameters','CSHelpWindow');
        end

        function initRadioLabels(this)
            if this.IsWidgetValid
                params = getParamStruct(this);
                if isempty(params)
                    numall = 0;
                    numminmax = 0;
                else
                    numall = 1;
                    numminmax = 1;
                    numparam = numel(params);
                    % Calculate number of samples

                    for ct = 1:numparam
                        val = params(ct).Value(:);
                        minval = min(val);
                        maxval = max(val);
                        numall = numall*numel(val);
                        if minval ~= maxval
                            numminmax = 2*numminmax;
                        end
                    end
                end

                this.GridAll.Text = ctrlMsgUtils.message(...
                    'Controllib:gui:ParamGenerateTabSamplingComboAll',numall);
                this.GridMinMax.Text = ctrlMsgUtils.message(...
                    'Controllib:gui:ParamGenerateTabSamplingComboMinMax',numminmax);


                % Check compatibility for pairwise
                if isempty(params)
                    % Put nums to be a value to generate invalid string
                    nums = [1 2];
                else
                    nums = arrayfun(@(x) numel(x.Value),params);
                end
                if numel(unique(nums)) == 1
                    this.GridPair.Text = ctrlMsgUtils.message(...
                        'Controllib:gui:ParamGenerateTabSamplingComboPair',nums(1));
                    this.GridPair.Enable = true;
                else
                    this.GridPair.Text = ctrlMsgUtils.message(...
                        'Controllib:gui:ParamGenerateTabSamplingComboPairInvalid');
                    this.GridPair.Enable = false;
                    if this.GridPair.Value
                        this.GridAll.Value = true;
                    end
                end
            end
        end

        function cbOKButtonPushed(this)
            cbApplyButtonPushed(this);
            close(this);
        end

        function cbApplyButtonPushed(this)
            if this.OverwriteRadioButton.Value
                overwrite(this);
            else
                append(this);
            end
        end
    end

    methods (Hidden)
        function w = qeGetWidgets(this)
            w.GridAll = this.GridAll;
            w.GridMinMax = this.GridMinMax;
            w.GridPair = this.GridPair;
            w.Table = this.Table;
            w.OverwriteRadioButton = this.OverwriteRadioButton;
            w.AppendRadioButton = this.AppendRadioButton;
            w.OKButton = this.OKButton;
            w.ApplyButton = this.ApplyButton;
            w.HelpButton = this.HelpButton;
            w.CloseButton = this.CloseButton;
        end
    end
end

classdef IOSelectorDialog < controllib.ui.internal.dialog.AbstractDialog & matlab.mixin.SetGet & matlab.mixin.Copyable
    % Input/Output Selector Dialog for Controls plots

    %   Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,SetAccess=private)
        RowNames
        ColumnNames
        RowVisible
        ColumnVisible
    end

    properties (Access=protected)
        Parent
        FigureGrid
        SelectAllButton
        Table
        ButtonPanel
        OKButton
        ApplyButton
        CancelButton
        HelpButton
    end

    %% Constructor
    methods
        function this = IOSelectorDialog(axesView,name)
            this.Parent = axesView;
            this.Title = name;
        end
    end

    %% Get/Set
    methods
        % RowNames
        function RowNames = get.RowNames(this)
            if isprop(this.Parent,'RowNames')
                RowNames = this.Parent.RowNames;
            else
                RowNames = string.empty;
            end
        end
        % ColumnNames
        function ColumnNames = get.ColumnNames(this)
            if isprop(this.Parent,'ColumnNames')
                ColumnNames = this.Parent.ColumnNames;
            else
                ColumnNames = string.empty;
            end
        end
        % RowVisible
        function RowVisible = get.RowVisible(this)
            if isprop(this.Parent,'RowVisible')
                RowVisible = this.Parent.RowVisible;
            else
                RowVisible = true;
            end
        end
        function set.RowVisible(this,RowVisible)
            if isprop(this.Parent,'RowVisible')
                this.Parent.RowVisible = RowVisible;
            end
        end
        % ColumnVisible
        function ColumnVisible = get.ColumnVisible(this)
            if isprop(this.Parent,'ColumnVisible')
                ColumnVisible = this.Parent.ColumnVisible;
            else
                ColumnVisible = true;
            end
        end
        function set.ColumnVisible(this,ColumnVisible)
            if isprop(this.Parent,'ColumnVisible')
                this.Parent.ColumnVisible = ColumnVisible;
            end
        end
    end

    %% Public methods
    methods
        function updateUI(this)
            this.Table.Data = this.RowVisible & this.ColumnVisible;
            this.Table.RowName = this.RowNames;
            this.Table.ColumnName = this.ColumnNames;
            this.Table.RowName = this.RowNames;
            this.Table.ColumnName = this.ColumnNames;
            this.SelectAllButton.Enable = ~all(this.RowVisible & this.ColumnVisible,"all");
        end
    end

    %% Protected methods
    methods (Access=protected)
        function buildUI(this)
            this.FigureGrid = uigridlayout(this.UIFigure,[3 2]);
            this.FigureGrid.RowHeight = {'fit','fit','fit'};
            this.FigureGrid.ColumnWidth = {'fit','1x'};
            this.SelectAllButton = uibutton(this.FigureGrid,Text='Select All');
            this.SelectAllButton.Layout.Row = 1;
            this.SelectAllButton.Layout.Column = 1;
            this.SelectAllButton.Enable = ~all(this.RowVisible & this.ColumnVisible,"all");
            this.Table = uitable(this.FigureGrid);
            this.Table.Layout.Row = 2;
            this.Table.Layout.Column = [1 2];
            this.Table.Data = this.RowVisible & this.ColumnVisible;
            this.Table.RowName = this.RowNames;
            this.Table.ColumnName = this.ColumnNames;

            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(this.FigureGrid,...
                ["Okay","Cancel","Apply","Help"]);
            bp = getWidget(this.ButtonPanel);
            bp.Layout.Row = 3;
            bp.Layout.Column = [1 2];
            this.OKButton = this.ButtonPanel.OKButton;
            this.ApplyButton = this.ButtonPanel.ApplyButton;
            this.CancelButton = this.ButtonPanel.CancelButton;
            this.HelpButton = this.ButtonPanel.HelpButton;
        end

        function connectUI(this)
            this.SelectAllButton.ButtonPushedFcn = @(es,ed) cbSelectAllButtonPushed(this);
            this.Table.SelectionChangedFcn = @(es,ed) cbTableSelectionChanged(this,ed);
            this.OKButton.ButtonPushedFcn = @(es,ed) cbOKButtonPushed(this);
            this.ApplyButton.ButtonPushedFcn = @(es,ed) cbApplyButtonPushed(this);
            this.CancelButton.ButtonPushedFcn = @(es,ed) cbCancelButtonPushed(this);
            this.HelpButton.ButtonPushedFcn = @(es,ed) cbHelpButtonPushed(this);
        end

        function cbTableSelectionChanged(this,ed)
            selection = ed.Selection;
            pattern = false(size(this.Table.Data));
            for ii = 1:size(selection,1)
                pattern(selection(ii,1),selection(ii,2)) = true;
            end
            this.Table.Data = pattern;
            this.SelectAllButton.Enable = ~all(pattern,"all");
        end

        function cbSelectAllButtonPushed(this)
            this.Table.Data = true(size(this.Table.Data));
            this.SelectAllButton.Enable = false;
        end

        function cbApplyButtonPushed(this)
            rowVisible = false(size(this.Table.Data,1),1);
            for ii = 1:size(this.Table.Data,1)
                rowVisible(ii) = any(this.Table.Data(ii,:));
            end
            columnVisible = false(1,size(this.Table.Data,2));
            for ii = 1:size(this.Table.Data,2)
                columnVisible(ii) = any(this.Table.Data(:,ii));
            end
            if ~all(this.Table.Data(rowVisible & columnVisible),'all') || ~any(rowVisible) || ~any(columnVisible)
                uialert(this.UIFigure,getString(message('Controllib:gui:strInvalidRowColumnSelection')),...
                    getString(message('Controllib:gui:strError')))
                return;
            end
            this.RowVisible = rowVisible;
            this.ColumnVisible = columnVisible;
        end

        function cbOKButtonPushed(this)
            rowVisible = false(size(this.Table.Data,1),1);
            for ii = 1:size(this.Table.Data,1)
                rowVisible(ii) = any(this.Table.Data(ii,:));
            end
            columnVisible = false(1,size(this.Table.Data,2));
            for ii = 1:size(this.Table.Data,2)
                columnVisible(ii) = any(this.Table.Data(:,ii));
            end
            if ~all(this.Table.Data(rowVisible & columnVisible),'all') || ~any(rowVisible) || ~any(columnVisible)
                uialert(this.UIFigure,getString(message('Controllib:gui:strInvalidRowColumnSelection')),...
                    getString(message('Controllib:gui:strError')))
                return;
            end
            this.RowVisible = rowVisible;
            this.ColumnVisible = columnVisible;
            close(this);
        end

        function cbCancelButtonPushed(this)
            close(this);
        end

        function cbHelpButtonPushed(this) %#ok<MANU>
            if isempty(ver('control')) || ~license('test','Control_Toolbox')
                helpview('ident','response_ioselector');
            else
                helpview('control','response_ioselector');
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function wdgts = qeGetWidgets(this)
            wdgts.SelectAllButton = this.SelectAllButton;
            wdgts.Table = this.Table;
            wdgts.OKButton = this.OKButton;
            wdgts.ApplyButton = this.ApplyButton;
            wdgts.CancelButton = this.CancelButton;
            wdgts.HelpButton = this.HelpButton;
        end
    end
end
classdef MixedInImportExportContainer < handle
    % MixedIn class that implements uicomponents for an import or export
    % container with a uitable.
    %
    % Properties
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.AllowMultipleRowSelection">AllowMultipleRowSelection</a>
    %   - Builds table with the first column as a checkbox that allows
    %   selection of multiple rows.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ShowExportAsColumn">ShowExportAsColumn</a>
    %   - Builds table with the last column as an editable text box that
    %   allows user to specify the variable name to which the data is
    %   exported.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ShowRefreshButton">ShowRefreshButton</a>
    %   - Allows removal of Refresh button in the dialog.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ColumnWidth">ColumnWidth</a>
    %   - Specify the width of the columns in the table.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.HeaderText">HeaderText</a>
    %   - Specify the header label (first row of the dialog).
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.TableTitle">TableTitle</a>
    %   - Specify the title above the table.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ActionButtonLabel">ActionButtonLabel</a>
    %   - Specify the label for the Import Button.
    %
    % Methods (Protected, Sealed)
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.buildImportExportContainer">buildImportExportContainer</a>
    %   - Build and parent the container (uigridlayout) with widgets
    %     for the import/export dialog.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.cleanupImportExportContainer">cleanupImportExportContainer</a>
    %   - Deletes the container components and widgets. Call this from
    %     the cleanupUI() or delete() methods.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.addWidget">addWidget</a>
    %   - Add widget in the container, above or below the table.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.refreshTable">refreshTable</a>
    %   - Updates the table with current data from source and clears
    %     all selections.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.updateTable">updateTable</a>
    %   - Updates the table with current data from source and preserves all
    %     selections.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.getSelectedIdx">getSelectedIdx</a>
    %   - Gets the indices of the selected rows in the table
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.getVariableNamesInTable">getVariableNamesInTable</a>
    %   - Returns the names in the variable column (first column
    %     returned by "getTableData").
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.getExportVariableNames">getExportVariableNames</a>
    %   - Returns the names in the 'Export As' column
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.qeGetCustomWidgets">qeGetContainerWidgets</a>
    %
    % Methods (Can be overloaded)
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.callbackRefreshButton">callbackRefreshButton</a>
    %
    % Abstract Methods
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.getTableData">getTableData</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.callbackActionButton">callbackActionButton</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.callbackHelpButton">callbackHelpButton</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.callbackCancelButton">callbackCancelButton</a>
    %
    % Events
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.SelectionChanged">SelectionChanged</a>
    %

    % Copyright 2019-2023 The MathWorks, Inc.
    
    properties (Dependent)
        % Property "RowSelection"
        %   Vector of doubles specifying the indices of rows that are
        %   selected.
        %
        %   Selection made interactively does not persist across calls to
        %   "updateUI()" or "refreshTable()".
        %
        %   Selection made via setting the property persists across calls
        %   to "updateUI()".
        RowSelection
    end

    properties (Access = protected)
        % Property "DisplayedTableHeight"
        DisplayedTableHeight
        % Property "DisplayedTableWidth"
        DisplayedTableWidth
        % Property "HeaderText":
        %   String or char array displayed at the top of the dialog. The
        %   default value is ''.
        HeaderText = ''
        % Property "TableTitle":
        %   String or char array displayed above the uitable as the title.
        %   The default value is ''.
        TableTitle = ''
        % Property "ActionButtonLabel"
        %   String or char array containing the label for the action button
        %   (Import/Export). The default value is 'OK'.
        ActionButtonLabel = getString(message('Controllib:gui:lblOK'))
        % Property "AllowMultipleRowSelection": 
        %   Boolean value indicating if multiple rows can be selected. The
        %   default value is true
        AllowMultipleRowSelection logical = true
        % Property "SelectColumnName":
        %   String or char array for the select column header name.
        SelectColumnName = '';
        % Property "ShowExportAsColumn":
        %   Boolean value indicating if the table should contain a
        %   an editable column to specify the variable name to export the
        %   data into. The default value is false
        ShowExportAsColumn logical = false
        % Property "AllowColumnSorting":
        %   Boolean value indicating if the table columns should be
        %   sortable. The default value is false
        AllowColumnSorting logical = false
        % Property "ShowSelectAllOption"
        %   Boolean value indicating if dialog should contain "Select All"
        %   and "Unselect All" buttons. The default value is false.
        ShowSelectAllButtons logical = false
        % Property "ShowRefreshButton":
        %   Boolean value indicating if the dialog should contain a
        %   'Refresh' button. The default value is true 
        ShowRefreshButton logical = true
        % Property "ShowHelpButton":
        %   Boolean value indicating if the dialog should contain a 'Help'
        %   button. The default value is true
        ShowHelpButton logical = true
        % Property "NumberOfAdditionalCommitButtons"
        NumberOfAdditionalCommitButtons = 0;
        % Property "ColumnWidth":
        %   Cell array of column width values for the table. Each element
        %   can either be a numeric value or 'auto'. The default value is
        %   {'auto'}
        ColumnWidth = {'auto'}
        % Property "ButtonWidth"
        ButtonWidth = [];
        % Property "Tags":
        %   Structure of strings for the dialog widget tags. SubClass can
        %   change the value of the tag for any widget, but should not
        %   change the fieldname which corresponds to the property names
        %   for the widgets.
        Tags = struct('UIGridLayout','ImportExport_GridLayout',...
                      'HeaderLabel','ImportExport_Header',...
                      'UITable','ImportExport_Table',...
                      'UITableTitle','ImportExport_TableTitle',...
                      'ActionButton','ImportExport_Action',...
                      'CancelButton','ImportExport_Cancel',...
                      'HelpButton','ImportExport_Help',...
                      'RefreshButton','ImportExport_Refresh');
        % Property "AddTagsToWidgets":
        %   Boolean value indicating if tags should be added to the dialog
        %   widgets. The default value is false.
        AddTagsToWidgets = false
    end
    
    properties(Access = protected, Dependent)
        % Property "VariableColumnName":
        %   Name of the table column that contains the variable names.
        VariableColumnName
        % Property "OptionalColumnNames":
        %   Names of all table columns, except the column containing the
        %   variable names.
        OptionalColumnNames
    end
    
    properties(Access = private)
        UIGridLayout
        UITableGrid
        HeaderLabel
        UITable
        UITableTitle

        SelectAllButton
        UnselectAllButton

        ButtonPanel
        ActionButton
        CancelButton
        HelpButton
        RefreshButton
        
        SelectedCellStyle = uistyle('BackgroundColor',0.15*([0 0.6 1]) + 0.85*([1 1 1]))
        NonEditableCellStyle = matlab.ui.style.internal.SemanticStyle(...
            'BackgroundColor','--mw-backgroundColor-input-readonly');
        EditableCellStyle = matlab.ui.style.internal.SemanticStyle(...
            'BackgroundColor','--mw-backgroundColor-input');

        % RowSelection_I represents the rows selected using the
        % "RowSelection" property. This persists across calls to
        % "updateUI()", "updateTable()" and "refreshTable()". Interactively
        % updating the table selection does not modify this property.
        RowSelection_I
        
        ColumnEditable
        IsTableEmpty = true
    end
    
    events
        % Event "SelectionChanged"
        %
        % The container sends this event after the selection in the table
        % changes, with the indices of the rows currently selected.
        SelectionChanged
        
        % Event "TableUpdated"
        TableUpdated
        
        % Event "RefreshButtonPushed"
        RefreshButtonPushed
    end
    
    %% Protected sealed methods
    methods (Access = protected, Sealed = true)
        % constructor
        function this = MixedInImportExportContainer()
            
        end
        
        % Create components
        function buildImportExportContainer(this,parentDialog)
            % Method "buildImportExportContainer":
            %   Build and parent the container (uigridlayout) with widgets
            %   for the import/export dialog.
            %
            %   buildImportExportContainer(this,parentDialog)
            %       "parentDialog" is a uifigure in which the container is
            %       placed.
            arguments
                this
                parentDialog matlab.ui.Figure
            end
            weakThis = matlab.lang.WeakReference(this);
            % Grid layout
            this.UIGridLayout = uigridlayout('Parent',parentDialog);
            this.UIGridLayout.RowHeight = {'fit','fit','1x','fit','fit'};
            this.UIGridLayout.ColumnWidth = {'fit','fit','1x','fit','fit'};
            this.UIGridLayout.Scrollable = 'on';
            
            % Header Text Label
            if ~isempty(this.HeaderText)
                this.HeaderLabel = uilabel(this.UIGridLayout);
                this.HeaderLabel.Layout.Row = 1;
                this.HeaderLabel.Layout.Column = [1 5];
                this.HeaderLabel.Text = this.HeaderText;
            end

            % Grid layout for uitable and controls for uitable
            glUITableAndTitle = uigridlayout(this.UIGridLayout);
            glUITableAndTitle.Layout.Row = 3;
            glUITableAndTitle.Layout.Column = [1 5];
            glUITableAndTitle.RowHeight = {'fit','fit','1x'};
            glUITableAndTitle.ColumnWidth = {'fit','fit','1x'};
            glUITableAndTitle.Padding = 0;
            % Table title
            if ~isempty(this.TableTitle)
                this.UITableTitle = uilabel(glUITableAndTitle);
                this.UITableTitle.Layout.Row = 1;
                this.UITableTitle.Layout.Column = [1 3];
                this.UITableTitle.Text = this.TableTitle;
                this.UITableTitle.FontWeight = 'bold';
            end
            % Select/Unselect all
            if this.AllowMultipleRowSelection && this.ShowSelectAllButtons
                % select all
                this.SelectAllButton = uibutton(glUITableAndTitle,...
                    Text=getString(message('Controllib:gui:strSelectAll')));
                this.SelectAllButton.Layout.Row = 2;
                this.SelectAllButton.Layout.Column = 1;
                this.SelectAllButton.ButtonPushedFcn = @(es,ed) cbSelectAll(weakThis.Handle);
                % unselect all
                this.UnselectAllButton = uibutton(glUITableAndTitle,...
                    Text=getString(message('Controllib:gui:strUnselectAll')));
                this.UnselectAllButton.Layout.Row = 2;
                this.UnselectAllButton.Layout.Column = 2;
                this.UnselectAllButton.ButtonPushedFcn = @(es,ed) cbUnselectAll(weakThis.Handle);
             end
            % UITable
            glUITable = uigridlayout(glUITableAndTitle);
            glUITable.RowHeight = {'1x'};
            glUITable.ColumnWidth = {'1x'};
            glUITable.Layout.Row = 3;
            glUITable.Layout.Column = [1 3];
            glUITable.Padding = 0;
            this.UITableGrid = glUITable;
            this.UITable = uitable('Parent',glUITable);
            this.UITable.ColumnSortable = this.AllowColumnSorting; 
            this.UITable.RowStriping = 'off';
            this.UITable.CellEditCallback = @(es,ed) cbCellEdit(weakThis.Handle,es,ed);
            this.UITable.DisplayDataChangedFcn = @(es,ed) cbDisplayDataChanged(weakThis.Handle,es,ed);
            if ~this.AllowMultipleRowSelection
                this.UITable.SelectionType = 'row';
                this.UITable.Multiselect = 'off';
                this.UITable.CellSelectionCallback = ...
                    @(es,ed) cbSingleRowSelection(weakThis.Handle,es,ed);
            end
            
            % Button Panel (for help/refresh/ok/cancel)
            buttonsToAdd = ["OK","Cancel"];
            if this.ShowHelpButton
                buttonsToAdd = [buttonsToAdd, "Help"];
                refreshButtonColumn = 2;
            else
                refreshButtonColumn = 1;
            end
            if this.ShowRefreshButton
                % Add supplement button in ButtonPanel
                buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                    this.UIGridLayout,buttonsToAdd,...
                    "Supplement",1,"Commit",this.NumberOfAdditionalCommitButtons);
                this.RefreshButton = uibutton(getWidget(buttonPanel),...
                    'Text',m('Controllib:gui:strRefresh'));
                this.RefreshButton.Layout.Row = 1;
                this.RefreshButton.Layout.Column = refreshButtonColumn;
                this.RefreshButton.ButtonPushedFcn = ...
                    @(es,ed) callbackRefreshButton(weakThis.Handle);
            else
                buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                    this.UIGridLayout,buttonsToAdd,...
                    "Commit",this.NumberOfAdditionalCommitButtons);
            end
            if ~isempty(this.ButtonWidth)
                buttonPanel.ButtonWidth = this.ButtonWidth;
            end
            this.ButtonPanel = buttonPanel;
            buttonPanelWidget = getWidget(buttonPanel);
            buttonPanelWidget.Layout.Row = 5;
            buttonPanelWidget.Layout.Column = [1 5];
            % Help Button
            if this.ShowHelpButton
                this.HelpButton = buttonPanel.HelpButton;
                this.HelpButton.ButtonPushedFcn = @(es,ed) callbackHelpButton(weakThis.Handle);
            end
            % Import Button
            this.ActionButton = buttonPanel.OKButton;
            this.ActionButton.Text = this.ActionButtonLabel;
            this.ActionButton.ButtonPushedFcn = @(es,ed) callbackActionButton(weakThis.Handle);
            % Cancel Button
            this.CancelButton = buttonPanel.CancelButton;
            this.CancelButton.ButtonPushedFcn = @(es,ed) callbackCancelButton(weakThis.Handle);
            
            % Add Tags
            if this.AddTagsToWidgets
                widgetNames = fieldnames(this.Tags);
                for wn = widgetNames'
                    widget = this.(wn{1});
                    if ~isempty(widget) && isvalid(widget)
                        widget.Tag = this.Tags.(wn{1});
                    end
                end
            end
        end
        
        function cleanupImportExportContainer(this)
            % Method "cleanupImportExportContainer":
            %   Deletes the container components and widgets. Call this from
            %   the cleanupUI() or delete() methods.
            %
            %   cleanupImportExportContainer(this)
            if ~isempty(this.RefreshButton) && isvalid(this.RefreshButton)
                delete(this.RefreshButton);
                this.RefreshButton = [];
            end
            
            if ~isempty(this.HelpButton) && isvalid(this.HelpButton)
                delete(this.HelpButton);
                this.HelpButton = [];
            end
            
            if ~isempty(this.CancelButton) && isvalid(this.CancelButton)
                delete(this.CancelButton);
                this.CancelButton = [];
            end
            
            if ~isempty(this.ActionButton) && isvalid(this.ActionButton)
                delete(this.ActionButton);
                this.ActionButton = [];
            end
            
            if ~isempty(this.UITable) && isvalid(this.UITable)
                delete(this.UITable);
                this.UITable = [];
            end
            
            if ~isempty(this.UITableTitle) && isvalid(this.UITableTitle)
                delete(this.UITableTitle);
                this.UITable = [];
            end
            
            if ~isempty(this.HeaderLabel) && isvalid(this.HeaderLabel)
                delete(this.HeaderLabel);
                this.HeaderLabel = [];
            end
            
            if ~isempty(this.UIGridLayout) && isvalid(this.UIGridLayout)
                delete(this.UIGridLayout);
                this.UIGridLayout = [];
            end
        end
        
        function refreshTable(this)
            % Method "refreshTable":
            %   Updates the table with current data from source and clears
            %   all selections.
            %
            %   refreshTable(this)
            updateTable(this);
        end
        
        function updateTable(this)
            % Method "updateTable":
            %   Updates the table with current data from source and preserves
            %   selections.
            %
            %   updateTable(this)
            data = getTableData(this);
            validateattributes(data,{'table'},{});
            if width(data)>0
                columnEditable = false(1,width(data));
                columnWidth = this.ColumnWidth;
                if this.ShowExportAsColumn
                    newColumn = table(matlab.lang.makeValidName(data{:,1}));
                    newColumn.Properties.VariableNames{1} = ...
                        m('Controllib:gui:AbstractExportDialogThirdColumnName');
                    data = [data(:,1),newColumn,data(:,2:end)];
                    columnEditable = [columnEditable(1), true, columnEditable(2:end)];
                    columnWidth = [columnWidth(1),{'auto'},columnWidth(2:end)];
                end
                
                if this.AllowMultipleRowSelection
                    data = [table(false(height(data),1),'VariableNames',{this.SelectColumnName}),data];
                    this.UITable.RowStriping = 'off';
                    columnEditable = [true, columnEditable];
                    columnWidth = [{70},columnWidth];
                end
            end
            if ~isempty(data)
                this.IsTableEmpty = false;
                
                this.UITable.Data = data;
                this.UITable.ColumnEditable = columnEditable;
                this.UITable.ColumnWidth = columnWidth;
                if ~isequal(this.ColumnEditable,columnEditable)
                    addStyle(this.UITable,this.NonEditableCellStyle,'column',find(~columnEditable));
                    addStyle(this.UITable,this.EditableCellStyle,'column',find(columnEditable));
                end
            else
                this.IsTableEmpty = true;
                this.UITable.Data = data;
            end
            this.ColumnEditable = columnEditable;
            selectRows(this,this.RowSelection_I);
            notify(this,'TableUpdated');
        end
        
        function addWidget(this,widget,location,rowHeight)
            % Method "addWidget":
            %   Add widget in the container, above or below the table.
            %
            %   addWidget(this,widget,location,rowHeight)
            %       "widget" is the uicomponent which will be placed in the
            %           container as an additional widget.
            %       "location" is 'abovetable' or 'belowtable'.
            %       "rowHeight" is an optional input specifying the height
            %           of the "widget".
            validatestring(location,{'abovetable','belowtable'});
            if nargin < 4
                rowHeight = 'fit';
            end
            switch location
                case 'abovetable'
                    addWidgetToGrid(this,widget,2,rowHeight);
                case 'belowtable'
                    addWidgetToGrid(this,widget,4,rowHeight);
            end
        end
        
        function idx = getSelectedIdx(this)
            % Method "getSelectedIdx":
            %   Gets the indices of the selected rows in the table
            %
            %   idx = getSelectedIdx(this)
            %       "idx" is a numeric row vector of indices.
            idx = [];
            if ~this.IsTableEmpty
                if this.AllowMultipleRowSelection
                    idx = find(this.UITable.Data{:,1});
                else
                    idx = this.RowSelection_I;
                end
            end
            
        end
        
        function varargout = getVariableNamesInTable(this)
            % Method "getVariableNamesInTable":
            %   Returns the names in the variable column (first column
            %   returned by "getTableData").
            %
            %   getVariableNamesInTable(this)
            variableNames = {};
            if ~this.IsTableEmpty
                if this.AllowMultipleRowSelection
                    idx = 2;
                else
                    idx = 1;
                end
                variableNames = this.UITable.Data{:,idx};
                displayedVariableNames = this.UITable.DisplayData{:,idx};
            end
            if nargout == 1
                varargout = {variableNames};
            else
                varargout = {variableNames, displayedVariableNames};
            end
        end
        
        function variableNames = getExportVariableNames(this,varargin)
            % Method "getExportVariableNames":
            %   If "ShowExportAsColumn" is true, it returns the names in the
            %   'Export As' column. Otherwise it returns the names in the
            %   'Variable' column.
            %
            %   getExportVariableNames(this)
            %   getExportVariableNames(this,idx)
            variableNames = {};
            if ~this.IsTableEmpty
                if this.ShowExportAsColumn
                    idx = 2;
                else
                    idx = 1;
                end
                if this.AllowMultipleRowSelection
                    idx = idx + 1;
                end
                variableNames = this.UITable.Data{:,idx};
            end
            if nargin > 1 
                variableNames = variableNames(varargin{1});
            end                
        end
        
        
        function selectVariables(this,varargin)
            % Method "selectVariables":
            %   Select a variable in the table
            %
            %   selectVariables(this,variableNames)
            %       "variableNames" is a string or char array of variables
            %       to be selected.
            %
            %       selectVariables(this,'a');
            %       selectVariables(this,'a','b');
            %       selectVariables(this,{'a','b'});
            data = getTableData(this);
            if iscell(varargin{1})
                inputVariableNames = varargin{1};
            else
                inputVariableNames = varargin;
            end
            [~,idxToSelect] = intersect(data{:,1},inputVariableNames(:));
            selectRows(this,idxToSelect);
        end
        
        function setFixedTableSize(this)
            if ~isempty(this.DisplayedTableHeight)
                this.UITableGrid.RowHeight{1} = this.DisplayedTableHeight;
            end
            if ~isempty(this.DisplayedTableWidth)
                this.UITableGrid.ColumnWidth{1} = this.DisplayedTableWidth;
            end
        end
        
        function setAutoTableSize(this)
            this.UITableGrid.RowHeight{1} = '1x';
            this.UITableGrid.ColumnWidth{1} = '1x';
        end

        function buttonPanelWidget = getButtonPanelWidget(this)
            buttonPanelWidget = getWidget(this.ButtonPanel);
        end
    end
    
    methods
        function variableColumnName = get.VariableColumnName(this)
            if this.AllowMultipleRowSelection
                idx = 2;
            else
                idx = 1;
            end
            variableColumnName = this.UITable.Data.Properties.VariableNames{idx};
        end
        
        function optionalColumnNames = get.OptionalColumnNames(this)
            data = this.UITable.Data;
            if this.AllowMultipleRowSelection
                idxStart = 3;
            else
                idxStart = 2;
            end
            if this.ShowExportAsColumn
                idxStart = idxStart + 1;
            end
            idxEnd = width(data);
            optionalColumnNames = data.Properties.VariableNames(idxStart:idxEnd);
        end

        % RowSelection
        function rowSelection = get.RowSelection(this)
            if ~isempty(this.UITable) && isvalid(this.UITable) && ~isempty(this.UITable.Data)
                rowSelection = getSelectedIdx(this);
            else
                rowSelection = this.RowSelection_I;
            end
        end

        function set.RowSelection(this,rowSelection)
            if ~isempty(this.UITable) && isvalid(this.UITable) && ~isempty(this.UITable.Data)
                selectRows(this,rowSelection);
            end
            this.RowSelection_I = rowSelection;
        end
    end
    
    %% Implementation of protected abstract or overloaded methods
    methods(Access = protected)
        function callbackRefreshButton(this)
            % Method "callbackRefreshButton":
            %   Overload this method to change the Refresh button callback.
            currentIdx = getSelectedIdx(this);
            variableNames = getVariableNamesInTable(this);
            selectedVariableNames = variableNames(currentIdx);
            updateTable(this);
            newVariableNames = getVariableNamesInTable(this);
            newIdx = find(ismember(newVariableNames,selectedVariableNames));
            if ~isempty(newIdx)
                selectRows(this,newIdx,StoreSelection=false);
            end
            notify(this,'RefreshButtonPushed');
        end
        
        function callbackHelpButton(this)
            
        end
    end
    
    %% Abstract methods
    methods(Access = protected, Abstract)
        % Abstract Method "callbackActionButton"
        %   Implement callback of Import or Export button.
        callbackActionButton(this);
        % Abstract Method "callbackCancelButton"
        callbackCancelButton(this);
        % Abstract Method "getTableData"
        %   Return data (of class 'table') to be shown in the dialog from subclass
        data = getTableData(this);
    end
    
    %% Callbacks for Export and Cancel Button
    methods(Access = private)
        function cbSingleRowSelection(this,~,ed)
            if ~isempty(ed.Indices)
                selectRows(this,ed.Indices(1));
            elseif ~isempty(this.RowSelection_I)
                selectRows(this,this.RowSelection_I)
            end
        end
        
        function cbDisplayDataChanged(this,~,~)
            if ~this.AllowMultipleRowSelection && ~isempty(this.RowSelection_I)
                selectRows(this,this.RowSelection_I);
            end
        end
        
        function cbCellEdit(this,~,ed)
            idx = ed.Indices(end,:);
            if this.AllowMultipleRowSelection && idx(2) == 1
                % Checkbox selected
                ed = controllib.app.internal.GenericEventData(getSelectedIdx(this));
                notify(this,'SelectionChanged',ed);
            elseif this.ShowExportAsColumn && idx(2) == width(this.UITable.Data)
                % Export as variable name edited
                variableName = this.UITable.Data{idx(1),idx(2)};
                validVariableName = matlab.lang.makeValidName(variableName);
                this.UITable.Data{idx(1),idx(2)} = validVariableName;
            end
        end

        function cbSelectAll(this)
            this.UITable.Data{:,1} = true;
        end

        function cbUnselectAll(this)
            this.UITable.Data{:,1} = false;
        end
        
        function selectRows(this,idx,optionalArguments)
            arguments
                this
                idx
                optionalArguments.StoreSelection = true
            end
            % Limit selections to height of table data. This changes the
            % set RowSelection if needed.
            idx = idx(idx <= size(this.UITable.Data,1));

            if this.AllowMultipleRowSelection
                this.UITable.Data{:,1} = false;
                if ~isempty(idx)
                    this.UITable.Data{idx,1} = true;
                end
            else
                if ~isequal(idx,this.UITable.Selection)
                    this.UITable.Selection = idx;
                 end
                if isempty(idx)
                    % To refresh the selected cell (not needed after the
                    % bug related to "focus" is fixed)
                    selectionType = this.UITable.SelectionType;
                    this.UITable.SelectionType = 'column';
                    this.UITable.SelectionType = selectionType;
                end
            end

            if optionalArguments.StoreSelection
                this.RowSelection_I = idx;
            end

            ed = controllib.app.internal.GenericEventData(idx);
            notify(this,'SelectionChanged',ed);
        end
        
        function addWidgetToGrid(this,widget,rowIdx,rowHeight)
            widget.Parent = this.UIGridLayout;
            widget.Layout.Row = rowIdx;
            widget.Layout.Column = [1 5];
            this.UIGridLayout.RowHeight{rowIdx} = rowHeight;
        end
        
    end
    
    %% qeFunctions
    methods (Hidden)
        function widgets = qeGetContainerWidgets(this)
            % Method "qeGetContainerWidgets":
            %   Returns struct of all widgets
            widgets.UIGridLayout = this.UIGridLayout;
            widgets.UITable = this.UITable;
            widgets.HeaderLabel = this.HeaderLabel;
            widgets.UITableTitle = this.UITableTitle;
            widgets.ActionButton = this.ActionButton;
            widgets.CancelButton = this.CancelButton;
            widgets.HelpButton = this.HelpButton;
            if this.ShowRefreshButton
                widgets.RefreshButton = this.RefreshButton;
            end
            if this.AllowMultipleRowSelection && this.ShowSelectAllButtons
                widgets.SelectAllButton = this.SelectAllButton;
                widgets.UnselectAllButton = this.UnselectAllButton;
            end
        end
        
        function table = qeGetTable(this)
            table = this.UITable;
        end
        
        function qeCallbackCancelButton(this)
            callbackCancelButton(this);
        end

        function qeCallbackHelpButton(this)
            callbackHelpButton(this);
        end

        function storedSelection = qeGetStoredRowSelection(this)
            storedSelection = this.RowSelection_I;
        end
    end
end

function str = m(id,varargin)
str = getString(message(id,varargin{:}));
end

% LocalWords:  uicomponents controllib uicomponents controllib uigridlayout
% LocalWords:  uicomponent

classdef AbstractImportDialog < controllib.ui.internal.dialog.MixedInImportExportContainer & ...
                           controllib.ui.internal.dialog.AbstractDialog
    % "AbstractImportDialog"
    %
    % Super class that implements uicomponents and provides helper data
    % methods for "Import Dialogs" that display a table based on variables
    % in the specified source. 
    %
    % Properties
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.AllowMultipleRowSelection">AllowMultipleRowSelection</a>
    %   - Builds table with the first column as a checkbox that allows
    %   selection of multiple rows. Default is false.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ShowRefreshButton">ShowRefreshButton</a>
    %   - Allows removal of Refresh button in the dialog. Default is true.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ShowHelpButton">ShowHelpButton</a>
    %   - Allows removal of Help button in the dialog.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ColumnWidth">ColumnWidth</a>
    %   - Specify the width of the columns in the table.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.HeaderText">HeaderText</a>
    %   - Specify the header label (first row of the dialog).
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.TableTitle">TableTitle</a>
    %   - Specify the title above the table.
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.DialogSize">DialogSize</a>
    %   - Specify the size of the dialog(uifigure) in pixels.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ActionButtonLabel">ActionButtonLabel</a>
    %   - Specify the label for the Import Button.
    %
    % Methods (Protected, Sealed)
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.refreshTable">refreshTable</a>
    %   - Updates the table with current data from source and clears
    %     all selections.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.updateTable">updateTable</a>
    %   - Updates the table with current data from source and preserves all
    %     selections.
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.setSource">setSource</a>
    %   - Specifies the source that contains the data
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.getData">getData</a>
    %   - Gets the variable names and values from the source.
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.getSelectedData">getSelectedData</a>
    %   - Gets the selected variable names and values from the source
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.getSelectedIdx">getSelectedIdx</a>
    %   - Gets the indices of the selected rows in the table
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.qeGetCustomWidgets">qeGetWidgets</a>
    %
    % Methods (Can be overloaded)
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.buildCustomWidgets">buildCustomWidgets</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.cleanupCustomWidgets">cleanupCustomWidgets</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.preUpdateUI">preUpdateUI</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.postUpdateUI">postUpdateUI</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.qeGetCustomWidgets">qeGetCustomWidgets</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.callbackHelpButton">callbackHelpButton</a>
    %
    % Abstract Methods
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.getTableData">getTableData</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.callbackActionButton">callbackActionButton</a>

    % Copyright 2019-2022 The MathWorks, Inc.
    
    %% Protected Properties
    properties (Access = protected)
        % Property "DialogSize": 
        %   Size of the dialog (uifigure) specified as a numeric vector of
        %   the form [width height] in pixels.
        DialogSize = []
    end
    
    %% Private Properties
    properties (Access = private)
        DataSourceType = 'workspace'
        DataSource = 'base'
    end
    
    %% Public methods
    methods(Sealed)
        function this = AbstractImportDialog()
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this@controllib.ui.internal.dialog.MixedInImportExportContainer();
            this.SelectColumnName = m('Controllib:gui:strImport');
            this.ShowExportAsColumn = false;
            this.ActionButtonLabel = getString(message('Controllib:gui:strImport'));
        end

        function updateUI(this)
            if this.IsWidgetValid
                preUpdateUI(this);
                refreshTable(this);
                postUpdateUI(this);
            end
        end
    end
    
    %% Protected sealed methods
    methods(Access = protected, Sealed = true)
        function buildUI(this)
            if ~isempty(this.DialogSize)
                this.UIFigure.Position(3:4) = this.DialogSize;
            end
            buildImportExportContainer(this,this.UIFigure);
            buildCustomWidgets(this);
        end
        
        function cleanupUI(this)
            % Method "cleanupUI":
            %
            % Called by the "delete" method. This calls
            % "cleanupCustomWidgets" for clean up of any additional
            % widgets and deletes the MixedInImportExportContainer widgets.
            %
            %   cleanupUI(this)
            cleanupCustomWidgets(this);
            cleanupImportExportContainer(this);
        end
        
        function [source,sourceType] = getSource(this)
            % Method "getSource":
            %   Returns the "source" and the "sourceType".
            %   [source,sourceType] = getSource(this);
            source = this.DataSource;
            sourceType = this.DataSourceType;
        end
        
        function setSource(this,source,sourceType)
            % Method "setSource":
            %   Specifies the source that contains the data
            %
            %   setSource(this,source)
            %       "source" specifies the workspace and can be 'base' (for
            %       base workspace) or a Simulink.ModelWorkspace.
            %   setSource(this,source,sourceType)
            %       "source" is a string specifying the MAT filename, or
            %       'base' (for base workspace) or a
            %       Simulink.ModelWorkspace. "sourceType" can be 'matfile'
            %       or 'workspace'. 
            if nargin == 1
                sourceType = 'workspace';
            else
                validatestring(sourceType,{'workspace','matfile'});
            end
            this.DataSourceType = sourceType;
            this.DataSource = source;
        end
        
        function data = getData(this,varargin)
            % Method "getData":
            %   Gets the variable names and values from the source.
            %
            %   data = getData(this)
            %       "data" is N x 2 cell array of all variable names and
            %       values in the source specified in "DataSource" and
            %       "DataSourceType".
            %
            %   data = getData(this,variableNames)
            %       "variableNames" is a cell array of M input variable
            %       names. "data" is an M x 2 cell array of the input
            %       variable names and variable values in the source.
            variableNames = varargin(:);
            if isempty(this.DataSource)
                data = cell.empty;
            else
                try
                    if strcmp(this.DataSourceType,'workspace')
                        if nargin == 1
                            variableNames = evalin(this.DataSource,'who');
                        end
                        variableValues = cellfun(@(x) evalin(this.DataSource,x), ...
                            variableNames,'UniformOutput',false);
                    elseif strcmp(this.DataSourceType,'matfile')
                        data = load(this.DataSource);
                        if nargin == 1
                            variableNames = fieldnames(data);
                        end
                        variableValues = cellfun(@(x) data.(x), variableNames, ...
                            'UniformOutput',false);
                    end
                    data = [variableNames, variableValues];
                catch ex
                    rethrow(ex);
                end
            end
        end
        
        function selectedData = getSelectedData(this)
            % Method "getSelectedData":
            %   Gets the selected variable names and values from the source.
            %   Depends on the variable name as the first column in the table
            %   returned by "getTableData".
            %
            %   data = getSelectedData(this)
            %       "data" is M x 2 cell array of names and values of the M
            %       selected variables in the source specified in
            %       "DataSource".
            selectedData = {};
            idx = getSelectedIdx(this);
            if ~isempty(idx)
                variableNames = getVariableNamesInTable(this);
                selectedVariableNames = variableNames(idx);
                selectedData = getData(this,selectedVariableNames{:});
            end
        end
        
        function callbackCancelButton(this)
            close(this);
        end
     end
    
    %% Protected methods (to be overloaded)
    methods(Access = protected)
        function buildCustomWidgets(this) %#ok<*MANU>
            % Method "buildCustomWidgets":
            %
            % Called during the buildUI() method. Overload this method to build and add custom widgets to the
            % dialog. Use the "addWidget" method to add the widgets.
        end
        
        function preUpdateUI(this)
            % Method "preUpdateUI":
            %
            % Called at the beginning of the updateUI() method. Overload
            % this method to update any custom widgets.
            %
            %   preUpdateUI(this)
        end
        
        function postUpdateUI(this)
            % Method "postUpdateUI":
            %
            % Called at the end of the updateUI() method. Overload
            % this method to update any custom widgets.
            %
            %   postUpdateUI(this)
        end
        
        function cleanupCustomWidgets(this)
            % Method "cleanupCustomWidgets":
            %
            % Called at the beginning of the cleanupUI() method. Overload
            % this method to clean up any custom widgets.
            %
            %   cleanupCustomWidgets(this)
        end
    end
    
    %% qeFunctions
    methods(Hidden, Sealed)
        function widgets = qeGetWidgets(this)
            % Method "qeGetWidgets":
            %   Returns a struct of all widgets.
            customWidgets = qeGetCustomWidgets(this);
            containerWidgets = qeGetContainerWidgets(this);
            if ~isempty(customWidgets)
                widgets = table2struct([struct2table(containerWidgets,'AsArray',true),...
                                        struct2table(customWidgets,'AsArray',true)]);
            else
                widgets = containerWidgets;
            end
        end
    end
    
    methods(Hidden)        
        function customWidgets = qeGetCustomWidgets(this)
            % Method "qeGetCustomWidgets":
            %   Overload this method to return a struct of custom widgets.
            customWidgets = [];
        end
    end
end

function msg = m(varargin)
msg = getString(message(varargin{:}));
end

% LocalWords:  controllib matfile uicomponents

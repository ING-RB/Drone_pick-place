classdef AbstractExportDialog < controllib.ui.internal.dialog.MixedInImportExportContainer & ...
        controllib.ui.internal.dialog.AbstractDialog
    % "AbstractExportDialog"
    %
    % Super class that implements uicomponents and provides helper data
    % methods for "Export Dialogs" that display a table based on variables
    % and exports selected to data to specified sink.
    %
    % Properties
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.AllowMultipleRowSelection">AllowMultipleRowSelection</a>
    %   - Builds table with the first column as a checkbox that allows
    %   selection of multiple rows.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ShowExportAsColumn">ShowExportAsColumn</a>
    %   - Builds table with a column as an editable text box that
    %   allows user to specify the variable name to which the data is
    %   exported.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ShowRefreshButton">ShowRefreshButton</a>
    %   - Allows removal of Refresh button in the dialog.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ShowHelpButton">ShowHelpButton</a>
    %   - Allows removal of Help button in the dialog.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ShowSelectAllButtons">ShowSelectAllButtons</a>
    %   - Allows addition of Select all and Unselectall buttons in the dialog.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ColumnWidth">ColumnWidth</a>
    %   - Specify the width of the columns in the table.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.HeaderText">HeaderText</a>
    %   - Specify the header label (first row of the dialog).
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.TableTitle">TableTitle</a>
    %   - Specify the title above the table.
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractExportDialog.DialogSize">DialogSize</a>
    %   - Specify the size of the dialog(uifigure) in pixels.
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.ActionButtonLabel">ActionButtonLabel</a>
    %   - Specify the label for the Export Button.
    %
    % Methods (Protected, Sealed)
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.refreshTable">refreshTable</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.updateTable">updateTable</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.setSink">setSink</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.getSelectedIdx">getSelectedIdx</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.qeGetCustomWidgets">qeGetCustomWidgets</a>
    %
    % Methods (Can be overloaded)
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.buildCustomWidgets">buildCustomWidgets</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.cleanupCustomWidgets">cleanupCustomWidgets</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.preUpdateUI">preUpdateUI</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.AbstractImportDialog.postUpdateUI">postUpdateUI</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.callbackHelpButton">callbackHelpButton</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.callbackActionButton">callbackActionButton</a>
    %
    % Abstract Methods
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.getTableData">getTableData</a>
    %   <a href="matlab:help controllib.ui.internal.dialog.MixedInImportExportContainer.getValueAt">getValueAt</a>
    
    % Copyright 2019-2022 The MathWorks, Inc.
    
    %% Protected Properties
    properties (Access = protected)
        % Property "DialogSize": 
        %   Size of the dialog (uifigure) specified as a numeric vector of
        %   the form [width height] in pixels.
        DialogSize = []
    end
    
    %% Private Properties
    properties(Access = private)
        DataSinkType = 'workspace'
        DataSink = 'base'
    end
    
    %% Events
    events
        % Event "ExportCompleted"
        %
        % The dialog sends this event after the execution of the
        % Export button callback, "callbackActionButton()" with the data of
        % the exported variable names.
        ExportCompleted
    end
    
    %% Public methods
    methods(Sealed)
        % constructor
        function this = AbstractExportDialog(name,title)
            this@controllib.ui.internal.dialog.AbstractDialog;
            this.Name = name;
            this.Title = title;
            this.TableTitle = getString(message('Controllib:gui:AbstractExportDialogTableBorder'));
            this.SelectColumnName = m('Controllib:gui:AbstractExportDialogExport');
            this.ShowExportAsColumn = true;
            this.ShowRefreshButton = false;
            this.ActionButtonLabel = getString(message('Controllib:gui:AbstractExportDialogExport'));
        end
        
        function updateUI(this)
            % Method "updateUI":
            if this.IsWidgetValid
                preUpdateUI(this);
                refreshTable(this);
                postUpdateUI(this);
            end
        end
    end
    
    %% Protected sealed methods
    methods (Access = protected, Sealed = true)
        function buildUI(this)
            % Method "buildUI":
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
        
        function setSink(this,sink,sinkType)
            % Method "setSink":
            %
            % Specifies the sink that the data is exported to
            %
            %   setSink(this,sink)
            %       "sink" specifies the workspace and can be 'base' (for
            %       base workspace) or a Simulink.ModelWorkspace.
            %   setSink(this,sink,sinkType)
            %       "sink" is a string specifying the MAT filename, or
            %       'base' (for base workspace) or a
            %       Simulink.ModelWorkspace. "sinkType" can be 'matfile'
            %       or 'workspace'.
            if nargin == 2
                sinkType = 'workspace';
            else
                validatestring(sinkType,{'workspace','matfile'});
            end
            this.DataSinkType = sinkType;
            this.DataSink = sink;
        end
        
        function callbackCancelButton(this)
            % Method "callbackCancelButton":
            close(this);
        end
        
        function isExportDone = export(this,variableValues,variableNames)
            % Method "export":
            %
            % Exports the data to the defined sink.
            %
            %   isExportDone = export(this,variableValues,variableNames)
            %       "variableValues" is a cell array containing the value
            %       of the data to be exported. "variableNames" is a cell
            %       array containing the corresponding names (as a string
            %       or char array). 
            %
            %       The length of "variableValues" and "variableNames"
            %       should be same.
            %
            %       "isExportDone" is a logical value indicating whether
            %       export was completed.
            isExportDone = false;
            
            % Get additional data
            
            n = length(variableValues);
            switch this.DataSinkType
                case 'workspace'
                    newVariableNames = ...
                        matlab.lang.makeUniqueStrings(variableNames,evalin(this.DataSink,'who'));
                    if ~isequal(newVariableNames,variableNames)
                        existingVariableNames = setdiff(variableNames,newVariableNames);
                        existingVariableNamesString = existingVariableNames{1};
                        for k = 2:length(existingVariableNames)
                            existingVariableNamesString = [existingVariableNamesString,...
                                ', ', existingVariableNames{k}]; %#ok<AGROW> 
                        end
                        confirmMessage = m('Controllib:gui:AbstractExportDialogExistingVariablesMessage',...
                                            existingVariableNamesString);
                                        
                        strExportAnyway = m('Controllib:gui:AbstractExportDialogstrExportAnyway');
                        strCancel = m('Controllib:gui:AbstractExportDialogCancel');
                        answer = uiconfirm(this.UIFigure,...
                            confirmMessage,...
                            m('Controllib:gui:AbstractExportDialogExistingVariablesTitle'),...
                            'Options',{strExportAnyway,strCancel},'DefaultOption',strCancel,...
                            'Icon','warning');
                        if strcmp(answer, strExportAnyway)
                            for ct = 1:n
                                % overwrite
                                assignin(this.DataSink,variableNames{ct},variableValues{ct});
                            end
                        else
                            return
                        end
                    else
                        for ct = 1:n
                            % overwrite
                            assignin(this.DataSink,variableNames{ct},variableValues{ct});
                        end
                    end
                    isExportDone = true;
                case 'matfile'
                    if isempty(this.DataSink)
                        [filename,pathname] = uiputfile('*.mat');
                        if filename
                            file = fullfile(pathname,filename);
                        else
                            isExportDone = false;
                            return;
                        end
                    else
                        file = this.DataSink;
                    end
                    for ct = 1:n
                        exportData.(variableNames{ct}) = variableValues{ct};
                    end
                    save(file,'-struct','exportData');
                    isExportDone = true;
            end
        end
    end
    
    %% Implementation of protected abstract or overloaded methods
    methods(Access = protected)
        function callbackActionButton(this)
            % Method "callbackActionButton":
            isPreActionSuccessful = preActionCallback(this);
            if isPreActionSuccessful
                try
                    idx = getSelectedIdx(this);
                    [additionalVarValues, additionalVarNames] = getAdditionalDataToExport(this);
                    % Error if nothing selected and no additional data
                    if isempty(idx) && isempty(additionalVarValues)
                        Title = m('Controllib:gui:AbstractExportDialogNoneSelectedTitle',...
                            this.VariableColumnName);
                        ErrorMessage = m('Controllib:gui:AbstractExportDialogNoneSelectedError',...
                            this.VariableColumnName);
                        uialert(this.UIFigure,ErrorMessage,Title);
                        return;
                    end
                    % Get variable names
                    exportedAsVariableNames = getExportVariableNames(this,idx);
                    variableValues = arrayfun(@(k) getValueAt(this,k),idx,'UniformOutput',false);
                    % Append additional variable values and names
                    if ~iscell(additionalVarValues)
                        additionalVarValues = {additionalVarValues};
                    end
                    if ~iscell(additionalVarNames)
                        additionalVarNames = {additionalVarNames};
                    end
                    variableValues = [variableValues(:); additionalVarValues(:)];
                    exportedAsVariableNames = [exportedAsVariableNames(:); additionalVarNames(:)];
                    % Export
                    isExportDone = export(this,variableValues,exportedAsVariableNames);
                    if isExportDone
                        allVariableNames = getVariableNamesInTable(this);
                        selectedVariableNames = allVariableNames(idx);
                        % Create data structure for event data
                        data = struct('ExportedAsVariableNames',exportedAsVariableNames,...
                                      'VariableNames',selectedVariableNames);
                        ed = ctrluis.toolstrip.dataprocessing.GenericEventData(data);
                        % Notify event
                        notify(this,'ExportCompleted',ed);
                        close(this);
                    else
                        return;
                    end
                catch Ex
                    ErrorMessage = Ex.message;
                    uialert(this.UIFigure,ErrorMessage,this.Title);
                end
            end
        end
        
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

        function isSuccessful = preActionCallback(this)
            % Method "preActionCallback":
            %
            % Called at the start of of the callbackActionButton method.
            % Overload this method to execute any actions before the export
            % process is executed.
            %
            %   isSuccessful = preActionCallback(this)
            isSuccessful = true;
        end
        
        function cleanupCustomWidgets(this)
            % Method "cleanupCustomWidgets":
            %
            % Called at the beginning of the cleanupUI() method. Overload
            % this method to clean up any custom widgets.
            %
            %   cleanupCustomWidgets(this)
        end
        
        function [variableValue, variableName] = getAdditionalDataToExport(this)
            % Method "getAdditionalDataToExport":
            %
            % Called when action button pushed. Overload this method to
            % provide additional variable values and names to export.
            %
            %   [variableValue,variableName] = getAdditionalDataToExport(this)
            %       variableValue and variableName is a cell array
            variableValue = {};
            variableName = {};
        end
    end
    
    %% Abstract methods
    methods(Access = protected, Abstract)
        % Abstract Method "getValueAt":
        %
        % Return the value of the object at the specified indices in the
        % table.
        %
        %   value = getValueAt(this,idx)
        getValueAt(this,idx);
    end
    
    %% qeFunctions
    methods (Hidden)
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
        function customWidgets = qeGetCustomWidgets(this)
            % Method "qeGetCustomWidgets":
            %   Overload this method to return a struct of custom widgets.
            customWidgets = [];
        end
        function table = qeGetJTable(this)
            widgets = qeGetContainerWidgets(this);
            table = widgets.UITable;
        end
        function qeCallbackExportButton(this)
            callbackActionButton(this);
        end
        function qeCallbackCancelButton(this)
            callbackCancelButton(this);
        end
        function qeCallbackHelpButton(this)
            callbackHelpButton(this);
        end
    end
end

function msg = m(varargin)
msg = getString(message(varargin{:}));
end
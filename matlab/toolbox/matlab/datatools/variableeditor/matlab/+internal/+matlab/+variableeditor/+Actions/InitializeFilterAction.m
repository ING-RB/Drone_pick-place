classdef InitializeFilterAction < internal.matlab.variableeditor.VEAction
    % InitializeFilterAction creates a filter manager and document
    % representing the filtered state of each variable in tabular
    % datatypes.

    % Copyright 2018-2024 The MathWorks, Inc.

    properties (Constant)
        ActionType = 'InitializeFilterAction';
        CheckboxColumnWidth = 35;
        DefaultValuesColumnWidth = 128;
        CountsColumnWidth = 35;
    end

    properties
        deletionListener = [];
        ValuesColumnWidth;
    end

    properties(Access=private, Transient)
        filterdDataChangeListener;  % Dictionary
        updateFilterFigureListener; % Dictionary
        DocClosedListener;
    end

    methods
        function this = InitializeFilterAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.InitializeFilterAction.ActionType;
            props.Enabled = true;
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.Callback = @this.InitFilter;
            this.filterdDataChangeListener = dictionary; % One entry per table
            this.updateFilterFigureListener = dictionary; % One entry per filter figure
            this.DocClosedListener = addlistener(this.veManager,'DocumentClosed',@(e,d)this.handleCleanup(d));
        end

        % The "FilteredDataChanged" callback function when a filter figure
        % filter action is made.
        function updateFilterFigureInformation(this, tws, embeddedTableDoc, varName, varVal)
            % If the variable doesn't exist anymore delete our listeners
            % (g3035981) isvalid for (g3071789)
            if ~tws.isVariable(varName) || ~isvalid(embeddedTableDoc)
                this.clearAllListeners();
                return;
            end

            % Update the filter figure's information.
            JSONPlotData = this.generateAndUpdateFilterFigureInfo(tws, embeddedTableDoc, varName, varVal);
            embeddedTableDoc.ViewModel.setProperty('CanvasID', JSONPlotData);
        end

        % Send the client the number of filtered rows and the original row count.
        function sendFilteredSummaryInformation(this, tws, mgr)
            filterSummary = tws.FilteredDataSummary;
            mgr.setProperty('FilterDataSummary', filterSummary);
            this.updateMetaDataStateOnObj(filterSummary);
        end
        
        function InitFilter(this, filtInfo)
            index = filtInfo.actionInfo.index;

            channel = strcat('/VE/filter',filtInfo.docID);
            mgr = internal.matlab.variableeditor.peer.VEFactory.createManager(channel, false);

            %Find the correct document to initialize the data in the new WS
            idx = arrayfun(@(x) isequal(x.DocID, filtInfo.docID), this.veManager.Documents);
            doc = this.veManager.Documents(idx);

            if isKey(mgr.RegisteredWorkspaces, 'filterWorkspace') 
                tws = mgr.Workspaces('filterWorkspace');
            else
                % Create a new workspace for filtering using the Doc
                tws = internal.matlab.variableeditor.Actions.Filtering.TabularVariableFilteringWorkspace(doc.DataModel.Data);
                % Register the new workspace
                mgr.registerWorkspace(tws, 'filterWorkspace');

                % If a general data change listener isn't registered for
                % the document, register it.
                if ~isConfigured(this.filterdDataChangeListener) || ~isKey(this.filterdDataChangeListener, doc.Name)
                    this.filterdDataChangeListener(doc.Name) = event.listener(tws, ...
                        'FilteredDataChanged', @(es,ed)this.sendFilteredSummaryInformation(tws,mgr));
                end
            end
            varName = doc.ViewModel.getHeaderInfoFromIndex(index+1);
            embeddedTableDoc = mgr.openvar(varName, tws, internal.matlab.variableeditor.NullValueObject('null'), UserContext='filtering');
            % In some instances of the Variable Editor setting a new
            % Variable can trigger filter state update, and new data
            % doesn't get set until an openvar happens.  This means the
            % we need to check the variable name state after the openvar
            % g3206106
            if ~tws.isVariable(varName)
                % We got the previous variables name, try again
                varName = doc.ViewModel.getHeaderInfoFromIndex(index+1);
                embeddedTableDoc = mgr.openvar(varName, tws, internal.matlab.variableeditor.NullValueObject('null'), UserContext='filtering');
            end


            % Initialize tablemodelprops
            if ~isempty(embeddedTableDoc) && ~isempty(embeddedTableDoc.ViewModel) && ismethod(embeddedTableDoc.ViewModel, 'setTableModelProperty')
                % ColumnWidth used to be sent from the client for syncup
                % and this caused unnecessary tablemodelprop updates. Hard code the value here, but convert client side filterdialog
                % to use columnConfigs at construct time with ColumnWidth wired in.
                embeddedTableDoc.ViewModel.setTableModelProperties('ShowSparkLines', false, 'ShowStatistics', false, 'ColumnWidth', 35);
            end

            varVal = tws.(varName);
            callbackDictionaryKey = strcat(doc.Name, varName);
            varIsNotCategorical = ((isfloat(varVal.Values) || isinteger(varVal.Values)) && isreal(varVal.Values) || isdatetime(varVal.Values) || isduration(varVal.Values));

            JSONPlotData = '';

            if varIsNotCategorical
                % g2953400: Update the filter figure information after detecting a "FilteredDataChanged" event.
                % This is necessary to propagate filtered changes from one column to all other columns in the table,
                % e.g., when rows get filtered out after a categorical filtering.
                if ~isConfigured(this.updateFilterFigureListener) || ~isKey(this.updateFilterFigureListener, callbackDictionaryKey)
                    this.updateFilterFigureListener(callbackDictionaryKey) = event.listener(tws, 'FilteredDataChanged', ...
                        @(es,ed) this.updateFilterFigureInformation(tws, embeddedTableDoc, varName, varVal));
                end

                % Create the server-side filter figure and get its ID.
                % The ID will be bundled with the JSON data so that the client knows
                % which specific figure to talk to.
                JSONPlotData = this.generateAndUpdateFilterFigureInfo(tws, embeddedTableDoc, varName, varVal);
                embeddedTableDoc.ViewModel.setProperty('CanvasID', JSONPlotData);
            end

            % Adding 10 to the Values column if there are lesser than 9
            % rows of data since we don't need to leave space for the
            % vartical scrollbars
            if (height(embeddedTableDoc.DataModel.Data) < 12)
                this.ValuesColumnWidth = this.DefaultValuesColumnWidth + 10;
            else
                this.ValuesColumnWidth = this.DefaultValuesColumnWidth;
            end

            % Set variable column widths for the embedded table dropdown
            % TODO: This needs to be refactored so that we are setting the
            % "ColumnWidth" model prop. 
            % FilteredColumnWidth is a temporary prop we are using to prevent
            % the display of LE Tables being affected.
            embeddedTableDoc.ViewModel.setColumnModelProperty(1, 'FilteredColumnWidth', this.CheckboxColumnWidth);
            embeddedTableDoc.ViewModel.setColumnModelProperties(2, 'FilteredColumnWidth', this.ValuesColumnWidth, 'editable', false);
            embeddedTableDoc.ViewModel.setColumnModelProperties(3, 'FilteredColumnWidth', this.CountsColumnWidth, 'editable', false);

            % Temporary workaround for mf0 bug. If canvasID exists, set as
            % TableModelProperty(g2331999)
            if ~isempty(JSONPlotData)
                embeddedTableDoc.ViewModel.setTableModelProperty('CanvasID', JSONPlotData);
            end
        end

        function JSONPlotData = generateAndUpdateFilterFigureInfo(~, tws, embeddedTableDoc, varName, varVal)
            figureID = tws.getFigureData(varName);
            filterFigure = tws.getFigure(varName);

            allDataFilteredOut = isempty(varVal.OriginalMin);
            if (allDataFilteredOut)
                % Even if all the data is filtered out, we must grab the
                % min and max of the original data for the user to see the
                % range of their data.
                origMin = min(tws.OriginalTable.(varName));
                origMax = max(tws.OriginalTable.(varName));
            else
                origMin = varVal.OriginalMin(1);
                origMax = varVal.OriginalMax(1);
            end

            filteredVarVal = embeddedTableDoc.Workspace.(varName);
            % g2953400: Rather than using "varVal" as the data to generate sparkline data, we use "filteredVarVal".
            % "varVal" is the original data for the column, and "filteredVarVal" is the filtered data (may have less rows).
            %
            % For example, let's say we have columns A and B. The user filters column A in a way that half of
            % column B's rows are filtered out. "varVal" for column B still has all the original data, but
            % "filteredVarVal" correctly only has half the original data, so we use the latter to generate sparkline data.
            %
            % We must still pass in the original min and max values; these serve as the limits of the data.
            [packagedData, histCountsEdges] = internal.matlab.variableeditor.peer.plugins.GenerateSparklineData(filteredVarVal, origMin, origMax);
            packagedData.serverFigureID = figureID;
            filterFigure.HistCounts = histCountsEdges;

            % Get the values the filter handles should be placed at.
            [minFilterHandleValue, maxFilterHandleValue] = filterFigure.getMinMaxFilterHandleValues();
            packagedData.minFilterHandleValue = minFilterHandleValue;
            packagedData.maxFilterHandleValue = maxFilterHandleValue;

            JSONPlotData = jsonencode(packagedData);
        end

        function UpdateActionState(this)
            this.Enabled = true;
        end
        
        % On DocumentClose, remove numeric varnames that were previously added to
        % datamanager via VarNamesMap.
        function handleCleanup(this, ed)
            % Make sure we haven't already cleaned up
            if isempty(this.filterdDataChangeListener)
                return;
            end
            % Clean up the table-level listener.
            if isConfigured(this.filterdDataChangeListener) && isKey(this.filterdDataChangeListener, ed.Name)
                lh = this.filterdDataChangeListener(ed.Name);
                delete(lh);
                this.filterdDataChangeListener(ed.Name) = [];
                internal.matlab.datatoolsservices.FormatDataUtils.getSetFilteredVariableInfo(ed.Name, [], false);
            end

            % Clean up filter figure-level listeners for the table.
            if isConfigured(this.updateFilterFigureListener)
                figKeys = keys(this.updateFilterFigureListener);
                figsToClean = figKeys(startsWith(figKeys(:), ed.Name));

                for i = 1:length(figsToClean)
                    curKey = figsToClean(i);
                    lh = this.updateFilterFigureListener(curKey);
                    delete(lh);
                    this.updateFilterFigureListener(curKey) = [];
                    % No more cleaning necessary. Filter figure cleanup is handled in the workspace.
                end
            end
        end

        function clearAllListeners(this)
            if isConfigured(this.filterdDataChangeListener)
                k = keys(this.filterdDataChangeListener);
                for i=1:length(k)
                    ed.Name = k{i};
                    this.handleCleanup(ed);
                end
            end

            if isConfigured(this.updateFilterFigureListener)
                k = keys(this.updateFilterFigureListener);
                for i = 1:length(k)
                    ed.Name = k{i};
                    this.handleCleanup(ed);
                end
            end
        end

        function delete(this)
            this.clearAllListeners();
        end
    end

    methods(Access='private')
        function updateMetaDataStateOnObj(this, filterSummary)
            doc = this.veManager.FocusedDocument;
            try
                if istabular(doc.DataModel.Data)                   
                    if (filterSummary.OriginalRowCount > filterSummary.FilteredRowCount)
                        internal.matlab.datatoolsservices.FormatDataUtils.getSetFilteredVariableInfo(doc.DataModel.Name, filterSummary.OriginalRowCount, true);
                    end
                end
            catch e
            end
        end
    end

    %% Test methods
    methods
        function listener = test_getFilteredDataChangeListener(this)
            listener = this.filterdDataChangeListener;
        end

        function test_setFilteredDataChangeListener(this, newListener)
            this.filterdDataChangeListener = newListener;
        end

        function listener = test_getUpdateFilterFigureListener(this)
            listener = this.updateFilterFigureListener;
        end

        function test_setUpdateFilterFigureListener(this, newListener)
            this.updateFilterFigureListener = newListener;
        end
    end
end

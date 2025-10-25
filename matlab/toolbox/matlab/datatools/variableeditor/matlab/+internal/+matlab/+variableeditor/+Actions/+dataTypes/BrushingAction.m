classdef BrushingAction < internal.matlab.variableeditor.VEAction
    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class handles bi-directional brushing numeric data with uifigures.
    
    % Copyright 2021-2024 The MathWorks, Inc.
    
    properties (Constant)
        ActionName = 'Brushing';
    end
    
    properties(Access= ?matlab.unittest.TestCase)
        LastSelectedRowIndices;
        VarNamesMap;
        DataManagerMap;
        LinkedVariables string = [];
        FigureToLinkedVariablesMap;
    end
    
    properties(Access=private, Transient)
        DocOpenedListener;
        DocClosedListener;
        VariablesLinkChangedListener;
        FocusedDocumentListeners;
    end

    methods
        function this = BrushingAction(props, manager)
           props.ID = internal.matlab.variableeditor.Actions.dataTypes.BrushingAction.ActionName;
           props.Enabled = false;
           props.Selected = false;
           this@internal.matlab.variableeditor.VEAction(props, manager);
           this.Callback = @this.handleBrush;
           this.VarNamesMap = containers.Map;
           this.FigureToLinkedVariablesMap = containers.Map;
           this.DataManagerMap = dictionary(string.empty, logical.empty);

           % If a document is opened and focused on, call handleDocumentOpened() with that specific
           % document. This will help with finding figures associated with the focused document.
           if ~isempty(manager.FocusedDocument)
               ed.Document = manager.FocusedDocument;
               this.handleDocumentOpened(ed)
           elseif ~isempty(manager.Documents)
                % g3405619: If there is no focused document, but _any_ document exists, we proceed with
                % calling handleDocumentOpened(). If this block is entered, it's likely the case
                % focus is being set at a later point in time.
                ed.Document = manager.Documents(end);
                this.handleDocumentOpened(ed);
           else % No documents exist
               this.DocOpenedListener = addlistener(this.veManager,'DocumentOpened',@(e,d)this.handleDocumentOpened(d));
           end
           this.DocClosedListener = addlistener(this.veManager,'DocumentClosed',@(e,d)this.handleDocumentClosed(d));
        end

        function UpdateActionStateOnFocusedDocument(this, focusedDoc)
                data = focusedDoc.DataModel.Data;
                if isprop(focusedDoc.DataModel, 'DataI')
                    data = focusedDoc.DataModel.DataI;
                end

                if ismatrix(data) && (isnumeric(data) || istabular(data))
                    % Update brushedState for focusedDoc
                    this.updateBrushedState(focusedDoc);
                    return;
                else
                    this.Enabled = false;
                end

        end
        % The Action will only be available for tables and numeric types.
        function UpdateActionState(this)
            focusedDoc = this.veManager.FocusedDocument;
           
            if ~isempty(focusedDoc)
                this.UpdateActionStateOnFocusedDocument(focusedDoc);
            else
                this.addOneShotDocumentFocusGainedListener('UpdateActionState',@(focusedDocument) UpdateActionStateOnFocusedDocument(this,focusedDocument));
            end
        end

        % API is called by brushManager's draw method whenever a brush
        % action was done on the plot. This method reshapes the indices and
        % updates selection on the Variable Editor's document.
        function setSelection(this, varName, brushedIndices, forceUpdate)
            arguments
                this
                varName
                brushedIndices = []
                forceUpdate = false
            end
            % If the variable is brushed from the editor, do not update
            % selection
            if ~isempty(this.LastSelectedRowIndices) && isequal(this.LastSelectedRowIndices, brushedIndices)
                if any(brushedIndices(:)) && ~forceUpdate
                    return;
                end
            end
            baseVarName = matlab.internal.datatoolsservices.getBaseVariableName(varName);
            idx = arrayfun(@(x) isequal(x.Name, baseVarName), this.veManager.Documents);
            brushedDoc = this.veManager.Documents(idx);
            if ~isempty(brushedDoc)
                brushedViewModel = brushedDoc.ViewModel;
                mode = brushedViewModel.getProperty('BrushingMode');
                if ~isempty(mode) && mode
                    this.updateSelectionIndices(brushedIndices, brushedViewModel);
                end
            end
            % Find all other connectedVars for the same variable and update their brushingProp
            % TODO: Explore if this can be done via BrushMgr, currently
            % this will only work if the variable is open.
            variableName = matlab.internal.datatoolsservices.getImmediateParentName(varName);
            if (this.VarNamesMap.isKey(variableName))
                connectedVars = this.VarNamesMap(variableName);

                % Note that datamanager.BrushManager may fail if Java is not
                % available, because internally it uses Java classes
                brushMgr = datamanager.BrushManager.getInstance();
                connectedVars = connectedVars(~strcmp(connectedVars, varName));
                connectedVars = connectedVars(ismember(connectedVars, brushMgr.VariableNames'));
                for i=1:length(connectedVars)
                      ind = find(strcmp(connectedVars{i},brushMgr.VariableNames));
                      if ~isempty(ind)
                          currBrushedIndex = brushMgr.SelectionTable(ind).I;
                          if ~isequal(currBrushedIndex, brushedIndices)
                             brushMgr.setBrushingProp(connectedVars{i},'','','I',brushedIndices);
                             brushMgr.draw(connectedVars{i},'','');
                          end
                      end
                end
            end
        end
        
        function updateSelectionIndices(this, brushedIndices, brushedViewModel)
            % If we are brushing from plot and VE has stale selection,
            % clear this.
            [k,c]=find(brushedIndices);
            % Brushed indices are set, get row/column Selection indices and setSelection.
            if ~isempty(k)
                kidx = unique(k);
                sz = brushedViewModel.getTabularDataSize;
                colIndices = [1 sz(2)];
                % If this is a row vector, construct selection intervals
                % for columns as well.
                if sz(1)==1
                    cidx = strjoin(string(unique(c)), ',');                        
                    colIndices = internal.matlab.variableeditor.BlockSelectionModel.getSelectionIntervals(brushedViewModel.DataModel.Data, char(cidx), 'cols');
                end
                selectionIdx = strjoin(string(kidx'), ',');
                minIdx = min(kidx);
                rowIndices = internal.matlab.variableeditor.BlockSelectionModel.getSelectionIntervals(brushedViewModel.DataModel.Data, char(selectionIdx), 'rows');
                % Scroll to the first brushed datapoint if not in viewport.
                if (~isempty(brushedViewModel.ViewportStartRow) && (minIdx < brushedViewModel.ViewportStartRow || minIdx > brushedViewModel.ViewportEndRow))
                    brushedViewModel.scrollViewOnClient(minIdx, 1);
                end
            else
                rowIndices = [];
                colIndices = [];
            end
            brushedViewModel.setSelection(rowIndices, colIndices, 'serverBrushing');
        end
        
        % returns a list of linked variables on brushed action, used for
        % testing purposes.
        function s = getLinkedVariables(this)
            s = this.LinkedVariables;
        end
        
        % Listener cleanup.
        function delete(this)
            if ~isempty(this.DocClosedListener)
                delete(this.DocClosedListener);
                this.DocClosedListener = [];
            end
            if ~isempty(this.VariablesLinkChangedListener)
            	delete(this.VariablesLinkChangedListener);
                this.VariablesLinkChangedListener = [];
            end
            if ~isempty(this.FocusedDocumentListeners)
                listenerArray = this.FocusedDocumentListeners.values;
                for k=1:length(listenerArray)
                    delete(listenerArray{k});
                end
                delete(this.FocusedDocumentListeners)
            end
            delete(this.VarNamesMap);
            delete(this.FigureToLinkedVariablesMap);
        end
    end
    
    methods(Access='protected')

        % Cleanup when figures that are linked are closed.
        function clearSelectionTable(~, linkedVariables)
            % Note that datamanager.BrushManager may fail if Java is not
            % available, because internally it uses Java classes
            brushMgr = datamanager.BrushManager.getInstance();
            if ~isempty(linkedVariables) && ~isempty(brushMgr.SelectionTable)
                % Get Parent name from linked variable (For a single
                % figure, they are most likely to all be linked to same
                % parent document)
                docName = matlab.internal.datatoolsservices.getImmediateParentName(linkedVariables(1));
                % Get list of all particpating variables from current parent
                selectionTableVarNames = brushMgr.VariableNames;
                brushedVars = find(contains(selectionTableVarNames, docName));
                % clear selectionTable for all these participating
                % variables. NOTE: Indices are just cleared, when variable
                % is closed, selectionVariables will be removed.
                for i=brushedVars'
                    idx = brushMgr.SelectionTable(i).I;
                    idx(:) = false;
                    brushMgr.setBrushingProp(selectionTableVarNames{i},'','','I',idx);
                end
            end
        end

        % The very first time a variable editor document is added, listen
        % on LinkGraphicsUpdated from LinkPlotManager
        function handleDocumentOpened(this, ed)
            % Add Listener on linkPlotMgr to notify whenever figure is linked or unlinked.
            if isempty(this.VariablesLinkChangedListener)
                linkPlotMgr = datamanager.LinkplotManager.getInstance;
                this.VariablesLinkChangedListener = addlistener(linkPlotMgr, ...
                    'LinkGraphicsUpdated', @(es,ed)this.handleLinkGraphicsUpdated(ed));

                % Note that datamanager.BrushManager may fail if Java is not
                % available, because internally it uses Java classes
                brushMgr = datamanager.BrushManager.getInstance();
                brushMgr.VEBrushAction = this;
                % If figures are already linked, update brushActionState
                if ~isempty(linkPlotMgr.Figures)
                    for i=1:length(linkPlotMgr.Figures)
                        evtData = datamanager.events.LinkedGraphicsUpdated;
                        evtData.VarNames = linkPlotMgr.Figures(i).VarNames;
                        evtData.FigureSource = linkPlotMgr.Figures(i);
                        this.handleLinkGraphicsUpdated(evtData, ed.Document);
                    end
                end
                if ~isempty(this.DocOpenedListener)
                    delete(this.DocOpenedListener);
                    this.DocOpenedListener = [];
                end
            end
        end

        % On Link Updated on the plots, hash varNames by FigureSource as
        % multiple varNames exist per figure. Construct LinkedVariables to
        % maintain a list of all active links to plots.
        function handleLinkGraphicsUpdated(this, evtData, focusedDoc)
            arguments
                this
                evtData
                focusedDoc = this.veManager.FocusedDocument
            end
            % disp(this.veManager);
            v = evtData.VarNames;
            % If the manager has no documents, this is a command line
            % workflow, there is nothing to update.
            if isempty(evtData.FigureSource) || isempty(this.veManager.Documents)
                return;
            end
            idx = num2str(double(evtData.FigureSource.Figure));
            linkedVariables = v(~cellfun(@isempty, v));
            isFigureLinked = isKey(this.FigureToLinkedVariablesMap, idx);
            if isFigureLinked
                origLink = this.FigureToLinkedVariablesMap(idx);
                if isequal(origLink,linkedVariables)
                    return;
                end
            end
            if isempty(linkedVariables)
                linkedVariables = "";
            end
            % If all variables are empty, this is from an rmfigure call and
            % figure is being destroyed, update selectionTable accordingly
            if any(strcmp(evtData.EventSource, "rmFigure")) && isFigureLinked
                this.clearSelectionTable(this.FigureToLinkedVariablesMap(idx));
                this.Selected = false;
            end

            if ~isempty(focusedDoc)
                this.createVarNamesMapIfNotExists(focusedDoc);
            else
                this.addOneShotDocumentFocusGainedListener('handleLinkGraphicsUpdated',@(focusedDocument) createVarNamesMapIfNotExists(this,focusedDocument));
            end

            this.FigureToLinkedVariablesMap(idx) = unique(string(linkedVariables));
            valueSet = values(this.FigureToLinkedVariablesMap);
            l = [];
            for i=1:length(valueSet)
                l = [l valueSet{i}];
            end
            this.LinkedVariables = l(~strcmp(l ,""));
            this.updateBrushedState();
            % For a linked figure, assign brushingModeListener prop to
            % track when brushing mode is turned on or off.
            f = evtData.FigureSource.Figure;
            ax = findobj(f, 'type', 'axes');
            if ~isempty(ax)
                if ~isprop(ax,'VEBrushingModeListener')
                    pVEBrushingModeListener = addprop(ax,'VEBrushingModeListener');
                    pVEBrushingModeListener.Transient = true;
                    pVEBrushingModeListener.Hidden = true;
                    ax.VEBrushingModeListener = event.proplistener(ax.InteractionContainer, ax.InteractionContainer.findprop('CurrentMode'),...
                        'PostSet', @(mm, ed) this.localCurrentModeChange(ed.AffectedObject, f));
                end
            end
        end

        % When brushing is toggled on the figure and a Variableeditor document is open, turn on brushing in Variable Editor. 
        function localCurrentModeChange(this, interactionContainer, figureSource)
            linkedVars = this.FigureToLinkedVariablesMap(num2str(double(figureSource)));
            docName = matlab.internal.datatoolsservices.getImmediateParentName(linkedVars(1));
            docIndex = this.veManager.documentIndex(docName);
            if ~isempty(docIndex) && this.Enabled
                doc = this.veManager.Documents(docIndex);
                % IF brushing is turned on, toggle the brushingMode
                % property on the focused view that is linked, else toggle it off.
                if  strcmp(interactionContainer.CurrentMode, 'brush')
                    mode = doc.ViewModel.getProperty('BrushingMode');
                    if isempty(mode) || ~mode
                        this.Selected = true;
                    	doc.ViewModel.setProperty('BrushingMode', true);
                    end
                else
                    % If selected is true, then set to false.
                    if (this.Selected)
                        this.Selected = false;
                    end
                    doc.ViewModel.setProperty('BrushingMode', false);
                end
            end
        end

        % For the given document, update Enabled state only if the variable
        % is linked to a plot.
        function updateBrushedState(this, doc)
            arguments
                this;
                doc = this.veManager.FocusedDocument;
            end
            if ~isempty(doc) && ~isempty(this.VarNamesMap) && isKey(this.VarNamesMap, doc.Name)
                varNames = this.VarNamesMap(doc.Name);
                isBrushEnabled = ismember(varNames, this.LinkedVariables);
                this.Enabled = any(isBrushEnabled);
            else
                % We could just openvar and not have any linked variables,
                % set Enabled to false
                this.Enabled = false;
            end
        end

        % When linked plot is launched, add numeric varnames to
        % datamanager.
        function createVarNamesMapIfNotExists(this, focusedDoc)
            data = focusedDoc.DataModel.Data;
            varName = focusedDoc.Name;
            if ~isKey(this.DataManagerMap, varName)
                varNamesCellstr = {};
                if istabular(data)
                    tableSubset = data(:, vartype('numeric'));
                    varNames = tableSubset.Properties.VariableNames;
                    varNamesCellstr = cellfun(@(n)sprintf('%s.%s',varName, n),varNames, 'UniformOutput',false);
                elseif isnumeric(data)
                   varNamesCellstr = {varName}; 
                end
                for i=1:length(varNamesCellstr)
                    datamanager.addArrayEditorVariable(varNamesCellstr{i});
                end
                % If BrushedSelection already exists, update selection on the
                % newly opened table

                % Note that datamanager.BrushManager may fail if Java is not
                % available, because internally it uses Java classes
                brushMgr = datamanager.BrushManager.getInstance();
                if ~isempty(brushMgr.VariableNames)
                    idx = ismember(brushMgr.VariableNames, varNamesCellstr);
                    if (any(idx))
                        try
                            selectionTable = brushMgr.SelectionTable(idx);
                            if any(selectionTable(1).I)
                                this.updateSelectionIndices(selectionTable(1).I, focusedDoc.ViewModel);
                            end
                        catch
                        end
                    end
                end
                this.VarNamesMap(varName) = varNamesCellstr;
                this.updateBrushedState(focusedDoc);
                this.DataManagerMap(varName) = 1;
            end
        end
        
        % On DocumentClose, remove numeric varnames that were previously added to
        % datamanager via VarNamesMap.
        function handleDocumentClosed(this, ed)
            if isKey(this.VarNamesMap, ed.Name)
                varNamesCellstr = this.VarNamesMap(ed.Name);
                 for i=1:length(varNamesCellstr)
                    datamanager.rmArrayEditorVariable(varNamesCellstr{i});
                 end
                 remove(this.VarNamesMap, ed.Name);
            end
            if isKey(this.DataManagerMap, ed.Name)
                this.DataManagerMap(ed.Name) = [];
            end
            this.updateBrushedState(ed.Document);
        end

        % When a user turns brushing mode On | Off, we reflect the current
        % brushing state of the figure on the view. If figure has brushed
        % indices, update on the view, else just select the first row from
        % the user's plaid selection (Selecting entire selection on view is
        % likely to be expensive)
        function restoreExistingBrushOnView(this, docName)
            % Note that datamanager.BrushManager may fail if Java is not
            % available, because internally it uses Java classes
            brushMgr = datamanager.BrushManager.getInstance();
            currentBrushedVariables = contains(brushMgr.VariableNames, docName);
            if any(currentBrushedVariables)
                selectionTable = brushMgr.SelectionTable(currentBrushedVariables);
                currentSelectedNames = brushMgr.VariableNames(currentBrushedVariables);
                indices = selectionTable(1).I;
                % If nothing was brushed on the view or figure, update
                % view's selection to be a single row
                if isempty(find(indices, 1))
                    vm = this.veManager.FocusedDocument.ViewModel;
                    sz = vm.getSize();
                    % Select just the first row of the current selection
                    selection = vm.getSelection();
                    row = 1;
                    if ~isempty(selection) && ~isempty(selection{1})
                        row = selection{1};
                    end
                    vm.setSelection([row(1) row(1)], [1 sz(2)]);
                else
                    % Mirror the figure's brushed selection on the view.
                    this.setSelection(currentSelectedNames{1}, indices, true);
                end
            end
        end

        % Handles Brush Selection from client and updates indices on brushManager.
        % Converts selection indices to brushindices that are set as
        % SelectionTable.
        function handleBrush(this, actionInfo)
            mgr = this.veManager;
            data = mgr.FocusedDocument.DataModel.Data;
            % If any row styles are remaining, clear these styles as we
            % have received a fresh selection from client.
            docName = mgr.FocusedDocument.Name;
            if isfield(actionInfo, 'menuID') && strcmp(actionInfo.menuID, 'BrushingToggle')
                if (isfield(actionInfo, 'selected') && actionInfo.selected)
                    this.restoreExistingBrushOnView(docName);
                    return;
                end
            end
            if ~isfield(actionInfo,'actionInfo')
                return;
            end
            ss = actionInfo.actionInfo.Selection.selectedRows;  
            sc = actionInfo.actionInfo.Selection.selectedColumns;
            % For tables, add all the numeric columns within the table as a
            % BrushingProp.
            if istabular(data)
                idx = zeros(height(data),1);
                tableSubset = data(:, vartype('numeric'));
                varNames = tableSubset.Properties.VariableNames;
                varNamesCellstr = cellfun(@(n)sprintf('%s.%s',docName, n),varNames, 'UniformOutput',false);               
                colIdx = 1;
            else
                idx = zeros(size(data));
                varNamesCellstr = {docName};
                colIdx = (sc.start+1:sc.end+1);
            end           
            for i = 1:length(ss)
                if iscell(ss)
                    sRow = ss{i};
                else
                    sRow = ss(i);
                end
                idx(sRow.start+1:sRow.end+1,colIdx)=1;
            end
            
            % Note that datamanager.BrushManager may fail if Java is not
            % available, because internally it uses Java classes
            brushMgr = datamanager.BrushManager.getInstance();
            this.LastSelectedRowIndices = idx;
            for i=1:length(varNamesCellstr)
                brushMgr.setBrushingProp(varNamesCellstr{i},'','','I',idx);
                brushMgr.draw(varNamesCellstr{i},'','');
            end
        end
    end

    methods (Access = ?tBrushingAction)
        function addOneShotDocumentFocusGainedListener(this, id, callback)
            % Add a "one shot" listener to the Manager DocumentFocusGained
            % which calls the function callback. id is an identifier
            % which allows multiple distinct one-shot listeners to be added
            if isempty(this.FocusedDocumentListeners)
                this.FocusedDocumentListeners = containers.Map;
            end
            this.FocusedDocumentListeners(id) = event.listener(this.veManager,'DocumentFocusGained', @(~,eventData) this.oneShotDocumentFocusGainedListenerCallback(callback,eventData.Document,id));
        end

        function oneShotDocumentFocusGainedListenerCallback(this, callback, focusedDocument, id)
            feval(callback,focusedDocument);
            % Delete the listener and remove it from the
            % FocusedDocumentListeners once it is executed to prove the
            % "one shot" behavior
            delete(this.FocusedDocumentListeners(id));
            this.FocusedDocumentListeners(id) = [];
        end

    end
end





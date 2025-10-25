classdef PropertyEditInspector < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % Internal class that defines the PropertyEditInspector Object create
    % a UIInspector view to edit properties of tables/timetables.

    % Copyright 2021-2025 The MathWorks, Inc.

    properties (Access='protected')
        PropEditorFigure;
        DataChangedListeners;
    end

    properties(Constant, Access='private')
        VEChannel = '/VariableEditorMOTW';
        VAR_CUTOFF_FOR_AUTOREFRESH = 100;
    end

    methods (Access='protected')
        % On PropertyEditInspector creation, register the tablePropEditor
        % proxyViews with the Inspector.
        function obj = PropertyEditInspector()
            internal.matlab.inspector.peer.InspectorFactory.registerInspectorView("matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj",...
                "matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataProxyView");
            internal.matlab.inspector.peer.InspectorFactory.registerInspectorView("matlab.internal.datatools.sidepanelwidgets.propediting.TimeTableMetaDataObj",...
                "matlab.internal.datatools.sidepanelwidgets.propediting.TimeTableMetaDataProxyView");
            internal.matlab.inspector.peer.InspectorFactory.registerInspectorView("matlab.internal.datatools.sidepanelwidgets.propediting.VariableMetaDataObj",...
                "matlab.internal.datatools.sidepanelwidgets.propediting.VariableMetaDataProxyView");
            internal.matlab.inspector.peer.InspectorFactory.registerInspectorView("matlab.internal.datatools.sidepanelwidgets.propediting.DatasetMetaDataObj",...
                "matlab.internal.datatools.sidepanelwidgets.propediting.DatasetMetaDataProxyView");
            obj.DataChangedListeners = containers.Map();
        end

        % Called when Inspector needs to inspect the varname being passed
        % in. This method creates the proxy view to be inspected and also
        % publishes a divFigurePacket to the client
        function createPropertyEditor(this, varname, workspace, columnIndex)
            variable = evalin(workspace, varname);
            if isempty(this.PropEditorFigure)
                this.PropEditorFigure = matlab.ui.internal.divfigure("Name", "PropEditorInspectorFigure");
                % Enabling theming support on PropEditorFigure
                matlab.graphics.internal.themes.figureUseDesktopTheme(this.PropEditorFigure);
                grid = uigridlayout(this.PropEditorFigure, [1, 1]);
                grid.Padding = 0;
                propInspector = matlab.ui.control.internal.Inspector(Parent = grid, ...
                    ShowObjectBrowser=true, UseLabelForReadOnly = true, ShowClassInHierarchy=false, UseVarNameAsHierarchyTop=true, ObjectName=varname);
                propInspector.DataChangeFcn = @(es,ed) this.handleDataChangeOnInspector(ed);
                propInspector.ObjectBrowserSelectionChangeFcn = @(es,ed) this.handleObjBrowserSelectionChange(ed);
            end
            if ~isKey(this.DataChangedListeners, varname)
                factory = internal.matlab.variableeditor.peer.VEFactory.getInstance;
                mgr = factory.createManager(this.VEChannel, false);
                docIdx =  mgr.documentIndex(varname, workspace);
                if ~isempty(docIdx)
                    view = mgr.Documents(docIdx).ViewModel;
                    this.DataChangedListeners(varname) = addlistener(view, 'DataChange', @(e,d)this.refreshInspector(varname, workspace, docIdx));
                end
            end
            propInspector = this.PropEditorFigure.Children.Children;
            if istable(variable)
                metaDataObj = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj(variable, varname, workspace);
                proxyView = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataProxyView(metaDataObj);
            elseif istimetable(variable)
                metaDataObj = matlab.internal.datatools.sidepanelwidgets.propediting.TimeTableMetaDataObj(variable, varname, workspace);
                proxyView = matlab.internal.datatools.sidepanelwidgets.propediting.TimeTableMetaDataProxyView(metaDataObj);
            elseif isa(variable, 'dataset')
                metaDataObj = matlab.internal.datatools.sidepanelwidgets.propediting.DatasetMetaDataObj(variable, varname, workspace);
                proxyView = matlab.internal.datatools.sidepanelwidgets.propediting.DatasetMetaDataProxyView(metaDataObj);
            end
            if (width(variable) > this.VAR_CUTOFF_FOR_AUTOREFRESH)
                propInspector.AutoRefresh = false;
            end
            propInspector.ObjectName=varname;
            % Pass in topLevelObj along with Object to be inspected.
            propInspector.inspect(proxyView, proxyView);
            logColumnIndex("createPropertyEditor", columnIndex)
            if ~isempty(columnIndex) && all(columnIndex > 0)
                selectedChildIndex = columnIndex + 1;
                propInspector.subInspect(selectedChildIndex');
            else
                propInspector.SubInspectIndex = 0;
            end

            % create divfigure packet
            data = matlab.ui.internal.FigureServices.getDivFigurePacket(this.PropEditorFigure);
            data.context = "VEMetaDataPropertyEditor/" + varname ;
            data.widgetName = varname;
            this.publishMessage(data);
        end

        % This is called whenever DataChanged is fired on the View
        % indicating something changed w.r.t workspace variable 'varname'.
        % Explicitly compare for variables change/custom props change to
        % decide whether inspector must be refreshed.
        function refreshInspector(this, varname, workspace, docIdx)
            if isempty(this.PropEditorFigure)
                return;
            end
            factory = internal.matlab.variableeditor.peer.VEFactory.getInstance;
            mgr = factory.createManager(this.VEChannel, false);
            propInspector = this.PropEditorFigure.Children.Children;
            varNameChanged = false;
            oldVarname = varname;
            if ~isempty(docIdx)
                doc = mgr.Documents(docIdx);
                view = mgr.Documents(docIdx).ViewModel;
                % Check to see if the variable name has changed
                if ~strcmp(doc.Name, varname)
                    varNameChanged = true;

                    this.updateName(varname, doc.Name, view, workspace, docIdx);

                    varname = doc.Name;
                    propInspector.ObjectName = varname;
                end
            end
            objBeingInspected = propInspector.InspectedObjects;
            if isa(objBeingInspected, 'internal.matlab.inspector.InspectorProxyMixin')
                objBeingInspected = objBeingInspected.OriginalObjects;
            end
            if ~isa(objBeingInspected, 'internal.matlab.inspector.EmptyObject') && ...
                    ismethod(objBeingInspected, 'getObjName') && ...
                    strcmp(objBeingInspected.getObjName, oldVarname)

                if ~varNameChanged
                    parentObj = propInspector.TopLevelObj;
                    if isa(parentObj, 'internal.matlab.inspector.InspectorProxyMixin')
                        parentObj = parentObj.OriginalObjects;
                    end
                    parentObjVariables = parentObj.VariablesObj;
                    variable = evalin(workspace, varname);
                    tableProps = matlab.internal.datatools.sidepanelwidgets.propediting.TableMetaDataObj.getTableProperties(parentObj);
                    if isa(variable, "dataset")
                        currentObjVariables = tableProps.VarNames;
                    else
                        currentObjVariables = tableProps.VariableNames;
                    end
                    if isempty(currentObjVariables)
                        currentObjVariables = string.empty;
                    end
                    try
                        % Clause to check if Variables have changed
                        doUpdate = ~(length(parentObjVariables) == length(currentObjVariables)) || ...
                            ~all(strcmp(parentObjVariables, currentObjVariables));
                        if ~doUpdate
                            % Clause to check if Custom Properties have changed
                            parentObjCustomVars = parentObj.CustomPropsObj;
                            % Get custom properties as a row vector
                            currentObjCustomVars = reshape(properties(tableProps.CustomProperties),1,[]);
                            if isempty(currentObjCustomVars)
                                currentObjCustomVars = string.empty;
                            end
                            doUpdate = ~(length(parentObjCustomVars) == length(currentObjCustomVars)) || ...
                                ~all(matches(parentObjCustomVars, currentObjCustomVars));
                        end
                        if doUpdate
                            propInspector.inspect(internal.matlab.inspector.EmptyObject);
                            this.createPropertyEditor(varname, workspace, 0);
                        end
                    catch e
                        internal.matlab.datatoolsservices.logDebug("PropertyEditInspector::refreshInspector", e.message);
                    end
                else
                    try
                        propInspector.inspect(internal.matlab.inspector.EmptyObject);
                        this.createPropertyEditor(varname, workspace, 0);
                    catch e
                        internal.matlab.datatoolsservices.logDebug("PropertyEditInspector::refreshInspector", "Varname Update Error: " + e.message);
                    end
                end
            end
        end

        function updateName(this, oldName, newName, view, workspace, docIdx)
            % Variable name has changed
            internal.matlab.datatoolsservices.logDebug("PropertyEditInspector::refreshInspector", "Variable Name Changed from " + oldName + " to " + newName);

            % Delete the old DataChangeListner and create a new one
            l = this.DataChangedListeners(oldName);
            if ~isempty(l) && isvalid(l)
                delete(l);
                this.DataChangedListeners(oldName) = [];
            end
            this.DataChangedListeners(newName) = addlistener(view, 'DataChange', @(e,d)this.refreshInspector(newName, workspace, docIdx));

            % Variable name has changed, let client-side know
            data.context = "VEMetaDataPropertyEditor/" + oldName ;
            data.widgetName = oldName;
            data.activateContext = true;
            data.widgetNameChange = true;
            data.newWidgetName = newName;
            this.publishMessage(data);
        end

        function ignoreUpdates(this, varname, shouldIgnore)
            if isKey(this.DataChangedListeners, varname)
                dclistner = this.DataChangedListeners(varname);
                dclistner.Enabled = ~shouldIgnore;
            end
        end

        % Called when Inspector needs to Update to subInspect a variable already being inspected.
        % If the variable is not being actively inspected due to context changes, then call createPropertyEditor.
        % This method publishes a message to client notifying that context
        % has been activated.
        function updateInspector(this, name, workspace, columnIndex)
            if isempty(this.PropEditorFigure)
                return;
            end
            propInspector = this.PropEditorFigure.Children.Children;
            try
                var = evalin(workspace, name);
            catch e
                internal.matlab.datatoolsservices.logDebug("PropertyEditInspector::updateInspector", e.message);
                return
            end
            % Exclude time column for timetables
            if istimetable(var)
                columnIndex = columnIndex - 1;
                columnIndex(columnIndex==0) = [];
            end
            focusedView = this.getFocusedView();
            if ~isempty(focusedView)
                if ~isempty(focusedView.getGroupedColumnCounts)
                    dataIndices =[];
                    for i=columnIndex'
                        [~,dataIdx] = focusedView.getHeaderInfoFromIndex(i);
                        dataIndices = [dataIndices dataIdx]; %#ok<AGROW>
                    end
                    columnIndex = unique(dataIndices);
                end
            end
            if ~isa(propInspector.InspectedObjects, 'internal.matlab.inspector.EmptyObject')
                % Always inspect the topLevelObj using inspect API
                objBeingInspected = propInspector.TopLevelObj;
                if isa(objBeingInspected, 'internal.matlab.inspector.InspectorProxyMixin')
                    objBeingInspected = objBeingInspected.OriginalObjects;
                end
                tableName = objBeingInspected.TableName;
                if ~strcmp(name, tableName)
                    this.createPropertyEditor(name, workspace, columnIndex);
                    return;
                end
                % If column =0, this could be a request to view Table
                % Properties, switch to TopLevelObj inspection
                if (isequal(columnIndex, 0) || isempty(columnIndex))
                    propInspector.inspect(propInspector.TopLevelObj, propInspector.TopLevelObj);
                elseif ismethod(objBeingInspected, 'getObjName') && strcmp(objBeingInspected.getObjName, name)
                    propInspector.subInspect(columnIndex + 1);
                end
                data.context = "VEMetaDataPropertyEditor/" + name ;
                data.widgetName = name;
                data.activateContext = true;
                this.publishMessage(data);
            else
                this.createPropertyEditor(name, workspace, columnIndex);
            end
        end

        % When DataChanges on PropertyInspector, use this to set properties
        % on certain Inspected Objects.
        % TODO: Update when Command has unevaluated string
        function handleDataChangeOnInspector(~, ~)
        end

        function handleObjBrowserSelectionChange(this, ed)
            focusedView = this.getFocusedView();
            if ~isempty(focusedView)
                try
                    data = focusedView.DataModel.getCloneData;
                    if ~istimetable(data)
                        selectedCols = ed.SelectedIndices - 1;
                    else
                        selectedCols = ed.SelectedIndices;
                    end
                    gColCounts = focusedView.getGroupedColumnCounts;
                    if ~isempty(gColCounts)
                        selectedCols = internal.matlab.variableeditor.TableViewModel.getViewIndexFromDataIndex(selectedCols, gColCounts);
                    end
                    cidx = strjoin(string(unique(selectedCols)), ',');
                    % Pass size along as dataSize can be different from viewSize (nested tables and gcols usecase)
                    colIndices = internal.matlab.variableeditor.BlockSelectionModel.getSelectionIntervals(focusedView.DataModel.Data, char(cidx), 'cols', focusedView.getSize);
                    focusedView.setSelection([1 size(data, 1)], colIndices);
                    focusedView.scrollViewOnClient(missing, min(colIndices))
                catch e
                    internal.matlab.datatoolsservices.logDebug("PropertyEditInspector::handleObjBrowserSelectionChange", e.message);
                end
            end
        end

        function focusedView = getFocusedView(this)
            focusedView = [];
            factory = internal.matlab.variableeditor.peer.VEFactory.getInstance;
            mgr = factory.createManager(this.VEChannel, false);
            focusedDoc = mgr.FocusedDocument;
            if ~isempty(focusedDoc)
                focusedView = focusedDoc.ViewModel;
            end
        end

        % When the variable being inspected is closed, this is called.
        % Destroy editor by setting to EmptyObject so that the timer is not
        % running when no variables are being inspected.
        function destroyPropEditor(this, varname)
            if ~isempty(this.PropEditorFigure) && isvalid(this.PropEditorFigure)

                propInspector = this.PropEditorFigure.Children.Children;

                % If object being inspected is an empty object, ignore.
                if ~isa(propInspector.InspectedObjects, 'internal.matlab.inspector.EmptyObject')
                    % Reset AutoRefresh property when variable is closed. First
                    % reset and then inspect empty obj, else we will end up creating timers.
                    if ~propInspector.AutoRefresh
                        propInspector.AutoRefresh = true;
                    end

                    objBeingInspected = propInspector.InspectedObjects;
                    if isa(objBeingInspected, 'internal.matlab.inspector.InspectorProxyMixin')
                        objBeingInspected = objBeingInspected.OriginalObjects;
                    end
                    if ismethod(objBeingInspected, 'getObjName') && strcmp(objBeingInspected.getObjName, varname)
                        propInspector.inspect(internal.matlab.inspector.EmptyObject);
                    end
                end

            end
            % Cleanup Datachanged listener on viewmodel if exists
            if isKey(this.DataChangedListeners, varname)
                delete(this.DataChangedListeners(varname));
                remove(this.DataChangedListeners, varname);
            end
        end

        function publishMessage(~, data)
            message.publish('/DatatoolsSidePanel', data);
        end
    end

    methods(Static, Access='public')
        % getInstance
        function obj = getInstance()
            mlock; % Keep persistent variables until MATLAB exits
            persistent propEditInspector;
            if isempty(propEditInspector)
                propEditInspector =  matlab.internal.datatools.sidepanelwidgets.propediting.PropertyEditInspector();
            end
            obj = propEditInspector;
        end

        function createEditor(name, workspace, columnIndex)
            arguments
                name {mustBeText}
                workspace = 'debug'
                columnIndex = []
            end
            % client side indices are 0 indexed,add 1 to adjust to 1 based
            % indices.

            logColumnIndex("createEditor", columnIndex)
            if ~isempty(columnIndex)
                columnIndex = columnIndex + 1;
            end

            tb = evalin(workspace, name);
            if istimetable(tb) && ~isempty(columnIndex)
                % adjust for timetable indices
                columnIndex = columnIndex -1;
            end
            propEditInspector =  matlab.internal.datatools.sidepanelwidgets.propediting.PropertyEditInspector.getInstance();
            propEditInspector.createPropertyEditor(name, workspace, columnIndex);
        end

        function updateEditor(name, workspace, columnIndex)
            arguments
                name {mustBeText}
                workspace = 'debug'
                columnIndex = []
            end
            propEditInspector =  matlab.internal.datatools.sidepanelwidgets.propediting.PropertyEditInspector.getInstance();
            % client side indices are 0 indexed,add 1 to adjust to 1 based indices.
            logColumnIndex("updateEditor", columnIndex)
            if ~isempty(columnIndex)
                columnIndex = columnIndex + 1;
            end
            propEditInspector.updateInspector(name, workspace, columnIndex);
        end

        function ignoreUpdatesOnEditor(name, shouldIgnore)
            propEditInspector =  matlab.internal.datatools.sidepanelwidgets.propediting.PropertyEditInspector.getInstance();
            propEditInspector.ignoreUpdates(name, shouldIgnore);
        end

        function destroyEditor(name)
            propEditInspector =  matlab.internal.datatools.sidepanelwidgets.propediting.PropertyEditInspector.getInstance();
            propEditInspector.destroyPropEditor(name);
        end
    end

    % Methods for testing
    methods (Access={?matlab.unittest.TestCase})
        function fig = getPropEditFigure(this)
            fig = this.PropEditorFigure;
        end
    end
end

function logColumnIndex(prefix, columnIndex)
    arguments
        prefix string
        columnIndex double
    end
    if isempty(columnIndex)
        internal.matlab.datatoolsservices.logDebug("PropertyEditInspector", prefix + ": columnIndex is empty");
    elseif isscalar(columnIndex)
        internal.matlab.datatoolsservices.logDebug("PropertyEditInspector", prefix + ": columnIndex = " + num2str(columnIndex));
    else
        internal.matlab.datatoolsservices.logDebug("PropertyEditInspector", prefix + ": columnIndex = " + strjoin(string(num2str([1;2])), ","));
    end
end

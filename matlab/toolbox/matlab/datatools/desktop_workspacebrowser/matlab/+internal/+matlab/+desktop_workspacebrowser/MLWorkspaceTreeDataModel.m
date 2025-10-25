classdef MLWorkspaceTreeDataModel < internal.matlab.variableeditor.MLStructureTreeDataModel & internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel
    %MLWorkspaceTreeDataModel
    %   MATLAB Workspace TreeData Model

    % Copyright 2023-2024 The MathWorks, Inc.


    methods(Access='public')
        % Constructor
        function this = MLWorkspaceTreeDataModel(Workspace, ~)
            this@internal.matlab.variableeditor.MLStructureTreeDataModel(...
                'who', Workspace);
            this = this@internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel(Workspace)
        end

        % Overrides variableChanged in MLWorkspaceDataModel to handle variable changes.
        % Unlike MLWorkspaceDataModel, this implementation does not convert variables back 
        % to ObjectValueSummary since we support expanding container data types in the WSB.
        % We need to trigger the dataChanged event to update the UI by comparing the raw data.
        function data = variableChanged(this, options)
            % variableChanged() is called by the MLNamedVariableObserver
            % workspaceUpdated() method in response to workspace updates from the
            % WebWorkspaceListener to track changes in the data. However,
            % this method will also be called when the class of the
            % variable changes, which causes the MLDocument
            % variableChanged() method to replace this MLArrayDataModel by
            % a new one to represent the new class. Detect this case and
            % return early to avoid calling updateData on this about to be
            % deleted MLArrayDataModel
            arguments
                this
                options.newData = [];
                options.newSize = 0;
                options.newClass = '';
                options.eventType = internal.matlab.datatoolsservices.WorkspaceEventType.UNDEFINED;
                options.forceUpdate (1,1) logical = false;
                options.varNames = [];
            end
            if isempty(options.varNames) || (isStringScalar(options.varNames) && strlength(options.varNames) == 0)
                opts = namedargs2cell(options);
                data = variableChanged@internal.matlab.variableeditor.MLArrayDataModel(this, opts{:});
            else
                updateHandled = false;

                % VARIABLE_CHANGED is generated for adds and modifications
                if options.eventType == internal.matlab.datatoolsservices.WorkspaceEventType.VARIABLE_CHANGED
                    currDataModelData = this.Data;
                    currVarNames = fieldnames(currDataModelData);
                    incomingVarNames = options.varNames;
                    newData = options.newData;
                    varAddedIndices = true(1, length(incomingVarNames));

                    if isscalar(incomingVarNames)
                        varChangedIndices = strcmp(currVarNames, incomingVarNames);
                        varAddedIndices(any(incomingVarNames == currVarNames)) = false;
                    else
                        varChangedIndices = ismember(currVarNames, incomingVarNames);
                        varAddedIndices(ismember(incomingVarNames, currVarNames)) = false;
                    end
                    varsChanged = currVarNames(varChangedIndices);
                    varsAdded = incomingVarNames(varAddedIndices);

                    % Notify once after identifying which new vars are added.
                    if ~isempty(varsAdded)
                        varsToLog = internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.getVarsToLog(varsAdded);
                        internal.matlab.datatoolsservices.logDebug("MLWorkspaceDataModel::variableChanged::", "notifying var added: " + varsToLog);
                        this.notifyVarsAdded(varsAdded);
                        % notifyVarsAdded could have modified this.Data
                        currDataModelData = this.Data;
                        onlyVarsChanged = false;
                    else
                        onlyVarsChanged = true;
                    end

                    % Notify once after identifying which new vars have changed.
                    bytesColDisplayed = this.BytesColDisplayed;
                    if ~isempty(varsChanged)
                        numVars = length(varsChanged);
                        for idx = 1:numVars
                            varName = varsChanged{idx};
                            try
                                newData.(varName) = evalin(this.Workspace, varName);
                            catch
                            end

                            if onlyVarsChanged && isfield(currDataModelData, varName) && ~bytesColDisplayed
                                % Check if the value changed only if the bytes column
                                % isn't displayed.  If it is displayed,
                                % ObjectValueSummary classes will contain RawData, which
                                % can take time to compare, so we can just assume any
                                % change will affect the Bytes column.
                                try
                                    % Use isequaln to see if the value actually changed,
                                    % even if this is a ObjectValueSummary object (since
                                    % it contains the content of what is being displayed)
                                    iseq = isequaln(currDataModelData.(varName), newData.(varName));
                                    if iseq
                                        varChangedIndices(idx) = false;
                                    end
                                catch
                                    % ignore any errors
                                end
                            end

                            % Set the new data
                            currDataModelData.(varName) = newData.(varName);
                        end

                        % notify once after updating Data of the DataModel
                        varsToLog = internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.getVarsToLog(varsChanged);
                        internal.matlab.datatoolsservices.logDebug("MLWorkspaceDataModel::variableChanged::", "notifying var changed: " + varsToLog);
                        this.Data = currDataModelData;
                        varChangedPos = find(varChangedIndices);
                        if ~isempty(varChangedPos)
                            this.notifyVarChanged(min(varChangedPos), max(varChangedPos), incomingVarNames);
                        end
                    end
                    updateHandled = true;

                    % update return value for tests
                    data = this.getData;
                elseif options.eventType == internal.matlab.datatoolsservices.WorkspaceEventType.VARIABLE_DELETED
                    data = this.getData;
                    fn = fieldnames(data);

                    % It's possible some of the deleted variables have already
                    % been removed from the data, for example when events get
                    % queued up.  Only call notifyVarsDeleted() if there are
                    % variables which we've removed here.
                    if any(cellfun(@(x) any(strcmp(x, fn)), options.varNames))
                        deletedRows = [];
                        deletedVars = string.empty;
                        for idx = 1:length(options.varNames)
                            varName = options.varNames(idx);
                            varIdx = strcmp(fn, varName);
                            if any(varIdx)
                                deletedRows(end+1) = find(varIdx); %#ok<*AGROW>
                                deletedVars(end+1) = varName;
                            end
                        end
                        internal.matlab.datatoolsservices.logDebug("MLWorkspaceDataModel::variableChanged::", "notifying var deleted");
                        if ~isempty(deletedRows)
                            this.notifyVarsDeleted(deletedVars, deletedRows);
                        end
                    end
                    updateHandled = true;
                end

                if ~updateHandled
                    opts = namedargs2cell(options);
                    data = variableChanged@internal.matlab.variableeditor.MLArrayDataModel(this, opts{:});
                end
            end
        end
    end

    methods(Access = protected)
        function lhs = getLHS(~, idx)
            % Return the left-hand side of an expression to assign a value
            % to a matlab structure field.  (The variable name will be
            % pre-pended by the caller).  Returns a string like: '.field'
            lhs = getLHS@internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel(idx);
        end
    end

    methods(Access = {?internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel, ?matlab.unittest.TestCase })

        % Override notifyVarChanged in MLWorkspaceDataModel
        % to include varsChanged parameter
        function notifyVarChanged(this, startRow, endRow, varsChanged)
            arguments
                this
                startRow
                endRow
                varsChanged = {}
            end
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            eventdata.StartRow = startRow;
            eventdata.EndRow = endRow;
            eventdata.StartColumn = 1;
            eventdata.EndColumn = internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.WORKSPACE_COLUMN_COUNT;
            % Set to false for now
            % Update the SizeChanged state in the RemoteStructureTreeViewModel
            eventdata.SizeChanged = false;
            eventdata.VarsChanged = varsChanged;
            try
                this.notify('DataChange', eventdata);
            catch e
                internal.matlab.datatoolsservices.logDebug("workspacebrowser::MLWorkspaceTreeDataModel", "notifyVarChanged failed: " + e.message);
            end
        end
    end
end

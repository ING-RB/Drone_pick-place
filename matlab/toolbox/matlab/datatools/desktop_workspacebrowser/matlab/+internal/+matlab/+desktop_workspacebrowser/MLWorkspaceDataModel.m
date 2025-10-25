classdef MLWorkspaceDataModel < internal.matlab.variableeditor.MLStructureDataModel
    %MLWorkspaceDataModel
    %   MATLAB Workspace Data Model

    % Copyright 2013-2024 The MathWorks, Inc.

    events
        VariablesAdded;
        VariablesRemoved;
        VariablesChanged;
    end

    % These datatypes are treated as ObjectValueSummary, but we still need
    % their underlying values in order to compute stats values.
    properties(Constant, Hidden=true)
        DefaultObjDataTypes = ["table", "timetable", "datetime", "duration", ...
            "calendarDuration", "string", "categorical", "ordinal", "nominal"];

        % This is the full number of possible workspace columns that can be
        % shown.  It's quicker in the refresh cycle to just say all columns
        % changed (since the entire row will be updated anyways).  If all
        % columns aren't currently shown, they will be cut down to visible
        % columns in the DataStore.
        WORKSPACE_COLUMN_COUNT = 13;

        % Maximum number of individual variables to log
        MAX_VARS_TO_LOG = 25;
    end

    properties(Hidden)
        BytesColDisplayed logical = false;
    end

    methods(Access='public')
        % Constructor
        function this = MLWorkspaceDataModel(Workspace, ~)
            this@internal.matlab.variableeditor.MLStructureDataModel(...
                'who', Workspace);
        end

        % workspace data changed event coming from internal.matlab.datatoolsservices.WorkspaceListener
        function workspaceUpdated(this, varNames, eventType)
            arguments
                this;
                varNames string = strings(0);
                eventType = internal.matlab.datatoolsservices.WorkspaceEventType.WORKSPACE_CHANGED;
            end

            varNamesArg = varNames;

            if ~this.IgnoreUpdates
                % This is called from java so we don't want to throw an
                % exception back to java, we'll catch it and deal with it
                % here
                errorMessages = {};
                ex = [];
                try

                    % If the variable names are available, just get a
                    % struct containing those.  If not, fall back to
                    % getting a struct of all the variables in the
                    % workspace.
                    if isempty(varNames) || all(strlength(varNames) == 0)
                        % cell array of the variable names in the workspace.  Use
                        % the builtin function in case 'who' is shadowed as a
                        % variable or function name.
                        wsVarNames = evalin(this.Workspace, "builtin('who')");

                        % Sorting the data alphabetically (case-insensitive)
                        %TODO: Make this an optional selection
                        [~, sortId] = sort(lower(wsVarNames));
                        wsVarNames = wsVarNames(sortId);

                        [data, errorMessages] = getStructOfWSContents(this, wsVarNames);
                    elseif ~isequal(eventType, internal.matlab.datatoolsservices.WorkspaceEventType.VARIABLE_DELETED)
                        % Don't need to get the workspace data for the deleted
                        % variables
                        [data, errorMessages, varNames] = getStructOfWSContents(this, varNames);
                        wsVarNames = varNames;
                    end

                    varSize = [1,1];  % struct size is always 1,1
                    varClass = 'struct'; % this was always a struct

                    if eventType == internal.matlab.datatoolsservices.WorkspaceEventType.VARIABLE_DELETED
                        % We can't use varNames at this point, because this has
                        % already been reconciled with our current data. In most
                        % cases they will be there, but in cases where events
                        % get queued up, it's possible they are already gone.
                        % But variableChanged() will check them individually.
                        this.variableChanged(newData = struct, newSize = varSize, newClass = varClass, varNames = varNamesArg, eventType = eventType);
                        removedVariables = varNamesArg;

                        wce = internal.matlab.workspace.WorkspaceChangeEventData;
                        wce.Variables = removedVariables;
                        this.notify('VariablesRemoved', wce);

                    elseif eventType == internal.matlab.datatoolsservices.WorkspaceEventType.VARIABLE_CHANGED
                        this.variableChanged(newData = data, newSize = varSize, newClass = varClass, varNames = varNames, eventType = eventType);

                        % Notify VariablesChanged based on incoming
                        % varNames from the workspace event and not
                        % calculating individual size/class for the
                        % fields, this can affect performance when
                        % workspace has large number of variables.
                        wce = internal.matlab.workspace.WorkspaceChangeEventData;
                        wce.Variables = varNames;
                        this.notify('VariablesChanged', wce);

                    elseif eventType == internal.matlab.datatoolsservices.WorkspaceEventType.VARIABLE_ADDED
                        this.variableChanged(newData = data, newSize = varSize, newClass = varClass, varNames = varNames, eventType = eventType);
                        addedVariables = varNamesArg;

                        wce = internal.matlab.workspace.WorkspaceChangeEventData;
                        wce.Variables = addedVariables;
                        this.notify('VariablesAdded', wce);

                    elseif eventType == internal.matlab.datatoolsservices.WorkspaceEventType.WORKSPACE_CLEARED
                        % Treat WORKSPACE_CLEARED as a variable deletion of all
                        % the variables being displayed.
                        removedVariables = string(fieldnames(this.Data));
                        this.variableChanged(newData = data, ...
                            newSize = varSize, ...
                            newClass = varClass, ...
                            varNames = removedVariables, ... % fieldnames of all of the data (variables)
                            eventType = internal.matlab.datatoolsservices.WorkspaceEventType.WORKSPACE_CLEARED);

                        wce = internal.matlab.workspace.WorkspaceChangeEventData;
                        wce.Variables = removedVariables;
                        this.notify('VariablesRemoved', wce);

                    elseif eventType == internal.matlab.datatoolsservices.WorkspaceEventType.WORKSPACE_CHANGED  || ...
                            eventType == internal.matlab.datatoolsservices.WorkspaceEventType.NUMERIC_FORMAT_CHANGED

                        % Special case for app usage which can call this with no
                        % additional arguments
                        currentFN = fieldnames(this.Data);
                        if nargin == 1
                            newFN = fieldnames(data);
                            if isequal(currentFN, newFN)
                                return;
                            end
                        end

                        % Treat workspace changed and numeric format changed
                        % like workspace cleared and then variables added
                        removedVariables = string(currentFN);
                        this.variableChanged(newData = data, ...
                            newSize = varSize, ...
                            newClass = varClass, ...
                            varNames = removedVariables, ... % fieldnames of all of the data (variables)
                            eventType = internal.matlab.datatoolsservices.WorkspaceEventType.WORKSPACE_CLEARED);
                        removedVariables = fieldnames(data);

                        wce = internal.matlab.workspace.WorkspaceChangeEventData;
                        wce.Variables = removedVariables;
                        currCachedSize = this.CachedSize;
                        this.setCachedSize([0, currCachedSize(2)]);

                        this.variableChanged(newData = data, ...
                            newSize = varSize, ...
                            newClass = varClass, ...
                            varNames = wsVarNames, ...
                            eventType = internal.matlab.datatoolsservices.WorkspaceEventType.VARIABLE_ADDED);
                        addedVariables = wsVarNames;

                        wce = internal.matlab.workspace.WorkspaceChangeEventData;
                        wce.Variables = addedVariables;
                        this.notify('VariablesAdded', wce);
                        this.CachedSize(1) = length(wsVarNames);
                    end

                catch ex
                    % We are probably evaluating in the wrong workspace!
                    errorMessages{end+1} = ex.message;
                end
                if ~isempty(errorMessages) && ...
                        ~internal.matlab.workspace.MLWorkspaceDataModel.isTransientErrorMessage(ex)
                    if ~ischar(this.Workspace)
                        error(message('MATLAB:workspace:ErrorUpdatingPrivateWorkspaceVariableList', strjoin(errorMessages,'\n')));
                    else
                        error(strjoin(errorMessages,'\n'));
                    end
                end
            end
        end

        function [data, errorMessages, existingVarNames] = getStructOfWSContents(this, varNames)
            % Convert the array of structure variables into one
            % structure with variable names as the fields and the
            % variable as the value
            data = struct();
            errorMessages = {};
            % existingVarNames = strings(0);

            for i=1:length(varNames)
                varName = varNames{i};
                try
                    data.(varName) = evalin(this.Workspace, varName);
                    % existingVarNames(end+1) = varName;
                catch ex
                    if ~isequal(varName, "ans")
                        errorMessages{end+1} = ex.message;
                    end
                end
            end

            existingVarNames = string(fieldnames(data));
        end

        % Executes a matlab command in the correct workspace when MATLAB is
        % available
        function evalStr = executeSetCommand(this, evalStr, varargin)
            ws = this.Workspace;
            if ischar(ws) && strcmpi(ws, 'caller')
                ws = 'debug';
            end
            if nargin == 3 && ~isempty(varargin{1})
                internal.matlab.datatoolsservices.executeCmdHandleError(evalStr, varargin{1}, false);
            else
                evalin(ws, evalStr);
            end
            try
                this.workspaceUpdated();
            catch
            end
        end

        % updateData
        function data = updateData(this, varargin)
            % Override the updateData function from the MLStructureDataModel to
            % provide extra behavior for objects which are being displayed in
            % the WSB.  For these, we don't want to hold onto a reference to
            % these, otherwise it can prevent the synchronous destruction of
            % these objects.  Instead, use an ObjectValueSummary object to store
            % it's information.

            % Note that the following code is similar to MLStructureDataModel
            % and MLArrayDataModel -- but it's all done here so as to be able to
            % modify objects.

            % Use the builtin function in case 'who' is shadowed as a variable
            % or function name.
            wsVarNames = evalin(this.Workspace, "builtin('who')");
            newData = getStructOfWSContents(this, wsVarNames);

            origData = this.Data;
            % Get the classes for the current data.  Replace any
            % ObjectValueSummary classes with their original classes
            origDataCell = struct2cell(origData);
            classes = cell(size(origDataCell));
            for idx = 1:length(origDataCell)
                classes{idx} = class(origDataCell{idx});
                if strcmp(classes{idx}, 'internal.matlab.workspace.ObjectValueSummary')
                    classes{idx} = origDataCell{idx}.DisplayClass;
                end
            end

            % Get the classes for the new data
            newClasses = cellfun(@(a) class(a), struct2cell(newData), ...
                "UniformOutput", false, ...
                "ErrorHandler", @(varargin) internal.matlab.datatoolsservices.FormatDataUtils.ERR_DISPLAYING_VALUE);
            classChange = ~isequaln(classes, newClasses);
            sameSize = true;
            if classChange
                sameSize = numel(classes) == numel(newClasses);
            else
                % Check for data changes
                dataChange = ~this.equalityCheck(origData, newData);
                if dataChange
                    sameSize = isequal(this.getDataSize(origData), this.getDataSize(newData));
                end
            end

            % If there is any class change or data change
            if classChange || dataChange
                if ~sameSize
                    % Keep [I, J] consistent with the value returned in
                    % doCompare, when the number of fields in the struct
                    % has changed.
                    if classChange
                        [I,J] = meshgrid(1:size(newClasses,1),1:this.NumberOfColumns);
                    else
                        [I,J] = meshgrid(1:max(size(origData,1),size(newData,1)),1:max(size(origData,2),size(newData,2)));
                    end
                else
                    %  name/value/class could have changed, update I,J accordingly
                    [I,J] = this.doCompare(newData);
                end
                eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
                I = I(:)';
                J = J(:)';

                rangeToUpdate = [I;J];
                if size(rangeToUpdate, 2) == 1
                    % Refresh data for single cell
                    eventdata.StartRow = rangeToUpdate(1,1);
                    eventdata.EndRow = rangeToUpdate(1,1);
                    eventdata.StartColumn = rangeToUpdate(2,1);
                    eventdata.EndColumn = rangeToUpdate(2,1);
                end
                eventdata.SizeChanged = ~sameSize;

                % Quick check if there are any objects being displayed.  Assume
                % true if there's an error (which can happen when an object is
                % open in the editor, and an error is inserted).
                isObjOrContainer = cellfun(@isObjOrContainerVar, struct2cell(newData), ...
                    "ErrorHandler", @(varargin) true);

                if any(isObjOrContainer)
                    f = fieldnames(newData);
                    objs = find(isObjOrContainer);
                    currentFormat = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat();
                    for idx = objs'
                        val = newData.(f{idx});

                        % For any objects, replace the data in the newData
                        % struct with a representation of the object, instead of
                        % keeping a direct reference to it (using an
                        % ObjectValueSummary object)
                        vs = internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.getObjectValueSummary(...
                            val, currentFormat, this.BytesColDisplayed);
                        newData.(f{idx}) = vs;
                    end
                end

                % Update cache size
                % internal.matlab.datatoolsservices.logDebug("MLWorkspaceDataModel::updateData::", "Detected Size Change" + num2str(eventdata.SizeChanged));
                if eventdata.SizeChanged
                    currentCachedSize = this.CachedSize;
                    this.setCachedSize([length(wsVarNames) currentCachedSize(2)]);
                end
                
                % Set the new data
                this.Data = newData;
                this.notify('DataChange',eventdata);
            end

            data = this.Data;
        end

        function eq = equalityCheck(this, oldData, newData)
            % g2131666: Objects in the oldData are of type
            % ObjectValueSummary. Hence, we need to ensure that we covert
            % the newData to the same format in order to compare the two

            f = fieldnames(newData);
            eq = true;
            currentFormat = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat();
            for n = 1:length(f)
                fld = f{n};
                % For a field rename, this could end up not being a current
                % field. Add checks and short circuit to update.
                if ~isfield(oldData, fld) || ~isfield(newData, fld)
                    eq = false;
                    break;
                end

                if isObjOrContainerVar(newData.(fld))
                    % Objects, structs, and cell arrays are all treated as
                    % ObjectValueSummary objects
                    vs = internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.getObjectValueSummary( ...
                        newData.(fld), currentFormat, this.BytesColDisplayed);
                    eq = internal.matlab.variableeditor.areVariablesEqual(oldData.(fld), vs);
                else
                    eq = internal.matlab.variableeditor.areVariablesEqual(oldData.(fld), newData.(fld));
                end
                if ~eq
                    break;
                end
            end
        end

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
                data = this.Data;

                % VARIABLE_CHANGED is generated for adds and modifications
                if options.eventType == internal.matlab.datatoolsservices.WorkspaceEventType.VARIABLE_CHANGED
                    data = this.handleVariablesChanged(options);
                    updateHandled = true;

                elseif options.eventType == internal.matlab.datatoolsservices.WorkspaceEventType.VARIABLE_ADDED
                    data = this.handleVariablesAdded(options);
                    updateHandled = true;

                elseif options.eventType == internal.matlab.datatoolsservices.WorkspaceEventType.VARIABLE_DELETED
                    this.handleVariablesDeleted(options);
                    updateHandled = true;

                elseif options.eventType == internal.matlab.datatoolsservices.WorkspaceEventType.WORKSPACE_CLEARED
                    this.handleAllVariablesDeleted(options);
                    updateHandled = true;
                end

                if ~updateHandled
                    opts = namedargs2cell(options);
                    data = variableChanged@internal.matlab.variableeditor.MLArrayDataModel(this, opts{:});
                end
            end
        end
    end

    methods(Access = {?internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel, ?matlab.unittest.TestCase })
        function data = handleVariablesAdded(this, options)
            % Notify listeners of the variables which were added
            varsAdded = options.varNames;

            % Notify once after identifying which new vars are added.
            if ~isempty(varsAdded)
                varsToLog = internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.getVarsToLog(varsAdded);
                internal.matlab.datatoolsservices.logDebug("MLWorkspaceDataModel::variableChanged::", "notifying var added: " + varsToLog);
                this.notifyVarsAdded(varsAdded);
            end

            % update return value for tests
            data = this.Data;
        end

        function data = handleVariablesChanged(this, options)
            % Notify listeners of the variables which were changed
            currDataModelData = this.Data;
            currVarNames = fieldnames(currDataModelData);
            incomingVarNames = options.varNames;
            newData = options.newData;

            if isscalar(incomingVarNames)
                varChangedIndices = strcmp(currVarNames, incomingVarNames);
            else
                varChangedIndices = ismember(currVarNames, incomingVarNames);
            end
            varsChanged = incomingVarNames;

            % Notify once after identifying which new vars have changed.
            if ~isempty(varsChanged)
                fmt = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat;
                numVars = length(varsChanged);
                for idx = 1:numVars
                    varName = varsChanged{idx};
                    try
                        newValue = evalin(this.Workspace, varName);
                        if isObjOrContainerVar(newValue)
                            newValue = internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.getObjectValueSummary(newValue, ...
                                fmt, this.BytesColDisplayed);
                        end

                        newData.(varName) = newValue;
                    catch
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
                    this.notifyVarChanged(min(varChangedPos), max(varChangedPos));
                end
            end
            % update return value for tests
            data = this.Data;
        end
        
        function handleVariablesDeleted(this, options)
            % Notify listeners of the variables which were deleted
            data = this.Data;
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
        end

        function handleAllVariablesDeleted(this, options)
            % Notify listeners of list of all displayed variables, which were
            % deleted
            deletedVars = options.varNames;
            deletedRows = 1:length(deletedVars);
            this.notifyVarsDeleted(deletedVars, deletedRows);
        end

        function notifyVarChanged(this, startRow, endRow)
            arguments
                this
                startRow
                endRow
            end
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            eventdata.StartRow = startRow;
            eventdata.EndRow = endRow;
            eventdata.StartColumn = 1;
            eventdata.EndColumn = internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.WORKSPACE_COLUMN_COUNT;
            eventdata.SizeChanged = false;
            this.notify('DataChange', eventdata);
        end

        function notifyVarsAdded(this, varNamesAdded)
            arguments
                this
                varNamesAdded string
            end
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            varAddedLen = length(varNamesAdded);
            currentCachedSize = this.CachedSize;

            % Specify the entire range if there are multiple variables
            % being deleted at once
            eventdata.StartRow = 1;
            eventdata.StartColumn = 1;
            eventdata.EndColumn = internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.WORKSPACE_COLUMN_COUNT;
            eventdata.SizeChanged = true;

            internal.matlab.datatoolsservices.logDebug("MLWorkspaceDataModel::UpdatedCachedSize", "Added: " + varAddedLen + ", CachedSize: " + this.CachedSize(1) + "," + this.CachedSize(2));
            currentData = this.Data;
            % Add the variables to this.Data
            fmt = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat;
            for idx = 1:varAddedLen
                newValue = evalin(this.Workspace, varNamesAdded(idx));
                if isObjOrContainerVar(newValue)
                    newValue = internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.getObjectValueSummary(newValue, ...
                        fmt, this.BytesColDisplayed);
                end
                currentData.(varNamesAdded(idx)) = newValue;
            end
            this.Data = currentData;
            
            newRowCount = length(fieldnames(currentData));
            this.setCachedSize([newRowCount currentCachedSize(2)]);
            eventdata.EndRow = newRowCount;

            this.notify('DataChange', eventdata);
        end


        function newData = notifyVarsDeleted(this, varNamesRemoved, deletedRows)
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
            deletedRows = sort(deletedRows);

            % Specify the entire range if there are multiple variables
            % being deleted at once
            eventdata.StartRow = deletedRows(1);
            eventdata.EndRow = length(fieldnames(this.Data)) - length(deletedRows);
            eventdata.StartColumn = 1;
            eventdata.EndColumn = internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.WORKSPACE_COLUMN_COUNT;
            eventdata.SizeChanged = true;

            % Remove those variables from this.Data (where they are
            % represented as fields in the struct)
            varRemovedLen = length(varNamesRemoved);
            currentCachedSize = this.CachedSize;
            
            this.setCachedSize([currentCachedSize(1)-varRemovedLen currentCachedSize(2)]);

            this.Data = rmfield(this.Data, varNamesRemoved);
            newData = this.Data;
            this.notify('DataChange', eventdata);
        end
    end

    methods(Access = protected)
        function lhs = getLHS(this, idx)
            % Return the left-hand side of an expression to assign a value
            % to a matlab structure field.  (The variable name will be
            % pre-pended by the caller).  Returns a string like: '.field'
            fieldNames = fieldnames(this.Data);
            numericIdx = str2num(idx); %#ok<ST2NM>
            lhs = fieldNames{numericIdx(1)};
        end

        function sizeStr = getSizeString(~, obj)
            % Returns a string representing the size.  For most cases, it
            % will be num2str(size(obj)), but this function also handles
            % java objects in the workspace
            try
                s = size(obj);
            catch
                s = [1,1];
            end
            if isnumeric(s)
                sizeStr = int2str(s);
            elseif isjava(obj) && ismethod(s, 'toString')
                sizeStr = char(s.toString);
            else
                sizeStr = '';
            end
        end

        % Utility Fn to compare if class or size of 'ans' variable has
        % changed in the workspace. If 'ans' is an ObjectValueSummary,
        % compare the underlying DisplaySize/DisplayClass to detect
        % changes.
        function isEqual = doAnsCompare(this, data)
            ansVal = this.Data.ans;
            currAnsVal = data.('ans');
            if isa(ansVal, 'internal.matlab.workspace.ObjectValueSummary')
                % For ObjectValueSummary, these display as something like 1x10
                % datetime.  So compare the size and class only.  (It wouldn't
                % matter, for example, if one of the dates differed).
                sz = internal.matlab.datatoolsservices.FormatDataUtils.getSizeString(currAnsVal);
                isEqual = isequal(ansVal.DisplaySize, sz) && isequal(ansVal.DisplayClass, class(currAnsVal));
            else
                try
                    % Quick comparison to see if the size/class are the same
                    isEqual = isequal(size(currAnsVal), size(ansVal)) && ...
                        isequal(class(currAnsVal), class(ansVal));
                    if isEqual
                        % If they are, check if the variable values are actually
                        % equal.  Use try/catch because there are odd situations
                        % which this can error (tall variables, user-defined
                        % classes)
                        isEqual = isequal(ansVal, currAnsVal);
                    end
                catch
                    % Ignore error, but assume they are different
                    isEqual = false;
                end
            end
        end
    end

    methods(Static, Hidden)
        function b = isTransientErrorMessage(ex)
            % Some error messages may be transient, only happening temporarily
            % but will be resolved on their own.  For example, the
            % AccessingVariableOfExitingFunction error may be hit when hitting
            % an error after dbquit, after being stopped at a breakpoint.  But
            % when execution continues, the error is resolved and the WSB is
            % updated without a problem.

            b = false;
            if isa(ex, 'MException')
                b = (ex.identifier == "MATLAB:interpreter:AccessingVariableOfExitingFunction");
            end
        end

        function vs = getObjectValueSummary(val, currentFormat, includeRawValue)
            arguments
                val
                currentFormat = internal.matlab.datatoolsservices.FormatDataUtils.getCurrentNumericFormat();
                includeRawValue logical = false;
            end

            persistent fdu;
            if isempty(fdu)
                fdu = internal.matlab.datatoolsservices.FormatDataUtils;
            end

            % Handle any errors getting the class or size.  (which can happen
            % when an object is open in the editor, and an error is inserted)
            dispVal = fdu.formatSingleDataForMixedView(val, currentFormat);

            try
                classValue = class(val);
                isNumericVal = isnumeric(val);
            catch
                classValue = internal.matlab.datatoolsservices.FormatDataUtils.ERR_DISPLAYING_VALUE;
                isNumericVal = false;
            end

            vs = internal.matlab.workspace.ObjectValueSummary;
            vs.DisplayValue = dispVal;
            if any(strcmp(classValue, ["distributed", "codistributed", "gpuArray", "dlarray"]))
                try
                    vs.DisplayType = underlyingType(val);
                    classValue = internal.matlab.datatoolsservices.FormatDataUtils.getClassString(...
                        val);
                catch
                end
            end
            vs.DisplayClass = classValue;
            vs.DisplaySize = fdu.getSizeString(val);

            % Save raw values on ObjValueSummary so that the 'Bytes' values
            % are computed based on the RawValue.  This is saved
            % conditionally based on the includeRawValue argument, which is
            % set by the caller based on if the bytes column is visible.
            if includeRawValue && ...
                    ismember(classValue,internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.DefaultObjDataTypes) || ...
                    isNumericVal
                vs.RawValue = val;
            end
        end

        function varsToLog = getVarsToLog(varList)
            maxToLog = internal.matlab.desktop_workspacebrowser.MLWorkspaceDataModel.MAX_VARS_TO_LOG;
            if length(varList) > maxToLog
                varsToLog = strjoin(varList(1:maxToLog)) + " and " + (length(varList) - maxToLog) + " more";
            else
                varsToLog = strjoin(varList);
            end
        end
    end
end

function b = isObjOrContainerVar(x)
    % Returns true if the variable is an object or a container like a struct or cell array.  Skip
    % logical objects (which can be user-defined or the OnOffSwitchState) since they don't display
    % in summary form.
    try
        b = (isobject(x) || isstruct(x) || iscell(x)) && ~islogical(x);
    catch
        % Assume true if there's an error (which can happen when an object is
        % open in the editor, and an error is inserted)
        b = true;
    end
end

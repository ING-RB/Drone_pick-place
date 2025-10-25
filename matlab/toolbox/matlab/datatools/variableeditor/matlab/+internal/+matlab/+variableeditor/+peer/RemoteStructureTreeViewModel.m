classdef RemoteStructureTreeViewModel < internal.matlab.variableeditor.peer.RemoteStructureViewModel & internal.matlab.variableeditor.StructureTreeViewModel
    % REMOTESTRUCTUREVIEWMODEL 
    % RemoteViewModelModel supports displaying scalar structs in a
    % tree-table view allowing users to expand/ collapse fields containing
    % structs/struct arrays upto any level.

    % Copyright 2022-2025 The MathWorks, Inc.

    properties (GetAccess=public, SetAccess={?matlab.unittest.TestCase})
        IsFullyExpanded (1,1) logical = false
        IsFullyCollapsed (1,1) logical = true
    end

    methods
        function this = RemoteStructureTreeViewModel(document, variable, viewID, userContext)
            arguments
                document
                variable
                viewID char = ''
                userContext char = ''
            end
            this@internal.matlab.variableeditor.StructureTreeViewModel(variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteStructureViewModel(document, variable, viewID, userContext);
            % Add variable name to expansion list as top-level fields are
            % expanded by default.
            this.ExpansionList(end+1) = variable.DataModel.Name;
        end

        % After changing our row information, this function must be called
        % to let listeners know that there's been an update.
        % This function assumes that the number of rows has changed prior
        % to it being called.
        function updateDataAndDispatchMessages(this, forceRowModelUpdate)
            arguments
                this
                forceRowModelUpdate (1,1) logical = false;
            end

            eventData = internal.matlab.datatoolsservices.data.DataChangeEventData;
            eventData.SizeChanged = true;

            % Reorder rows (only applies if they've been sorted).
            this.handleSortAscending();

            % In specific situtations (such as collapse all), metadata doesn't
            % completely update. At the time this comment was written, it's unclear
            % why this is so. For these situations, we force a complete refresh of
            % all row model information.
            if forceRowModelUpdate
                dataSize = this.getSize();
                this.updateRowModelInformation(1, dataSize(1));
            end

            this.notify('DataChange', eventData);

            % g3572610: It's imperative that we let the frontend know that the
            % number of visible rows has changed.
            this.updateRowMetaData();
        end

        % Expands a single field specified by rowID
        function expand(this, rowIDs)
            arguments
                this
                rowIDs double
            end

            for i=1:length(rowIDs)
               this.handleExpandCollapse(rowIDs(i), true); 
            end

            this.IsFullyCollapsed = false;
            this.updateDataAndDispatchMessages();
        end

        % Expands the fields, making sure that their parents are also expanded.
        function expandFields(this, fieldIDs)
            arguments
                this
                fieldIDs string
            end

            fieldsExpanded = false;
            for fieldNum=1:length(fieldIDs)
                fid = fieldIDs(fieldNum);

                parentIDs = internal.matlab.variableeditor.VEUtils.splitRowId(fid);
                for parentNum=2:length(parentIDs)-1
                    pid = internal.matlab.variableeditor.VEUtils.joinRowId(parentIDs(1:parentNum));
                    relID = internal.matlab.variableeditor.VEUtils.joinRowId(parentIDs(2:parentNum));
                    
                    if ~this.isRowExpanded([], pid)
                        this.updateRowExpansionList(pid, true);
                        childrenCount = this.getExpandedChildren(pid);
                        if (childrenCount > 0)
                            this.DataModel.updateSizeOnExpand(relID, childrenCount);
                        end
                        fieldsExpanded = true;
                    end
                end
                rawData = this.getData();
                data = this.getFieldData(rawData, fid);
                fieldDataExpandable = this.checkExpandability(data);
                if fieldDataExpandable
                    if ~this.isRowExpanded([], fid)
                        this.updateRowExpansionList(fid, true);
                        childrenCount = this.getExpandedChildren(fid);
                        if (childrenCount > 0)
                            pid = internal.matlab.variableeditor.VEUtils.joinRowId(parentIDs(2:end));
                            this.DataModel.updateSizeOnExpand(pid, childrenCount);
                        end
                        fieldsExpanded = true;
                    end
                end
            end

            % If fieldsExpanded = false, all fieldIDs were already
            % expanded, no need to emit a dataChanged event.
            if fieldsExpanded
                % TODO: Figure out why "expandFields()" needs a forced refresh.
                forceRowModelUpdate = true;
                this.updateDataAndDispatchMessages(forceRowModelUpdate);
            end
        end

        function rows = getFieldRows(this, fieldIDs, keepOrder)
            arguments
                this
                fieldIDs string
                keepOrder (1,1) logical = false
            end
            rows = zeros(length(fieldIDs), 1);
            dataSize = this.getSize();

            allIDs = string(this.getRowModelProperties(1:dataSize(1), 'id'));
            if ~keepOrder
                rows = find(ismember(allIDs, fieldIDs));
            else
                for i=1:length(fieldIDs)
                    fid = fieldIDs(i);
                   rowNum = find(allIDs == fid);
                   if ~isempty(rowNum)
                       rows(i) = rowNum;
                   end
                end
            end
        end

        % Collapses a single field
        function collapse(this, rowIDs)
            arguments
                this
                rowIDs double
            end

            for i=1:length(rowIDs)
               this.handleExpandCollapse(rowIDs(i), false); 
            end

            this.IsFullyExpanded = false;
            this.updateDataAndDispatchMessages();
        end

        % Expands all fields starting from the root variable.
        function expandAll(this)
            data = this.getData();
            name = this.DataModel.Name;

            [allExpandableFields, childrenCount] = this.fetchAllExpandableFieldNames(data, name, string.empty, 0, true);
            this.ExpansionList = [this.DataModel.Name allExpandableFields];
            currentCachedSize = this.DataModel.getCachedSize();
            numVisibleColumns = currentCachedSize(2);
            this.DataModel.setCachedSize([childrenCount numVisibleColumns]);
            this.DataModel.updateCachedSize();
            this.setExpandedState();

            this.updateDataAndDispatchMessages();
        end

        % Collapses all fields, starting from the root variable.
        function collapseAll(this)
            this.ExpansionList = [string(this.DataModel.Name)];

            % Clear cached size so that it can be recomputed on updateCachedSize().
            currentCachedSize = this.DataModel.getCachedSize();
            numVisibleColumns = currentCachedSize(2);
            this.DataModel.setCachedSize([0 numVisibleColumns]);
            this.DataModel.updateCachedSize();
            this.setCollapsedState();

            % When dispatching data, force a complete row model update.
            % TODO: Figure out why "collapseAll()" needs a forced refresh.
            forceRowModelUpdate = true;
            this.updateDataAndDispatchMessages(forceRowModelUpdate);
        end

        % Expands every field recursively starting from a particular field
        function expandAllInField(this)
            data = this.getData();
            fieldIDs = this.SelectedFields;
            allExpandableFields = [];
            childrenCount = 0;
            if ~isempty(fieldIDs)
                this.IsFullyCollapsed = false;
                for i=1:length(fieldIDs)
                    id = fieldIDs(i);
                    fieldData = this.getFieldData(data, id);
                    [allExpandableFieldsForID, childrenCountforID] = this.fetchAllExpandableFieldNames(fieldData, id, string.empty, 0, false);
                    allExpandableFields = [allExpandableFields id allExpandableFieldsForID];
                    childrenCount = childrenCount + childrenCountforID;
                end
                this.ExpansionList = unique([this.ExpansionList, allExpandableFields]);
                this.DataModel.updateSizeOnExpand('', childrenCount);

                this.updateDataAndDispatchMessages();
            end
        end
        
        % Collapses every field recursively starting from a particular field
        function collapseAllInField(this)
            fieldIDs = this.SelectedFields;
            % We need the greatest common ancestor to coalesce all children with the same root together 
            if ~isempty(fieldIDs)
                this.IsFullyExpanded = false;

                collapsableFields = this.getUniqueAncestors(fieldIDs);
                for i=1:length(collapsableFields)
                    childrenCount = this.getExpandedChildren(collapsableFields(i));
                    this.DataModel.updateSizeOnCollapse(childrenCount);
                end
                rootName = internal.matlab.variableeditor.VEUtils.appendRowDelimiter(collapsableFields);
                findIdxStartsWith = startsWith(this.ExpansionList, rootName);
                findIdxExact = strcmp(this.ExpansionList, collapsableFields);
                findIdx = findIdxStartsWith | findIdxExact;
                if any(findIdx)
                    this.ExpansionList(findIdx) = [];
                end

                this.updateDataAndDispatchMessages();
            end
        end

        % Set when all fields of structs are fully expanded. (Expand All)
        function setExpandedState(this)
            this.IsFullyExpanded = true;
            this.IsFullyCollapsed = false;
        end

        % Set when all fields of structs are fully collapsed. (Collapse All)
        function setCollapsedState(this)
            this.IsFullyExpanded = false;
            this.IsFullyCollapsed = true;
        end

        % For certain actions,we need to only perform on common greatest
        % ancestor closest to root. API returns a list of all unique
        % acestors from root. 
        % for e.g s.a.b.c and s.a.e.f are expanded, s.a is the gca.
        function uniqueFields = getUniqueAncestors(~, fields)
            arguments
                ~
                fields (1, :) string % Force "fields" to be a row vector; function does not work as expected otherwise
            end

            uniqueFields = string.empty;
            if isempty(fields)
                return;
            end

            numFields = arrayfun(@(x)length(internal.matlab.variableeditor.VEUtils.splitRowId(x)), fields);
            [~, idx] = sortrows(numFields');
            % Sorting fields by the ones that are closest to root
            numFields = fields(idx);

            while numFields.length > 0
                f = numFields(1);
                uniqueFields(end+1) = f;
                rootFName = internal.matlab.variableeditor.VEUtils.appendRowDelimiter(f);
                matchedIdxStartsWith = startsWith(numFields, rootFName);
                matchedIdxExact = strcmp(numFields, f);
                matchedIdx = matchedIdxStartsWith | matchedIdxExact;
                numFields(matchedIdx) = [];
            end
        end

        % Called on single cell edit from client. Pass along rowID of the
        % row being edited to DataModel.
        % Last param errorMsg is ignored as we do inline validation for
        % field/value editing.
        function varargout = setTabularDataValue(this, row, column, value, ~)
            rowId = this.getRowModelProperty(row, 'id');
            varargout{1} = this.setData(value, row, column, rowId{1});
        end

        % On equal selection, we do not update SelectedFields. In addition
        % to SelectedRpws/SelectedColumns, also verify if cache of
        % SelectedFields is up to date.
        function isEqual = isSelectionEqual(this, selectedRows, selectedColumns, selectedFields)
            arguments
                this
                selectedRows
                selectedColumns
                selectedFields = []
            end
            isEqual = this.isSelectionEqual@internal.matlab.variableeditor.peer.RemoteStructureViewModel(selectedRows, selectedColumns, selectedFields) && ...
                 isequal(string(selectedFields), this.SelectedFields);
        end

        % Gets the VariableName that will be used to index into the leaf
        % field of 'varName'. If the field's parent is a structArray, index
        % into the first element of the struct like 'parent(1).fieldName'
        %
        % Note: This returns the sub variable _name_, not its row ID. As such,
        % it is delimited with ".", since that is the proper MATLAB syntax.
        function subVarName = getSubVarName(this, dataModelName, cellVarName)
            arguments (Input)
                this
                dataModelName (1,1) string % Aside from replacing delimiters, this remains untouched.
                                           % We assume "dataModelName" is ALWAYS indexing correctly.
                cellVarName (1,1) string   % The variable name in the cell of interest.
                                           % We assume "cellVarName" must be tweaked to index correctly.
            end

            arguments (Output)
                subVarName char % Generated code to access the variable the user wishes to open.
            end

            splitCellNames = [internal.matlab.variableeditor.VEUtils.splitRowId(cellVarName)]; % Constant

            % Return early if no potential disambiguation is needed.
            if isscalar(splitCellNames)
                subVarName = char(strjoin([ ...
                    internal.matlab.variableeditor.VEUtils.getPeriodDelimitedRowIds(dataModelName), ...
                    cellVarName ...
                ], internal.matlab.variableeditor.VEUtils.DOT_SEPARATOR));
                return
            end

            % g3419814: We must process "cellVarName" for correct variable indexing.
            %
            % The need for this processing arises because tabular variables (i.e., columns)
            % allow unicode, and that includes parentheses---from strings alone, we cannot
            % determine if a pair of parentheses indicates indexing into a struct array or
            % indexing into a table variable.

            % Constant variable setup
            isStructArray = @(s) isstruct(s) && ~isscalar(s);
            % g3576572: For our object array check, we must explicitly determine whether the value is a map for two reasons:
            % 1) Maps can't be put into arrays
            % 2) "isscalar()" returns true if the map has more than one key, or if it has zero keys
            isNonTabularObjectArray = @(o) isobject(o) && ~istabular(o) && ~isa(o, 'containers.Map') && ~isscalar(o);
            dataModelData = this.getData();

            % Mutable variable setup
            processedCellVarName = [];
            curParentData = dataModelData; % Parent data is used when checking if a name refers to a struct array
            curParentName = "";

            % All levels of the "cellVarName" need processing.
            % We do not index into struct arrays if they are the last level.
            lastIndex = length(splitCellNames);
            for i = 1:lastIndex
                curName = splitCellNames(i);

                if istabular(curParentData)
                    curParentData = curParentData.(curName);        % Update parent data for the next loop iteration
                    if ~isvarname(curName)
                        [~,~,curName] = internal.matlab.datatoolsservices.FormatDataUtils.generateVariableNameAssignmentString(curName, curParentName, NaN);
                        curName = strcat('(', curName, ')');
                    end
                elseif isa(curParentData, 'containers.Map')
                    % g3519166: We must handle maps in a special method separate from other data types.
                    % Assumption: we can never drill into any of Map's children. We only have to update "curName".
                    curName = splitCellNames(end);
                else % Non-tabular, non-map parent data
                    curVal = curParentData.(curName);
                    if (isStructArray(curVal) || isNonTabularObjectArray(curVal)) && i ~= lastIndex
                        curParentData = curParentData.(curName)(1); % Update parent data for the next loop iteration
                        curName = sprintf("%s(1)", curName);
                    else
                        curParentData = curParentData.(curName);    % Update parent data for the next loop iteration
                    end
                end

                processedCellVarName = [processedCellVarName curName];
                curParentName = curName;

                % We've reached the end of this loop iteration and will drill down to the
                % next level in "cellVarName".
            end

            % We have performed all necessary "cellVarName" processing and can finally
            % create the "subVarName" output.
            subVarName = char(strjoin([ ...
                    internal.matlab.variableeditor.VEUtils.getPeriodDelimitedRowIds(dataModelName), ...
                    processedCellVarName ...
                ], internal.matlab.variableeditor.VEUtils.DOT_SEPARATOR));
        end
    end

    methods(Access='protected')

        % This formats SelectedFields to be set as TableModelProperty
        % Here, SelectedFileds is ',' separated list of field names of the struct.
        % Field names (like varnames of tables) can contain arbitrary chars, convert this to executable code before formatting
        % For example, if table varname = "var.a", formattedFields = s.("var.a")
        function formattedFields = getSelectedFieldsForPropertySet(this, selection)
            %Set the list of selected variables/fieldnames here
            formattedFields = char(selection);
            if ~isempty(formattedFields)
                delimiter = internal.matlab.variableeditor.VEUtils.DELIMITER;
                delimitedExecutableSelection = internal.matlab.variableeditor.VEUtils.getExecutableRowIdVersion(selection, false);
                selectionWithoutRootName = extractAfter(delimitedExecutableSelection, [this.DataModel.Name char(delimiter)]);
                formattedFields = internal.matlab.variableeditor.VEUtils.getPeriodDelimitedRowIds(selectionWithoutRootName);
                formattedFields = strjoin(formattedFields, ',');
            end
        end

        % Processed during getRendererdData to return JSON values for
        % displaying each rows of the scalar struct. 
        % TODO: Re-use more of RemoteStructureViewModel implementation
        function [renderedData, renderedDims] = renderData(this, data, classValues, fields, accessValues, ...
                startRow, endRow, startColumn, endColumn)
            rawData = this.getData();
            isVirtual = isa(rawData, "internal.matlab.variableeditor.VariableEditorPropertyProvider");
            numColumnsRequested = endColumn - startColumn + 1;
            renderedData = cell(size(data,1), numColumnsRequested);
            this.CellModelChangeListener.Enabled = false;
            CellMetaDataColIndices = [];
            % For each of the rows of rendered data, create the json object
            % string for each column's data.
            for row = 1:size(renderedData, 1)
                varName = this.OrderedFields{row};
                isEditable = this.isFieldEditable(varName);
                for col = startColumn:endColumn
                    val = data{row,col};
                    cellData = struct('value', val);
                    classVal = classValues{row};
                    fName = fields{col}.getHeaderName();

                    if any(strcmp(fName, ["Name", "Value"]))
                        if fName == "Name"
                            cellData.class = classVal;
                            if ~isempty(accessValues)
                                cellData.access = accessValues(row);
                            end
                            % For tall variables, fetch the underlying data
                            % and format in order to update icon with
                            % underlyingClass.
                            if strcmp(classVal, 'tall')
                                dataValue = this.getFieldData(rawData, varName);
                                editVal = this.getFormattedData(dataValue);
                                cellData.class = internal.matlab.datatoolsservices.FormatDataUtils.formattedClassValue(editVal{1}, 'tall');
                             elseif any(strcmp(classVal, ["distributed", "codistributed", "gpuArray", "dlarray"]))
                                % For gpuArrays/distributed and co-distributed, we want to display the
                                % in-memory datatype icons on client, send over the underlying datatype.
                               dataValue = this.getFieldData(rawData, varName);
                               underlyingtype = this.getUnderlyingDataType(dataValue);
                               cellData.class = internal.matlab.datatoolsservices.FormatDataUtils.formattedClassValue(underlyingtype, classVal);
                            end
                            % this clause is for a value class, send over
                            % additional info for editing.
                        else
                            if isVirtual && isVariableEditorVirtualProp(rawData, varName)
                                cellData.isMetaData = true;
                                isEditable = true;
                            else
                                if strcmp(classVal,'string')
                                    cellData.class = classVal;
                                end
                                dataValue = this.getFieldData(rawData, varName);
                                [val, editVal] = fields{col}.getEditValue(row, dataValue, val, this.DisplayFormatProvider.LongNumDisplayFormat);
                                if ~isequal(val, editVal)
                                    cellData.editValue = editVal;
                                end
                                cellData.editable = isEditable;
                                cellData.isMetaData = fields{col}.isMetaData(row);
                            end

                            if ~isEditable
                                this.setCellModelProperty(row, col,...
                                    'editable', false);
                                CellMetaDataColIndices = union(CellMetaDataColIndices, col);
                            end
                        end

                        % Finally, we convert the cell's "editor value" to the name of variable it represents.
                        % For example, say we have a struct "s.a" with field "b". When viewing the struct in the
                        % Variable Editor, cell "b" would have an editor value of "s.a.b". "s.a" with an appended
                        % delimiter is the root name, and "b" is what follows after.
                        rootName = internal.matlab.variableeditor.VEUtils.appendRowDelimiter(this.DataModel.Name);
                        cellVarName = this.getSubVarName(this.DataModel.Name, extractAfter(varName, rootName));

                        cellData.editorValue = cellVarName;
                    else
                        cellData.editable = fields{col}.Editable;
                    end
                    renderedData{row, col} = jsonencode(cellData);
                end
            end

            this.CellModelChangeListener.Enabled = true;
            if ~isempty(CellMetaDataColIndices)
                this.updateCellModelInformation(startRow, endRow, min(CellMetaDataColIndices), max(CellMetaDataColIndices));
            end
            renderedDims = size(renderedData);
        end

        function isEditable = isFieldEditable(this, fieldName)
            % If this is a fieldValue of a parent struct array, set
            % FieldEditable to be false.
            % If we have struct whose child is a struct array (1xn
            % or nx1, then isStructArray is true
            rootName = internal.matlab.variableeditor.VEUtils.appendRowDelimiter(this.DataModel.Name);
            fieldName = extractAfter(fieldName, rootName);
            fieldVals = internal.matlab.variableeditor.VEUtils.splitRowId(fieldName);
            isEditable = true;
            data = this.getData();
            % If fieldVals are of length <=1, we are at top level display
            % and this cannot be a struct array.
            if length(fieldVals) > 1
                parentVal = getfield(data, fieldVals{1:end-1});
                if this.checkExpandability(parentVal) && (size(parentVal, 1) > 1 || size(parentVal,2) > 1)
                    isEditable = false;
                end 
            end
        end

        % When RowMetaData 'isExpanded' is set from client, update
        % ExpansionList and emit DataChange to refresh the view.
        function status = handleClientSetRowMetaData(this, ed)
            if strcmp(ed.property, 'isExpanded')
                isExpanded = ed.value;
                row = ed.row + 1;
                this.handleExpandCollapse(row, isExpanded);

                % Update row metadata once rowExpansionList is populated
                status = this.handleClientSetRowMetaData@internal.matlab.variableeditor.peer.RemoteStructureViewModel(ed);

                this.updateDataAndDispatchMessages();
            else
                status = this.handleClientSetRowMetaData@internal.matlab.variableeditor.peer.RemoteStructureViewModel(ed);
            end
        end

        % Handles Expand/Collapse for a single row by computing children to
        % be added/removed and updating CachedSize on DataModel.
        function handleExpandCollapse(this, row, isExpanded)
            arguments
                this
                row double
                isExpanded logical
            end
            internal.matlab.datatoolsservices.logDebug("variableeditor::RemoteStructTreeViewModel", "handleExpandCollapse() called " + string(row));

            rowId = this.getRowModelProperty(row, 'id');
            % rowLevel = this.getRowModelProperty(row, 'level');
            % get the relative rowId from the first name
            rootName = internal.matlab.variableeditor.VEUtils.appendRowDelimiter(this.DataModel.Name);
            relativeID = strsplit(rowId{1}, rootName);
            if isExpanded
                % Expand and update size only if the current field is not
                % already expanded
                if ~any(ismember(this.ExpansionList, rowId{1}))
                    this.updateRowExpansionList(rowId{1}, isExpanded);
                    childrenCount = this.getExpandedChildren(rowId{1});
                    this.DataModel.updateSizeOnExpand(relativeID{2}, childrenCount);
                end
                this.IsFullyCollapsed = false;
            else
                % Collapse and update size only if the current field is not
                % already collapsed
                if any(ismember(this.ExpansionList, rowId{1}))
                    childrenCount = this.getExpandedChildren(rowId{1});
                    this.DataModel.updateSizeOnCollapse(childrenCount);
                    this.updateRowExpansionList(rowId{1}, isExpanded);
                end
                this.IsFullyExpanded = false;
            end

            % TODO: Figure out if we need to call "this.updateDataAndDispatchMessages()".
            this.updateRowMetaData();
        end

        % This function recursively fetches all visible fields and accordingly
        % updates their metadata. This metadata includes:
        % - Row "levels" (how indented the row should be to indicate hierarchy)
        % - Row IDs
        % - Whether the row is nested underneath another row
        %
        % TODO: Figure out when this should be called. This comment block previously
        % implied that this function should be called after every RowModel update,
        % meaning after every expand and collapse option. However, some expand and
        % collapse actions work as expected after excluding calling this function.
        function updateRowModelInformation (this, startRow, endRow, fullRows)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
            end

            sz = this.getTabularDataSize();
            numRows = sz(1);
            endRow = min(endRow, numRows);
            this.RowModelChangeListener.Enabled = false;

            % If this view is currently unsorted, fetch nested fields only
            % from startRow:endRow
            if isempty(this.SortedIndices)
                data = this.getData();
                structName = this.DataModel.Name;
                levels = zeros(1, endRow-startRow+1);
                ids = strings(1, endRow-startRow+1);
                isNested = zeros(1, endRow-startRow+1);
                origFieldNames = strings(1, endRow-startRow+1);
                [levels, ids, ~, isNested, ~] = this.fetchNestedFields(data, structName, 0, startRow, endRow, 1, levels, ids, origFieldNames, isNested);
            else
                [levels, ids, ~, isNested, ~] = this.fetchNestedFields();
                levels = levels(this.SortedIndices);
                ids = ids(this.SortedIndices);
                isNested = isNested(this.SortedIndices);
                % Truncate to requested rows
                levels = levels(startRow:endRow);
                isNested = isNested(startRow:endRow);
                ids = ids(startRow:endRow);
            end
            curRow = 1;
            for row=startRow:endRow
                this.setRowModelProperties(row,...
                    'level', levels(curRow),...
                    'id', ids(curRow),...
                    'isExpanded', any(ismember(this.ExpansionList, ids(curRow))),...
                    'isExpandable', isNested(curRow));
                curRow = curRow + 1;
            end

            this.RowModelChangeListener.Enabled = true;
            this.updateRowModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel(startRow, endRow, fullRows);
            this.cleanupStaleRowModelProperties(numRows);
        end

        % Adds rowId to expansionList if addToList is true and removes from
        % list if false.
        function updateRowExpansionList(this, rowId, addToList)
            arguments
                this
                rowId
                addToList logical = false
            end
            if addToList 
                if ~any(ismember(this.ExpansionList, rowId))
                    this.ExpansionList(end+1) = rowId;
                end
            else
               findIdx = ismember(this.ExpansionList, rowId);
               if any(findIdx)
                    this.ExpansionList(findIdx) = [];
                end
            end
        end

        % When data changes in DataModel, fields could have been added or
        % removed. Update Expansion list with fields currently unavailable
        % and update DataModel's Size cache.
        function handleDataChangedOnDataModel(this, es, ed)
            % Since size reduces, we need to update row metadata from
            % server to refresh viewport and update expansion list
            deletionList = string.empty;
            name = this.DataModel.Name;
            expansionList = this.ExpansionList;
            data = this.getData();
            for i=1:length(expansionList)
                fname = expansionList(i);
                % TODO: find if there is a better way to find if nested fields are available
                if ~ismissing(fname) && ~strcmp(fname, name)
                    try
                        fieldData = this.getFieldData(data, fname);
                        fieldDataExpandable = this.checkExpandability(fieldData);
                        if ~fieldDataExpandable
                            % This field is in expansion list but is no-longer a container data type, remove this field
                            % and all it's children from the ExpansionsList.
                            rootName = internal.matlab.variableeditor.VEUtils.appendRowDelimiter(fname);
                            matchedIdxStartsWith = startsWith(expansionList, rootName);
                            matchedIdxExact = strcmp(expansionList, fname);
                            matchedIdx = matchedIdxStartsWith | matchedIdxExact;
                            deletionList = [deletionList expansionList(matchedIdx)];
                            expansionList(matchedIdx) = missing;
                        end
                    catch e
                        deletionList(end+1)=fname;
                    end
                end
            end
            if ~isempty(deletionList)
                deletionIdx = ismember(this.ExpansionList, deletionList);
                this.ExpansionList(deletionIdx) = [];
            end
            
            updatedSize = this.fetchExpandedRowSize(data, this.DataModel.Name, 0, 0);
            % Check if cached size of rows have changed in order to set
            % SizeChanged
            currentCachedSize = this.DataModel.getCachedSize();
            if ~isequal(currentCachedSize(1), updatedSize)
                this.DataModel.setCachedSize([updatedSize currentCachedSize(2)]);
                ed.SizeChanged = 1;
            end
            this.handleDataChangedOnDataModel@internal.matlab.variableeditor.peer.RemoteStructureViewModel(es, ed);
            this.updateRowMetaData();
        end

        % Called on Field name edit from client. Pass along rowId to
        % DataModel
        function out = executeCommandInWorkspace(this, data, row, column)
            rowId = this.getRowModelProperty(row, 'id');
            out = this.setData(data, row, column, rowId{1});
        end

        % This method refreshes SortIndices and should be called after:
        % - Any time a sort action is performed on the field columns
        % - Any time a struct field is expanded or collapsed
        function handleSortAscending(this)
            if ~isempty(this.SortedColumnInfo.ColumnIndex)
                % On empty DataModel, clear SortedIndices and return.
                if isempty(this.getFields(this.DataModel.Data))
                    this.SortedIndices = [];
                    return;
                end
                data = this.getData();
                fieldNames = this.getFields(data);
                colIndex = this.SortedColumnInfo.ColumnIndex;
                % find field even if it's not visible, sortedIndices might
                % have to be computed even when a column is hidden
                fieldColumn = this.findField(colIndex);
                fieldColumn.setSortAscending(this.SortedColumnInfo.SortOrder);

                [~, ids, ~, isNested, ~] = this.fetchNestedFields();
                [cellData, virtualVals] = this.getRenderedCellData(data, ids);
                parents = internal.matlab.variableeditor.VEUtils.getParentFieldIds(ids);

                sortedIdx = this.getHeirarchicalSortedIndicies(cellData, fieldNames, virtualVals, data, fieldColumn, parents, ids, isNested);
                this.SortedIndices = sortedIdx;
                this.setTableModelProperty('LastSorted', struct('index', colIndex -1, 'order', this.SortedColumnInfo.SortOrder), true);
                this.SortedColumnViewIndex = colIndex - 1;
            end
        end

        % Computes sorted indices for each level of the expanded fields
        % from a particular FieldColumn
        function sortedIndices = getHeirarchicalSortedIndicies(this, cellData, fieldNames, virtualVals, data, fieldColumn, parents, ids, isNested, currentParent)
            arguments
                this
                cellData
                fieldNames
                virtualVals
                data
                fieldColumn
                parents
                ids
                isNested
                currentParent string {mustBeScalarOrEmpty} = string.empty;
            end

            sortedIndices = [];
            if isempty(data)
                return;
            end

            if isempty(currentParent)
                currentParent = parents(1);
            end

            childIndices = find(parents == currentParent);
            cellDataSubset = cellData(childIndices);
            if ~isempty(cellDataSubset)
                childIds = ids(childIndices);
                virtualValsForIdx = virtualVals(childIndices);
                sortedChildIndices = fieldColumn.getSortedIndices(cellDataSubset(:), childIds(:), virtualValsForIdx(:), data);
                if isempty(sortedChildIndices)
                    sortedChildIndices = childIndices;
                else
                    sortedChildIndices = childIndices(sortedChildIndices);
                end
    
                for c=1:length(sortedChildIndices)
                    childIndex = sortedChildIndices(c);
                    sortedIndices(end+1) = childIndex; %#ok<*AGROW>
                    if isNested(childIndex)
                        si = this.getHeirarchicalSortedIndicies(cellData, fieldNames, virtualVals, data, fieldColumn, parents, ids, isNested, ids(childIndex));
                        if ~isempty(si)
                            for i = 1:length(si)
                                sortedIndices(end+1) = si(i);
                            end
                        end
                    end
                end
            end
        end

        function oldValue = getOldValueFromRenameEventData(this, eventData)
            cellId = this.getRowModelProperty(eventData.row, 'id');
            rowId = cellId{:}; % String
            splitId = internal.matlab.variableeditor.VEUtils.splitRowId(rowId);
            oldValue = splitId(end);
        end

        % Called when the user sets table data from the client.
        % Supports toggling "visibility" for each table variable. This refers
        % to toggling an eye icon associated with the row; when the eye is
        % open, the row is "visible". When it's closed, the row is "hidden".
        function handleClientSetData(this, eventData)
            column = this.getStructValue(eventData, 'column');
            if ischar(column)
                column = str2double(column);
            end

            row = this.getStructValue(eventData, 'row');
            if ischar(row)
                row = str2double(row);
            end

            cellId = this.getRowModelProperty(row, 'id');
            rowId = cellId{:}; % String

            if this.DataModel.fieldDataIsTabular(rowId) && this.isFieldNameColumn(column)
                % Tabular column names supports all of unicode, so we don't
                % need to validate the renamed value like the struct fields.
                newData = this.getStructValue(eventData, 'data');
                fieldNameValidationFn = @(x) true;
                this.handleRenameAction(eventData, newData, fieldNameValidationFn, row, column);
                return
            end

            if this.isCustomColumn(column)
                if this.isFieldVisibilityColumn(column)
                    % Argument setup
                    oldData = this.getFields(this.getData());
                    oldData = oldData{:};
                    newData = this.getStructValue(eventData, 'data');

                    % eventData.rowId: StructName.TableName.VariableName

                    % Define visibility-related variables...
                    splitId = internal.matlab.variableeditor.VEUtils.splitRowId(rowId);
                    % splitId: ["StructName", "TableName", "VariableName"];
                    visFlags = strcat(splitId(1), ".", splitId(2), ".Properties.CustomProperties.VisibilityFlags");
                    % visFlags: "StructName.TableName.Properties.CustomProperties.VisibilityFlags"
                    visFlagsWithKey = strcat(visFlags, "('", rowId, "')");
                    % visFlagsWithKey: "StructName.TableName.Properties.CustomProperties.VisibilityFlags(StructName.TableName.VariableName)"

                    % ...and construct code that toggles the visibility value if the key exists in visFlags.
                    ifStatement = strcat("if isKey(", visFlags, ", '", rowId, "') ");
                    bodyCode = strcat(visFlagsWithKey, " = ", string(newData), ";");
                    code = strcat(ifStatement, bodyCode, ", end");

                    % Notify listeners to execute their callback functions.
                    % We create our own "SingleCellClick" user action for special VariableEditor behavior.
                    % This can be refactored so that the generated code can be executed here within the view model,
                    % rather than forcing the Variable Editor itself to execute the code.
                    % See VariableEditor.m's "handleDataEdit" function for more context.
                    this.notifyVariableEdit('SingleCellClick', row, column, oldData, newData, code);
                end
            else
                this.handleClientSetData@internal.matlab.variableeditor.peer.RemoteStructureViewModel(eventData);
            end
        end

        % TODO: This method updates selection when data changes or is
        % sorted to arrange selection w.r.t sorted indices. Implement with
        % g2854488.
        function updateSelection(~)
        end

        % See StructureViewModel.m for original function definition.
        function isCustomColumn = isCustomColumn(this, columnNumber)
            isCustomColumn = false;

            fieldColumn = this.findVisibleField(columnNumber);
            if isprop(fieldColumn, "CustomColumn")
                if fieldColumn.CustomColumn
                    isCustomColumn = true;
                end
            end
        end
    end

    methods(Hidden)
        % Returns true if rowId is in current ExpansionList and false
        % otherwise.
        function isExpanded = isRowExpanded(this, rowId, fieldName)
            isExpanded = any(ismember(fieldName, this.ExpansionList));
        end
    end
end

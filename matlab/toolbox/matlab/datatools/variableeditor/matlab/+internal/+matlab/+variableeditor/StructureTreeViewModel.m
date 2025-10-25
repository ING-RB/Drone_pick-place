classdef StructureTreeViewModel < ...
        internal.matlab.variableeditor.StructureViewModel
    % STRUCTURETREEVIEWMODEL 
    % StructureTreeViewModel base view model class for displaying scalar
    % structs in a tree view.

    % Copyright 2022-2025 The MathWorks, Inc.

    properties(Hidden)
        % Expansion List prop contains a string array of all the currently
        % expanded fields(rowIDs) in the view. This is used as source of truth to
        % know whether a child is expanded and to compute children count on
        % expansion or collapse. For e.g ["s", "s.a", "s.a.b.c.d",...]
        ExpansionList string
    end

    properties (Constant, Hidden)
        STRUCT_ARR_ELEM_CUTOFF = 3;
        % TODO: Properly integrate tree object data expansion and remove this flag.
        SUPPORT_EXPANDING_OBJECT_PROPERTIES = true;
        % List of objects that are non-expandable
        NON_EXPANDABLE_OBJECTS = {'embedded.fi'};
    end

    methods
        function [len] = getExpandedChildren(this, rowId)
            % Modify the logic to handle field name substring conflicts.
            % The modification makes use of dot notation, which treats each field as
            % a separate entity and avoids conflicts arising from substring matches.
            matchedIdxStartsWith = startsWith(this.ExpansionList, internal.matlab.variableeditor.VEUtils.appendRowDelimiter(rowId));
            matchedIdxExact = strcmp(this.ExpansionList, rowId);
            matchedIdx = matchedIdxStartsWith | matchedIdxExact;
            currentlyExpandedFields = this.ExpansionList(matchedIdx);
            data = this.getData();
            len = 0;
            rootIndex = length(internal.matlab.variableeditor.VEUtils.splitRowId(this.DataModel.Name));
            for i=1:length(currentlyExpandedFields)
                currRelativeField = currentlyExpandedFields(i);
                fieldID = internal.matlab.variableeditor.VEUtils.splitRowId(currRelativeField);
                countChildren = true;

                % Check all parents leading up to a root that is not
                % expanded, if all parents upto root are expanded, this
                % must be included in children count.
                for j=length(fieldID)-1:-1:rootIndex
                    parentID = internal.matlab.variableeditor.VEUtils.joinRowId(fieldID(1:j));
                    countChildren = any(strcmp(this.ExpansionList, parentID));
                    if ~countChildren
                        break;
                    end
                end
                if countChildren
                    len = len + length(this.getFields(this.getFieldData(data, currRelativeField)));
                end
            end
        end

        % Recursive function to fetch all levels/ids/fieldNames to be
        % displayed for a given struct (sub-)field based on some given
        % information.
        function [levels, ids, origNames, isExpandable, currRow] = fetchNestedFields(this, structVal, structname, level, startRow, endRow, currRow, levels, ids, origNames, isExpandable)
            arguments
                this
                structVal = this.getData()                 % The struct data to fetch its nested fields for
                structname = this.DataModel.Name           % The struct's name (which includes its parents' names; e.g., "struct.field.subfield")
                level = 0                                  % The struct's "level". struct.field.subfield has a level of "2", for example.
                startRow = 1                               % The starting row that will be displayed to the user.
                endRow = this.DataModel.CachedSize(1)      % The ending row that will be displayed to the user.
                currRow = 1                                % The current row we are fetching data at.
                levels = zeros(1, endRow-startRow+1)       % A running list of startRow through endRow's levels.
                ids = strings(1, endRow-startRow+1)        % A running list of startRow through endRow's IDs.
                origNames = strings(1, endRow-startRow+1)  % A running list of startRow through endRow's display names.
                isExpandable = zeros(1, endRow-startRow+1) % A running list of startRow through endRow's "isNested" state. If a row is nested, it means it contains sub rows.
            end

            % This algorithm is depth first search. We get the current struct's fields
            % (or current table's variables), then go through them one by one, checking whether
            % they, in turn, can be expanded. If they can, we call this function on the sub-field/variable.
            %
            % We only gather a row's metadata if it lies within the start and end row range.

            if (currRow > endRow)
                return;
            end

            fnames = this.getFields(structVal);
            fnames = fnames(:);
            % Vectorize delimiter concatenation for performance (g3406978)
            n = min(length(fnames),endRow);
            currRowIDs = strcat(repmat(string(structname)+internal.matlab.variableeditor.VEUtils.DELIMITER,...
                [n 1]),string(fnames(1:n)));

            for i=1:length(fnames)
                if (currRow <= endRow)
                    origFieldName = fnames{i};
                    currRowID = currRowIDs(i);

                    % "subFieldValue" will be used to represent the value of the current row.
                    subFieldValue = [];

                    % Only record the current row's metadata if it's within the start to end row range.
                    if currRow >= startRow && currRow <= endRow
                        adjustedIndex = currRow - startRow + 1;
                        origNames(adjustedIndex) = origFieldName;
                        ids(adjustedIndex) = currRowID;
                        levels(adjustedIndex) = level;

                        % The current row is only expandable if it contains fields.
                        subFieldValue = this.getFieldVal(origFieldName, structVal);
                        isExpandable(adjustedIndex) = this.checkExpandability(subFieldValue);
                    end

                    currRow = currRow+1;

                    if this.isRowExpanded([], currRowID)
                        % If the row is expanded, we know by definition that is has to be expandable
                        % (otherwise the user could not have expanded it). We're safe to dig into it.
                        try
                            % If "subFieldValue" has already been defined (because the current row is within
                            % the requested range), we reuse it. Otherwise, we fetch it here.
                            if isempty(subFieldValue)
                                subFieldValue = this.getFieldVal(origFieldName, structVal);
                            end

                            % Recursively continue fetching nested fields.
                            [levels, ids, origNames, isExpandable, currRow] = this.fetchNestedFields( ...
                                subFieldValue, currRowID, level+1, startRow, endRow, currRow, levels, ids, origNames, isExpandable);
                        catch e % Handle errors on recursion
                            internal.matlab.datatoolsservices.logDebug("variableeditor::StructureTreeViewModel", "fetchNestedFields failed: " + e.message);
                        end
                    end

                    % If we've encountered a row that is not expanded, we do not need to care whether
                    % it's expandable---regardless if it's expandable, we know we should not fetch
                    % its nested fields.

                else % We're past the requested end row:
                    % We've done everything we need to do, so we can safely return early.
                    return
                end
            end
        end

        % Recursive function that returns all possible fields that can be
        % expanded from a certain nested field.
        function [ids, childrenCount] = fetchAllExpandableFieldNames(this, structVal, structname, ids, childrenCount, countExpandedFields)
            fnames = this.getFields(structVal);
            expandableFlags = this.checkChildExpandability(structVal, @(val) this.checkExpandability(val));
            mustCount = countExpandedFields;
            if ~mustCount
                % Check if structname is expanded, and count only if not.
                mustCount = ~this.isRowExpanded([], structname);
            end
            if mustCount
                childrenCount = childrenCount + length(fnames);
            end
            for i=1:length(fnames)
                % check if startRow is currRow
                fname = fnames{i};
                currFieldName = internal.matlab.variableeditor.VEUtils.joinRowId({structname fname});
                if expandableFlags(i)
                    ids(end+1) = currFieldName;
                    [ids, childrenCount] = this.fetchAllExpandableFieldNames(structVal.(fname), currFieldName, ids, childrenCount, countExpandedFields);
                end    
            end
        end

        % Recursive function that returns the row size from a current field
        % level based on the current expansion.
        function rowCount = fetchExpandedRowSize(this, structVal, structName, currRow, rowCount)
            arguments
                this
                structVal  {isscalar}
                structName {mustBeTextScalar}
                currRow    double {mustBeNonnegative}
                rowCount   double {mustBeNonnegative}
            end

            fnames = this.getFields(structVal);
            rowCount = rowCount + length(fnames);

            for i=1:length(fnames)
                fname = fnames{i};
                currFieldName = internal.matlab.variableeditor.VEUtils.joinRowId({structName fname});
                isExpanded = this.isRowExpanded(currRow, currFieldName);
                currRow = currRow+1;
                if isExpanded
                    newStructVal = this.getFieldVal(fname, structVal);
                    rowCount = this.fetchExpandedRowSize(newStructVal, currFieldName, currRow, rowCount);
                end    
            end
        end

        % In addition to renderedData and renderedDims, this also returns
        % classValues computed (needed for icons on Name column) and
        % fieldColumns of fields visible.
        function [renderedData, renderedDims, classValues, columnFields, accessValues] = getDisplayData(...
                this, startRow, endRow, startColumn, endColumn)
            % This method always returns all columns of data, since there
            % is only a predefined number of columns.

            % Returns renderedData which is a cell array with each row
            % being a field in the structure, and the columns are:
            % 1 - field name
            % 2 - displayed value
            % 3 - size
            % 4 - class
            classValues = {};
            accessValues = {};
            columnFields = {};
            data = this.getData();
 
            numRows = endRow - startRow + 1;% find out if this would ever exceed fieldnames length
            numColsToCompute = endColumn - startColumn + 1;
            renderedData = cell([numRows numColsToCompute]);
            if numRows > 0
                % If this view is currently unsorted, fetch nested fields only
                % from startRow:endRow
                if isempty(this.SortedIndices)
                    structName = this.DataModel.Name;
                    levels = zeros(1, endRow-startRow+1);
                    ids = strings(1, endRow-startRow+1);
                    isNested = zeros(1, endRow-startRow+1);
                    displayFieldNames = strings(1, endRow-startRow+1);
                    [~, ids, displayFieldNames, ~, ~] = this.fetchNestedFields(data, structName, 0, startRow, endRow, 1, levels, ids, displayFieldNames, isNested);
                    fnames = ids;
                    [cellData, virtualVals, accessValues] = this.getRenderedCellData(data, fnames);
                else
                    [~, ids, displayFieldNames, ~, ~] = this.fetchNestedFields();
                    fnames = ids;
                    [cellData, virtualVals, accessValues] = this.getRenderedCellData(data, fnames);
                    if ~isempty(this.SortedIndices)
                        fnames = fnames(this.SortedIndices);
                        cellData = cellData(this.SortedIndices);
                        displayFieldNames = displayFieldNames(this.SortedIndices);
                    end
                    fnames = fnames(startRow:endRow);
                    cellData = cellData(startRow:endRow);
                    displayFieldNames = displayFieldNames(startRow:endRow);
                    virtualVals = virtualVals(startRow:endRow);
                end

                % TODO: Compute once and cache until data changes in dm
                this.OrderedFields = fnames;
                try
                    columnFields = cell([1, numColsToCompute]);
                    % "fnames" contains the IDs for every row shown in the (UI)Variable Editor.
                    % This differs from "displayFieldNames" in that the latter only contains the text
                    % we're displaying in the row; using the field name alone, you cannot determine
                    % which specific row is being displayed.

                    for col = startColumn: endColumn
                        fieldColumn = this.findVisibleField(col);
                        renderedData(:,col) = fieldColumn.getData(startRow, endRow, cellData, displayFieldNames, virtualVals, data, true, true, fnames);
                        hName = fieldColumn.getHeaderName();
                        if strcmp(hName, internal.matlab.variableeditor.FieldColumns.ClassCol.COLUMN_NAME)
                            classValues = renderedData(:, col);
                        end
                        columnFields{col} = fieldColumn;
                    end
    
                    % If classcol is hidden, we still want to compute classes to
                    % update the right icons in the name column
                    if isempty(classValues)
                        % Find class column even if unavailable on the view
                        classCol = this.findFieldByHeaderName(internal.matlab.variableeditor.FieldColumns.ClassCol.COLUMN_NAME, true);
                        classValues = classCol.getData(startRow, endRow, cellData, displayFieldNames, virtualVals, data, true, true, fnames);
                    end
                catch e
                    internal.matlab.datatoolsservices.logDebug("variableeditor::StructTreeViewModel", "getDisplayData failed: " + e.message);
                end
            end
            renderedDims = size(renderedData);
        end

        % On data set as a result of edit, varargin contains
        % row,col,newValue as well as RowID of the field being edited.
        function varargout = setData(this,varargin)
            % Simple case, all of data replaced
            if nargin == 2
                varargout{1} = this.setData@internal.matlab.variableeditor.ArrayViewModel(varargin{:});
                return;
            end
            % Check for paired values.  varargin should be triplets, or
            % triplets with an error message string at the end
            if rem(nargin-1, 4)~=0 && ...
                    (rem(nargin-2, 4)==0 && ~ischar(varargin{nargin-1}))
                error('Use name/row/col/rowID arguments to specify values');
            end

            % Range(s) specified (value-range pairs)
            args = cell(nargin-1,1);
            for i=4:4:nargin
                % TODO: Get the indices w.r.t sorted data
                args{i} = varargin{i}; % rowID
                args{i-1} = varargin{i-1}; % row
                args{i-2} = varargin{i-2}; % col
                args{i-3} = varargin{i-3}; % newValue
            end
            args{end} = varargin{end};
            
            varargout{1} = this.setData@internal.matlab.variableeditor.ArrayViewModel(args{:});
        end

        % Gets all currently selected fields.
        % Note that the output fields will not begin with our Data Model's
        % variable name; if you need the root variable name to be included,
        % use `this.SelectedFields` instead.
        %
        % NOTE: We may need to revisit this function's behavior. The base
        % version of this function returns selected fields _with_ the root;
        % it may be better to keep this behavior consistent.
        function selectedFields = getSelectedFields(this)
            arguments (Output)
                selectedFields (1,:) string
            end

            rootName = internal.matlab.variableeditor.VEUtils.appendRowDelimiter(this.DataModel.Name);
            selectedFields = extractAfter(this.SelectedFields, rootName);
        end

        % Returns nested field data at any particular level. 
        % NOTE: This API can throw errors if the field did not exist.
        % NOTE: This function looks like it was made with the assumption that the input argument
        %       "data" would always be the DataModel's data, and the provided field name would
        %       always be a full row ID. In the future, we should reassess if it's a good idea
        %       to genericize this function so it works with any subset of data.
        function fieldData = getFieldData(this, data, nestedFieldName)
            arguments
                this
                data
                nestedFieldName (1,:) string % If scalar, this must use the custom VEUtils delimiter
            end

            % If we are provided a single string, it's implied we must split the string
            % at each delimiter. If we are provided an array, it's implied we can skip
            % this work.
            if isscalar(nestedFieldName)
                % Cut the root out of the field name if necessary.
                rootName = internal.matlab.variableeditor.VEUtils.appendRowDelimiter(this.DataModel.Name);
                if contains(nestedFieldName, rootName)
                    nestedFieldName = extractAfter(nestedFieldName, rootName);
                end

                fieldVals = internal.matlab.variableeditor.VEUtils.splitRowId(nestedFieldName);
            else
                fieldVals = nestedFieldName;
            end

            try
                fieldData = getfield(data, fieldVals{:});
            catch ex
                fieldData = internal.matlab.datatoolsservices.FormatDataUtils.ERR_DISPLAYING_VALUE;
            end
        end

        % SelectedFields preserves the order of selection from client. Just
        % return this as is for FormattedSelection. 
        % This is used by plots gallery to plot fields.
        function varargout = getFormattedSelection(this, varargin)
            selectionString = strjoin(this.SelectedFields, ';');
            varargout{1} = char(selectionString);
        end

        % Determines whether the given field name belongs to a struct array.
        function isField = isStructArrayField(this, fieldName)
            arguments (Input)
                this
                fieldName (1,1) string % fieldName contains a special delimiter.
                                       % See internal.matlab.variableeditor.VEUtils for more details.
                                       % fieldName is not expected to start with this view model's struct's name.
            end
            arguments (Output)
                isField (1,1) logical
            end

            fieldVals = internal.matlab.variableeditor.VEUtils.splitRowId(fieldName);
            isField = false;
            try
                if length(fieldVals) > 1
                    data = this.getData();
                    parentVal = getfield(data, fieldVals{1:end-1});
                    % If fieldName is a field of a struct array or object array parent.
                    expandability = isstruct(parentVal) || internal.matlab.datatoolsservices.FormatDataUtils.checkNonPrimitiveObject(parentVal);
                    isField = expandability && ~isscalar(parentVal) && ~isempty(parentVal);
                end
            catch e
                internal.matlab.datatoolsservices.logDebug("variableeditor::StructTreeViewModel", "isStructArrayField failed with error: " + e.message);
            end
        end

        % Determines whether the given field name is a table variable/column.
        function [isTableVar, isRowTimeVar] = isTableVariable(this, fieldName)
            arguments (Input)
                this
                fieldName (1,1) string % fieldName contains a special delimiter.
                                       % See internal.matlab.variableeditor.VEUtils for more details.
                                       % fieldName is not expected to start with this view model's struct's name.
            end

            arguments (Output)
                isTableVar (1,1) logical
                isRowTimeVar (1,1) logical
            end

            fieldVals = internal.matlab.variableeditor.VEUtils.splitRowId(fieldName);
            isTableVar = false;
            isRowTimeVar = false;

            try
                if length(fieldVals) >= 2 % The minimum hierearchy needed is tableField.variable
                    data = this.getData();
                    parentVal = this.getFieldVal(internal.matlab.variableeditor.VEUtils.joinRowId(fieldVals(1:end-1)), data);

                    isTableVar = istabular(parentVal) && ismember(fieldVals{end}, parentVal.Properties.VariableNames);
                    isRowTimeVar = istimetable(parentVal) && strcmp(parentVal.Properties.DimensionNames{1}, fieldVals{end}) == 1;
                end
            catch e
                internal.matlab.datatoolsservices.logDebug("variableeditor::StructTreeViewModel", "isTableVariable failed with error: " + e.message);
            end
        end

        function containsTableVar = containsTableVariable(this, fieldNames)
            arguments (Input)
                this
                fieldNames (1,:) string % These field names contain a special delimiter.
                                        % See internal.matlab.variableeditor.VEUtils for more details.
            end

            arguments (Output)
                containsTableVar (1,1) logical
            end

            [isTableVarArray, isRowTimeVarArray] = arrayfun(@(name) this.isTableVariable(name), fieldNames);
            containsTableVar = any(isTableVarArray) || any(isRowTimeVarArray);
        end

        % Determines whether the given set of row IDs contain at least one timetable row time variable.
        function containsRowTimeVar = containsRowTimeVariable(this, fieldNames)
            arguments (Input)
                this
                fieldNames (1,:) string % These field names contain a special delimiter.
                                        % See internal.matlab.variableeditor.VEUtils for more details.
            end

            arguments (Output)
                containsRowTimeVar (1,1) logical
            end

            [~, isRowTimeVariable] = arrayfun(@(name) this.isTableVariable(name), fieldNames);
            containsRowTimeVar = any(isRowTimeVariable);
        end
    end

    methods (Access = protected)
        % Overrides StructureViewModel.m method
        function fields = getFields(~, data)
            if istabular(data)
                fields = data.Properties.VariableNames;

                % Prepend a "Time" field if the data is a timetable.
                if istimetable(data)
                    timeFieldName = data.Properties.DimensionNames(1);
                    fields = [timeFieldName, fields];
                end
            elseif internal.matlab.datatoolsservices.FormatDataUtils.checkNonPrimitiveObject(data)
                fields = properties(data);
            else
                fields = fieldnames(data);
            end
        end

        % Gets the value for a given nested field name.
        % For example: Given the hierarchy "struct.field.subField", an input
        % of "field.subField" will give the data for "subField". The "struct"
        % part is excluded.
        % - Note that this assumes the passed in "data" argument is this
        %   view model's struct.
        function val = getFieldVal(this, nestedFieldName, data)
            arguments (Input)
                this
                nestedFieldName (1,1) string
                data
            end

            fieldVals = internal.matlab.variableeditor.VEUtils.splitRowId(nestedFieldName);
            try
                if length(fieldVals) > 1
                    parentVal = getfield(data, fieldVals{1:end-1});
                    % If we have struct whose child is a struct array (1xn
                    % or nx1, then compute upto first 3 field values to be displayed)
                    expandability = isstruct(parentVal) || internal.matlab.datatoolsservices.FormatDataUtils.checkNonPrimitiveObject(parentVal);
                    if expandability && (size(parentVal, 1) > 1 || size(parentVal,2) > 1) && ~(isequal(parentVal, [1, 1]) || isscalar(parentVal))
                        len = min(length(parentVal), this.STRUCT_ARR_ELEM_CUTOFF);
                        isOverflow = length(parentVal) > len;
                        structArrVals = cell(1, len);
                        for i = 1:len
                            structArrVals{i} = parentVal(i).(fieldVals{end});
                        end
                        val = internal.matlab.variableeditor.StructArraySummary(structArrVals, isOverflow);
                    else
                        val = getfield(data, fieldVals{:});
                    end
                else
                    val = getfield(data, fieldVals{:});
                end
            catch
                val = internal.matlab.datatoolsservices.FormatDataUtils.NO_VALUE_PLACEHOLDER;
            end
        end

        % Return a cell array containing the values of the data
        function [cellData, virtualVals, accessVals] = getRenderedCellData(this, data, nameIDs)
            % TODO: If all collapsed, use struct2cell
            rootName = internal.matlab.variableeditor.VEUtils.appendRowDelimiter(this.DataModel.Name);
            nameIDs = extractAfter(nameIDs, rootName);
            cellData = cellfun(@(f) this.getFieldVal(f, data), nameIDs, ...
                'UniformOutput', false, ...
                'ErrorHandler', @(~,~) []);
            virtualVals = false(size(nameIDs));
            
            % For a struct, access is always considered public
            accessVals = repmat({'public'}, size(nameIDs));
        end

        % Sets selected fields based on currentFields(RowIDs) sent from the client.
        function setSelectedFields(this, selectedRows, selectedColumns, selectionSource, selectedFields)
            arguments
                this
                selectedRows = []
                selectedColumns = [] 
                selectionSource = ''
                selectedFields = {}
            end
            % TODO: check if everything was in memory
            if strcmp(selectionSource, 'client')
                % Set Selected Fields only if selection is from client.
                % NOTE: currFields coming from client is the rowId.
                % This will have @#@# delimited version, preserve this version in SelectedFields for actions to work
                this.SelectedFields = string(selectedFields);
            end 
        end
 
        % Helper function to determine if child elements are expandable
        function expandableFlags = checkChildExpandability(this, parentValue, expandabilityCheckFunc)
            arguments (Output)
                expandableFlags (:,1) double % Flags with one of two values:
                                             % 0: Child value is not expandable
                                             % 1: Child value is expandable
            end

            if isscalar(parentValue) && isstruct(parentValue)
                expandableFlags = structfun(expandabilityCheckFunc, parentValue);

            elseif istabular(parentValue)
                expandableFlags = varfun(expandabilityCheckFunc, parentValue);
                expandableFlags = table2array(expandableFlags);
                % If the value is a timetable, we need to add an element to
                % "expandableFlags" to signify that the "Time" column is not expandable.
                if istimetable(parentValue)
                    expandableFlags = [false, expandableFlags];
                end

            elseif internal.matlab.datatoolsservices.FormatDataUtils.checkNonPrimitiveObject(parentValue) ...
                    && isscalar(parentValue)
                % First check if the object uses property value pair
                % display
                doesClassUsePropertyValuePairDisplay = matlab.display.internal.doesClassUsePropertyValuePairDisplay(parentValue);
                if doesClassUsePropertyValuePairDisplay
                    % Use the MCOS API to get the properties of objects and their values
                    objectDisplayWidth = internal.matlab.datatoolsservices.FormatDataUtils.MAX_TEXT_DISPLAY_LENGTH;
                    propDisplay = matlab.display.internal.objectDisplay(parentValue, objectDisplayWidth);
                    propValues = propDisplay.PropertyValues;
                    expandableFlags = cellfun(expandabilityCheckFunc, propValues);
                else
                    propNames = properties(parentValue);
                    errorHandlerFunc = @(s, varargin) internal.matlab.datatoolsservices.FormatDataUtils.ERR_DISPLAYING_VALUE;
                
                    % Attempt to get property values, using the error handler for any errors that occur
                    propValues = cellfun(@(propName) parentValue.(propName), propNames, ...
                                             'UniformOutput', false, ...
                                             'ErrorHandler', errorHandlerFunc);

                    expandableFlags = cellfun(expandabilityCheckFunc, propValues);
                end
            else
                % Struct and object arrays need not be further expanded
                expandableFlags = zeros(1, length(this.getFields(parentValue)));
            end
        end
    end

   methods(Hidden)
        % Helper function to check if a value is expandable.
        % "value" can currently be a struct, table, timetable, or object handle.
        function isExpandable = checkExpandability(this, value)
            % g3338544: When checking if a struct is expandable, we use the "struct2cell"
            % instead of "fieldnames" function. "fieldnames" is an expensive function,
            % and we do not need any field names; all we're checking is that the struct
            % has at least one field.
            isExpandable = isstruct(value) && ~isempty(struct2cell(value)) ... % Is a struct with fields,
                        || (istabular(value) && ~isempty(value));              % or is a non-empty table

            % g3346726: For the time being, we do not support expanding tall tables.
            % We plan on supporting this in the future, but it will require significant work.
            isExpandable = isExpandable && ~isa(value, 'tall');

            if this.SUPPORT_EXPANDING_OBJECT_PROPERTIES && ...
                    ~isExpandable && isobject(value) & ~isempty(value)
                % Objects that satisfy the following criteria are expandable:
                % - Are non-primitive. This means they are not, for example, uint64 or uint8.
                % - Are not classes that we explicitly do not want expanded, such as "embedded.fi".
                % - Have at least one property.
                isNonPrimitiveObject = internal.matlab.datatoolsservices.FormatDataUtils.checkNonPrimitiveObject(value);
                isNonExpandableObject = any(strcmp(class(value), this.NON_EXPANDABLE_OBJECTS));

                isExpandable = isNonPrimitiveObject && ~isNonExpandableObject && ~isempty(properties(value));
            end
        end

        % Base class implementation returns false by default.  Args are this,
        % rowId, and fieldName.
        function isExpanded = isRowExpanded(~, ~, ~)
            isExpanded = false;
        end
   end
end

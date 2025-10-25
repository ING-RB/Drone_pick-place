classdef RemoteObjectArrayViewModel < ...
        internal.matlab.variableeditor.peer.RemoteArrayViewModel & ...
        internal.matlab.variableeditor.ObjectArrayViewModel
    % RemoteObjectArrayViewModel Remote Model Object Array View Model.  This
    % extends the ObjectArrayViewModel to provide the functionality for
    % display of object arrays and NxM struct arrays in Matlab Online.

    % Copyright 2015-2024 The MathWorks, Inc.

    methods
        function this = RemoteObjectArrayViewModel(document, variable, viewID, userContext)
            % Creates a new RemoteObjectArrayViewModel for the given
            % variable, using the specified document.
            if nargin < 4
                userContext = '';
                if nargin < 3
                    viewID = '';
                end
            end
            this@internal.matlab.variableeditor.ObjectArrayViewModel(...
                variable.DataModel, viewID, userContext);
            this = this@internal.matlab.variableeditor.peer.RemoteArrayViewModel(...
                document, variable, 'viewID', viewID, 'CornerSpacerTitle', getString(message(...
                'MATLAB:codetools:variableeditor:Properties')), ...
                'ShowAllProperties', variable.DataModel.ShowAllProperties, ...
                'TotalPropertyCount', height(properties(variable.DataModel.Data)), ...
                'VisiblePropertyCount', height(variable.DataModel.getProperties()));
        end

        % Override RemoteArrayViewModel's information
        function initTableModelInformation (this)
            this.setTableModelProperties(...
                'ShowColumnHeaderLabels', true,...
                'ShowColumnHeaderNumbers', false,...
                'ShowHeaderIcons',true,...
                'EditableColumnHeaders', false, ...
                'EditableColumnHeaderLabels', false);
        end

        % Returns a string row vector with column headers for the range
        % startCol:endCol
        function headerNames = getHeadersForRange(this, startCol, endCol)
            headerNames = string(this.DataModel.getProperties());
            headerNames = headerNames(startCol:endCol)';
        end


        function [renderedData, renderedDims] = getRenderedData(this, ...
                startRow, endRow, startColumn, endColumn)
            % Returns the rendered data for the specified range of
            % startRow/endRow, startColumn/endColumn.
            data = this.getRenderedData@internal.matlab.variableeditor.ObjectArrayViewModel(...
                startRow, endRow, startColumn, endColumn);
            rawData = this.DataModel.Data;
            dataAsCell = this.DataModel.DataAsCell;
            props = this.DataModel.getProperties();
            [renderedData, renderedDims] = internal.matlab.variableeditor.peer.RemoteObjectArrayViewModel.getJSONForExpandedObjectArrayData( ...
                data, props, rawData, dataAsCell, this.MetaData, startRow, startColumn, this.DataModel.Name);
        end

        function status = handlePropertySetFromClient(this, ~, ed)
            if ~isvalid(this) || ~isfield(ed, 'data')
                return;
            end

            % Handles properties being set.  ed is the Event Data, and it
            % is expected that ed.EventData.key contains the property which
            % is being set.  Returns a status: empty string for success,
            % an error message otherwise.
            status = '';
            if isfield(ed,'srcLang') && strcmp('CPP',ed.srcLang)
                return;
            end

            % TODO: make getSelection and setSelection part of a server
            % side selection plugin for views that do not want selection
            % turned on.
            if strcmpi(ed.data.key, 'ShowAllProperties')
                this.DataModel.ShowAllProperties = ed.data.newValue;
            end

            this.handlePropertySetFromClient@internal.matlab.variableeditor.peer.RemoteArrayViewModel([], ed);
        end

        function secondaryStatus = updateSecondaryStatus(this)
            [secondaryStatus,totalPropertyCount,visiblePropertyCount] = this.getSecondaryStatus();

            % Set properties for updated summary bar
            this.setProperty('TotalPropertyCount', totalPropertyCount);
            this.setProperty('VisiblePropertyCount', visiblePropertyCount);
            this.setProperty('secondaryStatus', secondaryStatus);
        end
    end

    methods(Access='protected')
        % Replaces data with empty value replacement or formats incoming
        % data such that we can eval the data to be set for the row/column
        % in the correct workspace.
        function [data, origValue, evalResult, isStr] = processIncomingDataSet(this, row, column, data)
            if isempty(data)
                % Cannot have empty data in object arrays
                error(message('MATLAB:codetools:variableeditor:EmptyValueInvalid'));
            end
            [data, origValue, evalResult, isStr] = this.processIncomingDataSet@internal.matlab.variableeditor.peer.RemoteArrayViewModel(row, column, data);
        end

        function isEqual = isEqualDataBeingSet(~, newValue, currentValue, ~, ~)
            isEqual = isequaln(newValue, currentValue);
        end
    end

    methods(Static)
        function [renderedData, renderedDims] = getJSONForObjectArrayData(...
                data, startRow, startColumn, variableName, useCellArrayIndexing)
            if nargin < 4
                variableName = '';
            end

            % Populate the renderedData cell array with the data determined
            % from the ObjectArrayViewModel, as well as the row/column
            % numbers
            renderedData = cell(size(data));

            sRow = max(1,startRow);
            sCol = max(startColumn,1);
            for col = 1:size(renderedData,2)
                for row = 1:size(renderedData,1)
                    jsonData =  struct('value',data{row,col},...
                        'isMetaData', true);

                    % Setup the editor value (something like
                    % varName(row,column))
                    if ~isempty(variableName)
                        if useCellArrayIndexing
                            jsonData.editorValue = sprintf('%s{%d,%d}', ...
                                variableName, row + sRow - 1, ...
                                col + sCol - 1);
                        else
                            jsonData.editorValue = sprintf('%s(%d,%d)', ...
                                variableName, row + sRow - 1, ...
                                col + sCol - 1);
                        end
                    end
                    renderedData{row,col} = jsonencode(jsonData);
                end
            end
            renderedDims = size(renderedData);
        end

        function [renderedData, renderedDims] = getJSONForExpandedObjectArrayData(data, props, rawData, rawDataAsCell, MetaData, startRow, startColumn, variableName, DisplayFormatProvider)
            arguments
                data;
                props;
                rawData;
                rawDataAsCell cell;
                MetaData;
                startRow double;
                startColumn double;
                variableName = '';
                DisplayFormatProvider internal.matlab.variableeditor.NumberDisplayFormatProvider = internal.matlab.variableeditor.NumberDisplayFormatProvider
            end
            isMetaData = MetaData;
            sRow = max(1,startRow);
            sCol = max(startColumn,1);
            colStrsIndex = 1;
            renderedData = cell(size(data));

            for col = 1:size(renderedData,2)
                rowStrsIndex = 1;
                for row = 1:size(renderedData,1)
                    editorValue = '';
                    rawDataAtIndex = rawDataAsCell{row+sRow-1,col+sCol-1};
                    if (isMetaData(row,col) || ...
                            ischar(rawDataAtIndex) && size(rawDataAtIndex,1) > 1) && ~isempty(variableName)
                        editorValue = sprintf('%s(%d).%s', variableName, row+sRow-1,char(props(col+sCol-1)));
                    end

                    % only numerics need to have an editvalue which is in
                    % long format
                    % other data types have their edit value same as data
                    % value

                    isNumericCell = isnumeric(rawDataAtIndex);
                    % For numeric objects, convert to numeric before
                    % formatting (g2044078)
                    if isNumericCell && isobject(rawDataAtIndex)
                        rawDataAtIndex = internal.matlab.datatoolsservices.FormatDataUtils.getNumericValue(rawDataAtIndex);
                        rawDataAsCell{row+sRow-1,col+sCol-1} = rawDataAtIndex;
                    end

                    if ~isMetaData(row,col)
                        longData = internal.matlab.datatoolsservices.FormatDataUtils.getDisplayEditValue(rawDataAtIndex, DisplayFormatProvider.LongNumDisplayFormat);
                    else
                        % This does not take the toJSON path. Adding this logic in formatDataUtils affects other
                        % scalar structs as well.  % Escape \ and " , Handle \n
                        % and \t for strings alone
                        data{row,col} = internal.matlab.variableeditor.peer.PeerUtils.formatGetJSONforCell(rawDataAtIndex, data{row,col});
                        longData = data{row,col};
                    end

                    jsonData =  struct('value',data{row,col},...
                        'editValue',longData,...
                        'isMetaData',isMetaData(row,col));
                    if ~isempty(editorValue)
                        jsonData.editorValue = editorValue;
                    end
                    jsonData = internal.matlab.variableeditor.peer.PeerUtils.toJSON(true, jsonData);

                    renderedData{row,col} = jsonData;
                    rowStrsIndex = rowStrsIndex + 1;
                end
                colStrsIndex = colStrsIndex + 1;
            end
            renderedDims = size(renderedData);
        end


        function b = usesCellArrayIndexing(rawData)
            b = isa(rawData, 'collection');
        end

    end

    methods(Access = protected)

        function classType = getClassType(this, row, column, sz)
            arguments
                this
                row
                column
                sz = this.getTabularDataSize()
            end
            classType = '';
            if row > sz(1) || column > sz(2)
                % Infinite grid, no exisitng class type.
                return;
            end
            % Called to return the class type
            classType = eval(sprintf('class(this.DataModel.DataAsCell{%d,%d})', ...
                row, column));
        end
       

        function isValid = validateInput(this, value, row, column)
            % Called to validate the input for the specified row/column.
            % Attempt to make the assignment to a copy of the data. If it errors, the error will
            % be displayed as an error message in the Variable Editor.
            % Do not modify DataModel's Data, this will prevent detection
            % of a DataChange and notifying the view.
            currData = this.DataModel.Data;
            props = this.DataModel.getProperties();
            if ~isempty(props)
                propertyName = props{column};
                propVal = currData(row).(propertyName);
                % If categorical, perform correct assignment
                % for validation
                if (iscategorical(propVal))
                    currData(row).(propertyName)(1) = value;
                else
                    currData(row).(propertyName) = value;
                end                
                isValid = true;
            else
                isValid = false;
            end
        end

        function classStr = getClassName(~)
            classStr = 'internal.matlab.variableeditor.peer.RemoteObjectArrayViewModel';
        end

        function updateCellModelInformation(this, startRow, endRow, startCol, endCol, fullRows, fullColumns)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startRow (1,1) double {mustBeNonnegative}
                endRow (1,1) double {mustBeNonnegative}
                startCol (1,1) double {mustBeNonnegative}
                endCol (1,1) double {mustBeNonnegative}
                fullRows (1,:) double = startRow:endRow
                fullColumns (1,:) double = startCol:endCol
            end
            this.CellModelChangeListener.Enabled = false;
            currentData = this.DataModel.getData;
            objectArrayProperties = this.DataModel.getProperties();    
            for col=endCol:-1:startCol
                classData = {currentData.(objectArrayProperties{col})}';
                for row = endRow:-1:startRow                  
                    cellData = classData{row};
                    if any(strcmp(class(cellData), ["categorical","nominal","ordinal"]))
                        cats = categories(cellData);
                        % Limit the number of categories displayed, otherwise we hit OutOfMemory errors
                        cats(internal.matlab.datatoolsservices.FormatDataUtils.MAX_CATEGORICALS:end) = [];
                        this.setCellModelProperties(row, col,...                    
                                'categories', cats, 'isProtected', isprotected(cellData), 'RemoveQuotedStrings', true);
                    end
                end
            end
            this.CellModelChangeListener.Enabled = true;
            this.updateCellModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel(startRow, endRow, startCol, endCol, fullRows, fullColumns);
            this.updateColumnModelInformation(startCol, endCol);
        end

        function updateColumnModelInformation(this, startCol, endCol, fullColumns)
            arguments
                this (1,1) internal.matlab.datatoolsservices.messageservice.PubSubTabularDataStore
                startCol (1,1) double {mustBeNonnegative}
                endCol (1,1) double {mustBeNonnegative}
                fullColumns (1,:) double = startCol:endCol
            end
            this.ColumnModelChangeListener.Enabled = false;
            currentData = this.DataModel.getData;
            objectArrayProperties = this.DataModel.getProperties();
            metaClassInfo = metaclass(currentData);

            endCol = min(endCol, length(objectArrayProperties));

            this.updateSecondaryStatus();

            if ~isempty(objectArrayProperties)
                for col=endCol:-1:startCol
                    try
                        classData = {currentData.(objectArrayProperties{col})}';
                        classStr = unique(string(cellfun(@class, classData, 'UniformOutput', false)));
                        if length(classStr) > 1
                            columnClassName = "mixed";
                        else
                            columnClassName = this.getLookupClassName(class(this), classData, classStr);
                        end
                    catch
                        columnClassName = "mixed";
                    end
                    propIndex = find(strcmp({metaClassInfo.PropertyList.Name}', objectArrayProperties{col}));
                    propInfo = metaClassInfo.PropertyList(propIndex);
                    try
                        % Sometimes metaclassInfo might not have the properties in objectArrayProperties, mark
                        % accessSpecifier as unknown and the column will be non-editable.
                        if isempty(propInfo)
                            accessSpecifiers = '';
                        elseif iscell(propInfo.SetAccess)
                            accessSpecifiers = cellfun(@(x)x.Name, propInfo.SetAccess, 'UniformOutput', false);                           
                        else
                            accessSpecifiers = propInfo.SetAccess;
                        end
                        isPubliclyAccessible = any(strcmp(accessSpecifiers, 'public'));
                        isEditable = isPubliclyAccessible && ~any(strcmp(columnClassName, ["duration", "calendarDuration"]));
        
                        this.setColumnModelProperties(col, 'class', columnClassName, 'icon', columnClassName, 'HeaderName', objectArrayProperties{col}, 'editable', isEditable);
                    catch e 
                        internal.matlab.datatoolsservices.logDebug("variableeditor::remoteobjectearrayviewmodel::updateColumnModelInformation::error", e.message);
                    end
                end
            end

            this.ColumnModelChangeListener.Enabled = true;
            this.updateColumnModelInformation@internal.matlab.variableeditor.peer.RemoteArrayViewModel(startCol, endCol);
        end
    end
end
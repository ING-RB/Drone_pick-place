classdef RemoteWorkspaceViewModel < internal.matlab.variableeditor.peer.RemoteStructureViewModel & internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase
    % RemoteWorkspaceViewModel is the view model for workspacebrowser    
    
    % Copyright 2013-2024 The MathWorks, Inc.

    properties(Access = private)
        % Save the evaluated value when changing the data.  This is used in
        % places where superclasses may try to do an evalin 'caller',
        % expecting caller to be the user's workspace.
        evaluatedSetValue;
    end

    events
        PropertyChange;
    end

    methods
        function this = RemoteWorkspaceViewModel(document, variable, viewID, UserContext)
            if nargin < 4
                UserContext = '';
            end
            this@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase(variable);
            this = this@internal.matlab.variableeditor.peer.RemoteStructureViewModel(document, variable, ...
                            viewID, UserContext);
            % Sorting based on the Name column by default
            fieldCol = this.findFieldByHeaderName('Name');
            this.SortedColumnInfo = struct('ColumnIndex', fieldCol.ColumnIndex, 'SortOrder', true);
        end

        function sendVariableEvent(this, type, Variables)
            this.sendVariableEvent@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase(type, Variables);
        end

        function subVarName = getSubVarName(this, name, varName)
            subVarName = this.getSubVarName@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase(name, varName);
        end

        % Handles event dispatches from client.
        % ed eventData with payload (struct('type','','originator','',srcLang:'CPP','data',[],target,[<ViewModel>])
        function varargout = handleEventFromClient(this, ~, ed)
            this.logDebug('PeerArrayView','handlePeerEvents','');
            varargout = {};
            if isfield(ed.data,'type')
                switch ed.data.type
                    case 'VariablesAdded'
                    case 'VariablesRemoved'
                    case 'VariablesChanged'
                    otherwise
                        this.handleEventFromClient@internal.matlab.variableeditor.peer.RemoteStructureViewModel([], ed);
                end
            end
        end

        function [renderedData, renderedDims] = getRenderedData(this, ...
                startRow, endRow, startColumn, endColumn)
            % Override the getRenderedData function from PeerStructureViewModel
            % to handle objects which are displayed in the Workspace Browser.
            % These may be represented by an internal object, the
            % ObjectValueSummaryObject.  For these, use the stored information
            % it contains.
            renderedData = [];
            renderedDims = [];
           
            if (startColumn > 0 && endColumn > 0)
                [data, ~, classValues, fieldColumns] = this.getRenderedData@internal.matlab.variableeditor.StructureViewModel(...
                    startRow, endRow, startColumn, endColumn);
                % Are any of the variables being displayed by the WSB an
                % ObjectValueSummary object?  If so, use the information stored in
                % these for display.
                dmData = this.DataModel.getData;  

                if ~isempty(fields(dmData))
                    fn = fieldnames(dmData);
                    cellData = struct2cell(dmData);
                    if ~isempty(this.SortedIndices)
                        cellData = cellData(this.SortedIndices);
                        fn = fn(this.SortedIndices);
                    end

                    % Check if it is a ObjectValueSummary.  Assume true if it errors
                    % (which can happen when an object is open in the editor,
                    % and an error is inserted)
                    valueSummary = cellfun(@(x) isa(x, 'internal.matlab.workspace.ObjectValueSummary'), cellData, ...
                        "ErrorHandler", @(varargin) true);
                    valueSummary = valueSummary(startRow:min(endRow, length(valueSummary)));
                    if any(valueSummary)
                        [data, classValues] = this.getUpdatedDataForObjects(data, dmData, ...
                            fn, fieldColumns, classValues, valueSummary, startRow);
                    end
                end
                [renderedData, ~] = this.renderData(data, classValues, fieldColumns, {}, ...
                    startRow, endRow, startColumn, endColumn);           
                
                % For editing use case, we might just get a cell range,
                % send back renderedData of correct dimensions for
                % getFormattedData call, the DataModel later updates necessary
                % data.
                renderedData = renderedData(:, startColumn:endColumn);
                renderedDims = size(renderedData);
            end
        end

        function [data, classValues] = getUpdatedDataForObjects(this, data, dmData, fn, fieldColumns, classValues, ...
                valueSummary, startRow)
            % valueSummaryIdx is w.r.t sorted indices.
            valueSummaryIdx = find(valueSummary)' + (startRow - 1);
            % Get a list of visible column indices(from fieldColumns passed
            % in) and just assign summary values to these fields alone.
            fieldColNames = cellfun(@(x) internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModel.getHeaderName(x), fieldColumns);
            [~, visibleIdx] = ismember(fieldnames(this.VisibleObjValuesMap), fieldColNames);
            % Replace the data for the ObjectValueSummary objects with the
            % stored value, size and class.
            for idx = valueSummaryIdx
                dataIdx = idx - startRow + 1;
                dataName = fn{idx};
                objValueSummary = dmData.(dataName);
                isTabular = ismember(objValueSummary.DisplayClass, ["table", "timetable"]);
                for i=1:length(visibleIdx)
                    if visibleIdx(i)
                        col = fieldColumns{visibleIdx(i)};
                        colName = col.HeaderName;
                        objValue = objValueSummary.(this.VisibleObjValuesMap.(colName));
                        % for displayValue assignments, use () to assign
                        % directly to the index of the cell array.
                        if strcmp(colName, "Value")
                            if isTabular  
                                [isFiltered, rowCount] = internal.matlab.datatoolsservices.FormatDataUtils.getSetFilteredVariableInfo(dataName);
                                if isFiltered
                                    objValue{1} = [objValue{1} ' | ' getString(message('MATLAB:codetools:variableeditor:FilteredVariableSummary', rowCount))];
                                end
                            end

                            try
                                data(dataIdx, visibleIdx(i)) = objValue;
                            catch
                                % Handle cases where it errors (which can happen
                                % when an object is open in the editor, and an
                                % error is inserted)
                                data{dataIdx, visibleIdx(i)} = internal.matlab.datatoolsservices.FormatDataUtils.ERR_DISPLAYING_VALUE;
                            end
                        else
                            data{dataIdx, visibleIdx(i)} = objValue;
                        end
                    end
                end
                % Update classvalues with the formatted class in order to
                % update the icons correctly for ObjectValueSummary
                % types.Class value may/may not be visible.
                classValues{dataIdx} = objValueSummary.DisplayClass;          
            end
        end       
    end

    methods(Access = protected)
     
        % Override from RemoteStructViewModel to provide
        % WorkspaceFieldSettings as WorkspaceBrowser has a separate
        % settings file.
        function fieldSettings = getFieldSettingsInstance(~)
            fieldSettings = internal.matlab.desktop_workspacebrowser.FieldColumns.WorkspaceFieldSettings.getInstance;           
        end

        % WSB does not have any server side plugins, do not initialize
        % widgetRegistry to save on startup.
        function initializePlugins(this)
            this.initializePlugins@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase();
        end
        
        function initFieldColumns(this, userContext)
            this.initFieldColumns@internal.matlab.variableeditor.peer.RemoteStructureViewModel(userContext);
            fieldColumn = this.findFieldByHeaderName("Name");
            fieldColumn.setHeaderTagName(getString(message('MATLAB:codetools:variableeditor:Name')));
            
            % Initialize Bytes Column to be added in additional to the
            % struct columns
            % TODO: Insert bytes col at position4, wire in to
            % insertFieldAt() API that will be added with column
            % re-ordering.
            settingsController = this.getSettingsController(userContext);
            visibleCols = internal.matlab.variableeditor.StructureViewModel.getVisibleColumns(settingsController);
            if ismember(visibleCols, 'Bytes')
                this.createBytesCol(settingsController);
            end       
        end

        function col = evaluateFieldCol(this, settingsController, colName)
            if strcmp(colName,'Bytes')
                col = this.createBytesCol(settingsController);
            else
                col = this.evaluateFieldCol@internal.matlab.variableeditor.peer.RemoteStructureViewModel(settingsController, colName);
            end
        end

        function bytesCol = createBytesCol(this, settingsController)
            bytesCol = this.createBytesCol@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase(settingsController);
        end

        function result = evaluateClientSetData(this, ~, ~, ~)
            % Return the previously evaluated value, because evalin
            % 'caller' from the superclasses won't be correct
            result = this.evaluatedSetValue;
        end
        
        function classStr = getClassName(~)
            classStr = 'internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModel';
        end
        function renameCmd = handleFieldNameEdit(this, data, row, column)
            renameCmd = this.handleFieldNameEdit@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase(data, row, column);
        end
        function msg =  getErrorOnInvalidRename(this, rawData)
            msg = this.getErrorOnInvalidRename@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase(rawData);
        end
        function b = didValuesChange(this, eValue, currentValue, row, column)            
            b = this.updateIfObjectValueSummary(currentValue, row, column);
            if ~b
                % If no update was necessary, proceed with the standard value change check
                b = this.didValuesChange@internal.matlab.variableeditor.peer.RemoteStructureViewModel(eValue, currentValue);
            end
        end
        
        % If rawData is of type ObjectValueSummary, return the DisplayValue
        % directly, else fall back for FormatDataUtil's formatting.
        function formattedData = getFormattedData(this, rawData)
            if (isa(rawData, 'internal.matlab.workspace.ObjectValueSummary'))
                formattedData = rawData.DisplayValue;
            else
                formattedData = this.getFormattedData@internal.matlab.variableeditor.peer.RemoteStructureViewModel(rawData);
            end            
        end

        function underlyingType = getUnderlyingDataType(this, rawData)
            underlyingType = [];
            if (isa(rawData, 'internal.matlab.workspace.ObjectValueSummary'))
                if ~isempty(rawData.DisplayType)
                    underlyingType = rawData.DisplayType;
                end
            else
                underlyingType = this.getUnderlyingDataType@internal.matlab.variableeditor.peer.RemoteStructureViewModel(rawData);
            end
        end

        function [affectsViewport, affectsOtherRanges] = rangeAffectsViewport(this, startRow, endRow, ~, ~)
            % Same as super method but ignores columns (which don't really change
            % independently in the WSB)
            vstartr = this.ViewportStartRow;
            vendr = this.ViewportEndRow;
            r1 = [vstartr 1 vendr-vstartr+1 1];
            r2 = [startRow 1 endRow-startRow+1 1];

            if startRow == endRow 
                otherRowsIntersect = ...
                    (startRow < vstartr  || ...
                    startRow > vendr);
            else
                otherRowsIntersect = ...
                    (startRow < vstartr  || ...
                    startRow > vendr) || ...
                    (endRow < vstartr  || ...
                    endRow > vendr);
            end

            affectsViewport = rectint(r1, r2) > 0;
            affectsOtherRanges = otherRowsIntersect;
        end
    end

    methods(Static)
        function hName = getHeaderName(fcol)
            hName = getHeaderName@internal.matlab.desktop_workspacebrowser.RemoteWorkspaceViewModelBase(fcol);
        end
    end

    methods(Access = {?matlab.unittest.TestCase })
        % For testing purposes only, this is used to reset the
        % sortedIndices
        function resetSortedIndices(this)
            this.SortedIndices = [];
        end

    end
end

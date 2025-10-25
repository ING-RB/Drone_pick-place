classdef DateTimeDurationFormatAction< internal.matlab.variableeditor.VEAction ...
        & internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase
    %DateTimeDurationFormatAction that sets the format for any
    %   DateTime/Duration Variables. Reacts to any plugin updates on the
    %   client side, also provides preview to users

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        ActionName = 'DateTimeDurationFormatAction';
        DUR_COLUMN_CLASS = 'duration';
        DUR_ARRAY_DATA_TYPE = 'DurationArray';
        DT_COLUMN_CLASS = 'datetime';
        DT_ARRAY_DATA_TYPE = 'DatetimeArray';
    end

    properties
        DurFormatPreviewCache;
        DTFormatPreviewCache;
        dataChangedOnPreview = false;
    end

    methods
        function this = DateTimeDurationFormatAction(props, manager)
            props.ID = internal.matlab.variableeditor.Actions.dataTypes.DateTimeDurationFormatAction.ActionName;
            props.Enabled = true;
            this@internal.matlab.variableeditor.Actions.dataTypes.DataTypesActionBase(manager);
            this@internal.matlab.variableeditor.VEAction(props, manager);
            this.DurFormatPreviewCache = containers.Map();
            this.DTFormatPreviewCache = containers.Map();
        end
    end

    methods(Access='protected')
        function [cmd, executionCmd] = generateCommandForAction(this, focusedDoc, actionData)
            % generateCommandForAction  generates command to be published
            % for setting Duration format on a variable of type 'duration'
            if isfield(actionData, 'actionInfo')
                evtType = actionData.actionInfo.evtType;
                actionInfo = struct('evtType', evtType);
                classType = actionData.actionInfo.classType;
                actionInfo.varType = classType;
                if ~isequal(evtType, 'previewend')
                    dtDurFormat = actionData.actionInfo.optionFormat;
                    actionInfo.dtDurFormat = dtDurFormat;
                end
            end
            cmd = '';
            executionCmd = '';


            % Cache the defualt format
            if isequal(actionInfo.evtType, 'previewstart')
                this.cacheFormat(focusedDoc, actionInfo);
            end

            switch actionInfo.varType
                case this.DT_COLUMN_CLASS
                    cmd = this.generateCmdForDateTimeVar(focusedDoc, actionInfo);

                case this.DUR_COLUMN_CLASS
                    cmd = this.generateCmdForDurationVar(focusedDoc, actionInfo);
            end

            % clear the cache when preview ends or commit evt is sent
            if isequal(actionInfo.evtType, 'previewend') || isequal(actionInfo.evtType, 'commitVariable')
                this.clearCache(focusedDoc.Name, actionInfo.varType);
            end

        end

        function cmd = generateCmdForDurationVar (this, focusedDoc, actionInfo)
            % generateCmdForDurationVar handles variables of duration type
            focusedView = focusedDoc.ViewModel;
            data = focusedView.DataModel.Data;
            cmd = [];
            evtType = actionInfo.evtType;

            % Duration variables can be present in Tables, timetables,
            % arrays, etc. Using switch to handle all cases
            switch focusedView.DataModel.Type
                case this.DUR_ARRAY_DATA_TYPE
                    % Duration Array
                    cmd = this.helperForDateTimeDurationArrayCmdGeneration(focusedDoc, actionInfo);

                    % Emit dataChanged event on DataModel when previewing
                    this.emitDataChangedEvent(focusedDoc, evtType);

                otherwise
                    % Tabular data like timetables, tables, that contain
                    % duration variables
                    selection = this.getSelectionIndices(focusedDoc);
                    selectedColIndices = this.getSelectedColumnIndices(selection);


                    for colId = selectedColIndices
                        if isequal(this.DUR_COLUMN_CLASS, class(data.(colId)))
                            cmdForDurCol = this.helperForDateTimeDurationTabularCmdGeneration(focusedDoc, actionInfo, colId);
                            % When preview is called no command is returned and cmd
                            % will be ''
                            if ~isequal(cmdForDurCol, '')
                                cmd = [cmd cmdForDurCol];
                            end
                        end
                    end

                    % Emit dataChanged event on DataModel when previewing
                    this.emitDataChangedEvent(focusedDoc, evtType, min(selectedColIndices), max(selectedColIndices));

            end
        end


        function cmd = generateCmdForDateTimeVar (this, focusedDoc, actionInfo)
            % generateCmdForDateTimeVar handles variables of type DateTime
            focusedView = focusedDoc.ViewModel;
            data = focusedView.DataModel.Data;
            cmd = [];
            evtType = actionInfo.evtType;
            % This is to bypass the fix for g2900618 which breaks when new
            % format is set
            focusedView.isDateTimeFormatActionUpdate = true;
            % Datetime variables can be present in Tables, timetables,
            % arrays, etc. Using switch to handle all cases
            switch focusedView.DataModel.Type
                case this.DT_ARRAY_DATA_TYPE
                    % DateTime Arrays
                    cmd = this.helperForDateTimeDurationArrayCmdGeneration(focusedDoc, actionInfo);

                    % Emit dataChanged event on DataModel when previewing
                    this.emitDataChangedEvent(focusedDoc, evtType);

                otherwise
                    % Tabular data like timetables, tables, that contain
                    % datetime variables
                    selection = this.getSelectionIndices(focusedDoc);
                    selectedColIndices = this.getSelectedColumnIndices(selection);


                    for colId = selectedColIndices
                        if isequal(this.DT_COLUMN_CLASS, class(data.(colId)))
                            cmdForDTCol = this.helperForDateTimeDurationTabularCmdGeneration(focusedDoc, actionInfo, colId);
                            % When preview is called no command is returned and cmd
                            % will be ''
                            if ~isequal(cmdForDTCol, '')
                                cmd = [cmd cmdForDTCol];
                            end
                        end
                    end

                    % Emit dataChanged event on DataModel when previewing
                    this.emitDataChangedEvent(focusedDoc, evtType, min(selectedColIndices), max(selectedColIndices));

            end
        end

        function cmd = helperForDateTimeDurationArrayCmdGeneration (this, focusedDoc, actionInfo)
            % helperForDateTimeDurationArrayCmdGeneration  Helper function
            % that generated the command to be published for DateTime and
            % Duration Arrays
            arguments
                this
                focusedDoc
                actionInfo
            end

            cmd = '';
            evtType = actionInfo.evtType;
            focusedView = focusedDoc.ViewModel;
            variableName = focusedDoc.Name;
            dataType = actionInfo.varType;

            try

                switch evtType
                    case 'commitVariable'
                        newFormat = actionInfo.dtDurFormat;
                        curFormat = focusedDoc.DataModel.Data.Format;


                        % Error handling, execute command to make sure
                        % there are no errors before code publishing. If
                        % there are, then they need to be sent to client to
                        % be printed on a notification dialog

                        duplicateData = focusedDoc.DataModel.Data;

                        % Eval on duplicateData variable to flush out
                        % errors
                        cmdToEval = sprintf('duplicateData.Format = "%s";', newFormat);
                        eval(cmdToEval);

                        % Command for code generation
                        cmd = sprintf('%s.Format = "%s";', variableName, newFormat);
                        this.dataChangedOnPreview = false;

                    case 'previewstart'
                        newFormat =actionInfo.dtDurFormat;
                        focusedView.DataModel.Data.Format = newFormat;
                        if ~this.dataChangedOnPreview
                            this.dataChangedOnPreview = true;
                        end

                    case 'previewend'
                        cachedFormat = this.getCachedFormat(variableName, dataType);
                        if ~isempty(cachedFormat)
                            focusedView.DataModel.Data.Format = cachedFormat;

                            if ~this.dataChangedOnPreview
                                this.dataChangedOnPreview = true;
                            end
                        end
                end
            catch e
                % send error to the client to be displayed in a error
                % dialog
                if (isequal(e.identifier, ...
                        'MATLAB:datetime:UnsupportedSymbol') || ...
                        isequal(e.identifier, ...
                        'MATLAB:duration:UnrecognizedFormat'))
                    focusedView.dispatchEventToClient(struct( ...
                        'type', 'actionError', ...
                        'status', 'error', ...
                        'message', e.message, ...
                        'source', 'server'));
                else
                    rethrow(e);
                end
            end

        end

        function cmd = helperForDateTimeDurationTabularCmdGeneration (this, focusedDoc, actionInfo, columnIndex)
            % helperForDurationTabular Helper function that generated
            % the command to be published for Duration variables in Tables
            % and Timetables
            arguments
                this
                focusedDoc
                actionInfo
                columnIndex
            end
            cmd = '';
            evtType = actionInfo.evtType;
            focusedView = focusedDoc.ViewModel;
            variableName = focusedDoc.Name;
            dataType = actionInfo.varType;
            isTimeTable = strcmp(focusedView.getDataType(), "timetable");

            try
                switch evtType
                    case 'commitVariable'
                        newFormat = actionInfo.dtDurFormat;
                        [columnName, actualColumnIndex] = focusedView.getHeaderInfoFromIndex(columnIndex);

                        % Error handling, execute command to make sure
                        % there are no errors before code publishing. If
                        % there are, then they need to be sent to client to
                        % be printed on a notification dialog
                        cmdToEval = sprintf('focusedDoc.DataModel.Data.(%s).Format = "%s";', string(actualColumnIndex), newFormat);
                        eval(cmdToEval);

                        % we can use actualColumnIndex if the column name
                        % has new line character
                        if ~isspace(columnName)
                            cmd = sprintf('%s.%s.Format = "%s";', variableName, columnName, newFormat);
                        elseif numel(splitlines(columnName)) > 1
                            % If the columnName has a newline character
                            % then fallback to using columnNumber instead
                            % of ColumnName

                            % Need to adjust column index because the Time
                            % column is represented as a normal column in
                            % the data model, but is actually not a column
                            % variable
                            adjustedColumnIndex = actualColumnIndex;
                            if isTimeTable
                                adjustedColumnIndex = adjustedColumnIndex - 1;
                            end
                            if adjustedColumnIndex > 1 || ~isTimeTable
                                cmd = sprintf('%s.(%s).Format = "%s";', variableName, string(adjustedColumnIndex), newFormat);
                            else
                                % This is a change to the RowTimes
                                cmd = sprintf('%s.Properties.RowTimes.Format = "%s";', variableName, newFormat);
                            end
                        else
                            cmd = sprintf('%s.("%s").Format = "%s";', variableName, columnName, newFormat);
                        end
                        this.dataChangedOnPreview = false;

                    case 'previewstart'
                        newFormat = actionInfo.dtDurFormat;
                        focusedView.DataModel.Data.(columnIndex).Format = newFormat;
                        if ~this.dataChangedOnPreview
                            this.dataChangedOnPreview = true;
                        end

                    case 'previewend'
                        % Fetch the DurationFormat cached initially when
                        % previewing
                        cachedFormats = this.getCachedFormat(variableName, dataType);
                        if ~isempty(cachedFormats)
                            cachedFormatForColumn = cachedFormats(columnIndex);

                            focusedView.DataModel.Data.(columnIndex).Format = cachedFormatForColumn;

                            if ~this.dataChangedOnPreview
                                this.dataChangedOnPreview = true;
                            end
                        end
                end

            catch e
                % send error to the client to be displayed in a error
                % dialog
                if (isequal(e.identifier, ...
                        'MATLAB:datetime:UnsupportedSymbol') || ...
                        isequal(e.identifier, ...
                        'MATLAB:duration:UnrecognizedFormat'))
                    focusedView.dispatchEventToClient(struct( ...
                        'type', 'actionError', ...
                        'status', 'error', ...
                        'message', e.message, ...
                        'source', 'server'));
                else
                    rethrow(e);
                end
            end

        end

        function cacheFormat (this, focusedDoc, actionInfo)
            % cacheFormat  caches the current DateTime or Duration Format
            % before the format is updated, this will be used and cleaned
            % up when preview ends
            focusedView = focusedDoc.ViewModel;
            varType = actionInfo.varType;
            if ~this.DurFormatPreviewCache.isKey(focusedDoc.Name) && ~this.DTFormatPreviewCache.isKey(focusedDoc.Name)
                if isequal(focusedView.DataModel.Type, this.DUR_ARRAY_DATA_TYPE)
                    % Array datatypes caching
                    this.DurFormatPreviewCache(focusedDoc.Name) = focusedView.getFormat();
                elseif isequal(focusedView.DataModel.Type, this.DT_ARRAY_DATA_TYPE)
                    this.DTFormatPreviewCache(focusedDoc.Name) = focusedView.getFormat();
                else
                    % Tabular datatypes: tables, timetables
                    if isequal(varType, this.DUR_COLUMN_CLASS)
                        % If its duration variable in tabular datatypes
                        this.DurFormatPreviewCache(focusedDoc.Name) = focusedView.DurFormats;
                    elseif isequal(varType, this.DT_COLUMN_CLASS)
                        % If its datetime variable in tabular datatypes
                        this.DTFormatPreviewCache(focusedDoc.Name) = focusedView.DTFormats;
                    end
                end
            end
        end

        function cachedFormat = getCachedFormat (this, variableName, dataType)
            % Fetch the cached format when previewing
            cachedFormat = [];
            switch dataType
                case this.DT_COLUMN_CLASS
                    if this.DTFormatPreviewCache.isKey(variableName)
                        cachedFormat = this.DTFormatPreviewCache(variableName);
                    end

                case this.DUR_COLUMN_CLASS
                    if this.DurFormatPreviewCache.isKey(variableName)
                        cachedFormat = this.DurFormatPreviewCache(variableName);
                    end
            end
        end

        function clearCache (this, variableName, dataType)
            % clear cache format for a specified variable
            switch dataType
                case this.DT_COLUMN_CLASS
                    if(this.DTFormatPreviewCache.isKey(variableName))
                        this.DTFormatPreviewCache.remove(variableName);
                    end

                case this.DUR_COLUMN_CLASS
                    if(this.DurFormatPreviewCache.isKey(variableName))
                        this.DurFormatPreviewCache.remove(variableName);
                    end
            end
        end

        function emitDataChangedEvent(this, focusedDoc, evtType, startColumn, endColumn)
            % emitDataChangedEvent  emit the dataChanged event on dataModel
            % whenever its Data is updated for supporting preview
            arguments
                this
                focusedDoc
                evtType
                startColumn = [];
                endColumn = [];
            end
            if ~isempty(focusedDoc) && (contains(evtType, 'preview') && this.dataChangedOnPreview)
                viewModel = focusedDoc.ViewModel;
                eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;
                size = viewModel.getTabularDataSize;
                eventdata.StartRow = 1;
                eventdata.StartColumn = 1;
                eventdata.EndRow = size(1);
                eventdata.EndColumn = size(2);

                if ~isempty(startColumn) && ~isempty(endColumn)
                    eventdata.StartColumn = startColumn;
                    eventdata.EndColumn = endColumn;
                end
                viewModel.DataModel.notify('DataChange', eventdata);
                % Set dataChanged flag to false so that no events are
                % emitted redundantly
                this.dataChangedOnPreview = false;

            end
        end

        function s = getSelectionIndices(~, focusedDoc)
            % getSelectionIndices local utility so that timetable's time
            % column does not get offset
            focusedView = focusedDoc.ViewModel;
            s = focusedView.getSelection();
            if istabular(focusedView.DataModel.Data)
                if ~isempty(s{2}) && ~isempty(focusedView.getGroupedColumnCounts)
                    s{2} = internal.matlab.variableeditor.TableViewModel.getColumnsFromSelectionString(s{2}, focusedView.getGroupedColumnCounts);
                end
            end
        end

        function colIndices = getSelectedColumnIndices(~, selection)
            % getSelectedColumnIndices  helper function to get flattened
            % list of selected column indices in a table
            colIndices = [];
            cSelection = selection{2};
            for i = 1:height(cSelection)
                colIndices = unique([colIndices, cSelection(i,1):cSelection(i,2)]);
            end
        end

    end

end
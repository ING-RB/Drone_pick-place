% This class is unsupported and might change or be removed without notice in a
% future version.

% This class is a mixin for row times for the TabularImportViewModel.

% Copyright 2022 The MathWorks, Inc.

classdef RowTimesViewMixin < handle
    properties
        RowTimesDialog;
        RowNames string = strings(0);
    end

    methods
        function closeRowTimesDialog(this)
            if ~isempty(this) && isvalid(this) && ~isempty(this.RowTimesDialog) && isvalid(this.RowTimesDialog)
                delete(this.RowTimesDialog.ConfigureRowTimesUIFigure);
            end
        end

        function configureRowTimes(this, x, y)
            if internal.matlab.importtool.server.ImportUtils.dialogIsOpen(this.RowTimesDialog, "ConfigureRowTimesUIFigure")
                figure(this.RowTimesDialog.ConfigureRowTimesUIFigure);
            else
                this.RowTimesDialog = internal.matlab.importtool.rowTimesDialog(...
                    "OkButtonFcn", @this.updateRowTimes, ...
                    "CancelButtonFcn", @this.rowTimesCancelled, ...
                    "Position", [x, y]);
            end
        end

        function updateRowTimes(this, values)
            % Updates the row times related properties
            if values.TimeStep
                % Time Step has a value and units
                rowTimesType = "timestep";
                rowTimesValue = values.TimeStepValue;
                rowTimesUnits = values.TimeStepUnits;
            else
                % Sample Rate has a value (frequency per second), no units
                rowTimesType = "samplerate";
                rowTimesValue = values.SampleRateValue;
                rowTimesUnits = "";
            end

            % Save the start time duration or datetime value
            if values.StartTimeDuration
                rowTimesStart = string(values.DurationValue);
                rowTimesStartType = "duration";
            else
                rowTimesStart = string(values.DatetimeValue);
                rowTimesStartType = "datetime";
            end

            this.setTableModelProperties(...
                "RowTimesType", rowTimesType, ...
                "RowTimesValue", rowTimesValue, ...
                "RowTimesUnits", rowTimesUnits, ...
                "RowTimesStart", rowTimesStart, ...
                "RowTimesStartType", rowTimesStartType);

            % Update the row times which are displayed in the table
            this.updateRowTimesInTable();
        end

        function rowTimesCancelled(~)
        end

        function r = getRowTimesProperties(this)
            % Returns the current row times properties, in a struct
            r = struct;
            tmp = this.TableModelProperties; %#ok<*MCNPN>
            r.rowTimesType = tmp.RowTimesType;
            r.rowTimesUnits = tmp.RowTimesUnits;
            r.rowTimesValue = tmp.RowTimesValue;
            r.rowTimesStart = tmp.RowTimesStart;
            r.rowTimesStartType = tmp.RowTimesStartType;
            r.rowTimesColumn = tmp.RowTimesColumn;
        end

        function r = getDefaultRowTimesProperties(~)
            % Returns the default row times values, in a struct
            import internal.matlab.importtool.server.output.TimeTableOutputType;
            r = struct;
            r.rowTimesType = TimeTableOutputType.DEFAULT_TYPE;
            r.rowTimesUnits = TimeTableOutputType.DEFAULT_UNITS;
            r.rowTimesValue = TimeTableOutputType.DEFAULT_VALUE;
            r.rowTimesStart = TimeTableOutputType.DEFAULT_START;
            r.rowTimesStartType = TimeTableOutputType.DEFAULT_START_TYPE;
            r.rowTimesColumn = "";
        end

        function rowNames = getRowNamesForTimeStepSampleRate(this, r)
            fmt = [];

            % Determine the step value for either timestep or sampleRate
            % (which is just a number of times per second).
            if r.rowTimesType == "timestep"
                % For timestep, the units is the function name, like
                % "seconds", or "calweeks".  Call it with the step
                % value.
                fcn = str2func(r.rowTimesUnits);
                step = fcn(r.rowTimesValue);
            else
                % For samplerate, the value is the number of times per
                % second.
                sampleRate = r.rowTimesValue;
                step = seconds(1/sampleRate);

                % Try to give the row times a format which matches the
                % actual output
                if r.rowTimesStartType == "duration" && ...
                        r.rowTimesStart == duration(0,0,0)
                    fmt = "s";
                end
            end

            % Determine the row times start - either datetime or
            % duration
            if r.rowTimesStartType == "duration"
                r.rowTimesStart = duration(r.rowTimesStart);
            else
                r.rowTimesStart = datetime(r.rowTimesStart);
            end

            % Create a vector of either datetime or duration, starting
            % at the appropriate start value, with the right step, and
            % ending so that we have enough for all rows in the table
            dims = this.DataModel.getSheetDimensions();
            d = r.rowTimesStart:step:r.rowTimesStart+dims(2)*step;
            if ~isempty(fmt)
                d.Format = fmt;
            end
            rowNames = string(d);
        end

        function updateRowTimesInTable(this)
            % Always clear out the row names to begin with
            dims = this.DataModel.getSheetDimensions();
            this.RowNames = strings(dims(2), 1);

            if strcmp(this.getTableModelProperty("OutputVariableType"), "timetable")
                % Only update row times for timetable output

                r = this.getRowTimesProperties();
                if strlength(r.rowTimesType) == 0
                    % No RowTimesType is specified, which may mean the user
                    % switched to timetable, but didn't change any options.  Use
                    % the TimeTableOutputType to get the appropriate settings --
                    % using a datetime or duration column if there is one,
                    % otherwise using the default time step.
                    ttOutput = internal.matlab.importtool.server.output.TimeTableOutputType;
                    ttOutput.initOutputArgsFromProperties(this);
                    r.rowTimesType = ttOutput.RowTimesType;
                    r.rowTimesColumn = ttOutput.RowTimesColumn;
                    if strlength(r.rowTimesType) == 0
                        r = this.getDefaultRowTimesProperties();
                    end
                end

                % Get the rows in the current selection -- row times are only
                % shown on rows which are selected.  This is especially crucial
                % for times which we are generating -- the times only apply to
                % the selection.  (For example, if you had a time step of 1
                % hour, and had 3 rows but only row 1 and 3 selected, you would
                % expect no time for row 2, and only 1 hour difference between
                % rows 1 and 3.
                excelSelection = this.getTableModelProperty("excelSelection");
                if ~isempty(excelSelection)
                    [rows, ~] = internal.matlab.importtool.server.ImportUtils.getRowsColsFromExcel(excelSelection);

                    if any(strcmp(r.rowTimesType, ["timestep", "samplerate"]))
                        rowNames = this.getRowNamesForTimeStepSampleRate(r);

                        % For each row selected (handling discontinuous selections),
                        % set the RowName for each incremental time value
                        timeIndex = 1;
                        numIntervals = size(rows, 1);
                        for interval = 1:numIntervals

                            % Copy the computed row times to the RowTimes property,
                            % for each interval in the selection.  The timeIndex
                            % increments for each interval.
                            intervalStartRow = rows(interval, 1);
                            intervalEndRow = rows(interval, 2);
                            this.RowNames(intervalStartRow:intervalEndRow) = ...
                                rowNames(timeIndex:timeIndex + (intervalEndRow - intervalStartRow));
                            timeIndex = timeIndex + (intervalEndRow - intervalStartRow) + 1;
                        end
                    end
                end
            end

            try
                endRow = length(this.RowNames);
                changeEventData = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                changeEventData.Row = 1:endRow;
                this.notify('RowMetaDataChanged', changeEventData);
            catch
            end
        end

        function idx = getRowTimesColumnIndex(this)
            % Returns the column number of the row times column, if it is set.
            currRowTimesCol = this.getTableModelProperty("RowTimesColumn");
            idx = this.getColumnIndexFromName(currRowTimesCol);
        end

        function idx = getColumnIndexFromName(this, colName)
            % Returns the column index, given a column name
            idx = [];
            if ~isempty(colName)
                varNames = string(this.getCurrentColumnVarNames());
                idx = find(varNames == colName);
            end
        end

        function name = getColumnNameFromIndex(this, colIdx)
            % Returns the column name from an index
            varNames = this.getCurrentColumnVarNames();
            name = string(varNames(colIdx));
        end

        function varNames = getDTDurationColNames(this)
            timeColOptions = arrayfun(@(x) x == "datetime" || x == "duration", ...
                this.ColumnClasses);
            varNames = this.getCurrentColumnVarNames;
            varNames = varNames(timeColOptions);
        end

        function reevaluateTimetableSettings(this)
            outputType = this.getTableModelProperty("OutputVariableType");
            if strcmp(outputType, "timetable")
                rowTimesColIdx = this.getRowTimesColumnIndex();
                rowTimesName = this.getTableModelProperty("RowTimesColumn");
                dtDurationColNames = this.getDTDurationColNames;
                if strlength(rowTimesName) > 0
                    % The row times column is set, see if it is still a
                    % datetime or duration
                    if isempty(rowTimesColIdx) || ...
                            rowTimesColIdx > length(this.ColumnClasses) || ...
                            ~any(this.ColumnClasses(rowTimesColIdx) == ["datetime", "duration"])
                        if ~isempty(dtDurationColNames)
                            this.setTableModelProperties(...
                                "RowTimesType", "column", ...
                                "RowTimesColumn", dtDurationColNames(1));
                        else
                            % Change to default row times
                            rowTimes = this.getDefaultRowTimesProperties();
                            this.setTableModelProperties(...
                                "RowTimesType", rowTimes.rowTimesType, ...
                                "RowTimesValue", rowTimes.rowTimesValue, ...
                                "RowTimesUnits", rowTimes.rowTimesUnits, ...
                                "RowTimesStart", rowTimes.rowTimesStart, ...
                                "RowTimesStartType", rowTimes.rowTimesStartType, ...
                                "RowTimesColumn", rowTimes.rowTimesColumn);
                        end
                    end
                end

                this.setTableModelProperty("DTDurationColumns", ...
                    dtDurationColNames);
                this.updateRowTimesInTable();
            end
        end
    end
    methods(Access = protected)
        function resetRowTimesColumnInfo(this, currRowTimesCol)
            dtDurationCols = this.getDTDurationColNames();                                                                                        this.setTableModelProperty("DTDurationColumns", ...
                dtDurationCols);

            resetToDefault = false;
            if ~any(cellfun(@(x) strcmp(x, currRowTimesCol), dtDurationCols))
                % The current row times column is no longer a datetime or
                % duration column, so reset everything
                if this.getTableModelProperty("RowTimesType") == "column" && ...
                        ~isempty(dtDurationCols)
                    this.setTableModelProperty("RowTimesColumn", ...
                        dtDurationCols(1));
                else
                    resetToDefault = true;
                end
            elseif isempty(dtDurationCols) && strlength(currRowTimesCol) > 0
                resetToDefault = true;
            end

            if resetToDefault
                this.setTableModelProperty("RowTimesColumn", "");
                this.setTableModelProperty("RowTimesType", "timestep");
                this.updateRowTimesInTable();

                try
                    changeEventData = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                    dims = this.DataModel.getSheetDimensions();
                    changeEventData.Row = 1:dims(2);
                    this.notify('RowMetaDataChanged', changeEventData);
                catch e
                    disp (e);
                end
            end
        end
    end
end
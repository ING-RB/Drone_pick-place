classdef FilterFigure < handle
%   Copyright 2018-2024 The MathWorks, Inc.

    properties
        Workspace;
        VariableName;
        HistCounts;
    end

    properties(Dependent)
        HistCountsTimeFormat;
    end

    properties(Access='private')
        Data;
        OrigData;
        SortedData;
        FigureMouseUpListener;
    end

    properties(Access={?internal.matlab.variableeditor.Actions.Filtering.FilterFigure, ...
            ?matlab.mock.TestCase})
        ID;
    end

    methods
        function this = FilterFigure(workspace, varName)
            this.ID = char(java.util.UUID.randomUUID);
            this.Workspace = workspace;
            this.VariableName = varName;
            this.setupData();

            this.FigureMouseUpListener = message.subscribe(['/DesktopDataTools/FigureView/' this.ID '/figuremouseup'], @(msg)this.updateNumericRanges(msg), 'enableDebugger', ~internal.matlab.datatoolsservices.WorkspaceListener.getIgnoreBreakpoints);
        end

        function value = get.HistCountsTimeFormat(this)
            value = this.OrigData(1).Format; % Default value

            if ~isempty(this.HistCounts)
                if this.dataIsTimeData()
                    value = this.HistCounts(1).Format;
                end
            end
        end

        function figD = getFigureData(this)
            figD = struct('figID', this.ID, 'varName', this.VariableName);
        end

        function isTimeData = dataIsTimeData(this)
            isTimeData = isdatetime(this.OrigData) || isduration(this.OrigData);
        end

        function setupData(this)
            origTable = this.Workspace.OriginalTable;
            this.OrigData = origTable.(this.VariableName);

            % g1788994: Inf or -Inf values in Columns need to be ignored
            % while creating the filtering visualizations
            if ~this.dataIsTimeData()
                this.Data = this.OrigData(this.OrigData > -Inf & this.OrigData < Inf);
            else
                this.Data = this.OrigData;

                % Sort the data so we may accurately send information to
                % the client Filter Figure regarding slider handle positions.
                this.SortedData = sort(this.Data);
                % Also omit NaNs. NaNs may prevent the server from sending
                % correct slider handle positions to the client.
                this.SortedData = rmmissing(this.SortedData);
            end

            if isempty(this.Data)
                this.Data = this.OrigData;
            end
        end

        function [lowerBound, upperBound] = getNumericFilterBounds(this)
            [lowerBound, upperBound] = this.Workspace.getNumericFilterBounds(this.VariableName);
        end

        function [minFilterHandleValue, maxFilterHandleValue] = getMinMaxFilterHandleValues(this)
            % 1. Grab this filter figure's min and max values.
            % 2. If min and max are numerical, simply return them.
            % 3. If min and max are datetime/duration, snap to the nearest bin value.

            [minFilterHandleValue, maxFilterHandleValue] = this.getNumericFilterBounds();

            valsEmpty = isempty(minFilterHandleValue) && isempty(maxFilterHandleValue);
            if ~valsEmpty && this.dataIsTimeData()
                % The frontend cannot use datetimes/durations in calculations, and as
                % such, cannot correctly position handles after the user updates
                % filter values using the filter textboxes.
                %
                % To work around this, we take the newly-set min/max values
                % and grab the closest edge to those values. When the frontend
                % filter figure initializes, it will position the filter handles
                % to the closest edges we found.
                bins = this.HistCounts;
                [~, minIndex] = min(abs(bins - minFilterHandleValue));
                [~, maxIndex] = min(abs(bins - maxFilterHandleValue));

                minFilterHandleValue = string(bins(minIndex));
                maxFilterHandleValue = string(bins(maxIndex));
            end

            % g3128793: The server, who displays the filter handles, expects to
            % receive these values as strings. As such, we stringify the values here.
            if ~valsEmpty
                minFilterHandleValue = string(minFilterHandleValue);
                maxFilterHandleValue = string(maxFilterHandleValue);
            end
        end

        function updateNumericRanges(this, msg)
            if isdatetime(this.SortedData)
                msg.min = strtrim(msg.min);
                msg.max = strtrim(msg.max);

                format = this.Data.Format;
                if isfield(msg, 'useSelectionRangeFormat') && msg.useSelectionRangeFormat
                    % Determine if the incoming message from the filter
                    % text boxes includes a time component.
                    try
                        datetime(msg.min, 'InputFormat', 'M/d/y HH:mm:ss');
                        inputFormat = 'M/d/y HH:mm:ss';
                    catch
                        inputFormat = 'M/d/y';
                    end
                else
                    inputFormat = this.HistCountsTimeFormat;
                end

                % Generate the datetime using the message min and max strings.
                try
                    xMin = datetime(msg.min, 'InputFormat', inputFormat, 'Format', format);
                    xMax = datetime(msg.max, 'InputFormat', inputFormat, 'Format', format);
                catch
                    % If the machine's locale causes an error when converting
                    % the string to a datetime, default to using the English locale.
                    xMin = datetime(msg.min, 'InputFormat', inputFormat, 'Format', format, 'Locale', 'en_US');
                    xMax = datetime(msg.max, 'InputFormat', inputFormat, 'Format', format, 'Locale', 'en_US');
                end
            elseif isduration(this.SortedData)
                format = this.Data.Format;
                isUnitDuration = any(strcmp(format, ["s" "m" "h" "d" "y"]));

                if ~isUnitDuration
                    xMin = duration(msg.min, 'Format', format);
                    xMax = duration(msg.max, 'Format', format);
                else
                    % g3152826: If the duration string is of a time unit
                    % (e.g., seconds, minutes), we cannot directly transform
                    % it into a duration using `duration(stringQuantity)`.
                    % We must use a slightly different approach to do this conversion.
                    xMin = internal.matlab.variableeditor.Actions.Filtering.convertStringUnitDurationToDuration(msg.min, format);
                    xMax = internal.matlab.variableeditor.Actions.Filtering.convertStringUnitDurationToDuration(msg.max, format);
                end
            else
                xMin = str2double(msg.min);
                xMax = str2double(msg.max);
            end

            this.Workspace.setNumericRange(this.VariableName, xMin, xMax);

            % Finally, if the client expects a reply, we must supply
            % positions to the client so that the slider handles will
            % get moved into the right places.
            if (msg.getFilterHandleValueReply == 1)
                [minVal, maxVal] = this.getMinMaxFilterHandleValues();
                this.sendFigureUpdate([minVal, maxVal]);
            end
        end

        function sendFigureUpdate(this, reply)
            message.publish(['/DesktopDataTools/FigureView/' this.ID '/figureupdate'], reply);
        end

        function delete(this)
            if ~isempty(this.FigureMouseUpListener)
                message.unsubscribe(this.FigureMouseUpListener);
            end
        end
    end
end

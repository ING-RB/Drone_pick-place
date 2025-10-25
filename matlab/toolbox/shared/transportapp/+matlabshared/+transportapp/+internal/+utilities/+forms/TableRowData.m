classdef TableRowData
    %TABLEROWDATA class contains row information data for the Communication
    %Log table.

    % Copyright 2021-2022 The MathWorks, Inc.

    properties
        % The type of action being performed.
        Action string {matlabshared.transportapp.internal.utilities.TransportDataValidator.validateAction(Action)} = string.empty

        % The actual data written/read
        Data

        % The size of the data written/read
        Size (1, 2) double

        % The associated data type selected for the read/write operations.
        DataType string {matlabshared.transportapp.internal.utilities.TransportDataValidator.validateDataType(DataType)} = string.empty

        % The time (in string) when the transport action was performed.
        Time (1, 1) string

        % Flag to show whether there was an error associated with the
        % transport action, and to show an "ERROR" text for the
        % corresponding table row.
        ErrorRow (1, 1) logical = false
    end

    properties (Constant)
        TimeTableHeader = {'Action', 'Data', 'Size', 'DataType'}

        RealDataTypes = ["single", "double"]

        AllProperties = [...
            string(matlabshared.transportapp.internal.utilities.forms.TableRowData.TimeTableHeader), ...
            "Time"...
            ]

        % If the data to be displayed in the table is a 1xn numeric value
        RowDelimiter = string(char(160))

        % If the data to be displayed in the table is a nx1 numeric value
        ColumnDelimiter = ";" + matlabshared.transportapp.internal.utilities.forms.TableRowData.RowDelimiter

        % For really large data values, the maximum data length that shows
        % up when users hover over the row data. If the data exceeds
        % MaxDataLength, the table display chops off the remaining data and
        % replaces it with "..."
        MaxDataLength = 1000

        % The value for the "Size" field of the table for an error
        % operation.
        ErrorSize = string(message("transportapp:appspace:propertyinspector:ErrorDataType").getString());

    end

    methods (Static)
        function tableVal = convertFormToTable(formVal)
            % Convert the arrays of TableRowData values (formVal) into a table
            % format to be displayed in the Communication Log table.

            arguments
                formVal (1, :) matlabshared.transportapp.internal.utilities.forms.TableRowData
            end

            import matlabshared.transportapp.internal.utilities.forms.TableRowData
            action = string.empty;
            data = string.empty;
            size = string.empty;
            datatype = string.empty;
            time = string.empty;
            for form = formVal
                if form.ErrorRow
                    size(end+1) = TableRowData.ErrorSize;
                else
                    size(end+1) = compose("%d x %d", form.Size);
                end
                action(end+1) = form.Action;
                data(end+1) = TableRowData.parseData(form.Data);
                datatype(end+1) = form.DataType;
                time(end+1) = form.Time;
            end

            % Create the final table.
            tableVal = table(action(:), data(:), size(:), datatype(:), time(:), ...
                'VariableNames', cellstr(TableRowData.AllProperties));
        end

        function timeTableData = convertFormToTimeTable(formVal)
            % Convert the arrays of TableRowData values (formVal) into a
            % timetable to be exported.

            arguments
                formVal (1, :) matlabshared.transportapp.internal.utilities.forms.TableRowData
            end
            import matlabshared.transportapp.internal.utilities.forms.TableRowData
            timeArr = datetime.empty;
            dataArr = cell.empty;
            actionArr = string.empty;
            sizeArr = cell.empty;
            dataTypeArr = string.empty;
            for form = formVal
                timeArr(end+1) = datetime(form.Time);
                actionArr(end+1) = form.Action;
                dataArr{end+1} = form.Data;
                sizeArr{end+1} = form.Size;
                dataTypeArr(end+1) = form.DataType;
            end

            % Create the final time table.
            timeTableData = timetable(timeArr(:), actionArr(:), dataArr(:), sizeArr(:), dataTypeArr(:), ...
                'VariableNames', TableRowData.TimeTableHeader);
        end

        function newForm = convertToBinary(formVal)
            % When the "Display" dropdown in the Toolstrip Communication
            % Log section is changed to "Binary", convert the data for the
            % TableRowData array "formVal" into a binary format. The converted
            % formVal is returned back as a new TableRowData array "newForm".

            arguments
                formVal (1, :)
            end
            import matlabshared.transportapp.internal.utilities.forms.TableRowData
            newForm = formVal.empty;
            for form = formVal
 
                % If the table row data is an invalid row for conversion to
                % binary, move on to the next row data.
                if TableRowData.invalidRowForConversion(form)
                    newForm(end+1) = form; %#ok<*AGROW>
                    continue
                end

                try
                    data = form.Data;
                    if ischar(data) || isstring(data)
                        data = uint16(char(data));
                    end
                catch
                    % If an error happens in the conversion to binary, keep
                    % the data display for the current row as is.
                    continue
                end
                form.Data = data;
                newForm(end+1) = form;
            end
        end

        function newForm = convertToASCII(formVal)
            % When the "Display" dropdown in the Toolstrip Communication
            % Log section is changed to "ASCII", convert the original data
            % for the TableRowData array "formVal" into an ASCII format. The
            % converted formVal is returned back as a new TableRowData array
            % "newForm".

            arguments
                formVal (1, :)
            end
            import matlabshared.transportapp.internal.utilities.forms.TableRowData
            newForm = formVal.empty;
            for form = formVal

                % If the table row data is an invalid row for conversion to
                % ASCII or is a single or double value, move on to the next
                % row data.
                if TableRowData.invalidRowForConversion(form) || ...
                        TableRowData.isRealDataType(form)
                    newForm(end+1) = form; %#ok<*AGROW>
                    continue
                end

                try
                    data = form.Data;

                    % Apply the ASCII conversion only when the original
                    % data is a numeric positive integer
                    if isnumeric(data) && ...
                            all(floor(data) == data) && ...
                            all(data >= 0)
                        data = string(char(data));
                    end
                catch
                    % If an error happens in the conversion to ASCII, keep
                    % the data display for the current row as is.
                    continue
                end
                form.Data = data;
                newForm(end+1) = form;
            end
        end

        function newForm = convertToHex(formVal)
            % When the "Display" dropdown in the Toolstrip Communication
            % Log section is changed to "Hexadecimal", convert the data for
            % the TableRowData array "formVal" into a hex format. The
            % converted formVal is returned back as a new TableRowData array
            % "newForm".

            arguments
                formVal (1, :)
            end
            import matlabshared.transportapp.internal.utilities.forms.TableRowData
            newForm = formVal.empty;
            for form = formVal

                % If the table row data is an invalid row for conversion to
                % hex or is a single or double value, move on to the next
                % row data.
                if TableRowData.invalidRowForConversion(form) || ...
                        TableRowData.isRealDataType(form)
                    newForm(end+1) = form; %#ok<*AGROW>
                    continue
                end

                try
                    data = form.Data;

                    if ischar(data) || isstring(data)
                        data = double(char(data));
                    end

                    isColumnData = iscolumn(data);

                    if isnumeric(data) && ...
                            all(floor(data) == data)
                        data = string(dec2hex(data));

                        if ~isColumnData
                            data = data';
                        end
                    end
                catch
                    % If an error happens in the conversion to hex, keep
                    % the data display for the current row as is.
                    continue
                end
                form.Data = data;
                newForm(end+1) = form;
            end
        end
    end

    methods (Static)
        function newData = parseData(dataVal)
            % Convert the data into a string to be displayed in the
            % Communication Log table.

            import matlabshared.transportapp.internal.utilities.forms.TableRowData

            newData = string(dataVal);

            if isnumeric(dataVal)
                nanIdx = find(isnan(dataVal));
                infIdx = find(isinf(dataVal));
                newData(nanIdx) = "NaN"; %#ok<*FNDSB> 
                newData(infIdx) = "Inf";
            end

            % For data of nx1 size, add the column delimiter. Else use the
            % row delimiter.
            if ~isscalar(newData) && iscolumn(newData)
                newData = strjoin(newData', TableRowData.ColumnDelimiter);
            else
                newData = strjoin(newData, TableRowData.RowDelimiter);
            end

            newData = replace(newData, " ", TableRowData.RowDelimiter);

            % If the total string becomes more than MaxDataLength, display
            % the remaining data as "..."
            if strlength(newData) > TableRowData.MaxDataLength
                newData = newData.extractBefore(TableRowData.MaxDataLength);
                newData = newData + "...";
            end
        end

        function flag = invalidRowForConversion(form)
            % If the row is an error row, or the data field is empty, the
            % table form is not a valid row for converting to
            % binary/ASCII/hex.

            data = form.Data;
            flag = form.ErrorRow || isempty(data) || (isstring(data) && all(data == ""));
        end

        function flag = isRealDataType(form)
            % If the table row's data type value is "single" or "double",
            % return true, else return false.

            flag = any(form.DataType == ...
                matlabshared.transportapp.internal.utilities.forms.TableRowData.RealDataTypes);
        end
    end
end

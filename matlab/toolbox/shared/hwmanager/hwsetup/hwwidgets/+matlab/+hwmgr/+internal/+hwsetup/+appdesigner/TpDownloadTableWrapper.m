classdef TpDownloadTableWrapper < matlab.hwmgr.internal.hwsetup.appdesigner.HTMLTableWrapper
    % TPDOWNLOADTABLEWRAPPER- wrapper specific for TpDownloadTable. It
    % provides all api's exposed by HTMLTableWrapper and makes changes
    % required for TpDownloadTable. For example: adding column names.

    % Copyright 2020-2022 The MathWorks, Inc.

    properties (Access = 'public')
        % TpDownloadTable Required Values
        Name = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.TpDownloadTableName;
        Version = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.TpDownloadTableVersion;
        Details = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.TpDownloadTableDetails;
        TextAlignment = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.TpDownloadTextAlignment;
        ColumnName = {'Name', 'Version', 'Details'};
        Border = 'on';
    end

    methods
        function obj = TpDownloadTableWrapper(varargin)
            obj@matlab.hwmgr.internal.hwsetup.appdesigner.HTMLTableWrapper(varargin{:});
        end

        function formatTextForDisplay(obj)
            % FORMATTEXTFORDISPLAY uses TpDownloadTable properties to construct
            % the HTML table for display

            % Find the maximum number of rows
            rowNum = max([numel(obj.Name), numel(obj.Version), numel(obj.Details)]);
            % Create temp cell arrays for storing the Name, Version and
            % Details
            tempVersion = cell(rowNum,1);
            tempNames = cell(rowNum,1);
            tempDetails = cell(rowNum,1);
            % Insert the data in the temp arrays
            tempVersion(1:numel(obj.Version)) = obj.Version;
            tempNames(1:numel(obj.Name)) = obj.Name;
            tempDetails(1:numel(obj.Details)) = obj.Details;
            % Maximum number of columns is 3 - Name, Version and Details
            tempColNames = cell(3,1);
            tempColNames(1:numel(obj.ColumnName)) = obj.ColumnName;

            % Does table have the First Column
            hasFirstCol = ~all(cellfun(@isempty,obj.Name));
            % Does table have the Second Column
            hasSecondCol = ~all(cellfun(@isempty,obj.Version));
            % Does table have the Third Column
            hasThirdCol = ~all(cellfun(@isempty,obj.Details));
            % Does table have the Column Headers
            hasColumnHeader = ~all(cellfun(@isempty,obj.ColumnName));
            % Create Cell array of hasColumn names.
            isColNameReq = {hasFirstCol, hasSecondCol, hasThirdCol};
            % Create the data for Table Headers
            tableHeaders = '';
            if hasColumnHeader
                numCols = max([hasFirstCol+hasSecondCol+hasThirdCol, numel(obj.ColumnName)]);
                tableHeaders = [tableHeaders '<tr>'];
                for i = 1:numCols
                    if isColNameReq{i}
                        tableHeaders = [ tableHeaders '<th>' tempColNames{i} '</th>']; %#ok<*AGROW>
                    end
                end
                tableHeaders = [tableHeaders '</tr>'];
            end
            tablecontents = '';

            % Create the data for rows
            for i = 1:rowNum
                tablecontents = [tablecontents '<tr>'];
                if hasFirstCol
                    tablecontents = [tablecontents '<td>' tempNames{i} '</td>'];
                end
                if hasSecondCol
                    tablecontents = [tablecontents '<td>' tempVersion{i} '</td>'];
                end
                if hasThirdCol
                    tablecontents = [tablecontents '<td>' tempDetails{i} '</td>'];
                end
                tablecontents = [tablecontents '</tr>'];
            end

            % Tags for defining the table
            styleSheet = obj.getStylesheet();
            if strcmp(obj.Border, 'off')
                styleSheet = strrep(styleSheet, obj.BorderStyle, '');
            end
            beginDoc = ['<html>' styleSheet '<body><table>'];
            endDoc = ['</table>' obj.getScript() '</body></html>'];

            % Construct the HTML table
            formattedString = [ beginDoc tableHeaders tablecontents endDoc ];

            obj.HTMLComponent.HTMLSource = char(join(formattedString));
        end
    end

    %----------------------------------------------------------------------
    % setter methods
    %----------------------------------------------------------------------
    methods
        function set.Name(obj, names)
            obj.Name = names;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end

        function set.Version(obj, versions)
            obj.Version = versions;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end

        function set.Details(obj, details)
            obj.Details = details;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end

        function set.ColumnName(obj, names)
            obj.ColumnName = names;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end

        function set.Border(obj, value)
            obj.Border = value;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end

        function set.TextAlignment(obj, value)
            obj.TextAlignment = value;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end
    end
end
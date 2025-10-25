classdef TpDownloadAndInstallStatusTableWrapper < matlab.hwmgr.internal.hwsetup.appdesigner.HTMLTableWrapper
    % TPDOWNLOADANDINSTALLSTATUSTABLEWRAPPER- wrapper specific for TpDownloadAndInstallStatusTableWrapper.
    % It provides all api's exposed by HTMLTableWrapper and makes changes
    % required for TpDownloadAndInstallStatusTable.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Access = 'public')
        Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass,...
                matlab.hwmgr.internal.hwsetup.StatusIcon.Fail,...
                matlab.hwmgr.internal.hwsetup.StatusIcon.Warn};
        Name = {'Tool 1', 'Tool 2', 'Tool 3'};      
        LicenseURL = {'www.mathworks.com', 'www.mathworks.com', 'www.mathworks.com'};
        ColumnHeader = {'Status', 'Name', 'License'};
    end

    methods
        function obj = TpDownloadAndInstallStatusTableWrapper(varargin)
            % constructor
            obj@matlab.hwmgr.internal.hwsetup.appdesigner.HTMLTableWrapper(varargin{:})
        end

        function formatTextForDisplay(obj)
            %FORMATTEXTFORDISPLAY - Formats the widgets properties
            %into an html document structure for display

            beginDoc = ['<html>' obj.getStylesheet() '<body><table>'];
            tableHeaders = ['<tr><th>' obj.ColumnHeader{1}...
                '</th><th>'  obj.ColumnHeader{2} '</th><th>'...
                obj.ColumnHeader{3} '</th></tr>'];
            rowNum = max([numel(obj.Name), numel(obj.Status), numel(obj.LicenseURL)]);
            htmlTable = cell(rowNum, 1);
            [htmlTable{:}] = deal('');
            iName = cell(rowNum, 1);
            iStatus = cell(rowNum, 1);
            iLicenseURL = cell(rowNum, 1);

            iStatus(1:numel(obj.Status)) = obj.Status;
            iName(1:numel(obj.Name)) = obj.Name;
            if ~isempty(obj.LicenseURL)
                iLicenseURL(1:numel(obj.LicenseURL)) = cellfun(...
                    @(x)['<a href = "' x '">'  obj.ColumnHeader{3}  '</a>'], obj.LicenseURL,...
                    'UniformOutput', false);
            end

            for i = 1:rowNum
                if isa(iStatus{i}, 'matlab.hwmgr.internal.hwsetup.StatusIcon')
                    icon = iStatus{i}.dispIcon();
                else
                    icon = iStatus{i};
                end
                htmlTable{i} = ['<tr><td style=""width:20px; word-wrap: break-word"">' icon...
                    '</td><td style=""width:250px; word-wrap: break-word"">' iName{i}...
                    '</td><td style=""width:120px; word-wrap: break-word"">' iLicenseURL{i} '</td></tr>'];
            end
            if isempty(htmlTable)
                tablecontents = '';
            else
                htmlTable = cellfun(@join, htmlTable, 'UniformOutput', false);
                tablecontents = strjoin(htmlTable);
            end
            endDoc = ['</table>' obj.getScript() '</body></html>'];

            % Construct the HTML table
            formattedString = [ beginDoc tableHeaders tablecontents endDoc ];

            obj.HTMLComponent.HTMLSource = formattedString;
        end
    end

    %----------------------------------------------------------------------
    % setter methods
    %----------------------------------------------------------------------
    methods
        function set.Status(obj, value)
            obj.Status = value;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end

        function set.Name(obj, value)
            obj.Name = value;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end

        function set.LicenseURL(obj, value)
            obj.LicenseURL = value;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end

        function set.ColumnHeader(obj, value)
            obj.ColumnHeader = value;
            obj.formatTextForDisplay();
            drawnow(); % refresh to display the new values
        end
    end
end
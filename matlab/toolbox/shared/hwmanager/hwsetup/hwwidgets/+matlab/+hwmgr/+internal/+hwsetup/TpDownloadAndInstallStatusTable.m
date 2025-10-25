classdef TpDownloadAndInstallStatusTable < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.EnableWidget
    % TPDOWNLOADANDINSTALLSTATUSTABLE Provides a table that has 3 columns and 'n'
    % number of rows.
    % The first column displays the status icon - busy, pass, fail etc.
    % The second column is a string describing the name of the 3P tool,
    % The third column is the License link
    %
    % TPDOWNLOADANDINSTALLSTATUSTABLE Widget Properties
    % Position        -Location and Size [left bottom width height]
    %                    (When the table is displayed the height and the
    %                    width of the table are adjusted based on the table
    %                    dimensions)
    % Visible         -Widget visibility specified as 'on' or 'off'
    % Status          -Cell array of icon enum
    %                    matlab.hwmgr.internal.hwsetup.StatusIcon
    % Name           -Cell array of strings/character vectors that
    %                    specify the name of the 3P tool
    % LicenseURL     -Link to the license for the 3P tool
    % ColumnHeader   - Cell Array of strings/character vectors that
    %                   specifies the column headings
    %
    % EXAMPLE:
    % w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    % t = matlab.hwmgr.internal.hwsetup.TpDownloadAndInstallStatusTable.getInstance(w);
    % t.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass, ...
    %               matlab.hwmgr.internal.hwsetup.StatusIcon.Fail}
    % t.Name = {'Tool 1', 'Tool 2'};
    % t.ColumnHeader = {'Status', 'Name', 'License'};
    % t.show();
    %
    % See also matlab.hwmgr.internal.hwsetup.Table

    % Copyright 2021-2022 The MathWorks, Inc.

    properties(Access = public, Dependent)
        % Status - Cell array where each element is a member of enumeration
        % matlab.hwmgr.internal.hwsetup.StatusIcon
        Status
        % Name - Cell array of character vectors/strings for the Name of
        % the 3P tool
        Name
        % LicenseURL - Cell array of character vectors/strings for license
        % link for the 3P tool
        LicenseURL
        % ColumnHeader - Cell array of character vectors/strings for table
        % column headers
        ColumnHeader
    end

    %----------------------------------------------------------------------
    % methods - constructor
    %----------------------------------------------------------------------
    methods(Access = protected)
        function obj = TpDownloadAndInstallStatusTable(varargin)
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});

            obj.Position = [200 50 300 300];
        end
    end

    %----------------------------------------------------------------------
    % setter methods
    %----------------------------------------------------------------------
    methods
        function set.Status(obj, status)
            validateattributes(status, {'cell'}, {'vector'})
            validateFcn = @matlab.hwmgr.internal.hwsetup.TpDownloadAndInstallStatusTable.validateStatusStr;
            if ~all(cellfun(validateFcn, status))
                error(message('hwsetup:widget:InvalidDataType', 'Status',...
                    'Cell array with elements either specified as empty characters or objects of type matlab.hwmgr.internal.hwsetup.StatusIcon'));
            end
            obj.setStatus(status);
        end
        function set.Name(obj, name)
            validateattributes(name, {'cell'}, {'vector'})
            if ~iscellstr(name) && ~isstring(name)
                error(message('hwsetup:widget:InvalidDataType', 'Values',...
                    'cell array of character vectors or string array'))
            end
            obj.setName(name);
        end
        function set.LicenseURL(obj, license)
            validateattributes(license, {'cell'}, {'vector'})

            obj.setLicenseURL(license);
        end
        function set.ColumnHeader(obj, ch)
            validateattributes(ch, {'cell'}, {'vector','numel',3})

            obj.setColumnHeader(ch);
        end
    end

    %----------------------------------------------------------------------
    % getter methods
    %----------------------------------------------------------------------
    methods
        function status = get.Status(obj)
            status = obj.getStatus;
        end

        function name = get.Name(obj)
            name = obj.getName();
        end

        function license = get.LicenseURL(obj)
            license = obj.getLicenseURL();
        end

        function ch = get.ColumnHeader(obj)
            ch = obj.getColumnHeader();
        end
    end

    %----------------------------------------------------------------------
    % helper methods
    %----------------------------------------------------------------------
    methods(Static)
        function obj = getInstance(parent)
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(parent,...
                mfilename);
        end

        function out = validateStatusStr(in)
            out = false;
            if isa(in, 'matlab.hwmgr.internal.hwsetup.StatusIcon')
                out =true;
            elseif ischar(in)
                if isempty(in)  || matlab.hwmgr.internal.hwsetup.TpDownloadAndInstallStatusTable.isIconStr(in)
                    out = true;
                end
            end
        end

        function out = isIconStr(str)
            out = ~isempty(regexp(str, '<html><body><img src=".+" height="16" width="16"></img></body></html>', 'once'));
        end
    end

    %----------------------------------------------------------------------
    % abstract methods
    %----------------------------------------------------------------------
    methods(Abstract, Access = 'protected')
        setName(obj, value)
        setLicenseURL(obj, value)
        setStatus(obj, value)
        setColumnHeader(obj, value)
        value = getName(obj)
        value = getStatus(obj)
        value = getLicenseURL(obj)
        value = getColumnHeader(obj)
    end

end
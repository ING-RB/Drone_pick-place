classdef TpDownloadTable  < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.EnableWidget
    %TpDownloadTable This class provides an instance of a TpDownloadTable widget as a
    %result of calling getInstance. A TpDownloadTable will render three text areas
    %for display: "Name", "Version", and "Details". Each areas can be
    %populated by custom text with a hyperlink attached to Details.
    %
    %   TpDownloadTable Widget Properties
    %   Position        -Location and Size [left bottom width height]
    %   Visible         -Widget visibility specified as 'on' or 'off'
    %   Tag             -String based identifier
    %   Name            -String array or Cell array of character vectors to describe the
    %                    third party software or any download-able content.
    %   Version         -String array or Cell array of character vectors to describe the Software version of the
    %                    third party software that needs to be downloaded.
    %   Details         -String array or Cell array of character vectors to describe
    %                    hyperlink details.
    %                    hyperlink.
    %   ColumnName      -Column heading names in String array or Cell array of character vectors
    %
    %   EXAMPLE:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   tpdt = matlab.hwmgr.internal.hwsetup.Panel.getInstance(w);
    %   tpdt = matlab.hwmgr.internal.hwsetup.TpDownloadTable.getInstance(p);
    %   tpdt.Position = [20 20 200 20];
    %   tpdt.Name = {'Texas Instrument CCSV5 with C2000 Code Generation Tools'};
    %   tpdt.Version = {'5.2.1'};
    %   tpdt.Details =  {'<a href=https://www.mathworks.com/>Download</a>'};
    %   tpdt.show();
    %
    %See also matlab.hwmgr.internal.hwsetup.widget
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties(Dependent)
        %Name- name of 3P software which will be displayed in the first column.
        Name
        
        %Version- Localized string to be displayed in the second column.
        Version
        
        %Details- Additional details about the 3P tool e.g. if a download is
        %required, link to the downloads etc.
        Details
        
        %ColumnName- cell array of headers for the columns.
        ColumnName
    end
    
    %Properties added for backward compatibility. No effect.
    properties
        Border
        ColumnWidth
        TextAlignment
    end
    
    methods(Access = protected)
        function obj = TpDownloadTable(varargin)
            %TpDownloadTable- construct TpDownload table and set defaults.
            
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});

            obj.Position =  matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.TpDownloadTablePosition;
        end
    end
    
    methods(Static)
        function obj = getInstance(aParent)
            %getInstance- return instance of TpDownloadTable.
            
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent,...
                mfilename);
        end
    end
    
    methods
        function set.Name(obj, names)
            %set.Name- text in first column.
            
            if isempty(names)
                % Allow empty char to Name column
                names = {''};
            else
                validateattributes(names, {'cell', 'string'}, {'vector'});
                if ~iscellstr(names) && ~isstring(names)
                    error(message('hwsetup:widget:InvalidDataType', 'Name',...
                        'string or string array or cell array of character vectors'))
                end
                names = cellstr(names);
            end
            obj.setName(names);
        end
        
        function set.Version(obj, versions)
            %set.Version- text in second column.
            
            if isempty(versions)
                % Allow empty char to hide Version column
                versions = {''};
            else
                validateattributes(versions, {'cell', 'string'}, {'vector'});
                if ~iscellstr(versions)  && ~isstring(versions)
                    error(message('hwsetup:widget:InvalidDataType', 'Version',...
                        'string or string array or cell array of character vectors'))
                end
                versions = cellstr(versions);
            end
            obj.setVersion(versions);
        end
        
        function set.Details(obj, details)
            %set.Details- set details as third column
            
            if isempty(details)
                % Allow empty char to hide Details column
                details = {''};
            else
                validateattributes(details, {'cell', 'string'}, {'vector'});
                if ~iscellstr(details) && ~isstring(details)
                    error(message('hwsetup:widget:InvalidDataType', 'Details',...
                        'string or string array or cell array of character vectors'))
                end
                details = cellstr(details);
            end
            obj.setDetails(details);
        end
        
        function set.ColumnName(obj, names)
            %set.ColumnName- set headers as top row.
            
            if isempty(names)
                % Allow empty char to hide header
                names = {''};
            else
                validateattributes(names, {'cell', 'string'}, {'vector'});
                if ~iscellstr(names) && ~isstring(names)
                    error(message('hwsetup:widget:InvalidDataType', 'ColumnName',...
                        'string or string array or cell array of character vectors'))
                end
                names = cellstr(names);
                if numel(names) > 3
                    error(message('hwsetup:widget:IncorrectSize', 'ColumnName',...
                        'maximum of 3 columns can be added'))
                end
            end
            obj.setColumnName(names);
        end
        
        function set.Border(obj, border)
            %set.Border- on/off to show/hide border.
            
            border = validatestring(border, {'on', 'off'});
            obj.setBorder(border);
        end
        
        function set.TextAlignment(obj, alignment)
            %set.TextAlignment- set text alignment for each table cell.
            
            lowerValue = validatestring(alignment, {'center', 'left', 'right'});
            obj.setTextAlignment(lowerValue);
        end
                
        % getters
        function names = get.Name(obj)
            %get.Name- return list of names.
            
            names = obj.getName;
        end
        
        function versions = get.Version(obj)
            %get.Version- return list of versions.
            
            versions = obj.getVersion;
        end
        
        function details = get.Details(obj)
            %get.Details- return list of details.
            
            details = obj.getDetails;
        end
        
        function names = get.ColumnName(obj)
            %get.ColumnName- return headers for each column.
            
            names = obj.getColumnName;
        end
        
        function border = get.Border(obj)
            %get.Border- get border on/off 
            
            border = obj.getBorder;
        end
        
        function alignment = get.TextAlignment(obj)
            %get.TextAlignment- get text alignment set for each cell.
            
            alignment = obj.getTextAlignment();
        end
    end
    
    methods(Abstract, Access = protected)
        %setName- Technology specific implementation of setting Name
        setName(obj, names);
        
        %setVersion- Technology specific implementation of setting Version
        setVersion(obj, value);
        
        %setDetails- Technology specific implementation of setting Details
        setDetails(obj, details);
        
        %setColumnName- Technology specific implementation of setting ColumnName
        setColumnName(obj, names);
        
        %setBorder- Technology specific implementation of setting border
        setBorder(obj, border);
        
        %setTextAlignment- Technology specific implementation of setting
        %text alignment.
        setTextAlignment(obj, alignmment);
        
        %getName- Technology specific implementation of getting Name
        names = getName(obj)
        
        %getVersion- Technology specific implementation of getting Version
        versions = getVersion(obj);
        
        %getDetails- Technology specific implementation of getting Details
        details = getDetails(obj);
        
        %getColumnName- Technology specific implementation of getting ColumnName
        names = getColumnName(obj);
        
        %getBorder- Technology specific implementation of getting border.
        border = getBorder(obj);
        
        %getTextAlignment- Technology specific implementation of getting
        %text alignment.
        alignment = getTextAlignment(obj);
    end    
end
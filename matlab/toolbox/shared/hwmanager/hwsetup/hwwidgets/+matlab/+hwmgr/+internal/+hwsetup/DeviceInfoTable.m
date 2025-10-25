classdef DeviceInfoTable < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.EnableWidget
    %DEVICEINFOTABLE Provides a table that has 2 columns and 'n' number of
    %rows. The first column is a label for the value specified in the
    %second column. This table should be used to display information for a
    %particular device, board, hardware etc.
    %
    %   DEVICEINFOTABLE Widget Properties
    %   Position        -Location and Size [left bottom width height]
    %                    (When the table is displayed the height and the
    %                    width of the table are adjusted based on the table
    %                    dimensions)
    %   Visible         -Widget visibility specified as 'on' or 'off'
    %   Labels          -Cell array of strings/character vectors that
    %                    specify row name
    %   Values          -Cell array of strings/character vectors that
    %                    specify the value for each label
    %   Tag             -Unique identifier for the button widget.
    %
    %   EXAMPLE:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   t = matlab.hwmgr.internal.hwsetup.DeviceInfoTable.getInstance(w);
    %   t.Labels = {'IP Address', 'Hostname', 'Password'};
    %   t.Values = {'192.34.56.1', 'raspberry', 'password'};
    %
    %See also matlab.hwmgr.internal.hwsetup.DeviceInfoTable
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
        %Labels - The label for the device information e.g. COM Port, IP
        %Address, Host Name etc. specified as a cell array of strings or
        %character vectors.
        Labels
        
        %Values - The actual value for each label, specified as a cell
        %array of strings or character vectors
        Values
    end
    
    properties
        %Todo: delete once all usage removed.
        %ColumnWidth- added for backward compatibility. Has no effect.
        ColumnWidth
    end
    
    methods(Access = protected)
        function obj = DeviceInfoTable(varargin)
            %DeviceInfoTable- Constructor
            
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});

            obj.Position = [100 100 300 80];
        end
    end
    
    methods
        function set.Labels(obj, labels)
            %set.Labels - set label values
            
            validateattributes(labels, {'cell'}, {'vector'})
            if ~iscellstr(labels) &&  ~isstring(labels)
                error(message('hwsetup:widget:InvalidDataType', 'Labels',...
                    'cell array of character vectors or string array'))
            end
            obj.setLabels(labels);
        end
        
        function labels = get.Labels(obj)
            %get.Labels - get label values in column 1
            
            labels = obj.getLabels;
        end
        
        function set.Values(obj, values)
            %set.Values - set values for each row
            
            validateattributes(values, {'cell'}, {'vector'});
            if ~iscellstr(values) && ~isstring(values)
                error(message('hwsetup:widget:InvalidDataType', 'Values',...
                    'cell array of character vectors or string array'))
            end
            obj.setValues(values)
        end
        
        function values = get.Values(obj)
            %get.Values - get values for each row
            
            values = obj.getValues();
        end
    end
    
    methods(Static)
        function obj = getInstance(parent)
            %getInstance - returns instance of DeviceInfoTable object
            
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(parent,...
                mfilename);
        end
    end
    
    methods(Abstract, Access = protected)
        %setLabels- Technology specific implementation for setting labels
        setLabels(obj, labels);
        
        %setValues- Technology specific implementation for setting values
        setValues(obj, values);
        
        %getLabels - Technology specific implementation for getting labels
        labels = getLabels(obj);
        
        %getValues - Technology specific implementation for getting values
        values = getValues(obj);
    end
end
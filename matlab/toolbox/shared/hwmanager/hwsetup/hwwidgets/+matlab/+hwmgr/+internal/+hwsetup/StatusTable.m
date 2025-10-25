classdef StatusTable < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.EnableWidget
    %STATUSTABLE Provides a table that has 2 columns and 'n' number of
    %rows. The first column displays the status icon - busy, pass, fail.
    %The second column is a string describing the activity performed.
    %
    %   StatusTable Widget Properties
    %   Position        -Location and Size [left bottom width height]
    %                    (When the table is displayed the height and the
    %                    width of the table are adjusted based on the table
    %                    dimensions)
    %   Visible         -Widget visibility specified as 'on' or 'off'
    %   Status          -Cell array of icon enum
    %                    matlab.hwmgr.internal.hwsetup.StatusIcon
    %   Steps           -Cell array of strings/character vectors that
    %                    specify the activity performed
    %   Tag             -Unique identifier for the button widget.
    %
    %   EXAMPLE:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   t = matlab.hwmgr.internal.hwsetup.StatusTable.getInstance(w);
    %   t.Status = {matlab.hwmgr.internal.hwsetup.StatusIcon.Pass, ...
    %               matlab.hwmgr.internal.hwsetup.StatusIcon.Fail}
    %   t.Steps = {'Test Driver Installation', 'Test Hardware Connection'};
    %   t.show();
    %
    %See also matlab.hwmgr.internal.hwsetup.Table
    
    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
        %Status - Cell array where each element is a member of enumeration
        %matlab.hwmgr.internal.hwsetup.StatusIcon
        Status
        
        %Steps - Cell array of character vectors/strings that describe the
        %activity for which status is being displayed
        Steps
        
        %Border- show or hide table borders
        Border
    end
    
    properties
        %Todo: delete once all usage removed.
        %ColumnWidth- added for backward compatibility. Has no effect.
        ColumnWidth
    end
    
    methods(Access = protected)
        function obj = StatusTable(varargin)
            %StatusTable- Constructor
            
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});
            
            obj.Position = [200 200 100 100];
        end
    end
    
    methods
        function set.Status(obj, status)
            %set.Status- set status in first column.
            
            validateattributes(status, {'cell'}, {'vector'})
            validateFcn = @obj.validateStatusStr;
            if ~all(cellfun(validateFcn, status))
                error(message('hwsetup:widget:InvalidDataType', 'Status',...
                    'Cell array with elements either specified as empty characters or objects of type matlab.hwmgr.internal.hwsetup.StatusIcon'));
            end
            obj.setStatus(status);
        end
        
        function status = get.Status(obj)
            %get.Status- return status in first column.
            
            status = obj.getStatus();
        end
        
        function set.Steps(obj, steps)
            %set.Steps- set steps in second column.
            
            validateattributes(steps, {'cell'}, {'vector'})
            if ~iscellstr(steps) && ~isstring(steps)
                error(message('hwsetup:widget:InvalidDataType', 'Values',...
                    'cell array of character vectors or string array'))
            end
            obj.setSteps(steps);
        end
        
        function steps = get.Steps(obj)
            %get.Steps- get list of steps in second column.
            
            steps = obj.getSteps();
        end
        
        function set.Border(obj, border)
            %set.Border setter for border
            
            border = validatestring(border, {'on', 'off'});
            obj.setBorder(border);
        end
        
        function border = get.Border(obj)
            %get.Border getter for border
            
            border = obj.getBorder();
        end
        
    end
    
    methods(Access = private)
        function out = validateStatusStr(obj, str)
            %validateStatusStr- validate the entered status icon text.
            
            out = false;
            if isa(str, 'matlab.hwmgr.internal.hwsetup.StatusIcon')
                out = true;
            elseif ischar(str)
                if isempty(str) || obj.isIconStr(str)
                    out = true;
                end
            end
        end
    end
    
    methods(Static)
        function obj = getInstance(parent)
            %getInstance- return instance of StatusTable.
            
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(parent,...
                mfilename);
        end
    end
    
    methods(Abstract, Access = protected)
        %setSteps- Technology specific implementation to set status
        setStatus(obj, status);
        
        %setSteps- Technology specific implementation to set steps
        setSteps(obj, steps);
        
        %getStatus- Technology specific implementation to get status.
        status = getStatus(obj)
        
        %getStatus- Technology specific implementation to get steps.
        steps = getSteps(obj)
        
        %setBorder- Technology specific implementation of setting border
        setBorder(obj, state);
        
        %getBorder- Technology specific implementation of getting border.
        border = getBorder(obj);
        
        %isIconStr- Technology specific implementation to validate icon
        %strings.
        isIconStr(obj, str);
    end
end
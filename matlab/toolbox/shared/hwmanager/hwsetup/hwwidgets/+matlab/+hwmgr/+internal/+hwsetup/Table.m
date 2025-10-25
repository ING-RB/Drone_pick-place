classdef Table < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.EnableWidget
    %TABLE Provides a Table widget as a result of calling
    %getInstance. TABLE widget provides an option for the user to add a
    %Table.
    %
    %   TABLE Widget Properties
    %   Position        -Location and Size [left bottom width height]
    %   Visible         -Widget visibility specified as 'on' or 'off'
    %   Data            -Table content, specified as a numeric array or cell array
    %   RowName         -Row heading names
    %   ColumnName      -Column heading names
    %   ColumnWidth     -Size of the Column.
    %   ColumnEditable  -Ability to edit column cells
    %   CellEditFcn     -Callback that runs when the user modifies a cell
    %                    item.
    %
    %     %   EXAMPLE:
    %     w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %     t = matlab.hwmgr.internal.hwsetup.Table.getInstance(w);
    %     % Set the properties for first table
    %     t.Tag = 'Example_Table;
    %     t.Position =  [140 320 201 62]
    %     t.RowName = {'Host Name','User Name','Password'};
    %     t.ColumnName = {};
    %     t.ColumnWidth = {100};
    %     t.Data = {'Raspberry Pi';'Raspi User';'raspi'}
    %
    %     t1 = matlab.hwmgr.internal.hwsetup.Table.getInstance(w);
    %     % Set the properties second table which shows Icons
    %     t1.Position =  [140 200 350 46]
    %     t1.RowName = {};
    %     t1.ColumnName = {};
    %     t1.ColumnWidth = {100};
    %     a = matlab.hwmgr.internal.hwsetup.IconEnumerator.Ok
    %     b = matlab.hwmgr.internal.hwsetup.IconEnumerator.NotOk
    %     t1.Data = {a.dispIcon,'Ping Hardware','';b.dispIcon,'Lorem    ipsum','Error message'}
    %     % Display the Image
    %     t.show();
    %
    %See also matlab.hwmgr.internal.hwsetup.widget

    % Copyright 2016-2022 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
        % Data provides the option to enter values to be stored in tables row and column.
        Data
        % Width of table columns
        ColumnWidth
        % Column heading names
        ColumnName
        % Row heading names
        RowName
        % Ability to edit column cells
        ColumnEditable
        %Selection- indicate which cells are currently selected,
        %corresponds to Selection property of uitable.
        Selection
    end
    
    properties(Access = public)
        % CellEdit - The function callback that gets executed when
        % table value changes.
        CellEditFcn
        % CellSelectionFcn  - The function callback that gets executed when
        % a particular is cell is selected.
        CellSelectionFcn
    end
    
    methods(Access = protected)
        function obj = Table(varargin)
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});
            % Set defaults
            if ~isequal(class(obj.Parent),...
                    'matlab.hwmgr.internal.hwsetup.appdesigner.Grid')
                [pW, pH] = obj.getParentSize();
                obj.Position = [pW*0.25, pH*0.25, pW*0.5, pH*0.5];
            end
            obj.ColumnName = {};
            obj.RowName = {};
            obj.DeleteFcn = @matlab.hwmgr.internal.hwsetup.Widget.close;
            obj.setCallback();
        end
    end
    
    methods(Static)
        function obj = getInstance(aParent)
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent, mfilename);
        end
    end
    
    
    %% Property setter and Getters
    methods
        function peer = getPeer(obj)
            peer = obj.Peer;
        end

        function h = getHeight(obj)
            pos = obj.Peer.Extent;
            h = pos(4);
        end
        
        function w = getWidth(obj)
            pos = obj.Peer.Extent;
            w = pos(3);
        end
        
        % Getters
        function value = get.Data(obj)
            value = obj.getData();
        end
        
        function value = get.ColumnWidth(obj)
            value = obj.getColumnWidth();
        end
        
        function value = get.ColumnName(obj)
            value = obj.getColumnName();
        end
        
        function value = get.RowName(obj)
            value = obj.getRowName();
        end
        
        function value = get.ColumnEditable(obj)
            value = obj.getColumnEditable();
        end

        function sel = get.Selection(obj)
            sel = obj.Peer.Selection;
        end
        
        %setters
        function set.Data(obj, value)
            validateattributes(value,{'cell', 'char', 'string', 'numeric', 'table'},{'2d'});
            obj.setData(value);
        end
        
        function set.ColumnWidth(obj, value)
            validateattributes(value, {'cell'}, {'nonempty'});
            obj.setColumnWidth(value);
        end
        
        function set.ColumnName(obj, value)
            validateattributes(value,{'cell', 'char', 'string', 'numeric'},{'2d'});
            obj.setColumnName(value);
        end
        
        function set.RowName(obj, value)
            validateattributes(value,{'cell', 'char', 'string', 'numeric'},{'2d'});
            obj.setRowName(value);
        end
        
        function set.ColumnEditable(obj, value)
            validateattributes(value,{'logical'},{'nonempty'});
            obj.setColumnEditable(value);
        end
        
        function set.Selection(obj, value)
           obj.Peer.Selection = value; 
        end
    end
    
    methods(Abstract, Access = 'protected')
        setData(obj, text);
        setColumnWidth(obj, value);
        setColumnName(obj, value);
        setRowName(obj, value);
        setColumnEditable(obj, value);

        value = getData(obj);
        value = getColumnWidth(obj);
        value = getColumnName(obj);
        value = getRowName(obj);
        value = getColumnEditable(obj);

        setCallback(obj);
        CellEditCbk(obj);
    end
    
end

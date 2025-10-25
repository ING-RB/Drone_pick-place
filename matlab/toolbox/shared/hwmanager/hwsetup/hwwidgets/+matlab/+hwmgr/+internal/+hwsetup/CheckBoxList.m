classdef CheckBoxList < matlab.hwmgr.internal.hwsetup.DerivedWidget
    %CHECKBOXLIST provides a vertical list of checkboxes using a Table widget.
    %Each entry can be checked/un-checked by the user.
    %
    %   CheckBoxList Widget Properties
    %   Position        -Location and Size [left bottom width height]
    %   Visible         -Widget visibility specified as 'on' or 'off'
    %   Title           -String label for the CheckBoxList
    %   Items           -Cell array of strings for the individual options
    %   Values          -Selected item in the CheckBoxList
    %   ValueIndex      -Index of selected item in the CheckBoxList
    %   Tag             -Unique identifier for the CheckBoxList widget.
    %   Enable          -Widget active state specifiec as 'on' or 'off'
    %   ValueChangedFcn -Callback function when checkbox value changes.
    
    %   EXAMPLE:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   cbl = matlab.hwmgr.internal.hwsetup.CheckBoxList.getInstance(w);
    %   cbl.Items = {'Item 1', 'Item 2', 'Item 3'};
    %   cbl.Title = 'CheckBox Header';
    %   cbl.ValueIndex = [1 3];
    %   cbl.Title = 'CheckBox Header';
    %
    %See also matlab.hwmgr.internal.hwsetup.Table
    
    % Copyright 2017-2021 The MathWorks, Inc.
    
    properties(SetAccess = protected, GetAccess = protected)
        % Inherited Properties
        BaseWidget
    end
    
    properties(Access = public, Dependent)
        % String Title for the CheckBoxList that shows up in First Row as
        % bold
        Title
        % Cell array of strings, label of Items that needs to
        % checked/unchecked
        Items
        % ColumnWidth - 1x2 Array specifying width of each column in a
        % table
        ColumnWidth
    end
    
    properties (SetAccess = protected, GetAccess = public)
        % Values - The current values that is selected from the list of items
        %    specified as a string
        Values
    end
    
    properties(Access = public, Dependent, SetObservable)
        % ValueIndex - The index of the selected item specified as an int
        ValueIndex
        
        % Inherited Properties
        % Visible
        % Tag
        % Position
    end
    
    properties(Access = public)
        % ValueChangedFcn - The function callback that gets executed when
        % checkbox value changes.
        ValueChangedFcn
    end
    
    properties(Access = private)
        % local property that is used to store/retrieve Title
        Header
    end
    
    properties(Access = private, Constant)
        MinHeight = 20
        MinWidth = 50
        OffsetPC = 2
        OffsetLinux = 1
    end
    
    methods(Access = protected)
        function obj = CheckBoxList(varargin)
            % Constructor
            obj@matlab.hwmgr.internal.hwsetup.DerivedWidget(varargin{:});
            obj.BaseWidget = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(obj.Parent, 'Table');
            obj.BaseWidget.Data = {};
            obj.Title = 'CheckBox Header';
            obj.Items = {'Item 1', 'Item 2',  'Item 3'};
            obj.ValueIndex = [1, 3];
            obj.ColumnWidth = [30, 120];
            obj.BaseWidget.ColumnEditable = [true, false];
            obj.BaseWidget.CellSelectionFcn = @obj.CellSelectionCbk;
            obj.BaseWidget.CellEditFcn = @obj.CellEditCbk;
            addlistener(obj,'ValueIndex','PostSet',@obj.valueChangedCbk);
        end
        
        function fit(obj)
            % FIT - Adjusts the height and width of the table to match the
            % dimensions based on the data entered
            
            %getWidth and getHeight methods rely on Extent property of uitable.
            w = obj.BaseWidget.getWidth();
            h = obj.BaseWidget.getHeight();
            if ~isequal(w, 0) && ~isequal(h, 0)
                if w <= obj.MinWidth % These conditions will occur when no Items are mentioned for uitable
                    w = obj.MinWidth; % Minimum width required to create DIT
                end
                if h <= obj.MinHeight
                    h = obj.MinHeight;% Minimum height required to create DIT
                end
                
                if ispc
                    w = w - obj.OffsetPC; % offset 2 pixel to align with border
                    h = h - obj.OffsetPC;% offset 2 pixel to align with border
                elseif ~ismac % if Linux
                    w = w - obj.OffsetLinux; % offset 1 pixel to align with border
                    h = h - obj.OffsetLinux;% offset 1 pixel to align with border
                end
                init_pos = obj.Position;
                obj.Position  = [init_pos(1) init_pos(2)+init_pos(4)-h w h];
            end
        end
    end
    
    methods
        function show(obj)
            %SHOW - Display the HW Setup widget
            %   show(obj) displays the widget, if the parent for the widget
            %   is not visible, the parent's visibility is set to 'on' as
            %   well (This is done recursively till the window containing
            %   the widget is set to visible 'on')
            obj.BaseWidget.show();
        end
    end
    
    methods
        function set.ColumnWidth(obj, width)
            validateattributes(width, {'numeric'},...
                {'size', [1, 2], '>=', 1});
            obj.BaseWidget.ColumnWidth = num2cell(width);
        end
        
        function width = get.ColumnWidth(obj)
            width = obj.BaseWidget.ColumnWidth;
        end
        
        function set.Items(obj, items)
            validateattributes(items,{'cell'},{'vector', 'nonempty'});
            if ~iscellstr(items) && ~isstring(items)
                error(message('hwsetup:widget:InvalidDataType', 'Items',...
                    'cell array of character vectors or string array'))
            end
            
            data = cell(numel(items)+1,2);
            items = cellfun(@(x) sprintf('   %s',x),items,'un',0); % Indent items by three spaces
            items = items';% conver row vector to column vector
            data(:,2) = [obj.BaseWidget.Data(1,2); items];% assign items in second column
            % When Items are set, always set this to flase
            data(:,1) = {false};
            obj.BaseWidget.Data = data;
        end
        
        function items = get.Items(obj)
            items = obj.BaseWidget.Data(2:end,2)';
            items = cellfun(@strtrim, items, 'UniformOutput', false);
        end
        
        function set.Title(obj, title)
            validateattributes(title, {'char', 'string'}, {'nonempty'});
            % make title bold using cell specific styling
            obj.Header = title;
            obj.BaseWidget.addStyle(uistyle('FontWeight', 'bold'), [1, 2]);
            obj.BaseWidget.Data(1, :) = {false, char(title)};
        end
        
        function values = get.Title(obj)
            values = obj.Header;
        end
        
        function set.ValueIndex(obj, valIdx)
            nItems = numel(obj.Items);
            validateattributes(valIdx, {'numeric'}, {'>', 0, '<=', nItems});
            
            for i = 1:numel(obj.Items)
                if any(ismember(valIdx, i))
                    obj.BaseWidget.Data{i+1, 1} = true;
                else
                    obj.BaseWidget.Data{i+1,1} = false;
                end
            end
            
            if all([obj.BaseWidget.Data{2:end, 1}])
                % All checked
                obj.BaseWidget.Data{1, 1} = true;
            elseif ~any([obj.BaseWidget.Data{2:end, 1}])
                % None checked
                obj.BaseWidget.Data{1, 1} = false;
            end
        end
        
        
        function valIdx = get.ValueIndex(obj)
            % get the indices of checked items
            valIdx = find(cell2mat(obj.BaseWidget.Data(2:end, 1)))';
        end
        
        function values = get.Values(obj)
            % get values (names)of checked items
            values = obj.Items(obj.ValueIndex);
        end
        
        function CellEditCbk(obj, src, event)
            % Callback to toggle the checkbox status when user directly
            % clicks on a checkbox.
            if isprop(event,'Indices')
                if isequal(event.Indices,[1 1])
                    if obj.BaseWidget.Data{1}
                        % If CheckAll checkbox is true, mark all as
                        % checked.
                        obj.BaseWidget.Data(2:end, 1) = {true};
                    else
                        % If CheckAll checkbox is unchecked, mark all as
                        % unchecked.
                        obj.BaseWidget.Data(2:end, 1) = {false};
                    end
                else
                    if ~event.NewData
                        % If NewData is Zero for a checkbox, then un-check
                        % it.
                        obj.BaseWidget.Data(1) = {false};
                    else
                        % get all logical values of Items
                        logicalItems = cell2mat(obj.BaseWidget.Data(2:end, 1));
                        if all(logicalItems)
                            % If all are checked, check the CheckAll checkbox
                            obj.BaseWidget.Data(1) = {true};
                        end
                    end
                end
                obj.valueChangedCbk(src, event);% this will be called only when first column is selected to change the value of checked items
            end
        end
        
        function CellSelectionCbk(obj, src, event)
            % Callback to toggle the checkbox status when Item is selected
            % instead of checkbox specific index.
            if isprop(event,'Indices') && ~isempty(event.Indices)
                if isequal(event.Indices,[1 1])
                else
                    % toggle the logical value of the selected index
                    obj.BaseWidget.Data(event.Indices(1) ,1) = {~obj.BaseWidget.Data{event.Indices(1), 1}};
                    if isequal(event.Indices,[1 2])
                        if obj.BaseWidget.Data{1}
                            % If 'CheckAll checkbox' is true, mark all as
                            % checked.
                            obj.BaseWidget.Data(2:end, 1) = {true};
                        else
                            % If 'CheckAll checkbox' is false, mark all as
                            % un-checked.
                            obj.BaseWidget.Data(2:end, 1) = {false};
                        end
                    end
                    % get all logical values of Items
                    logicalItems = cell2mat(obj.BaseWidget.Data(2:end, 1));
                    if all(logicalItems)
                        % If all are checked, mark the 'CheckAll checkbox'
                        % checked.
                        obj.BaseWidget.Data(1) = {true};
                    else
                        % If any one is un-checked, mark the 'CheckAll
                        % checkbox' un-chcked
                        obj.BaseWidget.Data(1) = {false};
                    end
                    % Call the callback
                    obj.valueChangedCbk(src, event);
                end
                obj.BaseWidget.Selection = [];
            end
        end
    end
    
    methods(Access = protected)
        function valueChangedCbk(obj, varargin)
            %varargin should be two elements an object and an event
            validateattributes(varargin, {'cell'}, {'row', 'ncols', 2});
            validateattributes(varargin{2}, {'matlab.ui.eventdata.CellEditData','matlab.ui.eventdata.CellSelectionChangeData',...
                'event.PropertyEvent', 'event.EventData'}, {});
            obj.safeCallbackInvoke(obj.ValueChangedFcn, varargin{2});
        end
    end
    
    methods(Static)
        function obj = getInstance(parent)
            obj = matlab.hwmgr.internal.hwsetup.CheckBoxList(parent);
        end
    end
end
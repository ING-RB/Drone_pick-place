classdef RadioGroup < matlab.hwmgr.internal.hwsetup.Widget & ...
        matlab.hwmgr.internal.hwsetup.mixin.BackgroundColor & ...
        matlab.hwmgr.internal.hwsetup.mixin.EnableWidget & ...
        matlab.hwmgr.internal.hwsetup.Container
    %RADIOGROUP Provides a RADIOGROUP widget as a result of calling
    %getInstance. RADIOGROUP widget provides an option to list Radio
    %buttons for the user with SelectionChangeFcn callback.
    %
    %   RADIOGROUP Widget Properties
    %   Position        -Location and Size [left bottom width height]
    %   Visible         -Widget visibility specified as 'on' or 'off'
    %   Title           -String label for the RADIOGROUP
    %   TitleAlignment  -test alignment(center, left, right) % to do
    %   Items           -Cell array of strings for the individual options
    %   Value           -Selected item in the RADIOGROUP
    %   ValueIndex      -Index of selected item in the RADIOGROUP
    %   Tag             -Unique identifier for the RADIOGROUP widget.
    %   Enable          -Widget active state specified as 'on' or 'off'
    %
    %   EXAMPLE:
    %   w = matlab.hwmgr.internal.hwsetup.Window.getInstance();
    %   p = matlab.hwmgr.internal.hwsetup.Panel.getInstance(w);
    %   rg = matlab.hwmgr.internal.hwsetup.RadioGroup.getInstance(p);
    %   rg.Position = [20 80 200 100];
    %   rg.Title = 'MyRadioGroup!';
    %   rg.Items = {'Option1', 'Option2', 'Option3'};
    %   rg.show();
    %
    %See also matlab.hwmgr.internal.hwsetup.widget
    
    % Copyright 2016-2021 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
        % Title for the Radio group
        Title
    end
    
    properties(Access = public)
        % Cell array of radio buttons that has to placed inside the
        % Radiogroup widget.
        Items
    end
    
    properties (SetAccess = protected, GetAccess = public)
        %Value - The current value that is selected from the list of radio
        %buttons.
        Value
    end
    
    properties(Access = public, SetObservable)
        % ValueIndex - The index of the selected item specified as an
        % integer.
        ValueIndex
    end
    
    properties(Access = public)
        %SelectionChangedFcn - The callback that gets executed when
        %selection changes.
        SelectionChangedFcn
    end
    
    properties(Constant, Access = private)
        %PaddingPixels - padding for items inside the group.
        PaddingPixels = 20;
        
        %StartRadioButtonFromLeftEdge - left margin for radio buttons.
        StartRadioButtonFromLeftEdge = 4.5;
    end
    
    methods(Access= protected)
        function obj = RadioGroup(varargin)
            %RadioGroup - construct group and set defaults.
            
            obj@matlab.hwmgr.internal.hwsetup.Widget(varargin{:});
            obj.Peer.SizeChangedFcn = @obj.sizeChangedFcn;
            obj.DeleteFcn = @matlab.hwmgr.internal.hwsetup.Widget.close;
            if ~isequal(class(obj.Parent),...
                    'matlab.hwmgr.internal.hwsetup.appdesigner.Grid')
                [pW, pH] = obj.getParentSize();
                obj.Position = [pW*0.25 pH*0.25 pW*0.3 pH*0.4];
            end
            obj.Title = matlab.hwmgr.internal.hwsetup.util.WidgetDefaults.RadioGroupTitle;
            obj.Items = {'Option1', 'Option2', 'Option3'};
            obj.Color = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput;
            obj.setCallback();
        end
    end
    
    methods
        function setColor(obj)
            %setColor - set background color for the group.
            
            setColor@matlab.hwmgr.internal.hwsetup.mixin.BackgroundColor(obj);
        end
        
        function setPosition(obj, position)
            %setPosition - override setPosition in WidgetBase to position
            %radiobuttons within a buttongroup.
            %First set parent position then position children accordingly.
            
            setPosition@matlab.hwmgr.internal.hwsetup.WidgetBase(obj, position);
            
            obj.setChildPosition();
             % set minimum width and height if necessary.
            obj.setMinSize();
        end
    end
    
    methods(Static)
        function obj = getInstance(aParent)
            %getInstance - returns instance of RadioGroup widget.
            
            obj = matlab.hwmgr.internal.hwsetup.Widget.createWidgetInstance(aParent, mfilename);
        end
    end
    
    %% Property Setter and Getters
    methods
        function title = get.Title(obj)
            %getTitle - get title for the button group.
            
            title = obj.getTitle();
        end
        
        function items = get.Items(obj)
            %get.Items - get items in the button group.

            items = obj.getItems();
        end
        
        function value = get.Value(obj)
            %getValue - get text of the selected radio button.
            
            value = obj.getValue();
        end
        
        function valIdx = get.ValueIndex(obj)
            %getValueIndex - get selected radio button index.

            valIdx = obj.getValueIndex();
        end
        
        function set.Title(obj, title)
            %setTitle - set title for the button group.

            obj.validateStringInput(title);
            obj.setTitle(title);
        end
        
        function set.Items(obj, items)
            %set.Items - add items to the button group.

            validateattributes(items, {'cell'}, {'vector'})
            if ~iscellstr(items) && ~isstring(items)
                error(message('hwsetup:widget:InvalidDataType', 'Items',...
                    'cell array of character vectors or string array'))
            end
            if isempty(items)
                items = {''};
            end
            % The RadioGroup needs to be reset based on the new Items list
            obj.repaintRadioGroup(items);
        end
        
        function set.ValueIndex(obj, valIdx)
            %set.ValueIndex - set index of radio button to be selected.
            
            validateattributes(valIdx, {'numeric'}, {'nonempty', '<=', numel(obj.Items)}) %#ok<MCSUP>
            obj.setValueIndex(valIdx);
        end
    end
    
    methods(Access = private) 
        function setItems(obj, items)
            %setItems - Set the Text property of the individual Radio
            %Buttons to the corresponding Items.
            
            if numel(items) < numel(obj.Children)
                numToPad = numel(obj.Children) - numel(items);
                items(end:end + numToPad) = {''};
            end
            for i=1:numel(obj.Children)
                obj.Children{i}.Text = items{i};
            end
        end
        
        function out = getOperation(obj, newItems)
            %getOperation - find the operation to perform when repainting
            %the RadioGroup. The valid operations are add, delete and
            %rename.
            
            currentItems = obj.Items;
            if numel(currentItems) > numel(newItems)
                out = 'delete';
            elseif numel(currentItems) < numel(newItems)
                out = 'add';
            elseif numel(currentItems) == numel(newItems)
                out = 'rename';
            end
        end
        
        function setChildPosition(obj)
           %setChildPosition - Set the positions of the Radio Button
           %widgets.
           
           panelHeight = obj.Position(4);  
           panelWidth = obj.Position(3);  
           isVisible = 'on';
           distFromBottomEdge = panelHeight - obj.PaddingPixels*2; % Leave 40 pixels at the top
            for i = 1:numel(obj.Children)
                initChildPosition = obj.Children{i}.Position;
                % Adjust each radio button such that it is 20 pixels from
                % the other
                obj.Children{i}.Position = [obj.StartRadioButtonFromLeftEdge distFromBottomEdge panelWidth initChildPosition(4)];
                obj.Children{i}.Visible = isVisible;
                if distFromBottomEdge > obj.PaddingPixels
                    % If the panel height is not big enough to accommodate
                    % all widgets, create the widgets that will not be
                    % visible at the same position as the last visible
                    % widget but turn the visibility of these widgets off.
                    % When the panel height is increased sufficiently,
                    % these widgets should be rendered
                    distFromBottomEdge = distFromBottomEdge - obj.PaddingPixels;
                else
                    isVisible = 'off';
                end
            end  
        end
        
        function adjustRadioGroupHeight(obj)
            %adjustRadioGroupHeight - adjust height based on items in the
            %group.
            
            height = obj.PaddingPixels*2;
            for i = 1:numel(obj.Children)
                height = height + obj.Children{i}.Position(4);
            end
            obj.Position(4) = height;
            obj.Position(2) = obj.Position(2) + height;
        end
        
        function repaintRadioGroup(obj, newItems)   
            %repaintRadioGroup - Redraw the RadioGroup
            % add: Add radio buttons
            % delete: Delete radiobuttons
            % rename: Rename the items
            
            out = obj.getOperation(newItems);
            currentItems = obj.Items;
            switch out
                case 'add'
                    numItemsToAdd = numel(newItems) - numel(currentItems);
                    for i = 1:numItemsToAdd
                        obj.Children{end+1} = matlab.hwmgr.internal.hwsetup.RadioButton.getInstance(obj);
                    end
                    obj.setChildPosition();
                    obj.setItems(newItems);
                case 'delete'
                    numItemsToRemove = numel(currentItems) - numel(newItems);
                    for i = 1:numItemsToRemove
                        obj.Children{end- (i-1)}.delete();
                    end
                    obj.Children(end-numItemsToRemove+1:end) = [];
                    obj.setChildPosition();
                    obj.setItems(newItems);
                case 'rename'
                    obj.setItems(newItems);
            end
            obj.setValueDefault();
        end

        function sizeChangedFcn(obj, ~, ~)
            % SIZECHANGEDFCN called when the Peer size changes. This can
            % happen when the parent grid resizes.

            % re-arrange the inner radio buttons
            obj.setChildPosition();
            % set minimum width and height if necessary.
            obj.setMinSize();
        end
    end
    
    methods(Abstract, Access = protected)
        %setCallback - Technology specific implementation for setting
        %callback.

        setCallback(obj);
        
        %selectionChangedCB - Technology specific implementation for
        %callback.
        selectionChangedCB(obj);
        
        %setTitle - Technology specific implementation for setting title.
        setTitle(obj, title);
        
        %setValueIndex - Technology specific implementation for setting 
        %selected index.
        setValueIndex(obj, valIdx);
        
        %deleteChildren - Technology specific implementation for deleting 
        %children in the group.
        deleteChildren(obj);
        
        %setValueDefault - Technology specific implementation for setting
        %default values.
        
        setValueDefault(obj);
        
        %setMinSize - Technology specific implementation to set the minimum
        %height and width of the group.
        setMinSize(obj);
        
        %setRestoreValue - Technology specific implementation to restore 
        %the saved button state through value index.
        setRestoreValue(obj, valueIndex)
        
        %getTitle - Technology specific implementation for getting title.
        getTitle(obj);
        
        %getItems - Technology specific implementation for getting items.
        getItems(obj);
        
        %getValue - Technology specific implementation for getting text of 
        %selected button.
        getValue(obj);
        
        %getValueIndex - Technology specific implementation for getting
        %index of selected button.
        getValueIndex(obj);
    end
end

% LocalWords:  hwmgr hwsetup rg Radiogroup radiobuttons buttongroup
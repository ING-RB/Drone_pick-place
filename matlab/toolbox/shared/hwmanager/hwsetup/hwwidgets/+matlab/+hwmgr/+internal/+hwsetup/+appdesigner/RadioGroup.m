classdef RadioGroup < matlab.hwmgr.internal.hwsetup.RadioGroup
    %matlab.hwmgr.internal.hwsetup.appdesigner.RadioGroup is a class that
    %implements a HW Setup radiobutton group using uibuttongroup.
    %It exposes all of the settable and gettable properties defined by the
    %interface specification
    %
    %See also  matlab.hwmgr.internal.hwsetup.RadioGroup
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    properties(Access = private, Constant)
        %DisabledForegroundColor - color when Enabled property RadioGroup
        %is false.
        DisabledForegroundColor = [0.5 0.5 0.5];
        
        %EnabledForegroundColor - color when Enabled property RadioGroup
        %is true.
        EnabledForegroundColor = [0 0 0];
        
        %MinHeight - minimum height for the group.
        MinHeight = 45;
        
        %MinWidth - minimum width for the group.
        MinWidth = 25;
    end
    
    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            %createWidgetPeer creates a UI Component peer for RadioGroup
            %widget.
            
            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {},...
                'createWidgetPeer', 'aParent');
            
            aPeer = uibuttongroup('Parent', aParent,...
                'Visible', 'on',...
                'Interruptible','off', ...
                'BorderType', 'none',...
                'AutoResizeChildren', 'off',...
                'FontSize', matlab.hwmgr.internal.hwsetup.util.Font.getPlatformSpecificFontSize());
        end
    end
    
    methods(Access = protected)
        function setCallback(obj)
            %setCallback - sets the SelectionChangedFcn on the group.
            
            obj.Peer.SelectionChangedFcn = @obj.selectionChangedCB;
        end
        
        function selectionChangedCB(obj, varargin)
            %selectionChangedCB - invokes selection changed callback
            
            validateattributes(varargin, {'cell'}, {'row', 'ncols', 2});
            validateattributes(varargin{2}, {'event.PropertyEvent',...
                'matlab.ui.eventdata.SelectionChangedData'}, {});
            obj.safeCallbackInvoke(obj.SelectionChangedFcn, varargin{2});
        end
        
        function setTitle(obj, title)
            %setTitle - set title for the button group.
            
            obj.Peer.Title = title;
        end
        
        function setValueIndex(obj, valIdx)
            %setValueIndex - set selected radio button to true.
            
            obj.Children{valIdx}.Value = true;
        end
        
        function deleteChildren(obj)
            %deleteChildren - delete buttons within the group.
            
            for i = 1:numel(obj.Children)
                obj.Children{i}.delete();
            end
            obj.Children = {};
        end
        
        function setValueDefault(obj)
            %setValueDefault - select first radio button as the default.
            
            obj.Children{1}.Value = true;
        end
        
        function setRestoreValue(obj, childIndex)
            %setRestoreValue - restore the saved button state through value
            %index.
            
            obj.Children{childIndex}.Value = true;
        end
        
        function setMinSize(obj)
            %setMinSize - set minimum height and width for radio group.
            
            pos = obj.Position();
            if pos(4) <= obj.MinHeight
                obj.Peer.Position(4) = obj.MinHeight; % Minimum height required to create Radio group
            end
            if pos(3) <= obj.MinWidth
                obj.Peer.Position(3) = obj.MinWidth;% Minimum width required to create Radio group
            end
        end
        
        function title = getTitle(obj)
            %getTitle - get title for the button group.
            
            title = obj.Peer.Title;
        end
        
        function items = getItems(obj)
            %getItems - get items in the group. Flip the obj.Peer.Children
            %values upside down, since children are returned in the
            %opposite order.
            
            items = get(flipud(obj.Peer.Children), 'Text');
        end
        
        function value = getValue(obj)
            %getValue - get text of the selected radio button.
            
            for i = 1:numel(obj.Items)
                if obj.Children{i}.Value == true
                    value = obj.Children{i}.Text;
                end
            end
        end
        
        function valIdx = getValueIndex(obj)
            %getValueIndex - get selected radio button index.
            
            for i = 1:numel(obj.Items)
                if obj.Children{i}.Value == true
                    valIdx =  i;
                end
            end
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = RadioGroup(varargin)
            %RadioGroup - constructor
            
            obj@matlab.hwmgr.internal.hwsetup.RadioGroup(varargin{:});
            addlistener(obj, 'ValueIndex', 'PostSet', @obj.selectionChangedCB);
        end
    end
    
    methods
        function setEnable(obj, enableState)
            %setEnable - update the colors to display enable/disable state.
            
            if strcmp(enableState, 'on')
                obj.Peer.ForegroundColor = obj.EnabledForegroundColor;
            elseif strcmp(enableState, 'off')
                obj.Peer.ForegroundColor = obj.DisabledForegroundColor;
            end
        end
        
        function enableState = getEnable(obj)
            %getEnable - read enable state based on the displayed colors.
            
            enableState = 'on';
            if obj.Peer.ForegroundColor == obj.DisabledForegroundColor
                enableState = 'off';
            end
        end
    end
end
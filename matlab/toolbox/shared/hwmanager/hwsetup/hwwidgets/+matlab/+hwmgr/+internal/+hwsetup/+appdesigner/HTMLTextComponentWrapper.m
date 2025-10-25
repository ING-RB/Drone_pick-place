classdef HTMLTextComponentWrapper < handle &...
        matlab.mixin.SetGet
    %This class is undocumented and may change in a future release.
    
    %HTMLTEXTCOMPONENTWRAPPER - This class acts as a wrapper for uilabel 
    %widgets using html interpreter, wrapped up inside a gridlayout. 
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    %UIComponents
    properties(Access = 'protected')
        ContainerComponent %parent container that hosts the text
        LabelComponent %label ui component
    end
    
    %Peer interface values
    properties(Dependent)
        Enable
        Position
        Tag
        Visible
        VerticalAlignment
        Layout % to support Grid as a parent
    end

    properties
        Parent
    end
    
    methods
        function obj = HTMLTextComponentWrapper(aParent)
            %TextComponentWrapper- construct a panel and grid to host the html
            %text.
            %|------------------------------------------|
            %|                uipanel                   |
            %|  |-----------------------------------|   |
            %|  |           uigridlayout            |   |
            %|  |   |--------------------------|    |   |
            %|  |   |          uilabel         |    |   |
            %|  |   |--------------------------|    |   |
            %|  |-----------------------------------|   |
            %|------------------------------------------|
            
            obj.ContainerComponent = uipanel(aParent, 'BorderType', 'none');
            obj.Parent = aParent;
            grid = uigridlayout(obj.ContainerComponent, [1, 1],...
                'RowSpacing', 0, 'ColumnSpacing', 0, 'RowHeight', {'fit'},...
                'ColumnWidth', {'1x'}, 'Scrollable', 'on', 'Padding', [0 0 0 0]);

            obj.LabelComponent = uilabel('Parent', grid, 'Visible', 'on',...
                'WordWrap', 'on', 'Interpreter', 'html',...
                'VerticalAlignment', 'top',...
                'FontSize', matlab.hwmgr.internal.hwsetup.util.Font.getPlatformSpecificFontSize());
        end
        
        function delete(obj)
            %delete- delete parent container.
            
            delete(obj.ContainerComponent);
        end
    end
    
    %----------------------------------------------------------------------
    % setter methods
    %----------------------------------------------------------------------
    methods
        function set.Enable(obj, value)
            set(obj.LabelComponent, 'Enable', value);
        end
        
        function set.Visible(obj, value)
            obj.ContainerComponent.Visible = value;
        end
        
        function set.Tag(obj, value)
            obj.ContainerComponent.Tag = value;
        end
        
        function set.Position(obj, position)
            obj.ContainerComponent.Position = position;
        end

        function set.Layout(obj, layout)
            obj.ContainerComponent.Layout = layout;
        end

        function set.VerticalAlignment(obj, value)                        
            set(obj.LabelComponent, 'VerticalAlignment', value);
        end
    end
    
    %----------------------------------------------------------------------
    % getter methods
    %----------------------------------------------------------------------
    methods        
        function enable = get.Enable(obj)
            enable = obj.LabelComponent.Enable;
        end
        
        function visible = get.Visible(obj)
            visible = obj.ContainerComponent.Visible;
        end
        
        function tag = get.Tag(obj)
            tag = obj.ContainerComponent.Tag;
        end
        
        function position = get.Position(obj)
            position = obj.ContainerComponent.Position;
        end

        function layout = get.Layout(obj)
            layout = obj.ContainerComponent.Layout;
        end

        function value = get.VerticalAlignment(obj)           
            value = get(obj.LabelComponent, 'VerticalAlignment') ;
        end
    end
end
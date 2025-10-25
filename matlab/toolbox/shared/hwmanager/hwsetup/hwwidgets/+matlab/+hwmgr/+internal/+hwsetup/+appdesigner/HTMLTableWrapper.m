classdef HTMLTableWrapper < handle &...
        matlab.mixin.SetGet
    %This class is undocumented and may change in a future release.
    
    %HTMLTABLEWRAPPER - This class acts as a wrapper for HTML tables
    %constructed using UI Components. This hides some of the implementation
    %quirkiness around managing tables.
    
    % Copyright 2023 The MathWorks, Inc.
    
    %UIComponents
    properties(Access = 'protected')
        ContainerComponent %parent container that hosts the table
        HTMLComponent
        FontSize
    end

    properties
        Parent
    end
    
    properties(Constant)
        BackgroundColor = matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput;
        BorderStyle = ['  border: 1px solid var(' matlab.hwmgr.internal.hwsetup.util.Color.BorderColorPrimary ');'];
    end
    
    %Peer interface values
    properties(Dependent)
        Enable
        Layout
        Position
        Tag
        Visible
    end
    
    methods
        function obj = HTMLTableWrapper(aParent)
            %HTMLTableWrapper- construct a panel that will host the table.
            
            %container component that hosts the table grid
            obj.Parent = aParent;
            obj.ContainerComponent = uipanel('Parent', aParent);
            obj.ContainerComponent.BorderType = 'none';
            matlab.hwmgr.internal.hwsetup.util.Color.applyThemeColor(obj.ContainerComponent,'BackgroundColor',obj.BackgroundColor);
            obj.FontSize = matlab.hwmgr.internal.hwsetup.util.Font.getPlatformSpecificFontSize();
            
            grid = uigridlayout(obj.ContainerComponent,...
                [1,1], 'Scrollable', false, 'Padding', 2, 'ColumnSpacing',...
                0, 'RowSpacing', 0);
            matlab.hwmgr.internal.hwsetup.util.Color.applyThemeColor(grid,'BackgroundColor',obj.BackgroundColor);
            obj.HTMLComponent = uihtml(grid, 'DataChangedFcn', @obj.hyperlinkHandler);
            matlab.ui.internal.HTMLUtils.enableTheme(obj.HTMLComponent);
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
            %setEnable - update enable state of table. This includes enabling
            %or disabling the ContainerComponent, which is
            %the panel that hosts the widget.
            
            set(obj.ContainerComponent, 'Enable', value);
        end
        
        function set.Visible(obj, value)
            %set.Visible- control visibility of table.
            
            obj.ContainerComponent.Visible = value;
        end
        
        function set.Tag(obj, value)
            %set.Tag- set tag for table container.
            
            obj.ContainerComponent.Tag = value;
        end
        
        function set.Position(obj, position)
            %set.Position- propagate the position property of widget to the
            %table.
            
            obj.ContainerComponent.Position = position;
        end

        function set.Layout(obj, layout)
            obj.ContainerComponent.Layout = layout;
        end
    end
    
    %----------------------------------------------------------------------
    % getter methods
    %----------------------------------------------------------------------
    methods
        function enable = get.Enable(obj)
            %get.Enable - get enable state of table.
            %returns the state of the ContainerComponent.
            
            enable = obj.ContainerComponent.Enable;
        end
        
        function visible = get.Visible(obj)
            %get.Visible- get visibility of table.
            
            visible = obj.ContainerComponent.Visible;
        end
        
        function tag = get.Tag(obj)
            %get.Tag- get table tag
            
            tag = obj.ContainerComponent.Tag;
        end
        
        function position = get.Position(obj)
            %get.Position- return position of container panel.
            
            position = obj.ContainerComponent.Position;
            
        end

        function value = get.Layout(obj)
            value = obj.ContainerComponent.Layout;
        end
    end
    
    %----------------------------------------------------------------------
    % helper methods
    %----------------------------------------------------------------------
    methods(Access = protected)
        function hyperlinkHandler(~, ~, e)
            %HYPERLINKHANDLER - This handler allows a web browser to open
            %when hyperlinks are clicked.
            
            web(e.Data, '-browser');
        end
        
        function stylesheet = getStylesheet(obj)
            stylesheet = ['<style>'...
                ' html, body, table, tr, h1, h6 {'...
                '  padding: 0;'...
                ['  background-color:var(' matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput ');']...
                '  margin: 0;'...
                ' }'...
                ' body {'...
                ['  font-size: ' num2str(obj.FontSize) 'px;']...
                ['  color:var(' matlab.hwmgr.internal.hwsetup.util.Color.ColorPrimary ')']...
                ' }'...
                ' table {'...
                '  border-collapse: collapse;'...
                '  font-family: Helvetica;'...          
                [' font-size: ' num2str(obj.FontSize) 'px;']...
                '  width: 100%;'....
                ' }'...
                ' td, th {'...
                '  padding: 2;'...
                obj.BorderStyle...
                ' }'...
                ' th {'...
                ['  background-color:var(' matlab.hwmgr.internal.hwsetup.util.Color.BackgroundColorInput ');']...
                [' font-size: ' num2str(obj.FontSize) 'px;']...
                '  text-align: left;'...
                '  padding: 2px;'...
                ' }'...
                ' h1 {'...
                ['  color:var(' matlab.hwmgr.internal.hwsetup.util.Color.ColorListPrimary ')']...
                '  font-weight: bold;'...
                ' }'...
                ' h6, .hwsetup_error {'...
                ['  color:var(' matlab.hwmgr.internal.hwsetup.util.Color.ColorError ')']...
                '  font-weight: bold;'...
                [' font-size: ' num2str(obj.FontSize) 'px;']...
                ' }'...
                ' .hwsetup_warn {'...
                ['  color:var(' matlab.hwmgr.internal.hwsetup.util.Color.ColorMatlabWarning ')']...
                '  font-weight: bold;'...
                [' font-size: ' num2str(obj.FontSize) 'px;']...
                ' }'...
                '</style>'];
        end
        
        function script = getScript(~)
            script = ['<script type = "text/javascript">'...
                ' function setup(htmlComponent) {'...
                '  anchorTags = document.querySelectorAll("a");'...
                '  for (var k = 0, aTag; aTag = anchorTags[k]; k++ ) {'...
                '   let actualURL = aTag.href;'...
                '   aTag.href = "#!";'...
                '   aTag.onclick = function () {'...
                '    htmlComponent.Data = actualURL;'...
                '    return false;'...
                '   }'...
                '  }'...
                ' };'...
                '</script>'];
        end
    end
end
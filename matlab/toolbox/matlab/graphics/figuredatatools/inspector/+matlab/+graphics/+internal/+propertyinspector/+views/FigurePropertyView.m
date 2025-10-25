classdef FigurePropertyView < internal.matlab.inspector.InspectorProxyMixin
    % This class has the metadata information on the figure's property
    % groupings as reflected in the property inspector

    % Copyright 2017-2024 The MathWorks, Inc.

    properties
        NextPlot,
        DockControls,
        MenuBar,
        ToolBar,
        WindowStyle,
        ButtonDownFcn,
        CloseRequestFcn,
        CreateFcn,
        DeleteFcn,
        KeyPressFcn,
        KeyReleaseFcn,
        ResizeFcn,
        SizeChangedFcn,
        WindowButtonDownFcn,
        WindowButtonMotionFcn,
        WindowButtonUpFcn,
        WindowKeyPressFcn,
        WindowKeyReleaseFcn,
        WindowScrollWheelFcn,
        WindowState,
        Children,
        HandleVisibility,
        Parent,
        Visible,
        BeingDeleted,
        BusyAction,
        CurrentAxes,
        CurrentCharacter,
        CurrentObject,
        CurrentPoint,
        HitTest,
        Icon,
        Interruptible,
        Selected,
        SelectionHighlight,
        SelectionType,
        ContextMenu,
        Clipping,
        InnerPosition,
        OuterPosition,
        Position,
        Resize,
        Units,
        Pointer,
        PointerShapeCData,
        PointerShapeHotSpot,
        PaperOrientation,
        PaperPosition,
        PaperPositionMode,
        PaperSize,
        PaperType,
        PaperUnits,
        Name,
        Number,
        NumberTitle,
        IntegerHandle,
        Tag,
        Type,
        UserData,
        FileName,
        Alphamap,
        Color,
        Colormap,
        ThemeChangedFcn,
        ThemeMode
    end

    properties (Constant, Hidden)
        ValidThemeTypes = ["light","dark"]
    end

    properties (Dependent, SetObservable)
        Theme internal.matlab.editorconverters.datatype.StringEnumeration
    end

    methods
        function this = FigurePropertyView(obj)

            this@internal.matlab.inspector.InspectorProxyMixin(obj);

            %...............................................................

            g13 = this.createGroup('MATLAB:propertyinspector:WindowAppearance','','');
            g13.addProperties('Theme','MenuBar','ToolBar');
            g13.addSubGroup('DockControls','Color','WindowStyle','WindowState', 'ThemeMode');
            g13.Expanded = true;
            this.PropertyTypeMap("Theme") = 'inspector.internal.datatype.Theme';

            %...............................................................

            g10 = this.createGroup('MATLAB:propertyinspector:Position','','');
            g10.addEditorGroup('Position');
            g10.addProperties('Units');

            g10b = g10.addSubGroup();
            g10b.addEditorGroup('InnerPosition');
            g10b.addEditorGroup('OuterPosition');
            g10b.addProperties('Clipping',...
                'Resize');

            g10.Expanded = true;
            %...............................................................

            g2 = this.createGroup('MATLAB:propertyinspector:Plotting','','');
            g2.addProperties('Colormap','Alphamap','NextPlot');

            %...............................................................

            g12 = this.createGroup('MATLAB:propertyinspector:PrintingandExporting','','');

            g12.addEditorGroup('PaperPosition');
            g12.addProperties('PaperPositionMode');
            g12.addEditorGroup('PaperSize');
            
            g12.addProperties('PaperUnits','PaperOrientation','PaperType');                               
            %...............................................................                                     
            
            g11 = this.createGroup('MATLAB:propertyinspector:MousePointer','','');
            g11.addProperties('Pointer','PointerShapeCData','PointerShapeHotSpot');

            %...............................................................

            g8 = this.createGroup('MATLAB:propertyinspector:Interactivity','','');
            g8.addProperties('CurrentAxes','CurrentObject');
            g8.addEditorGroup('CurrentPoint');
            g8.addProperties('CurrentCharacter','Selected',...
                'SelectionHighlight','SelectionType','ContextMenu',...
                'Visible');

            %...............................................................


            g3 = this.createGroup('MATLAB:propertyinspector:CommonCallbacks','','');
            g3.addProperties('ButtonDownFcn','CreateFcn','DeleteFcn','ThemeChangedFcn');

            %...............................................................

            g4 = this.createGroup('MATLAB:propertyinspector:KeyboardCallbacks','','');
            g4.addProperties('KeyPressFcn','KeyReleaseFcn');

            %...............................................................

            g5 = this.createGroup('MATLAB:propertyinspector:WindowCallbacks','','');
            g5.addProperties('CloseRequestFcn','SizeChangedFcn','WindowButtonDownFcn',...
                'WindowButtonMotionFcn','WindowButtonUpFcn',...
                'WindowKeyPressFcn','WindowKeyReleaseFcn',...
                'WindowScrollWheelFcn','ResizeFcn');

            %...............................................................
            g9 = this.createGroup('MATLAB:propertyinspector:CallbackExecutionControl','','');
            g9.addProperties('Interruptible','BusyAction','HitTest','BeingDeleted');
            %...............................................................

            g6 = this.createGroup('MATLAB:propertyinspector:ParentChild','','');
            g6.addProperties('Parent','Children','HandleVisibility');

            %...............................................................

            g1 = this.createGroup('MATLAB:propertyinspector:Identifiers','','');
            g1.addProperties('Name','Icon','Number','NumberTitle','IntegerHandle','FileName','Type','Tag','UserData');
        end

        function set.Theme(obj, inspectorValue)
            if obj.InternalPropertySet
                return
            end

            if isa(inspectorValue, "internal.matlab.editorconverters.datatype.StringEnumeration")
                val = inspectorValue.Value;
            else
                val = inspectorValue;
            end

            if isa(val, "inspector.internal.datatype.Theme")
                val = char(inspectorValue);
            end
            obj.OriginalObjects.Theme = val;
        end

        function val = get.Theme(obj)
            th = obj.OriginalObjects.Theme;
            currValue = "light"; % assume light theme unless dark theme detected
            if ~isempty(th) && isequal(th,matlab.graphics.internal.themes.darkTheme)
                currValue = "dark";
            end
            val = internal.matlab.editorconverters.datatype.StringEnumeration(currValue, ...
                matlab.graphics.internal.propertyinspector.views.FigurePropertyView.ValidThemeTypes);
        end
    end
end

classdef MAPPIntegration < handle
    %MAPPINTEGRATION

%   Copyright 2024 The MathWorks, Inc.

    methods (Static)
        function map = getComponentMap()
            map = dictionary();

            %% Button
            comp = struct('InformalInterfaceName', 'uibutton', 'AdditionalArguments', 'push');
            comp.CallbackFunctions(1).CallbackName = 'ButtonPushedFcn';
            map('Button') = comp;

            %% ButtonGroup
            comp = struct('InformalInterfaceName', 'uibuttongroup');
            comp.CallbackFunctions(1).CallbackName = 'SelectionChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'SizeChangedFcn';
            comp.CallbackFunctions(3).CallbackName = 'ButtonDownFcn';
            map('ButtonGroup') = comp;

            %% CheckBox
            comp = struct('InformalInterfaceName', 'uicheckbox');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            map('CheckBox') = comp;

            %% CheckBoxTree
            comp = struct('InformalInterfaceName', 'uitree', 'AdditionalArguments', 'checkbox');
            comp.CallbackFunctions(1).CallbackName = 'CheckedNodesChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'SelectionChangedFcn';
            comp.CallbackFunctions(3).CallbackName = 'NodeExpandedFcn';
            comp.CallbackFunctions(4).CallbackName = 'NodeCollapsedFcn';
            comp.CallbackFunctions(5).CallbackName = 'NodeTextChangedFcn';
            map('CheckBoxTree') = comp;

            %% ColorPicker
            comp = struct('InformalInterfaceName', 'uicolorpicker');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            map('ColorPicker') = comp;

            %% ContextMenu
            comp = struct('InformalInterfaceName', 'uicontextmenu');
            comp.CallbackFunctions(1).CallbackName = 'ContextMenuOpeningFcn';
            map('ContextMenu') = comp;

            %% ContinuousKnob
            comp = struct('InformalInterfaceName', 'uiknob');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'ValueChangingFcn';
            map('Knob') = comp;

            %% DatePicker
            comp = struct('InformalInterfaceName', 'uidatepicker');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            map('DatePicker') = comp;

            %% DiscreteKnob
            comp = struct('InformalInterfaceName', 'uiknob', 'AdditionalArguments', 'discrete');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            map('DiscreteKnob') = comp;

            %% DropDown
            comp = struct('InformalInterfaceName', 'uidropdown');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'DropDownOpeningFcn';
            comp.CallbackFunctions(3).CallbackName = 'ClickedFcn';
            map('DropDown') = comp;

            %% EditField
            comp = struct('InformalInterfaceName', 'uieditfield', 'AdditionalArguments', 'text');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'ValueChangingFcn';
            map('EditField') = comp;

            %% Gauge
            comp = struct('InformalInterfaceName', 'uigauge', 'AdditionalArguments', 'circular');
            map('Gauge') = comp;

            %% GridLayout
            comp = struct('InformalInterfaceName', 'uigridlayout');
            map('GridLayout') = comp;

            %% HTML
            comp = struct('InformalInterfaceName', 'uihtml');
            comp.CallbackFunctions(1).CallbackName = 'DataChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'HTMLEventReceivedFcn';
            map('HTML') = comp;

            %% Hyperlink
            comp = struct('InformalInterfaceName', 'uihyperlink');
            comp.CallbackFunctions(1).CallbackName = 'HyperlinkClickedFcn';
            map('Hyperlink') = comp;

            %% Image
            comp = struct('InformalInterfaceName', 'uiimage');
            comp.CallbackFunctions(1).CallbackName = 'ImageClickedFcn';
            map('Image') = comp;

            %% Label
            comp = struct('InformalInterfaceName', 'uilabel');
            map('Label') = comp;

            %% Lamp
            comp = struct('InformalInterfaceName', 'uilamp');
            map('Lamp') = comp;

            %% LinearGauge
            comp = struct('InformalInterfaceName', 'uigauge', 'AdditionalArguments', 'linear');
            map('LinearGauge') = comp;

            %% ListBox
            comp = struct('InformalInterfaceName', 'uilistbox');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'ClickedFcn';
            comp.CallbackFunctions(3).CallbackName = 'DoubleClickedFcn';
            map('ListBox') = comp;

            %% Menu
            comp = struct('InformalInterfaceName', 'uimenu');
            comp.CallbackFunctions(1).CallbackName = 'MenuSelectedFcn';
            map('Menu') = comp;

            %% NinetyDegreeGauge
            comp = struct('InformalInterfaceName', 'uigauge', 'AdditionalArguments', 'ninetydegree');
            map('NinetyDegreeGauge') = comp;

            %% NumericEditField
            comp = struct('InformalInterfaceName', 'uieditfield', 'AdditionalArguments', 'numeric');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'ValueChangingFcn';
            map('NumericEditField') = comp;

            %% Panel
            comp = struct('InformalInterfaceName', 'uipanel');
            comp.CallbackFunctions(1).CallbackName = 'SizeChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'ButtonDownFcn';
            map('Panel') = comp;

            %% PushTool
            comp = struct('InformalInterfaceName', 'uipushtool');
            comp.CallbackFunctions(1).CallbackName = 'ClickedCallback';
            map('PushTool') = comp;

            %% RadioButton
            comp = struct('InformalInterfaceName', 'uiradiobutton');
            map('RadioButton') = comp;

            %% RangeSlider
            comp = struct('InformalInterfaceName', 'uislider', 'AdditionalArguments', 'range');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'ValueChangingFcn';
            map('RangeSlider') = comp;

            %% RockerSwitch
            comp = struct('InformalInterfaceName', 'uiswitch', 'AdditionalArguments', 'rocker');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            map('RockerSwitch') = comp;

            %% SemicircularGauge
            comp = struct('InformalInterfaceName', 'uigauge', 'AdditionalArguments', 'semicircular');
            map('SemicircularGauge') = comp;

            %% Slider
            comp = struct('InformalInterfaceName', 'uislider');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'ValueChangingFcn';
            map('Slider') = comp;

            %% Spinner
            comp = struct('InformalInterfaceName', 'uispinner');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'ValueChangingFcn';
            map('Spinner') = comp;

            %% StateButton
            comp = struct('InformalInterfaceName', 'uibutton', 'AdditionalArguments', 'state');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            map('StateButton') = comp;

            %% Switch
            comp = struct('InformalInterfaceName', 'uiswitch', 'AdditionalArguments', 'slider');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            map('Switch') = comp;

            %% Tab
            comp = struct('InformalInterfaceName', 'uitab');
            comp.CallbackFunctions(1).CallbackName = 'SizeChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'ButtonDownFcn';
            map('Tab') = comp;

            %% TabGroup
            comp = struct('InformalInterfaceName', 'uitabgroup');
            comp.CallbackFunctions(1).CallbackName = 'SelectionChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'ButtonDownFcn';
            map('TabGroup') = comp;

            %% Table
            comp = struct('InformalInterfaceName', 'uitable');
            comp.CallbackFunctions(1).CallbackName = 'CellEditCallback';
            comp.CallbackFunctions(2).CallbackName = 'SelectionChangedFcn';
            comp.CallbackFunctions(3).CallbackName = 'DisplayDataChangedFcn';
            comp.CallbackFunctions(4).CallbackName = 'CellSelectionCallback';
            comp.CallbackFunctions(5).CallbackName = 'ButtonDownFcn';
            comp.CallbackFunctions(6).CallbackName = 'KeyPressFcn';
            comp.CallbackFunctions(7).CallbackName = 'KeyReleaseFcn';
            comp.CallbackFunctions(8).CallbackName = 'ClickedFcn';
            comp.CallbackFunctions(9).CallbackName = 'DoubleClickedFcn';
            map('Table') = comp;

            %% TextArea
            comp = struct('InformalInterfaceName', 'uitextarea');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'ValueChangingFcn';
            map('TextArea') = comp;

            %% ToggleButton
            comp = struct('InformalInterfaceName', 'uitogglebutton');
            map('ToggleButton') = comp;

            %% ToggleSwitch
            comp = struct('InformalInterfaceName', 'uiswitch', 'AdditionalArguments', 'toggle');
            comp.CallbackFunctions(1).CallbackName = 'ValueChangedFcn';
            map('ToggleSwitch') = comp;

            %% ToggleTool
            comp = struct('InformalInterfaceName', 'uitoggletool');
            comp.CallbackFunctions(1).CallbackName = 'ClickedCallback';
            comp.CallbackFunctions(2).CallbackName = 'OnCallback';
            comp.CallbackFunctions(3).CallbackName = 'OffCallback';
            map('ToggleTool') = comp;

            %% Toolbar
            comp = struct('InformalInterfaceName', 'uitoolbar');
            map('Toolbar') = comp;

            %% Tree
            comp = struct('InformalInterfaceName', 'uitree');
            comp.CallbackFunctions(1).CallbackName = 'SelectionChangedFcn';
            comp.CallbackFunctions(2).CallbackName = 'NodeExpandedFcn';
            comp.CallbackFunctions(3).CallbackName = 'NodeCollapsedFcn';
            comp.CallbackFunctions(4).CallbackName = 'NodeTextChangedFcn';
            map('Tree') = comp;

            %% TreeNode
            comp = struct('InformalInterfaceName', 'uitreenode');
            map('TreeNode') = comp;

            %% UIAxes
            comp = struct('InformalInterfaceName', 'uiaxes');
            comp.CallbackFunctions(1).CallbackName = 'ButtonDownFcn';
            map('UIAxes') = comp;

            %% Figre
            comp = struct('InformalInterfaceName', 'uifigure');
            comp.CallbackFunctions(1).CallbackName = 'CloseRequestFcn';
            comp.CallbackFunctions(2).CallbackName = 'ButtonDownFcn';
            comp.CallbackFunctions(3).CallbackName = 'KeyPressFcn';
            comp.CallbackFunctions(4).CallbackName = 'SizeChangedFcn';
            comp.CallbackFunctions(5).CallbackName = 'ThemeChangedFcn';
            comp.CallbackFunctions(6).CallbackName = 'WindowButtonDownFcn';
            comp.CallbackFunctions(7).CallbackName = 'WindowButtonMotionFcn';
            comp.CallbackFunctions(8).CallbackName = 'WindowButtonUpFcn';
            comp.CallbackFunctions(9).CallbackName = 'WindowKeyPressFcn';
            comp.CallbackFunctions(10).CallbackName = 'WindowKeyReleaseFcn';
            comp.CallbackFunctions(11).CallbackName = 'KeyReleaseFcn';
            comp.CallbackFunctions(12).CallbackName = 'WindowScrollWheelFcn';
            map('UIFigure') = comp;
        end
    end
end

classdef LoopClosureFigureDocument < nav.slamapp.internal.FigureDocument

%This class is for internal use only. It may be removed in the future.

%LOOPCLOSUREFIGUREDOCUMENT Figure document for display of scan map or occupancy
%   grid map

% Copyright 2018-2024 The MathWorks, Inc.

    properties (Constant)
        %DefaultIconButtonSize
        DefaultIconButtonSize = [24, 24];
    end

    properties

        %PrevLoopClosureStepper
        PrevLoopClosureStepper

        %NextLoopClosureStepper
        NextLoopClosureStepper
    end

    methods
        function obj = LoopClosureFigureDocument(tag)
        %LoopClosureFigureDocument Constructor
            obj@nav.slamapp.internal.FigureDocument(tag);

            obj.Axes = axes(obj.Figure, 'Box', 'on', 'Units', 'normalized');
            obj.Axes.Visible = 'off';
            grid(obj.Axes, 'on');
            obj.Axes.DataAspectRatioMode = 'manual';
            obj.Axes.DataAspectRatio = [1 1 1];
            obj.Axes.PlotBoxAspectRatioMode = 'manual';
            obj.Axes.PlotBoxAspectRatio = [1 1 1];
            obj.Axes.Toolbar.Visible = 'off';

            view(obj.Axes, -90, 90);
            xlabel(obj.Axes, 'X');
            ylabel(obj.Axes, 'Y');

            hold(obj.Axes, 'on');
            obj.RefScanTransform = hgtransform('Parent', obj.Axes);
            obj.RefScanLineObj = plot(obj.RefScanTransform, 0,0,'.');
            rt = plot(obj.RefScanTransform, 0, 0, '.', 'MarkerSize', 2);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(obj.RefScanLineObj, "Color", obj.RefScanColor);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(rt, "Color", obj.RefScanColor);

            obj.RefScanXAxisLineObj = plot(obj.RefScanTransform, [0 1], [0 0]);
            obj.RefScanXAxisLineObj.Visible = 'off';
            matlab.graphics.internal.themes.specifyThemePropertyMappings(obj.RefScanXAxisLineObj, "Color", obj.ConnectorColor);

            obj.CurrentScanTransform = hgtransform('Parent', obj.Axes);
            obj.CurrentScanLineObj = plot(obj.CurrentScanTransform, 0,0, '.');
            ct = plot(obj.CurrentScanTransform, 0,0, '.', 'MarkerSize', 2);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(obj.CurrentScanLineObj, "Color", obj.CurrentScanColor);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(ct, "Color", obj.CurrentScanColor);

            obj.CurrentScanXAxisLineObj = plot(obj.CurrentScanTransform, [0 1], [0 0]);
            obj.CurrentScanXAxisLineObj.Visible = 'off';
            matlab.graphics.internal.themes.specifyThemePropertyMappings(obj.CurrentScanXAxisLineObj, "Color", obj.CurrentScanColor);

            obj.XYConnectorLineObj = plot(obj.Axes, 0, 0);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(obj.XYConnectorLineObj, "Color", obj.ConnectorColor);

            obj.clearScanPair();
            hold(obj.Axes, 'off');
             
            ibSize = obj.DefaultIconButtonSize;
            obj.BadgeModify = uibutton(obj.Figure, 'Position', [2 2 ibSize(1) ibSize(2)], 'Text', '','IconAlignment','leftmargin');
            matlab.ui.control.internal.specifyIconID(obj.BadgeModify, 'edit_LoopClosure', ibSize(1), ibSize(2));
            obj.BadgeModify.Visible = 'off';

            % creating backward and forward stepper buttons
            params = [];
            hspace = 5;
            axPos = obj.getAxesActualPlotBoxCoordinates;
            params.Position = [axPos(1)+axPos(3)+ hspace, axPos(2) + axPos(4) - ibSize(2), ibSize(1), ibSize(2)];
            params.BackgroundColor = "--mw-backgroundColor-primary";
            params.IconAlignment = 'leftmargin';
            params.Enable = 'on';
            params.TooltipString = obj.retrieveMsg('PrevLoopClosureStepperDescription');

            obj.PrevLoopClosureStepper = robotics.appscore.internal.createIconButton(obj.Figure, [obj.Figure.Tag '_PrevLoopClosureStepper'], params, 'stepBackwardUI', ibSize);
            obj.PrevLoopClosureStepper.Visible = 'off';

            params.Position = [axPos(1)+axPos(3)+ hspace, axPos(2) + axPos(4) - 2*ibSize(2) - hspace, ibSize(1), ibSize(2)];
            params.TooltipString = obj.retrieveMsg('NextLoopClosureStepperDescription');
            params.IconAlignment = 'rightmargin';
            obj.NextLoopClosureStepper = robotics.appscore.internal.createIconButton(obj.Figure, [obj.Figure.Tag '_NextLoopClosureStepper'], params, 'stepForwardUI', ibSize);
            obj.NextLoopClosureStepper.Visible = 'off';

            addlistener(obj.Figure, 'SizeChanged', @(src, evt) obj.repositionIconButton(hspace));
        end

        function show(obj, vis)
        %show
            if nargin == 1
                obj.Axes.Visible = 'on';
                obj.Axes.Toolbar.Visible = 'on';
            else
                obj.Axes.Visible = vis;
                obj.Axes.Toolbar.Visible = vis;
            end
        end

        function repositionIconButton(obj, hspace)
        %repositionIconButton
            axPos = getAxesActualPlotBoxCoordinates(obj);
            ibSize = obj.DefaultIconButtonSize;
            pos = [axPos(1)+axPos(3)+ hspace, axPos(2) + axPos(4) - ibSize(2), ibSize(1), ibSize(2)];
            obj.PrevLoopClosureStepper.Position = pos;

            pos = [axPos(1)+axPos(3)+ hspace, axPos(2) + axPos(4) - 2*ibSize(2) - hspace, ibSize(1), ibSize(2)];
            obj.NextLoopClosureStepper.Position = pos;

        end

        function restoreToInitState(obj)
        %restoreToInitState

            restoreToInitState@nav.slamapp.internal.FigureDocument(obj);
            obj.PrevLoopClosureStepper.Visible = 'off';
            obj.NextLoopClosureStepper.Visible = 'off';
        end

        function drawScanPair(obj, refScan, currScan, relPose, scanIdPair)
        %drawScanPair

            drawScanPair@nav.slamapp.internal.FigureDocument(obj, refScan, currScan, relPose, scanIdPair);

            obj.PrevLoopClosureStepper.Visible = 'on';
            obj.NextLoopClosureStepper.Visible = 'on';

        end
    end
end

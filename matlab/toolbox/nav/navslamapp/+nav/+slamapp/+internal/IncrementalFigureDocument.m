classdef IncrementalFigureDocument < nav.slamapp.internal.FigureDocument

%This class is for internal use only. It may be removed in the future.

%INCREMENTALFIGUREDOCUMENT Figure document for display of incremental
%   scan matching

% Copyright 2018-2024 The MathWorks, Inc.


    properties
        %DefaultIconButtonSize
        DefaultIconButtonSize = [24, 24];
    end

    methods
        function obj = IncrementalFigureDocument(tag)
        %IncrementalFigureDocument Constructor
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
            obj.CurrentScanXAxisLineObj = plot(obj.CurrentScanTransform, [0 1], [0 0]);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(obj.CurrentScanLineObj, "Color", obj.CurrentScanColor);
            matlab.graphics.internal.themes.specifyThemePropertyMappings(ct, "Color", obj.CurrentScanColor);  
            matlab.graphics.internal.themes.specifyThemePropertyMappings(obj.CurrentScanXAxisLineObj, "Color", obj.CurrentScanColor);    
            obj.CurrentScanXAxisLineObj.Visible = 'off';

            obj.XYConnectorLineObj = plot(obj.Axes, 0, 0);           
            matlab.graphics.internal.themes.specifyThemePropertyMappings(obj.XYConnectorLineObj, "Color", obj.ConnectorColor); 

            obj.clearScanPair();
            hold(obj.Axes, 'off');

            obj.BadgeModify = uibutton(obj.Figure, 'Position', [2 2 obj.DefaultIconButtonSize(1) obj.DefaultIconButtonSize(2)], 'Text','', 'IconAlignment','leftmargin');
            matlab.ui.control.internal.specifyIconID(obj.BadgeModify, 'edit_incremental', obj.DefaultIconButtonSize(1), obj.DefaultIconButtonSize(2));
            obj.BadgeModify.Visible = 'off';
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
    end
end

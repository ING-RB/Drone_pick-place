classdef (ConstructOnLoad, UseClassDefaultsOnLoad, Sealed) PolarRegion < ...
        matlab.graphics.primitive.Data & ...
        matlab.graphics.mixin.PolarAxesParentable & ...
        matlab.graphics.mixin.Selectable & ...
        matlab.graphics.mixin.Legendable & ...
        matlab.graphics.mixin.ColorOrderUser & ...
        matlab.graphics.internal.GraphicsUIProperties
    %

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (Dependent)
        ThetaSpan (1,2) {mustBeNumeric, mustBeReal} = [0 0]
        RadiusSpan (1,2) {mustBeNumeric, mustBeReal} = [0 0]
        FaceColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = '#7d7d7d'
        FaceAlpha matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = .3
        EdgeColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = 'none'
        LineStyle  matlab.internal.datatype.matlab.graphics.datatype.LineStyle = '-'
        LineWidth matlab.internal.datatype.matlab.graphics.datatype.Positive = .5
        Clipping  matlab.internal.datatype.matlab.graphics.datatype.on_off = true
        Layer  matlab.internal.datatype.matlab.graphics.datatype.AxisTopBottom = 'bottom'
    end

    properties (Hidden, Transient, NonCopyable, InternalComponent, AffectsObject, GetAccess = ?ChartUnitTestFriend, SetAccess=private)
        Face
        Edge
    end

    properties (Hidden, Transient, NonCopyable)
        SelectionHandle matlab.graphics.interactor.ListOfPointsHighlight
    end

    properties (Hidden, AffectsObject, AbortSet)
        ThetaSpan_I (1,2) {mustBeNumeric, mustBeReal} = [0 0]
        RadiusSpan_I (1,2) {mustBeNumeric, mustBeReal} = [0 0]
        Layer_I  matlab.internal.datatype.matlab.graphics.datatype.AxisTopBottom = 'bottom'
    end

    properties (Hidden, AffectsObject, AffectsLegend, AbortSet)
        FaceColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = '#7d7d7d'
        FaceAlpha_I matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = .3
        EdgeColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = 'none'
        LineStyle_I  matlab.internal.datatype.matlab.graphics.datatype.LineStyle = '-'
        LineWidth_I matlab.internal.datatype.matlab.graphics.datatype.Positive = .5
        Clipping_I  matlab.internal.datatype.matlab.graphics.datatype.on_off = true
    end

    properties (Hidden)
        ThetaSpanMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        RadiusSpanMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        FaceAlphaMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        EdgeColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        LineStyleMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        LineWidthMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        ClippingMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        LayerMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end

    properties (AffectsObject, AffectsLegend)
        FaceColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end

    properties (AffectsObject, Access = {?matlab.graphics.chart.internal.AbstractPieChart, ?ChartUnitTestFriend})
        RadiusOffset (1,1) double {mustBeFinite} = 0
    end

    methods(Access='protected', Hidden)
        function shortdisp = getPropertyGroups(~)
            shortdisp = matlab.mixin.util.PropertyGroup(...
                {'ThetaSpan','RadiusSpan','FaceColor','EdgeColor','LineStyle','LineWidth'});
        end
        function lbl = getDescriptiveLabelForDisplay(obj)
            lbl = obj.Tag;
            if isempty(lbl)
                lbl = obj.DisplayName;
            end
        end
    end
    methods(Access='protected', Static)
        function map = getThemeMap
            map = struct(FaceColor = "--mw-graphics-colorNeutral-region-primary");
        end
    end

    methods
        function obj = PolarRegion(varargin)
            obj.Face = matlab.graphics.primitive.world.TriangleStrip(Internal = true);
            obj.Edge = matlab.graphics.primitive.world.LineLoop(Internal = true);
            obj.Type = 'polarregion';
            obj.SeriesIndex_I = 'none';

            addDependencyConsumed(obj, {'colororder_linestyleorder'});
            matlab.graphics.chart.internal.ctorHelper(obj, varargin);
        end
    end

    methods (Hidden)
        doUpdate(obj, us)
        graphic = getLegendGraphic(obj, fontsize)
        extents = getXYZDataExtents(obj, transform, constraints)
    end

    % getters and setters
    methods
        function val = get.FaceColor(obj)
            if obj.FaceColorMode == "auto"
                forceFullUpdate(obj, 'all', 'FaceColor');
            end
            val = obj.FaceColor_I;
        end

        function val = get.FaceAlpha(obj)
            val = obj.FaceAlpha_I;
        end

        function val = get.EdgeColor(obj)
            val = obj.EdgeColor_I;
        end

        function val = get.LineStyle(obj)
            val = obj.LineStyle_I;
        end

        function val = get.LineWidth(obj)
            val = obj.LineWidth_I;
        end

        function val = get.Clipping(obj)
            val = obj.Clipping_I;
        end

        function val = get.Layer(obj)
            val = obj.Layer_I;
        end

        function val = get.ThetaSpan(obj)
            val = obj.ThetaSpan_I;
        end

        function val = get.RadiusSpan(obj)
            val = obj.RadiusSpan_I;
        end

        function set.FaceColor(obj, val)
            obj.FaceColorMode = 'manual';
            obj.FaceColor_I = val;
        end

        function set.FaceAlpha(obj, val)
            obj.FaceAlphaMode = 'manual';
            obj.FaceAlpha_I = val;
        end

        function set.EdgeColor(obj, val)
            obj.EdgeColorMode = 'manual';
            obj.EdgeColor_I = val;
        end

        function set.LineStyle(obj, val)
            obj.LineStyleMode = 'manual';
            obj.LineStyle_I = val;
        end

        function set.LineWidth(obj, val)
            obj.LineWidthMode = 'manual';
            obj.LineWidth_I = val;
        end

        function set.Clipping(obj, val)
            obj.ClippingMode = 'manual';
            obj.Clipping_I = val;
        end

        function set.Layer(obj, val)
            obj.LayerMode = 'manual';
            obj.Layer_I = val;
        end

        function set.ThetaSpan(obj, val)
            obj.ThetaSpanMode = 'manual';
            obj.ThetaSpan_I = val;
        end

        function set.RadiusSpan(obj, val)
            obj.RadiusSpanMode = 'manual';
            obj.RadiusSpan_I = val;
        end

        % Setter Fanouts
        function set.LineStyle_I(obj, val)
            if ~isempty(obj.Edge) %#ok<*MCSUP>
                hgfilter('LineStyleToPrimLineStyle', obj.Edge, val);
            end
            obj.LineStyle_I = val;
        end

        function set.LineWidth_I(obj, val)
            if ~isempty(obj.Edge) && obj.Edge.LineWidthMode == "auto"
                obj.Edge.LineWidth_I = val;
            end
            obj.LineWidth_I = val;
        end

        function set.Clipping_I(obj, val)
            if ~isempty(obj.Edge) && obj.Edge.ClippingMode == "auto"
                obj.Edge.Clipping_I = val;
            end
            if ~isempty(obj.Face) && obj.Face.ClippingMode == "auto"
                obj.Face.Clipping_I = val;
            end
            obj.Clipping_I = val;
        end

        function set.Edge(obj, val)
            % Apply fanouts when setting a new Edge primitive
            obj.Edge = val;
            if ~isempty(obj.Edge) 
                if obj.Edge.ClippingMode == "auto"
                    obj.Edge.Clipping_I = obj.Clipping_I;
                end
                if obj.Edge.LineWidthMode == "auto"
                    obj.Edge.LineWidth_I = obj.LineWidth_I;
                end
                hgfilter('LineStyleToPrimLineStyle', obj.Edge, obj.LineStyle);
            end
        end

        function set.Face(obj, val)
            % Apply fanouts when setting a new Face primitive
            obj.Face = val;
            if ~isempty(obj.Face) && obj.Face.ClippingMode == "auto"
                obj.Face.Clipping_I = obj.Clipping_I;
            end
        end
    end

    methods (Hidden)
        function actualValue = setParentImpl(obj, proposedValue)
            if isa(proposedValue, 'matlab.graphics.primitive.Group') || ...
                    isa(proposedValue, 'matlab.graphics.primitive.Transform')
                childName = fliplr(strtok(fliplr(class(obj)), '.'));
                targetName = fliplr(strtok(fliplr(class(proposedValue)), '.'));
                error(message('MATLAB:hg:InvalidParent',childName, targetName))
            end
            actualValue = proposedValue;
        end
    end
end

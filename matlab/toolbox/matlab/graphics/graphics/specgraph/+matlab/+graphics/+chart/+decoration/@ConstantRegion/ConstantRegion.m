%

%   Copyright 2023-2024 The MathWorks, Inc.

classdef (ConstructOnLoad, UseClassDefaultsOnLoad, Sealed) ConstantRegion < matlab.graphics.primitive.Data &...
        matlab.graphics.mixin.AxesParentable & matlab.graphics.mixin.Legendable &...
        matlab.graphics.internal.GraphicsUIProperties & ...
        matlab.graphics.mixin.Selectable & ...
        matlab.graphics.mixin.ColorOrderUser

    properties(Dependent, Hidden)
        PrimitiveChildEnabled matlab.lang.OnOffSwitchState = 'off';
    end

    properties (Hidden, AffectsDataLimits)
        Value_I {mustBeTwoElementsAndNumericDateTimeOrCategorical(Value_I)} = [0 0];
        InterceptAxis_I matlab.internal.datatype.matlab.graphics.chart.datatype.InterceptAxisType = 'y';
    end

    properties (Hidden, AffectsObject)
        Layer_I matlab.internal.datatype.matlab.graphics.datatype.AxisTopBottom = 'bottom';
    end

    properties(Transient, NonCopyable, Hidden, Access={?tConstantRegion,?tPrimitiveContainerConstantRegion, ...
            ?matlab.graphics.interaction.graphicscontrol.InteractionObjects.ConstantRegionResizeInteraction})
        Region matlab.graphics.primitive.world.TriangleStrip;
        Edge matlab.graphics.primitive.world.LineStrip;
        SelectionHandle matlab.graphics.interactor.ListOfPointsHighlight;
        PrimitiveChild matlab.graphics.primitive.world.ConstantRegionPrimitive;
    end

    properties (Dependent)
        Value {mustBeTwoElementsAndNumericDateTimeOrCategorical(Value)} = [0 0];
        InterceptAxis matlab.internal.datatype.matlab.graphics.chart.datatype.InterceptAxisType = 'y';
        LineWidth matlab.internal.datatype.matlab.graphics.datatype.Positive = 0.5;
        EdgeColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = 'none';
        EdgeAlpha matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 1;
        LineStyle matlab.internal.datatype.matlab.graphics.datatype.LineStyle = '-';
        FaceColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = '#7d7d7d';
        FaceAlpha matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.3;
        Layer matlab.internal.datatype.matlab.graphics.datatype.AxisTopBottom = 'bottom';
    end

    properties (Hidden, AffectsObject, AffectsLegend)
        LineWidth_I matlab.internal.datatype.matlab.graphics.datatype.Positive = 0.5;
        EdgeColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = 'none';
        EdgeAlpha_I matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 1;
        LineStyle_I matlab.internal.datatype.matlab.graphics.datatype.LineStyle = '-';
        FaceColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = '#7d7d7d';
        FaceAlpha_I matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.3;
    end

    properties
        FaceColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
    end

    properties (Hidden)
        LineWidthMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        EdgeColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        EdgeAlphaMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        LineStyleMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        FaceAlphaMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        LayerMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';
        PrimitiveChildEnabled_I matlab.lang.OnOffSwitchState = 'off';
        PrimitiveChildEnabledMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';

    end

    methods
        function storedValue = get.Value(obj)
            storedValue = obj.Value_I;
        end

        function set.Value(obj, newValue)
            obj.Value_I = newValue;
        end

        function storedValue = get.InterceptAxis(obj)
            storedValue = obj.InterceptAxis_I;
        end

        function set.InterceptAxis(obj, newValue)
            obj.InterceptAxis_I = newValue;
        end

        function storedValue = get.FaceColor(obj)
            if obj.FaceColorMode == "auto"
                forceFullUpdate(obj, 'all', 'FaceColor')
            end
            storedValue = obj.FaceColor_I;
        end

        function set.FaceColor(obj, newValue)
            obj.FaceColor_I = newValue;
            obj.FaceColorMode = 'manual';
        end

        function storedValue = get.FaceAlpha(obj)
            storedValue = obj.FaceAlpha_I;
        end

        function set.FaceAlpha(obj, newValue)
            obj.FaceAlpha_I = newValue;
            obj.FaceAlphaMode = 'manual';
        end

        function storedValue = get.EdgeColor(obj)
            storedValue = obj.EdgeColor_I;
        end

        function set.EdgeColor(obj, newValue)
            obj.EdgeColor_I = newValue;
            obj.EdgeColorMode = 'manual';
        end

        function storedValue = get.EdgeAlpha(obj)
            storedValue = obj.EdgeAlpha_I;
        end
        
        function set.EdgeAlpha(obj, newValue)
            obj.EdgeAlpha_I = newValue;
            obj.EdgeAlphaMode = 'manual';
        end

        function storedValue = get.LineWidth(obj)
            storedValue = obj.LineWidth_I;
        end

        function set.LineWidth(obj, newValue)
            obj.LineWidth_I = newValue;
            obj.LineWidthMode = 'manual';
        end

        function storedValue = get.LineStyle(obj)
            storedValue = obj.LineStyle_I;
        end

        function set.LineStyle(obj, newValue)
            obj.LineStyle_I = newValue;
            obj.LineStyleMode = 'manual';
        end

        function set.FaceColorMode(obj, newValue)
            if newValue == "auto" && obj.FaceColorMode == "manual"
                obj.MarkDirty('all');
            end
            obj.FaceColorMode = newValue;
        end

        function storedValue = get.PrimitiveChildEnabled(obj)
            storedValue = obj.PrimitiveChildEnabled_I;
        end

        function set.PrimitiveChildEnabled(obj, newValue)
           obj.PrimitiveChildEnabled_I = newValue; 
           obj.PrimitiveChildEnabledMode = 'manual';
        end

        function set.Layer(obj, newValue)
            obj.Layer_I = newValue;
            obj.LayerMode = 'manual';
        end

        function storedValue = get.Layer(obj)
            storedValue = obj.Layer_I;
        end
    end

    methods (Hidden)
        function hObj = ConstantRegion(varargin)
            args = varargin;

            % Create underlying trianglestrip for the surface
            hTriangleStrip = matlab.graphics.primitive.world.TriangleStrip;
            hTriangleStrip.ColorBinding_I = 'object';
            hTriangleStrip.ColorType_I = 'truecoloralpha';
            hTriangleStrip.Internal = true;
            hTriangleStrip.StripData = uint32([1 5]);
            hObj.addNode(hTriangleStrip);
            hObj.Region = hTriangleStrip;
            hObj.Type = 'constantregion';
            hObj.addDependencyConsumed({'xyzdatalimits', 'view' 'colororder_linestyleorder'});

            % Create underlying linestrip for the two edges.
            hLineStrip = matlab.graphics.primitive.world.LineStrip;
            hLineStrip.ColorBinding_I = 'object';
            hLineStrip.ColorType_I = 'truecoloralpha';
            hLineStrip.AlignVertexCenters = 'on';
            hLineStrip.Internal = true;
            hObj.addNode(hLineStrip);
            hObj.Edge = hLineStrip;

            hObj.SeriesIndex_I = "none";
            matlab.graphics.chart.internal.ctorHelper(hObj, args);

            hPrimChild = matlab.graphics.primitive.world.ConstantRegionPrimitive;
            hPrimChild.Internal = true;
            hObj.addNode(hPrimChild);
            hObj.PrimitiveChild = hPrimChild;
        end

        function doUpdate(hObj, us)
            hRegion = hObj.Region;
            hEdge = hObj.Edge;
            primChild = hObj.PrimitiveChild;

            % Need to translate the user API with internal one for
            % primitive object's and their Layer.
            if strcmp(hObj.Layer, 'top')
                layerValue = 'front';
            else
                layerValue = 'back';
            end
            hRegion.Layer = layerValue;
            hEdge.Layer = layerValue;
            primChild.Layer = layerValue;

            if strcmp(hObj.PrimitiveChildEnabledMode, 'auto')
                hObj.PrimitiveChildEnabled_I = usePrimitiveContainer(us, hObj);
            end

            didapply = hObj.applyColor(us, 'FaceColor');
            % Compatibility layer: ConstantRegion overrides the default
            % none color.
            if didapply && isequal(hObj.SeriesIndex_I,"none")
                set(hObj,'FaceColor_I','factory')
            end

            % If FaceColor is 'none' and Alpha is 1, hgfilter cannot
            % interpret them when 1 is cast to char. 
            if strcmp(hObj.FaceColor_I, 'none')
                faceColor = hObj.FaceColor_I;
            else
                faceColor = [hObj.FaceColor_I hObj.FaceAlpha];
            end

            % Same thing for Edge
            if strcmp(hObj.EdgeColor, 'none')
                edgeColor = hObj.EdgeColor;
            else
                edgeColor = [hObj.EdgeColor hObj.EdgeAlpha];
            end

            hgfilter('RGBAColorToGeometryPrimitive', hRegion, faceColor);
            hgfilter('RGBAColorToGeometryPrimitive', hEdge, edgeColor);
            hEdge.LineWidth = hObj.LineWidth;
            hgfilter('LineStyleToPrimLineStyle', hEdge, hObj.LineStyle);

            ds = us.DataSpace;

            % The user passed in values need to be validated and converted
            % based on their dataspace. In this process, we also find out
            % which edges need to be drawn.
            [values, edgesToDraw] = updateUserValuesToVerticesAndDetermineWhichEdgesToDraw(hObj, ds);

            values = adjustDataIfCategorical(iscategorical(hObj.Value(1)), values);

            % Converts datetime, duration, categorical to be plotted
            switch hObj.InterceptAxis
                case 'x'
                    xVertsRegion = values([1 1 2 2]);
                    yVertsRegion = ds.YLim([1 2 1 2]);
                case 'y'
                    xVertsRegion = ds.XLim([1 2 1 2]);
                    yVertsRegion = values([1 1 2 2]);
            end

            % Calculate the ZVerts first since they don't depend on the
            % InterceptAxis
            zVal = mean(ds.ZLim);
            zVertsRegion = [zVal zVal zVal zVal zVal zVal];

            iter = matlab.graphics.axis.dataspace.XYZPointsIterator;
            set(iter, 'XData', xVertsRegion, 'YData', yVertsRegion, 'ZData', zVertsRegion);
            transformedVertices = TransformPoints(us.DataSpace, us.TransformUnderDataSpace,iter);
            hRegion.VertexData = transformedVertices;
            hEdge.VertexData = hRegion.VertexData(:,edgesToDraw);

            if any(ismissing(values))
                hObj.Edge.Visible = 'off';
                hObj.Region.Visible = 'off';
                hObj.PrimitiveChild.Visible = 'off';
            elseif hObj.PrimitiveChildEnabled
                % Set Visibility 
                primChild.Visible = hObj.Visible;
                hRegion.Visible = 'off';
                hEdge.Visible = 'off';

                % Set the upper and lower values for the ConstnatRegion
                % based on the transformed vertices. Preserve the value if
                % it's infinite though.
                if ~iscategorical(hObj.Value(1))
                    sortedVals = sort(hObj.Value);
                    primChild.LowerValueIsInf = ~isfinite(sortedVals(1));
                    primChild.UpperValueIsInf = ~isfinite(sortedVals(2));
                end

                switch hObj.InterceptAxis
                    case 'x'
                        idx = 1;
                    case 'y'
                        idx = 2;
                end
                primChild.LowerValue = double(min(transformedVertices(idx,:)));
                primChild.UpperValue = double(max(transformedVertices(idx,:)));

                primChild.InterceptAxis = hObj.InterceptAxis;
                primChild.LineWidth = hObj.LineWidth;
                hgfilter('RGBAColorToGeometryPrimitive', primChild, faceColor);
                hgfilter('LineStyleToPrimLineStyle', primChild, hObj.LineStyle);

                % Since we're not passing edgecolor to hgfilter, need to
                % verify the color isn't 'none'. Emulate this by just
                % turning Alpha to 0. 
                if strcmp(edgeColor, 'none')
                    edgeColor = [0 0 0 0];
                end
                primitiveEdgeColor = uint8(edgeColor*255);
                primChild.EdgeColorData = primitiveEdgeColor';
                primChild.EdgeColorType = "truecoloralpha";
            else
                % Set Visibility
                primChild.Visible = 'off';
                hRegion.Visible = hObj.Visible;
                hEdge.Visible = hObj.Visible;
            end

            % Draw the Selection Handles
            if strcmp(hObj.Visible,'on') && strcmp(hObj.Selected,'on') && strcmp(hObj.SelectionHighlight,'on')
                if isempty(hObj.SelectionHandle)
                    hObj.SelectionHandle = matlab.graphics.interactor.ListOfPointsHighlight;
                    hObj.SelectionHandle.Internal = true;
                    hObj.addNode(hObj.SelectionHandle);
                    hObj.SelectionHandle.Description = 'ConstantRegion SelectionHandle';
                end

                if strcmp(hObj.Layer, 'top')
                    hObj.SelectionHandle.Layer = 'front';
                else
                    hObj.SelectionHandle.Layer = 'back';
                end

                hObj.SelectionHandle.Visible = true;
                hObj.SelectionHandle.VertexData = hObj.Edge.VertexData;
            elseif ~isempty(hObj.SelectionHandle)
                hObj.SelectionHandle.VertexData = [];
                hObj.SelectionHandle.Visible = 'off';
            end
        end

        function extents = getXYZDataExtents(hObj, ~, ~)
            % Cull out any inf values.
            values = hObj.Value(~isinf(hObj.Value));

            switch hObj.InterceptAxis
                case 'x'
                    [xnumeric, ~] = matlab.graphics.internal.makeNumeric(hObj, values, NaN);
                    [x, y, z] = matlab.graphics.chart.primitive.utilities.arraytolimits(xnumeric, NaN, NaN);
                case 'y'
                    [~, ynumeric] = matlab.graphics.internal.makeNumeric(hObj, NaN, values);
                    [x, y, z] = matlab.graphics.chart.primitive.utilities.arraytolimits(NaN, ynumeric, NaN);
            end
            extents = [x;y;z];
        end

        mcodeConstructor(hObj, hCode)

        %Allows to appear in legend
        function icon = getLegendGraphic(obj)
            icon = matlab.graphics.primitive.world.Group;

            face = matlab.graphics.primitive.world.TriangleStrip( ...
                Parent = icon, ...
                VertexData = single([0 0 1 1; 0 1 0 1; 0 0 0 0]), ...
                StripData = uint32([1 5]));
            color = obj.FaceColor_I;
            if ~isequal(color, "none")
                color = [color obj.FaceAlpha_I];
            end
            hgfilter('RGBAColorToGeometryPrimitive', face, color);
            if ~isequal(obj.EdgeColor_I, "none")
                edge = matlab.graphics.primitive.world.LineLoop( ...
                    Parent = icon, ...
                    VertexData = single([0 0 1 1;0 1 1 0; 0 0 0 0]), ...
                    StripData = uint32([1 5]), ...
                    LineWidth = obj.LineWidth_I, ...
                    LineJoin = 'miter', ...
                    AlignVertexCenters = 'on');
                hgfilter('LineStyleToPrimLineStyle', edge, obj.LineStyle_I);
                hgfilter('RGBAColorToGeometryPrimitive', edge, [obj.EdgeColor_I obj.EdgeAlpha_I]);
            end
        end
        
        function actualValue = setParentImpl(~, proposedValue)
            if isa(proposedValue, 'matlab.graphics.primitive.Group') || ...
                    isa(proposedValue, 'matlab.graphics.primitive.Transform')
                error(message('MATLAB:graphics:constantline:InvalidParent'));
            end
            actualValue = proposedValue;
        end

    end

    methods(Access = 'protected')
        function groups = getPropertyGroups(~)
            % For short disp
            groups = matlab.mixin.util.PropertyGroup({'InterceptAxis',...
                'Value', 'FaceColor', 'LineStyle', 'LineWidth', 'Label'});
        end

        function varargout = getDescriptiveLabelForDisplay(hObj)
            if ~isempty(hObj.Tag)
                varargout{1} = hObj.Tag;
            else
                varargout{1} = hObj.DisplayName;
            end
        end
    end

    methods (Access='protected', Static)
        function map = getThemeMap
            map = struct('FaceColor', '--mw-graphics-colorNeutral-region-primary');
        end
    end

end

function sortedVals = adjustDataIfCategorical(dataIsCategorical, sortedVals)
    % Categorical regions should highlight the area surrounding the value
    % such that if you specify the same categorical value twice, the value
    % should be visible unlike other datatypes. We achieve this by padding
    % it by 0.5
    if dataIsCategorical
        sortedVals = sortedVals + [-0.5 0.5];
    end
end

function [sortedVals, edgesToDraw] = updateUserValuesToVerticesAndDetermineWhichEdgesToDraw(hObj, ds)
% The values the user passed in need to be converted to vertex data. Inf
% and 0 in log scale have special behavior regarding both the Region and
% the Edge which are determined by other helper functions.

switch hObj.InterceptAxis
    case 'x'
        [rawNumericValues, ~] = matlab.graphics.internal.makeNumeric(hObj, hObj.Value, []);
        lims = ds.XLim;
        scale = ds.XScale;
    case 'y'
        [~, rawNumericValues] = matlab.graphics.internal.makeNumeric(hObj, [], hObj.Value);
        lims = ds.YLim;
        scale = ds.YScale;
end

% If any of the values are returned as NaN, neither the edge nor the region
% is rendered.
sortedVals = sort(rawNumericValues);
sortedVals = adjustForLogScale(sortedVals, lims, scale);
[sortedVals, edgesToDraw] = updateInfValuesAndDetermineWhichEdgesToDraw(sortedVals, lims);
end

function [values, edgesToDraw] = updateInfValuesAndDetermineWhichEdgesToDraw(values, limits)
% Update infinite values such that they represent their corresponding
% limit. i.e. -inf is the lower limit and inf is the upper limit.
% Additionally, grab the logical indices for which Edge to draw from the
% Region's 4 data points in its VertexData.

finite = isfinite(values);

% Only draw the edges which are finite. i.e. we don't want to draw an edge
% at the lower limits if a value is -inf. 
edgesToDraw = finite([1 1 2 2]);

% Replace -infinity/+infinity with the lower/upper limit.
values(values==-inf) = limits(1);
values(values==inf) = limits(2);

end

function values = adjustForLogScale(values, limits, scale)
% If we're in a positive log scale: 
% -Inf and Inf behave the same as in linear scale.
% 0 behaves like -Inf
% Negative finite values behave like NaN.
% The opposite is true for negative log scale. 

if strcmp(scale, 'log')
    if limits(1) > 0
        % Positive log scale
        values(values==0) = -Inf;
        values(values<0 & isfinite(values)) = NaN;
    else
        % Negative log scale
        values(values==0) = Inf;
        values(values>0 & isfinite(values)) = NaN;
    end
end

end

function usePrimitive = usePrimitiveContainer(updateState, hObj)
    if ~(hObj.Selected && hObj.SelectionHighlight) && isa(updateState.Canvas, 'matlab.graphics.primitive.canvas.HTMLCanvas') && ~updateState.Canvas.ServerSideRendering
        % Bail when using Selection handles since those aren't on the
        % client yet.
        usePrimitive = true;
    else
        usePrimitive = false;
    end
end

function mustBeTwoElementsAndNumericDateTimeOrCategorical(data)
if numel(data) ~= 2
    error(message('MATLAB:graphics:constantline:ValueMustBeTwoElements'));
end

if~(isnumeric(data) || isdatetime(data) || iscategorical(data) || isduration(data))
    error(message('MATLAB:graphics:constantline:InvalidData'));
elseif isnumeric(data)
    if any(~isreal(data))
        error(message('MATLAB:graphics:constantline:ComplexValue', 'Value'));
    end
end

end

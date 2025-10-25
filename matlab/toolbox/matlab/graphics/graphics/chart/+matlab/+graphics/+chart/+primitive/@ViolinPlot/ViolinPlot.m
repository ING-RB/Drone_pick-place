classdef (ConstructOnLoad, UseClassDefaultsOnLoad, Sealed) ViolinPlot <...
        matlab.graphics.primitive.Data ...
        & matlab.graphics.mixin.DataProperties ...
        & matlab.graphics.internal.GraphicsUIProperties ...
        & matlab.graphics.mixin.ColorOrderUser ...
        & matlab.graphics.mixin.Legendable ...
        & matlab.graphics.mixin.AxesParentable ...
        & matlab.graphics.chart.interaction.DataAnnotatable ...
        & matlab.graphics.mixin.GraphicsPickable ...
        & matlab.graphics.mixin.Selectable

    %

    %   Do not remove above white space.

    %   Copyright 2023-2024 The MathWorks, Inc.

    % Data properties
    properties(Dependent)
        % Data that appears along the x-axis
        XData
        % Data that is used for computing distributions
        YData
        % PDF - outline of the violins:
        EvaluationPoints (:,:) {mustBeFloat,mustBeReal,mustBeNonsparse,mustBeFinite} = []
        DensityValues (:,:) {mustBeNumeric,mustBeReal} = []
    end

    properties(NeverAmbiguous)
        XDataMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        YDataMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end
    properties(NeverAmbiguous, AffectsObject, AbortSet)
        EvaluationPointsMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        DensityValuesMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end

    % Data internal properties
    properties(Hidden, Dependent, AffectsObject, AffectsDataLimits)
        XData_I = []
        YData_I = []
    end
    properties(Hidden, AffectsObject, AffectsDataLimits)
        EvaluationPoints_I (:,:) {mustBeFloat,mustBeReal,mustBeNonsparse,mustBeFinite} = []
        DensityValues_I (:,:) {mustBeNumeric,mustBeReal} = []
    end

    properties (Hidden, Dependent, SetAccess=private)
        XDataCache
    end

    properties (Dependent)
        XVariable = ''
        YVariable = ''
    end

    properties (Hidden, Dependent)
        XVariable_I = ''
        YVariable_I = ''
    end

    % XGroupData related properties.
    properties(Transient, NonCopyable, Access = {?ChartTestFriend})
        XGroupPositions
        XGroupIndex
        XNumGroups
    end
    properties(Hidden, Transient, NonCopyable, GetAccess='public', SetAccess='protected')
        XNumPerGroup
        MaxDensityValues
    end

    properties (Hidden, Access='protected', Transient, NonCopyable)
        XDataDirty (1,1) logical = true
        YDataDirty (1,1) logical = true
        EvaluationPointsNeedCompute (1,1) logical = true
        DensityValuesNeedCompute (1,1) logical = true
    end

    properties(Hidden, Transient, NonCopyable, Access = {?ChartTestFriend})
        % Number of evaluation points per violin
        numEvalPts (1,1) {mustBeInteger, mustBePositive,...
            mustBeLessThan(numEvalPts,4096)} = 100
    end

    properties(Transient, NonCopyable, Access = {?ChartTestFriend})
        % Store the vertices in data units for use by data tips.
        DataTipsVertexData
    end


    % Graphics Handles: Internal handles to world primitives
    properties(Hidden, Transient, NonCopyable, Access = {?ChartTestFriend})
        Face (:,1) matlab.graphics.primitive.world.TriangleStrip
        Edge (:,1) matlab.graphics.primitive.world.LineLoop
    end

    properties (Hidden, Transient, NonCopyable)
        SelectionHandle matlab.graphics.interactor.ListOfPointsHighlight
    end

    % Edge and Face spec properties
    properties(Dependent, SetObservable)
        % Specify face color for the violin
        FaceColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = '#0072BD'

        % Specify transparency for the violin
        FaceAlpha matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.2

        % Specify color for violin edges.
        EdgeColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = '#0072BD'

        % Specify style for violin edge lines
        LineStyle  matlab.internal.datatype.matlab.graphics.datatype.LineStyle = '-'

        % Specify width for violin edge lines
        LineWidth matlab.internal.datatype.matlab.graphics.datatype.Positive = 0.5

        % Clipping:
        Clipping  matlab.internal.datatype.matlab.graphics.datatype.on_off = true
    end

    % Edge and Face spec internal properties
    properties(Hidden, AffectsObject, AffectsLegend, AbortSet)
        FaceColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = '#0072BD'
        FaceAlpha_I matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 0.2
        EdgeColor_I matlab.internal.datatype.matlab.graphics.datatype.RGBAColor = '#0072BD'
        LineStyle_I  matlab.internal.datatype.matlab.graphics.datatype.LineStyle = '-'
        LineWidth_I matlab.internal.datatype.matlab.graphics.datatype.Positive = 0.5
        Clipping_I  matlab.internal.datatype.matlab.graphics.datatype.on_off = true
    end

    % Display related properties
    properties(Dependent)
        % Width of violins. Applies to the violin with the maximum density value
        DensityWidth matlab.internal.datatype.matlab.graphics.datatype.Positive = 0.9

        % Normalized space that groups take up, relative to XDataUnitWidth_I:
        ColorGroupWidth matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 1
    end
    properties(Dependent,AbortSet)
        % Orientation - vertical(default) or horizontal
        Orientation matlab.internal.datatype.matlab.graphics.datatype.HorizontalVertical = 'vertical'

        % Layout of color groups - grouped(default) or overlaid
        ColorGroupLayout matlab.internal.datatype.matlab.graphics.datatype.ColorGroupLayout = 'grouped'

        % Directions to plot violin - 'both' (default), 'positive','negative'
        DensityDirection matlab.internal.datatype.matlab.graphics.datatype.DensityDirection = 'both'

        % How to scale each violin - 'area' (default), 'count','width'
        DensityScale matlab.internal.datatype.matlab.graphics.datatype.DensityScale = 'area'
    end
    properties(Hidden, AffectsObject)
        Orientation_I matlab.internal.datatype.matlab.graphics.datatype.HorizontalVertical = 'vertical'
        ColorGroupLayout_I matlab.internal.datatype.matlab.graphics.datatype.ColorGroupLayout = 'grouped'
        ColorGroupWidth_I matlab.internal.datatype.matlab.graphics.datatype.ZeroToOne = 1
        DensityDirection_I matlab.internal.datatype.matlab.graphics.datatype.DensityDirection = 'both'
        DensityWidth_I matlab.internal.datatype.matlab.graphics.datatype.Positive = 0.9
        DensityScale_I matlab.internal.datatype.matlab.graphics.datatype.DensityScale = 'area'
    end

    % Public mode properties
    properties(AbortSet, AffectsObject, AffectsLegend)
        FaceColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        EdgeColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end
    properties(AbortSet, AffectsObject)
        ColorGroupWidthMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end

    % Properties that store internal modes
    properties(Hidden, AbortSet)
        FaceAlphaMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        LineStyleMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        LineWidthMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        OrientationMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        ColorGroupLayoutMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        DensityWidthMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        DensityDirectionMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        DensityScaleMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
        ClippingMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto'
    end

    properties(Hidden)
        % Peer ID: The rank of this object among it's peers
        PeerID matlab.internal.datatype.matlab.graphics.datatype.Positive = 1

        % Peers of this ViolinPlot
        ViolinPeers (:,1) matlab.graphics.chart.primitive.ViolinPlot

        % A mode property to indicate whether GroupByColor was specified
        % as a Name-Value pair to violinplot()
        GroupByColorMode matlab.internal.datatype.matlab.graphics.datatype.AutoManual = 'auto';

        % If we set the default width, then it should be 0.9 times this:
        XDataUnit_I matlab.internal.datatype.matlab.graphics.datatype.Positive = 1
    end
    properties(Hidden, AffectsObject)
        % Number of distinct categories for grouping based on color
        NumColorGroups matlab.internal.datatype.matlab.graphics.datatype.Positive = 1
    end



    % Constructor
    methods
        function obj = ViolinPlot(varargin)
            % Object type
            obj.Type = 'violinplot';

            % Add dependencies
            obj.addDependencyConsumed({'colororder_linestyleorder'});

            internalModeStorage = true;
            obj.linkDataPropertyToChannel('XData', 'X', internalModeStorage);
            obj.linkDataPropertyToChannel('YData', 'Y', internalModeStorage);

            % Initialize graphics objects
            % TriangleStrip for the violin face
            obj.Face = matlab.graphics.primitive.world.TriangleStrip(...
                Internal = true, Description = 'Violin Face');
            obj.addNode(obj.Face);
            % LineLoop for the violin edge
            obj.Edge = matlab.graphics.primitive.world.LineLoop(...
                Internal = true, Description = 'Violin Edge',...
                AlignVertexCenters = 'off');
            obj.addNode(obj.Edge);

            % Process Name/Value pairs
            matlab.graphics.chart.internal.ctorHelper(obj, varargin);
        end
    end


    % Get/Set methods
    methods

        % X properties get/set methods:
        function set.XData(obj, value)
            obj.setDataPropertyValue("X", value, false);
        end
        function set.XDataMode(obj, mode)
            currentMode = obj.XDataMode;
            if currentMode == "manual" && mode == "auto"
                obj.XData_I = [];
                % Handle automatically creating x-data:
                obj.setDefaultXData
            end
            obj.setDataPropertyMode("X", mode);
        end
        function set.XData_I(obj, value)
            obj.setDataPropertyValue("X", value, true);
        end
        function set.XVariable(obj, value)
            obj.setVariablePropertyValue("X", value, false);
        end
        function set.XVariable_I(obj, value)
            obj.setVariablePropertyValue("X", value, true);
        end
        function value = get.XData(obj)
            % Handle automatically creating x-data, if needed:
            obj.setDefaultXData
            value = obj.getDataPropertyValue("X", false);
        end
        function mode = get.XDataMode(obj)
            mode = obj.getDataPropertyMode("X");
        end
        function value = get.XData_I(obj)
            % Intentionally does not run obj.setDefaultXData
            value = obj.getDataPropertyValue("X", true);
        end
        function value = get.XVariable(obj)
            value = obj.getVariablePropertyValue("X", false);
        end
        function value = get.XVariable_I(obj)
            value = obj.getVariablePropertyValue("X", true);
        end
        function value = get.XDataCache(obj)
            % Intentionally does not run obj.setDefaultXData
            value = obj.getDataPropertyNumericValue("X", false);
        end

        % Y properties get/set methods:
        function set.YData(obj, value)
            obj.setDataPropertyValue("Y", value, false);
        end
        function set.YDataMode(obj, mode)
            obj.setDataPropertyMode("Y", mode);
        end
        function set.YData_I(obj, value)
            obj.setDataPropertyValue("Y", value, true);
        end
        function set.YVariable(obj, value)
            obj.setVariablePropertyValue("Y", value, false);
        end
        function set.YVariable_I(obj, value)
            obj.setVariablePropertyValue("Y", value, true);
        end
        function value = get.YData(obj)
            value = obj.getDataPropertyValue("Y", false);
        end
        function mode = get.YDataMode(obj)
            mode = obj.getDataPropertyMode("Y");
        end
        function value = get.YData_I(obj)
            value = obj.getDataPropertyValue("Y", true);
        end
        function value = get.YVariable(obj)
            value = obj.getVariablePropertyValue("Y", false);
        end
        function value = get.YVariable_I(obj)
            value = obj.getVariablePropertyValue("Y", true);
        end

        % EvaluationPoints get/set methods
        function evalPts = get.EvaluationPoints(obj)
            if strcmpi(obj.EvaluationPointsMode,'auto')
                forceFullUpdate(obj,'all','EvaluationPoints');
            end
            evalPts = obj.EvaluationPoints_I;
        end
        function set.EvaluationPoints(obj, evalPts)
            if isvector(evalPts)
                evalPts = evalPts(:);
            end
            obj.EvaluationPoints_I = evalPts;
            obj.EvaluationPointsMode = 'manual';
            obj.EvaluationPointsNeedCompute = false;
            obj.DensityValuesNeedCompute = true;
        end
        function set.EvaluationPointsMode(obj,value)
            obj.EvaluationPointsMode = value;
            if strcmpi(value,'auto')
                % Make sure to recompute in case the data is the same
                obj.EvaluationPointsNeedCompute = true;
            end
        end

        % DensityValues get/set methods
        function densVal = get.DensityValues(obj)
            if strcmpi(obj.DensityValuesMode,'auto')
                forceFullUpdate(obj,'all','DensityValues');
            end
            densVal = obj.DensityValues_I;
        end
        function set.DensityValues(obj, densVal)
            if isvector(densVal)
                densVal = densVal(:);
            end
            obj.DensityValues_I = densVal;
            obj.DensityValuesMode = 'manual';
            obj.MaxDensityValues = max(densVal,[],1);
            if isempty(obj.MaxDensityValues)
                obj.MaxDensityValues = 0;
            end
            obj.DensityValuesNeedCompute = false;
        end
        function set.DensityValuesMode(obj,value)
            obj.DensityValuesMode = value;
            if strcmpi(value,'auto')
                % Make sure to recompute in case the data is the same
                obj.DensityValuesNeedCompute = true;
            end
        end


        % Display properties get/set methods
        function val = get.FaceColor(obj)
            if strcmpi(obj.FaceColorMode,'auto')
                forceFullUpdate(obj,'all','FaceColor');
            end
            val = obj.FaceColor_I;
        end
        function set.FaceColor(obj, val)
            obj.FaceColor_I = val;
            obj.FaceColorMode = 'manual';
        end

        function val = get.FaceAlpha(obj)
            val = obj.FaceAlpha_I;
        end
        function set.FaceAlpha(obj, val)
            obj.FaceAlpha_I = val;
            obj.FaceAlphaMode = 'manual';
        end

        function val = get.EdgeColor(obj)
            if strcmpi(obj.EdgeColorMode,'auto')
                forceFullUpdate(obj,'all','EdgeColor');
            end
            val = obj.EdgeColor_I;
        end
        function set.EdgeColor(obj, val)
            obj.EdgeColor_I = val;
            obj.EdgeColorMode = 'manual';
        end

        function val = get.LineStyle(obj)
            val = obj.LineStyle_I;
        end
        function set.LineStyle(obj, val)
            obj.LineStyleMode = 'manual';
            obj.LineStyle_I = val;
        end
        function set.LineStyle_I(obj, val)
            % Setter Fanouts
            if ~isempty(obj.Edge)
                hgfilter('LineStyleToPrimLineStyle', obj.Edge, val);
            end
            obj.LineStyle_I = val;
        end

        function val = get.LineWidth(obj)
            val = obj.LineWidth_I;
        end
        function set.LineWidth(obj, val)
            obj.LineWidth_I = val;
            obj.LineWidthMode = 'manual';
        end
        function set.LineWidth_I(obj, val)
            % Setter Fanouts
            if ~isempty(obj.Edge) && obj.Edge.LineWidthMode == "auto"
                obj.Edge.LineWidth_I = val;
            end
            obj.LineWidth_I = val;
        end

        function val = get.Clipping(obj)
            val = obj.Clipping_I;
        end
        function set.Clipping(obj, val)
            obj.ClippingMode = 'manual';
            obj.Clipping_I = val;
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

        function val = get.DensityDirection(obj)
            val = obj.DensityDirection_I;
        end
        function set.DensityDirection(obj, val)
            obj.DensityDirection_I = val;
            obj.DensityDirectionMode = 'manual';
        end

        function val = get.DensityWidth(obj)
            val = obj.DensityWidth_I;
        end
        function set.DensityWidth(obj, val)
            obj.DensityWidth_I = val;
            obj.DensityWidthMode = 'manual';
        end

        function val = get.DensityScale(obj)
            val = obj.DensityScale_I;
        end
        function set.DensityScale(obj, val)
            obj.DensityScale_I = val;
            obj.DensityScaleMode = 'manual';
        end

        function or = get.Orientation(obj)
            or = obj.Orientation_I;
        end
        function set.Orientation(obj,or)
            % NB: The Orientation property has the AbortSet attribute,
            % which means swapNonNumericXYRulers is called just once
            % instead of once for each object.
            [~, err] = matlab.graphics.internal.swapNonNumericXYRulers(obj);
            if ~isempty(err)
                if strcmp(err, 'Type')
                    error(message('MATLAB:graphics:violinplot:OrientationMixedType'))
                elseif strcmp(err, 'YYAxis')
                    error(message('MATLAB:graphics:violinplot:OrientationYYAxis'))
                end
            end

            obj.Orientation_I = or;
            obj.OrientationMode = 'manual';

            % Also set the Orientation for the peers of this ViolinPlot
            valid = isvalid(obj.ViolinPeers);
            set(obj.ViolinPeers(valid), ...
                'Orientation_I', obj.Orientation_I, ...
                'OrientationMode', obj.OrientationMode);
        end

        function val = get.ColorGroupLayout(obj)
            val = obj.ColorGroupLayout_I;
        end
        function set.ColorGroupLayout(obj, val)
            obj.ColorGroupLayout_I = val;
            obj.ColorGroupLayoutMode = 'manual';

            % Also set the property for the peers of this ViolinPlot
            valid = isvalid(obj.ViolinPeers);
            set(obj.ViolinPeers(valid), ...
                'ColorGroupLayout_I', obj.ColorGroupLayout_I, ...
                'ColorGroupLayoutMode', obj.ColorGroupLayoutMode);
        end

        function val = get.ColorGroupWidth(obj)
            if obj.ColorGroupWidthMode == "auto"
                forceFullUpdate(obj,'all','ColorGroupWidth');
            end
            val = obj.ColorGroupWidth_I;
        end
        function set.ColorGroupWidth(obj, val)
            obj.ColorGroupWidth_I = val;
            obj.ColorGroupWidthMode = 'manual';

            % Also set the property for the peers of this ViolinPlot
            valid = isvalid(obj.ViolinPeers);
            set(obj.ViolinPeers(valid), ...
                'ColorGroupWidth_I', obj.ColorGroupWidth_I, ...
                'ColorGroupWidthMode', obj.ColorGroupWidthMode);
        end

        function set.ColorGroupWidthMode(obj, mode)
            obj.ColorGroupWidthMode = mode;
            % Also set the property for the peers of this ViolinPlot
            valid = isvalid(obj.ViolinPeers);
            set(obj.ViolinPeers(valid),...
                'ColorGroupWidthMode', obj.ColorGroupWidthMode);
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


    % Update related methods
    methods(Hidden)
        function doUpdate(obj, updateState)

            % Update XData_I potentially needed if YData_I changed:
            if obj.YDataDirty
                obj.setDefaultXData
            end

            % Check XData and YData for consistency if the pdf needs data
            % in order to be computed:
            if (obj.EvaluationPointsMode == "auto" || obj.DensityValuesMode == "auto") &&...
                    ( numel(obj.XData_I) ~= numel(obj.YData_I) )
                % NB: Empty data is fine and doesn't throw error
                error(message('MATLAB:graphics:violinplot:BadXDataYData'))
            end

            % Did anything change?
            updatePDF = obj.XDataDirty || obj.YDataDirty ||...
                obj.EvaluationPointsNeedCompute || ...
                obj.DensityValuesNeedCompute;

            if obj.EvaluationPointsMode == "auto"
                if ~( isempty(obj.XData_I) || isempty(obj.YData_I) )
                    % We have XData and YData; both are non-empty

                    % Update the x grouping, if needed
                    if obj.XDataDirty
                        [obj.XGroupIndex, obj.XGroupPositions] = ...
                            findgroups(obj.XDataCache(:));
                        obj.XNumGroups = numel(obj.XGroupPositions);
                        updateNumPerGrp(obj);
                        obj.XDataDirty = false;
                    end

                    if updatePDF
                        % Do we update the DensityValues too?
                        if obj.DensityValuesMode == "auto"
                            updateEvalPtsAndDensity(obj);
                            obj.MaxDensityValues = max(obj.DensityValues_I,[],1);
                            obj.DensityValuesNeedCompute = false;
                        else
                            updateEvaluationPoints(obj);
                            % Update the max densities (e.g. if the object was loaded):
                            obj.MaxDensityValues = max(obj.DensityValues_I,[],1);
                        end
                        % Now YData and EvaluationPoints have been used:
                        obj.YDataDirty = false;
                        obj.EvaluationPointsNeedCompute = false;
                    end

                else
                    % No data present. Empty values propagate through
                    obj.XNumGroups = 0;
                    obj.XGroupPositions = [];
                    obj.XNumPerGroup = 0;
                    obj.EvaluationPoints_I = [];
                    obj.XDataDirty = false;
                    obj.YDataDirty = false;
                    if obj.DensityValuesMode == "auto"
                        obj.DensityValues_I = [];
                        obj.MaxDensityValues = 0;
                    else
                        error(message('MATLAB:graphics:violinplot:DensValModeManualEvalPtsAutoMissingData'))
                    end
                end
            else % EvaluationPointsMode is set to 'manual'.
                if ~isempty(obj.XData_I) % We have XData.
                    if ~isempty(obj.YData_I) && ...
                            ( numel(obj.XData_I) ~= numel(obj.YData_I) )
                        % If YData is provided, it must match
                        error(message('MATLAB:graphics:violinplot:BadXDataYData'))
                    end
                    if ~isempty(obj.EvaluationPoints_I)
                        obj.numEvalPts = size(obj.EvaluationPoints_I,1);
                    end

                    [tmpGrpIdx, tmpGrpPos] = ...
                        findgroups(obj.XDataCache(:));
                    if numel(tmpGrpPos) ~= size(obj.EvaluationPoints_I,2)
                        error(message('MATLAB:graphics:violinplot:EvalPtsModeManualBadXNumGroups'))
                    end
                    % Update the x grouping, if needed
                    if obj.XDataDirty
                        obj.XGroupIndex = tmpGrpIdx;
                        obj.XGroupPositions = tmpGrpPos;
                        obj.XNumGroups = numel(tmpGrpPos);
                        updateNumPerGrp(obj);
                        obj.XDataDirty = false;
                    end

                    if obj.DensityValuesMode == "auto" && updatePDF
                        updateDensityValues(obj);
                        obj.MaxDensityValues = max(obj.DensityValues_I,[],1);
                    end
                    % Otherwise, either there's nothing to do or both
                    % EvaluationPointsMode and DensityValuesMode are
                    % set to'manual'
                    obj.YDataDirty = false;
                    obj.EvaluationPointsNeedCompute = false;
                    obj.DensityValuesNeedCompute = false;
                else
                    % No XData data present.
                    if obj.DensityValuesMode == "auto"
                        error(message('MATLAB:graphics:violinplot:DensValMissingData'))
                    else
                        % DensityValuesMode is 'manual' too.
                        if isempty(obj.EvaluationPoints_I)
                            obj.XNumGroups = 0;
                            obj.XGroupPositions = [];
                            obj.XNumPerGroup = 0;
                        else
                            % Get info from EvaluationPoints:
                            [obj.numEvalPts, obj.XNumGroups] = size(obj.EvaluationPoints_I);
                            obj.XGroupPositions = 1:obj.XNumGroups;
                            % By default use the number of evaluation points:
                            obj.XNumPerGroup = repelem(obj.numEvalPts,obj.XNumGroups);
                        end
                        if updatePDF
                            if isempty(obj.EvaluationPoints_I)
                                obj.MaxDensityValues = 0;
                            else
                                obj.MaxDensityValues = max(obj.DensityValues_I,[],1);
                            end
                        end
                    end
                    obj.XDataDirty = false;
                    obj.EvaluationPointsNeedCompute = false;
                    obj.DensityValuesNeedCompute = false;
                end

            end

            % Dimensions of pdf parts must agree:
            if ( ~isequal(size(obj.EvaluationPoints_I), size(obj.DensityValues_I)) )
                error(message('MATLAB:graphics:violinplot:BadEvalPtsAndDensity'))
            end

            if obj.ColorGroupWidthMode == "auto"
                obj.ColorGroupWidth_I = obj.getColorGroupWidth();
            end

            % Check orientation:
            isVertical = obj.Orientation_I == "vertical";

            % Get x groups positions and widthFactor:
            [xpositions,widthFactor] = ...
                getGroupPositionAndWidthFactor(obj,obj.XGroupPositions);
            % Get number of x groups and their IDs:
            numXGroups = obj.XNumGroups;
            validXGroupIDs = 1:numXGroups;

            ds = updateState.DataSpace;
            if isVertical
                XDataLinearScale = isequal(ds.XScale,'linear');
                invalidXGroups = matlab.graphics.chart.primitive.utilities.isInvalidInLogScale(...
                    ds.XScale, ds.XLim, xpositions);
            else
                XDataLinearScale = isequal(ds.YScale,'linear');
                invalidXGroups = matlab.graphics.chart.primitive.utilities.isInvalidInLogScale(...
                    ds.YScale, ds.YLim, xpositions);
            end
            if any(invalidXGroups)
                numXGroups = numXGroups - sum(invalidXGroups);
                validXGroupIDs(invalidXGroups) = [];
            end

            % Get number of evaluation points and cumulative used:
            numPoints = obj.numEvalPts;
            cumnumEvalPts = (0:(numXGroups-1))*numPoints;

            % Get scaling factors for each violin
            scalingFactors = getScalingFactors(obj);

            % Iterator for transforming data points.
            faceIter = matlab.graphics.axis.dataspace.XYZPointsIterator;
            edgeIter = matlab.graphics.axis.dataspace.XYZPointsIterator;
            edgeStripData = uint32(ones([1,2*numXGroups]));
            if obj.DensityDirection_I == "both"
                obj.DataTipsVertexData = zeros(2*numXGroups*numPoints,3);
                obj.DataTipsVertexData(:,3) = 1:(2*numXGroups*numPoints);
            else
                obj.DataTipsVertexData = zeros(numXGroups*numPoints,3);
                obj.DataTipsVertexData(:,3) = 1:(numXGroups*numPoints);
            end

            for idx = 1:numXGroups

                grpID = validXGroupIDs(idx);
                % Center of the violin
                pos = xpositions(grpID);

                if isinteger(pos)
                    pos = double(pos);
                end

                % Get the density aspect of the violin.
                evalPts = obj.EvaluationPoints_I(:,grpID)';
                densVal = widthFactor * scalingFactors(grpID) * obj.DensityValues_I(:,grpID)';

                % Create outlines of violins:
                if XDataLinearScale
                    posVx = pos + densVal;
                    negVx = pos - flip(densVal);
                else
                    doflip = pos <=0;
                    % Flip negative pos:
                    if doflip
                        pos = -1*pos;
                    end
                    % Add density:
                    posVx = 10.^(log10(pos) + densVal);
                    negVx = 10.^(log10(pos) - flip(densVal));
                    if doflip
                        posVx = -1*posVx;
                        negVx = -1*negVx;
                        pos = -1*pos;
                    end
                end

                % Positive part of violin. Start at bottom:
                positiveVertices = [posVx; evalPts];
                % Negative part of violin. Start at top:
                negativeVertices = [negVx; flip(evalPts)];
                % Center and top and bottom of violin:
                centerVertices = [repelem(pos,numPoints); evalPts];
                topVertex = [pos; max(evalPts)];
                bottomVertex = [pos; min(evalPts)];

                % Collect the untransformed vertices for face, edge and
                % data tips.
                if obj.DensityDirection_I == "both"
                    % Combine into the two sides:
                    faceVertexData = matlab.graphics.chart.primitive.ViolinPlot.getFaceVertices(...
                        flip(negativeVertices,2), positiveVertices);
                    edgeVertexData = [positiveVertices, negativeVertices];
                    dataTipsVertices = edgeVertexData';
                elseif obj.DensityDirection_I == "positive"
                    faceVertexData = matlab.graphics.chart.primitive.ViolinPlot.getFaceVertices(...
                        centerVertices,positiveVertices);
                    % Add the top and bottom points to the edge:
                    edgeVertexData = [bottomVertex,positiveVertices,topVertex];
                    dataTipsVertices = positiveVertices';
                elseif obj.DensityDirection_I == "negative"
                    faceVertexData = matlab.graphics.chart.primitive.ViolinPlot.getFaceVertices(...
                        flip(negativeVertices,2),centerVertices);
                    % Add the top and bottom points to the edge:
                    edgeVertexData = [topVertex,negativeVertices,bottomVertex];
                    dataTipsVertices = negativeVertices';
                end

                if isVertical
                    xDimID = 1;
                    yDimID = 2;
                else
                    xDimID = 2;
                    yDimID = 1;
                end

                % Add to the face iterator vertex data:
                faceIter.XData = [faceIter.XData faceVertexData(xDimID,:)];
                faceIter.YData = [faceIter.YData faceVertexData(yDimID,:)];

                % Add to the edge iterator vertex data:
                edgeIter.XData = [edgeIter.XData edgeVertexData(xDimID,:)];
                edgeIter.YData = [edgeIter.YData edgeVertexData(yDimID,:)];

                if obj.DensityDirection_I == "both"
                    edgeStripData(:,(2*(idx-1)+1):(2*idx)) = uint32(2*cumnumEvalPts(idx) + [1, 2*numPoints + 1]);
                    obj.DataTipsVertexData((idx-1)*2*numPoints+1:idx*2*numPoints,1:2) = dataTipsVertices(:,[xDimID, yDimID]);
                else
                    edgeStripData(:,(2*(idx-1)+1):(2*idx)) = uint32(cumnumEvalPts(idx) + 2*(idx-1) + [1, (numPoints+2)+1]);
                    obj.DataTipsVertexData((idx-1)*numPoints+1:idx*numPoints,1:2) = dataTipsVertices(:,[xDimID, yDimID]);
                end
            end
            % Transform iterators to edge and face:
            xform = updateState.TransformUnderDataSpace;
            % Set the vertex data of the violin face:
            obj.Face.VertexData = TransformPoints(ds, xform, faceIter);
            % Set the vertex data of the violin edge:
            obj.Edge.VertexData = TransformPoints(ds, xform, edgeIter);
            obj.Edge.StripData = edgeStripData;


            % Colors etc.
            obj.assignSeriesIndex;

            % Get face color and set it to primitives
            obj.applyColor(updateState, 'FaceColor');
            facecolor = obj.FaceColor_I;

            % Get edge color.
            if strcmp(obj.EdgeColorMode, 'auto') && ~isempty(facecolor)
                % By default, the edge has the same color as the face
                edgeColor = facecolor;
                obj.EdgeColor_I = facecolor;
            else
                edgeColor = obj.EdgeColor_I;
            end

            % Violin Face:
            violinface = obj.Face;
            if strcmp(facecolor, 'none')
                hgfilter('RGBAColorToGeometryPrimitive', violinface, facecolor);
            else
                hgfilter('RGBAColorToGeometryPrimitive', ...
                    violinface, [facecolor,obj.FaceAlpha_I]);
            end

            % Violin Edge:
            violinedge = obj.Edge;
            hgfilter('RGBAColorToGeometryPrimitive', violinedge, edgeColor);

            % Selection handles:
            hasVisibleSelectionHandles = ~isempty(obj.Edge.VertexData) && ...
                obj.Visible && obj.Selected && obj.SelectionHighlight;
            if hasVisibleSelectionHandles
                if isempty(obj.SelectionHandle)
                    obj.SelectionHandle = matlab.graphics.interactor.ListOfPointsHighlight('Internal',true);
                    obj.addNode(obj.SelectionHandle);
                    obj.SelectionHandle.Description = 'ViolinPlot SelectionHandle';
                end

                % Find indices so that the points are symmetric
                nEvalPts = obj.numEvalPts;
                numValid = numel(validXGroupIDs);  % Not obj.XNumGroups, in case of log
                if obj.DensityDirection == "both"
                    numEdgePtsInEach = 2*nEvalPts;
                else
                    numEdgePtsInEach = nEvalPts + 2;
                end
                q = max(2,floor(nEvalPts/10));  % 10 makes 11 points each half

                % Start with indices for the one half:
                idx = [1 q:q:nEvalPts];
                if idx(end) ~= nEvalPts
                    idx(end+1) = nEvalPts;
                end
                if obj.DensityDirection == "both"
                    % Add left side:
                    idx = [idx, flip(numEdgePtsInEach - idx + 1)];
                else
                    % Add top and bottom points:
                    idx = [1 idx+1 nEvalPts+2];
                    if obj.DensityDirection == "negative"
                        % Ensure same left points as for DensityDirection "both":
                        idx = flip(numEdgePtsInEach - idx + 1);
                    end
                end
                % Expand indices for all (valid) violins:
                idx = idx(:) + (0:numValid-1)*numEdgePtsInEach;

                obj.SelectionHandle.VertexData = obj.Edge.VertexData(:,idx(:));
                obj.SelectionHandle.MaxNumPoints = (numEdgePtsInEach+5)*numValid;
                obj.SelectionHandle.Clipping = obj.Clipping;
                obj.SelectionHandle.Visible = 'on';
            elseif ~isempty(obj.SelectionHandle)
                obj.SelectionHandle.VertexData = [];
                obj.SelectionHandle.Visible = 'off';
            end

        end

        function graphic = getLegendGraphic(obj, fontsize)
            % Displays a quadrilateral in the legend
            graphic = matlab.graphics.primitive.world.Group;

            face = matlab.graphics.primitive.world.Quadrilateral(...
                Parent = graphic, Visible = obj.Face.Visible,...
                VertexData = single([0 0 1 1;0 1 1 0;0 0 0 0]),...
                VertexIndices = [], StripData = []);
            color = obj.FaceColor_I;
            if ~isequal(color, "none")
                color = [color obj.FaceAlpha_I];
            end
            hgfilter('RGBAColorToGeometryPrimitive', face, color);

            linewidth = min(obj.LineWidth_I,fontsize/2);
            edge = matlab.graphics.primitive.world.LineLoop(...
                Parent = graphic, Visible = obj.Edge.Visible,...
                LineJoin = 'miter', AlignVertexCenters = 'on',...
                LineWidth = linewidth, LineStyle = obj.Edge.LineStyle,...
                VertexData = face.VertexData, VertexIndices = [],...
                StripData = uint32([1 5]));
            hgfilter('RGBAColorToGeometryPrimitive', edge, obj.EdgeColor_I);
        end

        function ex=getXYZDataExtents(obj,~,constraints)
            % Compute the x, y and z limits based on input data. This
            % determines the XLim and YLim of ViolinPlot's parent

            if isempty(obj.XDataCache) || obj.YDataDirty
                obj.setDefaultXData
            end

            if obj.EvaluationPointsMode == "manual"
                if isempty(obj.XData_I)
                    x = 1:size(obj.EvaluationPoints_I,2);
                else
                    x = obj.XDataCache(:);
                end
                y = obj.EvaluationPoints_I(:);
            else
                x = obj.XDataCache(:); % Could be empty - ok
                if ~isempty(obj.YData_I) && ~isempty(x)
                    [groupIDs, pos] = findgroups(x);
                    numGrps = numel(pos);
                    bw = zeros(1,numGrps);
                    for i = 1:numGrps
                        % Get an estimate of the range of the EvaluationPoints
                        if isfinite(pos(i))
                            xind = groupIDs == i;
                            yGrp = getValidYData(obj, xind);
                            bw(i) = matlab.internal.math.validateOrEstimateBW(...
                                "MATLAB:kde:", yGrp(:), [], 1, [-Inf Inf]);
                        end
                    end
                    [miny, maxy] = bounds(getValidYData(obj, isfinite(x)));
                    bwBuffer = 3*max(bw);
                    y = [miny - bwBuffer, maxy + bwBuffer];
                else
                    y = [];
                end
            end

            % Find the groups and possible offset because of 'GroupByColor'
            [~,pos] = findgroups(x);
            [offset,pad] = getGroupPositionAndWidthFactor(obj,0);
            pos = pos(isfinite(pos)) + offset;
            y = y(isfinite(y));

            % Each *lim: [min, maxnegative, minpositive, max] (NaN possible)
            [xlim, ylim, zlim] = matlab.graphics.chart.primitive.utilities.arraytolimits(pos,y,[]);

            % Handle log scale and zero-crossing:
            isVert = obj.Orientation_I == "vertical";
            if isVert
                XDataLinearScale = constraints.AllowZeroCrossing(1);
            else
                XDataLinearScale = constraints.AllowZeroCrossing(2);
            end

            % Pad extents:
            if XDataLinearScale
                xlim(1)=xlim(1)-pad;
                xlim(4)=xlim(4)+pad;
                % Changes to zero-crossing extents due to density:
                if xlim(1)<0 && isnan(xlim(2))
                    % previously all positive but now crosses zero
                    xlim(2)=-eps;
                end
                if xlim(1)>0
                    xlim(3)=xlim(1);
                elseif xlim(4)>0 && isnan(xlim(3))
                    % previously all negative but now crosses zero
                    xlim(3)=eps;
                end
                if xlim(4)<0
                    xlim(2)=xlim(4);
                end
            else
                %log case: transform extents, apply width padding, untransform
                if isnan(xlim(3))
                    % all negative/zero data
                    xlim(1)=-10.^(log10(-xlim(1))+pad);
                    xlim(2)=-10.^(log10(-xlim(2))-pad);
                    xlim(4)=xlim(2);
                else
                    % at least some non-negative data
                    xlim(3)=10.^(log10(xlim(3))-pad);
                    xlim(4)=10.^(log10(xlim(4))+pad);
                    if xlim(1)>0
                        xlim(1)=xlim(3);
                    end
                end
            end

            if isVert
                ex = [xlim; ylim; zlim];
            else
                ex = [ylim; xlim; zlim];
            end
        end

    end

    methods(Access='protected', Hidden)
        function dataPropertyValueChanged(obj, channelName)
            if channelName(1) == 'X'
                obj.XDataDirty = true;
            end
            if channelName(1) == 'Y'
                obj.YDataDirty = true;
            end
        end

        function [converter, converterFound] = getNonNumericConverterForChannel(obj, channelName)
            if obj.Orientation_I == "horizontal"
                if channelName == "X"
                    channelName = "Y";
                elseif channelName == "Y"
                    channelName = "X";
                end
            end
            [converter, converterFound] = getNonNumericConverterForChannel@matlab.graphics.mixin.DataProperties(obj, channelName);
        end

        function shortdisp = getPropertyGroups(obj)
            suffix = {'Data' 'Variable'};
            dnames{1} = sprintf('X%s', suffix{1 + obj.isDataComingFromDataSource('X')});
            dnames{2} = sprintf('Y%s', suffix{1 + obj.isDataComingFromDataSource('Y')});

            shortdisp = matlab.mixin.util.PropertyGroup([{'FaceColor', ...
                'FaceAlpha', 'EdgeColor', 'LineWidth', ...
                'DensityDirection', 'DensityScale'} dnames]);
        end
        function name = getDescriptiveLabelForDisplay(obj)
            if ~isempty(obj.Tag)
                name = obj.Tag;
            else
                name = obj.DisplayName;
            end
        end

        function value = getColorGroupWidth(obj)
            value = 1;
            if obj.NumColorGroups > 1
                value = min(0.8, obj.NumColorGroups/(obj.NumColorGroups+1.5));
            end
        end

        function [pos,widthFactor] = getGroupPositionAndWidthFactor(obj,pos)
            % If needed, the positions and widths are adjusted for rendering
            % but the property DensityWidth remains unchanged.

            widthFactor = obj.DensityWidth_I/2;
            num = obj.NumColorGroups;

            if obj.GroupByColorMode == "manual" && num > 1
                switch obj.ColorGroupLayout_I
                    case 'grouped'
                        idx = obj.PeerID;
                        div = 1/(num);
                        unitWidth = obj.ColorGroupWidth_I*obj.XDataUnit_I;

                        % Update widthFactor
                        widthFactor = obj.ColorGroupWidth_I*widthFactor*div;

                        % Update position
                        pos = pos + unitWidth/2*(div - 1)  + ...
                            (idx-1)*unitWidth*div;
                    case 'overlaid'
                        % Overlay, i.e. don't do the grouping above
                end
            end
        end

        function sf = getScalingFactors(obj)
            % We should have the width, count, and maximum density for each
            % of the groups (if there are >=1 groups)

            sf = 1;
            if obj.XNumGroups > 0
                switch obj.DensityScale_I
                    case 'area'
                        sf = 1/max(obj.MaxDensityValues);
                        sf = repelem(sf,obj.XNumGroups);
                    case 'count'
                        % Only the one(s) with highest count reach the width
                        countScaling = obj.XNumPerGroup./max(obj.XNumPerGroup);
                        sf = countScaling ./obj.MaxDensityValues;
                    case 'width'
                        % Simple case, all reach the width
                        sf = 1./obj.MaxDensityValues;
                end
            end
        end

        function setDefaultXData(obj)
            xdata_I = obj.getDataPropertyValue("X", true);
            if obj.XDataMode == "auto" && ...
                    (isempty(xdata_I) || isempty(obj.YData_I) || obj.YDataDirty)
                if obj.Orientation == "vertical"
                    ruler = obj.getRulerForDimension("X");
                else
                    ruler = obj.getRulerForDimension("Y");
                end
                if obj.GroupByColorMode == "manual"
                    % Only set via function by providing 'GroupByColor'
                    % Note also the behavior in set.XDataMode
                    value = ones(numel(obj.YData_I),1);
                else
                    value = repelem(obj.PeerID,numel(obj.YData_I),1);
                end
                if isscalar(ruler)
                    value = num2ruler(value,ruler);
                end
                % Note: Empty YData_I will result in empty XData_I
                obj.XData_I = value;
                % This flips XDataDirty to true
            end
        end

        function updateNumPerGrp(obj)
            numXGroups = obj.XNumGroups;
            obj.XNumPerGroup = zeros(1,numXGroups);
            for idx = 1:numXGroups
                obj.XNumPerGroup(idx) = sum(obj.XGroupIndex == idx);
            end
        end

        function ydata = getValidYData(obj, xind)
            % Handles sparse and integer types, turns Inf into NaN:
            ydata = full(obj.YData_I(xind));
            ydata(~isfinite(ydata)) = NaN;
            if isinteger(ydata)
                ydata = double(ydata);
            end
        end

        function updateDensityValues(obj)
            % Requires data to be non-empty
            numXGroups = obj.XNumGroups;
            numPts = obj.numEvalPts;

            obj.DensityValues_I = zeros(numPts, numXGroups);

            for idx = 1:numXGroups
                xind = obj.XGroupIndex == idx;
                ydata = getValidYData(obj, xind);

                if all(isnan(ydata))
                    obj.DensityValues_I(:,idx) = NaN(numPts,1);
                else
                    obj.DensityValues_I(:,idx) = kde(ydata, ...
                        EvaluationPoints = obj.EvaluationPoints_I(:,idx));
                end
            end
        end

        function updateEvaluationPoints(obj)
            % Requires data to be non-empty
            numXGroups = obj.XNumGroups;
            numPts = obj.numEvalPts;

            obj.EvaluationPoints_I = zeros(numPts, numXGroups);

            for idx = 1:numXGroups
                xind = obj.XGroupIndex == idx;
                ydata = getValidYData(obj, xind);

                if all(isnan(ydata))
                    obj.EvaluationPoints_I(:,idx) = NaN(numPts,1);
                else
                    [~, obj.EvaluationPoints_I(:,idx)] = ...
                        kde(ydata, NumPoints=numPts);
                end
            end
        end

        function updateEvalPtsAndDensity(obj)
            % Requires data to be non-empty
            numXGroups = obj.XNumGroups;
            numPts = obj.numEvalPts;

            obj.EvaluationPoints_I = zeros(numPts, numXGroups);
            obj.DensityValues_I = zeros(numPts, numXGroups);

            for idx = 1:numXGroups
                xind = obj.XGroupIndex == idx;
                ydata = getValidYData(obj, xind);

                if all(isnan(ydata))
                    obj.DensityValues_I(:,idx) = NaN(numPts,1);
                else
                    [obj.DensityValues_I(:,idx), obj.EvaluationPoints_I(:,idx)] = ...
                        kde(ydata, NumPoints=numPts);
                end
            end
        end
    end

    methods(Access='public',Hidden)
        function hints = getHints(obj)
            varNames = obj.getChannelDisplayNames(["X", "Y"]);
            xID = 1;
            yID = 2;
            if obj.Orientation_I == "horizontal"
                xID = 2;
                yID = 1;
            end
            hints = { ...
                {'Label', 'X', convertStringsToChars(varNames(xID))}, ...
                {'Label', 'Y', convertStringsToChars(varNames(yID))}};
            hints = hints(varNames ~= "");
        end

        function reactToXYRulerSwap(obj)
            obj.MarkDirty('limits');
        end

        mcodeConstructor(obj, code)
    end

    % From the DataAnnotatable interface to support datatips:
    methods(Hidden, Access = 'public')
        dataTipRows = createDefaultDataTipRows(obj)
        coordinateData = createCoordinateData(obj, valueSource, index, ~)
        valueSources = getAllValidValueSources(obj)
    end
    methods(Hidden, Access = 'protected')
        index = doGetNearestPoint(obj, position)
        [index, interp] = doGetInterpolatedPoint(obj, position)
        [index, interp] = doGetInterpolatedPointInDataUnits(obj, position)
        index = doGetNearestIndex(obj, index)
        [index, interp] = doIncrementIndex(obj, index, direction, ~)
        point = doGetReportedPosition(obj, index, ~)
        point = doGetDisplayAnchorPoint(obj, index, ~)
        descriptors = doGetDataDescriptors(obj, index, ~)

        function indices = doGetEnclosedPoints(~, ~)
            % Not implemented.
            indices = [];
        end
    end

    % Static method
    methods(Static, Hidden)

        function validateData(dataMap)
            arguments
                dataMap (1,1) matlab.graphics.data.DataMap
            end

            channels = string(fieldnames(dataMap.Map));
            keep = ismember(channels, ["X", "Y"]);
            channels = channels(keep);
            for c = channels'
                subscript = dataMap.Map.(c);
                data = dataMap.DataSource.getData(subscript);
                for d = 1:numel(data)
                    matlab.graphics.chart.primitive.ViolinPlot.validateDataPropertyValue(c, data{d});
                end
            end
        end

        function [vec] = getFaceVertices(leftVec,rightVec)
            % Merge the two vectors to create vertices for triangle strips.
            % Vectors are assumed to be of dimension [2,n].
            % Output dimension is [2, 6*(n-1)].
            n = size(leftVec,2);
            vec = zeros([2,(n-1)*6]);
            for i = 1:(n-1)
                vec(:,(i-1)*6 + (1:6)) = [leftVec(:,i), rightVec(:,i), rightVec(:,i+1),...
                    rightVec(:,i+1), leftVec(:,i+1), leftVec(:,i)];
            end
        end
    end

    methods(Static, Access=protected)
        function data = validateDataPropertyValue(channelName, data)
            switch(channelName)
                case 'Y'
                    data = validateDataPropertyValue@matlab.graphics.mixin.DataProperties(channelName, data);
                    if ~isnumeric(data)
                        error(message('MATLAB:graphics:violinplot:InvalidYData'))
                    end
                otherwise
                    data = validateDataPropertyValue@matlab.graphics.mixin.DataProperties(channelName, data);
            end
        end
    end


end
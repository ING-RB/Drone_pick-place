classdef (Abstract) BaseAxesView < matlab.mixin.SetGet & controllib.chart.internal.foundation.MixInListeners
    % controllib.chart.internal.view.axes.InputOutputAxesView manages the responses and the axes and all chart
    % properties associated with it
    %
    % h = InputOutputView(nInputs,nOutputs)
    %   nInputs     number of inputs
    %   nOutputs    number of outputs
    %
    % h = InputOutputView(______,Name-Value)
    %   GridSize            size of grid of axes, default value is [nOutputs,nInputs]
    %   OuterPosition       [x0,y0,w,h] in normalized units, default value is [0 0 1 1]
    %   Title               string specifying chart title, default is ""
    %   XLabel              string specifying chart xlabel, default is ""
    %   YLabel              string specifying chart ylabel, default is ""
    %   InputNames          string array specifying input names, should be compatible with nInputs/GridSize
    %   OutputNames         string array specifying output names, should be compatible with nOutputs/GridSize
    %   Visible             matlab.lang.OnOffSwitchState scalar specifying visibility
    %   InputVisible        matlab.lang.OnOffSwitchState vector specifying input visibility
    %   OutputVisible       matlab.lang.OnOffSwitchState vector specifying output visibility
    %   Grid                matlab.lang.OnOffSwitchState scalar specifying visibility of grid lines
    %   GridColor           (1,3) double vector specifying color of grid lines
    %   Parent              parent chart for axes and layout objects, by default they will be unparented
    %   Axes                axes to be used in chart (usually from serialization and loading)
    %   XLimitsSharing      string specifying the sharing of x-limits, default value is "all"
    %   YLimitsSharing      string specifying the sharing of y-limits, default value is "row"
    %   XLimitsFocus        array or cell array specifying focus to be used in setting x-limits
    %   YLimitsFocus        array or cell array specifying focus to be used in setting y-limits
    %   AutoAdjustXLimits   logical scalar specifying if x-limits are to be adjusted
    %   AutoAdjustYLimits   logical scalar specifying if y-limit are to be adjusted
    %   TitleStyle          struct with FontSize,FontWeight,FontAngle,Color and Interpreter for title
    %   XLabelStyle         struct with FontSize,FontWeight,FontAngle,Color and Interpreter for xlabel
    %   YLabelStyle         struct with FontSize,FontWeight,FontAngle,Color and Interpreter for ylabel
    %   InputLabelStyle     struct with FontSize,FontWeight,FontAngle,Color and Interpreter for input labels
    %   OutputLabelStyle    struct with FontSize,FontWeight,FontAngle,Color and Interpreter for output labels
    %   AxesStyle           struct with FontSize,FontWeight,FontAngle,Color and Interpreter for tick labels
    %
    % Public properties:
    %   Title               (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   XLabel              (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   YLabel              (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   InputNames          (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   OutputNames         (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   Visible             (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   InputVisible        (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   OutputVisible       (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   Grid                (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   XLimits             (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   XLimitsMode         (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   XLimitsSharing      (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   YLimits             (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   YLimitsMode         (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   YLimitsSharing      (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %
    %   XLimitsFocus        set focus for x-limits
    %   YLimitsFocus        set focus for y-limits
    %
    % Protected properties:
    %   Responses       array of type controllib.chart.internal.responses.BaseResponse to manage the response
    %                   lines and characteristic markers
    %   NInputs         number of inputs
    %   NOutputs        number of outputs
    %   GridSize        size of grid of axes
    %   AxesGrid        manages axes (labels, limits, layout), type controllib.chart.internal.layout.AxesGrid
    %   Style           of type controllib.chart.internal.options.ViewStyle
    %
    %   CharacteristicTypes         string array of characteristic type
    %   CharacteristicVisibility    struct of Visible property for different characteristics
    %
    % Public methods:
    %
    %   updateResponse(this,systems)
    %       - updates the response objects linked to the systems objects
    %       - systems is array of type controllib.chart.internal.foundation.BaseResponse
    %
    %   updateResponseVisibility(this,system)
    %       - updates visibility of response linked to system based on system.Visible
    %
    %   addResponse(this,system)
    %       - creates and adds response (controllib.chart.internal.view.wave.BaseResponseView) using
    %       system (controllib.chart.internal.foundation.BaseResponse)
    %
    %   updateFocus(this,systems)
    %       - update XLimitsFocus and YLimitsFocus using systems
    %
    %   createDataTips(this)
    %       - create data tips for all responses
    %   createDataTips(this,N)
    %       - create data tips for the N-th response
    %
    %   setoptions(this,options)
    %       - set common options for View
    %
    % Abstract methods:
    %
    %   updateFocus_(this,systems)
    %       - compute and set XLimitsFocus and YLimitsFocus using systems
    %
    %   response = createResponseView(this,systems)
    %       - create and return array of response (controllib.chart.internal.view.wave.BaseResponseView)
    %       using systems

    % Copyright 2021-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess=immutable)
        % Manage label styles (outer labels, input/output labels, tick labels) of a chart.
        % <a href="matlab:help controllib.chart.internal.options.ViewStyle">ViewStyle</a>
        Style controllib.chart.internal.options.ViewStyle {mustBeScalarOrEmpty}
    end

    properties (Access = protected)
        % Manage the responses lines and characteristic markers in the
        % chart. Should be subclass of <a href="matlab:help controllib.chart.internal.view.wave.BaseResponseView">BaseResponse</a>
        ResponseViews (:,1) controllib.chart.internal.view.wave.BaseResponseView

        % Manages axes in a chart (labels, limits, layout).
        % <a href="matlab:help controllib.chart.internal.layout.AxesGrid">AxesGrid</a>
        AxesGrid controllib.chart.internal.layout.AxesGrid {mustBeScalarOrEmpty}
    end

    properties (Dependent)
        % Limits
        XLimits
        XLimitsMode
        YLimits
        YLimitsMode
        XLimitsFocus
        YLimitsFocus
        XLimitsFocusFromResponses
        YLimitsFocusFromResponses
        SyncChartWithAxesView
    end

    properties (Dependent, AbortSet, SetObservable)
        % Chart title string
        Title
        % Chart subtitle string
        Subtitle
        % Chart xlabel string
        XLabel
        % Chart ylabel string
        YLabel
        % Set visibility : true | false
        Visible
        % CurrentInteractionMode
        CurrentInteractionMode
    end

    properties (Dependent,SetAccess=private)
        Toolbar
        VisibleResponses
    end

    properties (Hidden,SetAccess=protected)
        CharacteristicTypes (:,1) string
        CharacteristicsVisibility
        ResponseXLimitsFocus
        ResponseYLimitsFocus
    end

    properties (Hidden,Dependent,Access=protected)
        GridSize
    end

    properties (GetAccess=protected, SetAccess=immutable, WeakHandle)
        Chart controllib.chart.internal.foundation.AbstractPlot {mustBeScalarOrEmpty} = controllib.chart.internal.foundation.AbstractPlot.empty
    end

    properties (Access = protected)
        SnapToDataVertexForDataTipInteraction = "interpolate"
    end

    %% Events
    events
        AxesHitToOpenPropertyEditor
        LimitsChanged
        GridUpdated
        GridSizeChanged
    end

    %% Abstract methods
    methods(Abstract, Access = protected)
        response = createResponseView(this,response,idx);
        [xLimitsFocus,yLimitsFocus] = updateFocus_(this,responses);
    end

    %% Constructor/destructor
    methods
        function this = BaseAxesView(chart,optionalInputs)
            % Construct view
            arguments
                chart (1,1) controllib.chart.internal.foundation.AbstractPlot
                optionalInputs.InitializeUsingView = []
            end
            this.Chart = chart;

            if ~isempty(optionalInputs.InitializeUsingView)
                view = optionalInputs.InitializeUsingView;
                mustBeA(view,'controllib.chart.internal.view.axes.BaseAxesView');
                this.Style = view.Style;
                this.AxesGrid = qeGetAxesGrid(view);
            else
                % Initialize style
                this.Style = controllib.chart.internal.options.ViewStyle(chart);
            end
            initialize(this.Style,this.Chart);
        end

        function delete(this)
            unregisterListeners(this);
            delete(this.AxesGrid);
            delete(this.ResponseViews);
        end
    end

    %% Public methods
    methods
        function responseViews = addResponseView(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse {mustBeNonempty}
            end
            idx = length(this.ResponseViews);
            for ii = 1:numel(responses)
                responseView = createResponseView(this,responses(ii));
                if idx == 0 && ii == 1
                    this.ResponseViews = responseView;
                else
                    this.ResponseViews = [this.ResponseViews; responseView];
                end
            end
            responseViews = this.ResponseViews(idx+1:end);
            parentResponseViews(this);
        end

        function updateFocus(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end
            responses = this.VisibleResponses;
            if isempty(responses)
                return;
            end

            % Compute focus
            [xLimitsFocus,yLimitsFocus] = updateFocus_(this,responses);

            % Cache the focus computed from responses
            this.ResponseXLimitsFocus = xLimitsFocus;
            this.ResponseYLimitsFocus = yLimitsFocus;

            % Update axes grid
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                if ~this.XLimitsFocusFromResponses
                    xLimitsFocus = localMergeFocus(xLimitsFocus,this.XLimitsFocus);
                end
                if ~this.YLimitsFocusFromResponses
                    yLimitsFocus = localMergeFocus(yLimitsFocus,this.YLimitsFocus);
                end
                
                if all(all(cellfun(@(x)diff(x)>0 | any(isnan(x)),xLimitsFocus)))
                    this.AxesGrid.XLimitsFocus = xLimitsFocus;
                    this.Chart.XLimitsFocus_I = xLimitsFocus;
                end

                if all(all(cellfun(@(x)diff(x)>0 | any(isnan(x)),yLimitsFocus)))
                    this.AxesGrid.YLimitsFocus = yLimitsFocus;
                    this.Chart.YLimitsFocus_I = yLimitsFocus;
                end

                autoGenerateXData = [responses.AutoGenerateXData];
                if ~any(autoGenerateXData)
                    this.AxesGrid.AutoAdjustXLimits = false;
                else
                    this.AxesGrid.AutoAdjustXLimits = true;
                end

                update(this.AxesGrid);
            end
        end

        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            idx = find(arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews),1);
            responseView = this.ResponseViews(idx);
            hasDifferentCharacteristics = ~isempty(setdiff(...
                union(responseView.CharacteristicTypes,response.CharacteristicTypes),...
                intersect(responseView.CharacteristicTypes,response.CharacteristicTypes)));
            if responseView.Response.NResponses ~= response.NResponses || hasDifferentCharacteristics
                delete(responseView);
                this.ResponseViews = this.ResponseViews(isvalid(this.ResponseViews));
                responseView = createResponseView(this,response);
                createResponseDataTips(responseView);
                this.ResponseViews = [this.ResponseViews(1:idx-1); responseView; this.ResponseViews(idx:end)];
                parentResponseViews(this);
            else
                update(responseView);
            end
        end

        function updateResponseVisibility(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            responseView = getResponseView(this,response);
            updateVisibility(responseView,response.Visible & response.ShowInView,ArrayVisible=response.ArrayVisible);
        end

        function Axes = getAxes(this,idxInfo)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                idxInfo.Row (1,:) {mustBeInteger,mustBePositive} = 1:this.GridSize(1)
                idxInfo.Column (1,:) {mustBeInteger,mustBePositive} = 1:this.GridSize(2)
            end
            idxInfo = namedargs2cell(idxInfo);
            Axes = getAxes(this.AxesGrid,idxInfo{:});
        end

        function VisibleAxes = getVisibleAxes(this)
            VisibleAxes = this.AxesGrid.VisibleAxes;
        end

        function addCharacteristicType(this,type)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                type (1,1) string
            end
            this.CharacteristicsVisibility.(type) = false;
            this.CharacteristicTypes = [this.CharacteristicTypes; type];
        end

        function updateCharacteristic(this,characteristicType,responses,optionalArguments)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                characteristicType (1,1) string
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
                optionalArguments.Visible (1,1) logical = this.CharacteristicsVisibility.(characteristicType);
            end
            this.CharacteristicsVisibility.(characteristicType) = optionalArguments.Visible;
            if optionalArguments.Visible
                needsBuild = false;
                for ii = 1:length(this.ResponseViews)
                    if this.ResponseViews(ii).Response.Visible
                        charData = getCharacteristic(this.ResponseViews(ii),characteristicType);
                        if ~isempty(charData)
                            needsBuild = needsBuild || ~charData.IsInitialized;
                        end
                    end
                end
                if needsBuild
                    parentResponseViews(this);
                else
                    for ii = 1:length(this.ResponseViews)
                        if this.ResponseViews(ii).Response.Visible
                            charData = getCharacteristic(this.ResponseViews(ii),characteristicType);
                            if ~isempty(charData)
                                updateCharacteristic(this.ResponseViews(ii),characteristicType);
                                setCharacteristicVisible(this.ResponseViews(ii),characteristicType,optionalArguments.Visible);
                            end
                        end
                    end
                end
            else
                for ii = 1:length(this.ResponseViews)
                    if this.ResponseViews(ii).Response.Visible
                        charData = getCharacteristic(this.ResponseViews(ii),characteristicType);
                        if ~isempty(charData)
                            setCharacteristicVisible(this.ResponseViews(ii),characteristicType,optionalArguments.Visible);
                        end
                    end
                end
            end
            postUpdateCharacteristic(this,characteristicType,responses);
        end

        function build(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end

            % Create AxesGrid
            if isempty(this.AxesGrid) || ~isvalid(this.AxesGrid)
                createAxesGrid(this);
            end

            updateFocus(this);

            % Apply options to AxesGrid (need to set it directly on
            % for the case where AxesGrid labels are different, but Chart
            % and AxesView labels are the same)
            this.AxesGrid.Title = this.Chart.Title.String;
            this.AxesGrid.Subtitle = this.Chart.Subtitle.String;
            setXLabelString(this,this.Chart.XLabel.String);
            setYLabelString(this,this.Chart.YLabel.String);
            updateGrid(this);

            % Add listeners
            connect(this);

            % Connect to chart (for labels)
            connectStyleToChart(this);

            % Post build
            postBuild(this);
        end

        function responseView = getResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            % Find and return response by Tag
            idx = arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews);
            responseView = this.ResponseViews(idx);
        end

        function permuteResponseViews(this,idx)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                idx (:,1) double
            end
            this.ResponseViews = this.ResponseViews(idx);
            parentResponseViews(this);
        end

        function deleteResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                responseView (1,1) controllib.chart.internal.view.wave.BaseResponseView
            end
            delete(responseView);
            this.ResponseViews = this.ResponseViews(isvalid(this.ResponseViews));
        end

        function registerCharacteristicTypes(this,characteristicTypes)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                characteristicTypes (:,1) string
            end
            if ~isempty(characteristicTypes) && ~any(characteristicTypes == "")
                for k = 1:length(characteristicTypes)
                    if ~isfield(this.CharacteristicsVisibility,characteristicTypes(k))
                        this.CharacteristicsVisibility.(characteristicTypes(k)) = false;
                    end
                end
                this.CharacteristicTypes = string(fieldnames(this.CharacteristicsVisibility))';
            end
        end

        function unregisterCharacteristicTypes(this,characteristicTypes)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                characteristicTypes (:,1) string
            end
            for k = 1:length(characteristicTypes)
                this.CharacteristicsVisibility = rmfield(this.CharacteristicsVisibility,characteristicTypes(k));
            end
        end

        function removeToolbar(this)
            this.AxesGrid.ToolbarButtons = "none";
        end

        function syncAxesGridXLimits(this)
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.XLimits = this.XLimits;
                this.AxesGrid.XLimitsMode = this.XLimitsMode;
                if ~this.XLimitsFocusFromResponses
                    this.AxesGrid.XLimitsFocus = this.XLimitsFocus;
                end
                update(this.AxesGrid);
            end
        end

        function syncAxesGridYLimits(this)
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.YLimits = this.YLimits;
                this.AxesGrid.YLimitsMode = this.YLimitsMode;
                if ~this.YLimitsFocusFromResponses
                    this.AxesGrid.YLimitsFocus = this.YLimitsFocus;
                end
                update(this.AxesGrid);
            end
        end

        function syncAxesGridParent(this)
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                syncTiledLayoutParent(this.AxesGrid);
            end
        end

        function setAxesGrid(this,hAxesGrid)
            arguments
                this
                hAxesGrid
            end
            this.AxesGrid = hAxesGrid;
        end

        function parentResponseViews(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end
            for ii = 1:length(this.ResponseViews)
                for jj = 1:length(this.ResponseViews(ii).CharacteristicTypes)
                    charType = this.ResponseViews(ii).CharacteristicTypes(jj);
                    if isfield(this.CharacteristicsVisibility,charType) && this.CharacteristicsVisibility.(charType)
                        buildCharacteristic(this.ResponseViews(ii),charType);
                    end
                end
            end
            if ~isempty(this.ResponseViews)
                ax = getParentAxes(this);
                setParent(this.ResponseViews,ax,this.GridSize,this.AxesGrid.SubGridSize);
            end
            for ii = 1:length(this.ResponseViews)
                if this.ResponseViews(ii).Response.Visible
                    for jj = 1:length(this.ResponseViews(ii).CharacteristicTypes)
                        charType = this.ResponseViews(ii).CharacteristicTypes(jj);
                        if isfield(this.CharacteristicsVisibility,charType)
                            if this.CharacteristicsVisibility.(charType)
                                updateCharacteristic(this.ResponseViews(ii),charType);
                            end
                            setCharacteristicVisible(this.ResponseViews(ii),charType,...
                                this.CharacteristicsVisibility.(charType));
                        end
                    end
                end
            end
            for k = 1:length(this.ResponseViews)
                postParentResponseView(this,this.ResponseViews(k));
            end
        end

        function unparentResponseViews(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end

            % This unparents all the graphic objects that the ResponseView
            % manages
            for k = 1:length(this.ResponseViews)
                unParent(this.ResponseViews(k));
            end
        end
    end

    %% Get/Set
    methods
        % Toolbar
        function Toolbar = get.Toolbar(this)
            Toolbar = this.AxesGrid.Toolbar;
        end

        % Visible
        function Visible = get.Visible(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end
            Visible = this.AxesGrid.Visible;
        end

        function set.Visible(this,Visible)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                Visible (1,1) matlab.lang.OnOffSwitchState
            end
            this.AxesGrid.Visible = Visible;
        end

        % CurrentInteractionMode
        function currentInteractionMode = get.CurrentInteractionMode(this)
            currentInteractionMode = this.AxesGrid.CurrentInteractionMode;
        end

        function set.CurrentInteractionMode(this,currentInteractionMode)
            this.AxesGrid.CurrentInteractionMode = currentInteractionMode;
        end

        % GridSize
        function GridSize = get.GridSize(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end
            GridSize = this.AxesGrid.GridSize;
        end

        function set.GridSize(this,GridSize)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                GridSize (1,2) double {mustBeInteger,mustBePositive}
            end
            this.AxesGrid.GridSize = GridSize;
        end

        % Title
        function Title = get.Title(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end
            Title = this.AxesGrid.Title;
        end

        function set.Title(this,Title)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                Title (:,1) string
            end
            this.AxesGrid.Title = Title;
        end

        % Subtitle
        function Subtitle = get.Subtitle(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end
            Subtitle = this.AxesGrid.Subtitle;
        end

        function set.Subtitle(this,Subtitle)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                Subtitle (:,1) string
            end
            this.AxesGrid.Subtitle = Subtitle;
        end

        % XLabel
        function XLabel = get.XLabel(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end
            XLabel = getXLabelString(this);
        end

        function set.XLabel(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                XLabel (:,1) string
            end
            setXLabelString(this,XLabel);
        end

        % YLabel
        function YLabel = get.YLabel(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end
            YLabel = getYLabelString(this);
        end

        function set.YLabel(this,YLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                YLabel (:,1) string
            end
            setYLabelString(this,YLabel);
        end

        % XLimits
        function XLimits = get.XLimits(this)
            XLimits = this.Chart.XLimits;
        end

        function set.XLimits(this,XLimits)
            this.Chart.XLimits = XLimits;
        end

        % YLimits
        function YLimits = get.YLimits(this)
            YLimits = this.Chart.YLimits;
        end

        function set.YLimits(this,YLimits)
            this.Chart.YLimits = YLimits;
        end

        % XLimitsMode
        function XLimitsMode = get.XLimitsMode(this)
            XLimitsMode = this.Chart.XLimitsMode;
        end

        function set.XLimitsMode(this,XLimitsMode)
            this.Chart.XLimitsMode = XLimitsMode;
        end

        % YLimitsMode
        function YLimitsMode = get.YLimitsMode(this)
            YLimitsMode = this.Chart.YLimitsMode;
        end

        function set.YLimitsMode(this,YLimitsMode)
            this.Chart.YLimitsMode = YLimitsMode;
        end

        % XLimitsFocus
        function XLimitsFocus = get.XLimitsFocus(this)
            XLimitsFocus = this.Chart.XLimitsFocus;
        end

        function set.XLimitsFocus(this,XLimitsFocus)
            this.Chart.XLimitsFocus = XLimitsFocus;
        end

        % YLimitsFocus
        function YLimitsFocus = get.YLimitsFocus(this)
            YLimitsFocus = this.Chart.YLimitsFocus;
        end

        function set.YLimitsFocus(this,YLimitsFocus)
            this.Chart.YLimitsFocus = YLimitsFocus;
        end

        % XLimitsFocusFromResponses
        function XLimitsFocusFromResponses = get.XLimitsFocusFromResponses(this)
            XLimitsFocusFromResponses = this.Chart.XLimitsFocusFromResponses;
        end

        function set.XLimitsFocusFromResponses(this,XLimitsFocusFromResponses)
            this.Chart.XLimitsFocusFromResponses = XLimitsFocusFromResponses;
        end

        % YLimitsFocusFromResponses
        function YLimitsFocusFromResponses = get.YLimitsFocusFromResponses(this)
            YLimitsFocusFromResponses = this.Chart.YLimitsFocusFromResponses;
        end

        function set.YLimitsFocusFromResponses(this,YLimitsFocusFromResponses)
            this.Chart.YLimitsFocusFromResponses = YLimitsFocusFromResponses;
        end

        % SyncChartWithAxesView
        function SyncChartWithAxesView = get.SyncChartWithAxesView(this)
            SyncChartWithAxesView = this.Chart.SyncChartWithAxesView;
        end

        function set.SyncChartWithAxesView(this,SyncChartWithAxesView)
            this.Chart.SyncChartWithAxesView = SyncChartWithAxesView;
        end

        % VisibleResponses
        function VisibleResponses = get.VisibleResponses(this)
            r = this.Chart.Responses;
            if isempty(r)
                VisibleResponses = controllib.chart.internal.foundation.BaseResponse.empty;
            else
                VisibleResponses = r(arrayfun(@(x) isvalid(x) & x.Visible & x.ShowInView,r));
            end
        end
    end

    %% Protected methods
    methods(Access = protected)
        function connectStyleToChart(this)
            labelType = ["Title";"Subtitle";"XLabel";"YLabel"];
            for ii = 1:length(labelType)
                L = addlistener(this.Chart.(labelType(ii)),"LabelChanged",@(es,ed) cbLabelChanged(this,es,ed,labelType(ii)));
                registerListeners(this,L,labelType(ii)+"Changed");
                L = addlistener(this.Chart.(labelType(ii)),"VisibilityChanged",@(es,ed) cbLabelVisibilityChanged(this,es,labelType(ii)));
                registerListeners(this,L,labelType(ii)+"VisibilityChanged");
            end
            L = addlistener(this.Chart.AxesStyle,"AxesStyleChanged",@(es,ed) cbChartAxesStyleChanged(this,ed));
            registerListeners(this,L,"ChartAxesStyleChanged");
        end

        function cbLabelChanged(this,es,ed,labelType)
            switch ed.PropertyChanged
                case "String"
                    this.(labelType) = es.String;
                otherwise
                    this.Style.(labelType).(ed.PropertyChanged) = es.(ed.PropertyChanged);
            end
        end

        function cbLabelVisibilityChanged(this,es,labelType)
            this.AxesGrid.(labelType+"Visible") = es.Visible;
            update(this.AxesGrid);
        end

        function cbChartAxesStyleChanged(this,ed)
            customGridProps = controllib.chart.internal.options.AxesStyle.getCustomGridProperties();
            switch ed.PropertyChanged
                case cellstr(customGridProps)
                    updateGrid(this);
                case "GridVisible"
                    this.Style.Axes.XGrid = this.Chart.AxesStyle.GridVisible;
                    this.Style.Axes.YGrid = this.Chart.AxesStyle.GridVisible;
                case "MinorGridVisible"
                    this.Style.Axes.XMinorGrid = this.Chart.AxesStyle.MinorGridVisible;
                    this.Style.Axes.YMinorGrid = this.Chart.AxesStyle.MinorGridVisible;
                otherwise
                    this.Style.Axes.(ed.PropertyChanged) = this.Chart.AxesStyle.(ed.PropertyChanged);
            end
        end

        function connect(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end

            % Add Listener to NextPlot
            L = addlistener(this.AxesGrid,'NextPlot','PostSet',@(es,ed) set(this.Chart,NextPlot=ed.AffectedObject.NextPlot));
            registerListeners(this,L,"NextPlot");

            % Add Listener to AxesHit event
            L = addlistener(this.AxesGrid,'AxesHit',@(es,ed) cbAxesHit(this,ed));
            registerListeners(this,L,"AxesHit");

            % Add Listener to AxesReset event
            L = addlistener(this.AxesGrid,'AxesReset',@(es,ed) cbAxesReset(this));
            registerListeners(this,L,"AxesReset");

            % Add Listener to GridSizeChanged event
            L = addlistener(this.AxesGrid,'GridSizeChanged',@(es,ed) notify(this,"GridSizeChanged"));
            registerListeners(this,L,"GridSizeChanged");

            % Update listeners
            registerListeners(this,addlistener(this.AxesGrid,'LayoutChanged',...
                @(es,ed) cbAxesGridLayoutChanged(this)),'AxesGridLayoutChangedListener');
            registerListeners(this,addlistener(this.AxesGrid,'LabelsChanged',...
                @(es,ed) cbAxesGridLabelsChanged(this)),'AxesGridLabelsChangedListener');
            registerListeners(this,addlistener(this.AxesGrid,'XLimitsChanged',...
                @(es,ed) cbAxesGridXLimitsChanged(this)),'AxesGridXLimitsChangedListener');
            registerListeners(this,addlistener(this.AxesGrid,'YLimitsChanged',...
                @(es,ed) cbAxesGridYLimitsChanged(this)),'AxesGridYLimitsChangedListener');

            % LabelStyle listeners
            registerLabelStyleListeners(this);

            connect_(this);
        end

        function registerLabelStyleListeners(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end
            titleL = addlistener(this.Style.Title,'LabelStyleChanged',@(es,ed) update(this.AxesGrid,UpdateLabels=true));
            subtitleL = addlistener(this.Style.Subtitle,'LabelStyleChanged',@(es,ed) update(this.AxesGrid,UpdateLabels=true));
            xL = addlistener(this.Style.XLabel,'LabelStyleChanged',@(es,ed) update(this.AxesGrid,UpdateLabels=true));
            yL = addlistener(this.Style.YLabel,'LabelStyleChanged',@(es,ed) update(this.AxesGrid,UpdateLabels=true));
            axL = addlistener(this.Style.Axes,'AxesStyleChanged',@(es,ed) updateAxesStyle(this));
            registerListeners(this,[titleL,subtitleL,xL,yL,axL],{'TitleChangedListener';'SubtitleChangedListener';'XLabelChangedListener';...
                'YLabelChangedListener';'AxesStyleChangedListener'});
        end

        function createAxesGrid(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end
            gridSize = getAxesGridGridSize(this);
            subGridSize = getAxesGridSubGridSize(this);
            optionalInputs = getAxesGridInputs(this);
            optionalInputs = namedargs2cell(optionalInputs);
            this.AxesGrid = controllib.chart.internal.layout.AxesGrid(getChartLayout(this.Chart),...
                gridSize,subGridSize,optionalInputs{:});
            ax = getAxes(this.AxesGrid);
            ax(1).InteractionOptions.DatatipsPlacementMethod = this.SnapToDataVertexForDataTipInteraction;
        end

        function gridSize = getAxesGridGridSize(~)
            gridSize = [1 1];
        end

        function subGridSize = getAxesGridSubGridSize(~)
            subGridSize = [1 1];
        end

        function inputs = getAxesGridInputs(this)
            inputs.Axes = this.Chart.Axes;
            inputs.TitleStyle = this.Style.Title;
            inputs.SubtitleStyle = this.Style.Subtitle;
            inputs.XLabelStyle = this.Style.XLabel;
            inputs.YLabelStyle = this.Style.YLabel;
            inputs.AxesStyle = this.Style.Axes;
            inputs.InteractionOptions = matlab.graphics.interaction.interactionoptions.CartesianAxesInteractionOptions(...
                RotateSupported=false,BrushSupported=false,...
                DatatipsPlacementMethod=this.SnapToDataVertexForDataTipInteraction);
        end

        function postBuild(this)
            syncAxesGridXLimits(this);
            syncAxesGridYLimits(this);
            cbViewXLimitsChanged(this.Chart,this.AxesGrid.XLimits,this.AxesGrid.XLimitsMode,this.AxesGrid.XLimitsFocus);
            cbViewYLimitsChanged(this.Chart,this.AxesGrid.YLimits,this.AxesGrid.YLimitsMode,this.AxesGrid.YLimitsFocus);
        end

        function ax = getParentAxes(this)
            ax = getAxes(this.AxesGrid);
        end

        function XLabel = getXLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end
            XLabel = this.AxesGrid.XLabel;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                XLabel (1,1) string
            end
            this.AxesGrid.XLabel = XLabel;
        end

        function YLabel = getYLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end
            YLabel = this.AxesGrid.YLabel;
        end

        function setYLabelString(this,YLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                YLabel (1,1) string
            end
            this.AxesGrid.YLabel = YLabel;
        end

        function updateGrid(this)
            disableListeners(this.Chart,"ChildAddedToAxes");
            updateGrid_(this);
            enableListeners(this.Chart,"ChildAddedToAxes");
            notify(this,'GridUpdated');
        end

        function postUpdateCharacteristic(this,characteristicType,responses) %#ok<INUSD>
        end

        function cbAxesHit(this,ed)
            fig = ancestor(ed.Data.Axes,'figure');
            switch fig.SelectionType
                case 'normal'
                    deleteAllDataTips(this,ed);
                case 'open'
                    notify(this,'AxesHitToOpenPropertyEditor');
            end
            this.Chart.DataAxes = [ed.Data.Row ed.Data.Column];
        end

        function cbAxesReset(this)
            cla(this.Chart,"reset");
        end

        function deleteAllDataTips(this,ed) %#ok<INUSD>
            % Select inputIdx and outputIdx based on IOGrouping
            for k = 1:length(this.ResponseViews)
                deleteAllDataTips(this.ResponseViews(k));
            end
        end

        function postParentResponseView(this,responseView) %#ok<INUSD>
        end

        function connect_(this) %#ok<MANU>
        end

        function updateGrid_(this) %#ok<MANU>
        end

        function cbAxesGridLayoutChanged(this) %#ok<MANU>
        end

        function cbAxesGridLabelsChanged(this) %#ok<MANU>
        end

        function cbAxesGridXLimitsChanged(this)
            this.SyncChartWithAxesView = false;
            cbViewXLimitsChanged(this.Chart,this.AxesGrid.XLimits,this.AxesGrid.XLimitsMode,this.AxesGrid.XLimitsFocus);
            this.SyncChartWithAxesView = true;
            for k = 1:length(this.ResponseViews)
                types = this.ResponseViews(k).CharacteristicTypes;
                for n = 1:length(types)
                    updateCharacteristicByLimits(this.ResponseViews(k),types(n));
                end
            end
        end

        function cbAxesGridYLimitsChanged(this)
            this.SyncChartWithAxesView = false;
            cbViewYLimitsChanged(this.Chart,this.AxesGrid.YLimits,this.AxesGrid.YLimitsMode,this.AxesGrid.YLimitsFocus);
            this.SyncChartWithAxesView = true;
            for k = 1:length(this.ResponseViews)
                types = this.ResponseViews(k).CharacteristicTypes;
                for n = 1:length(types)
                    updateCharacteristicByLimits(this.ResponseViews(k),types(n));
                end
            end
        end
    end

    %% Hidden methods
    methods(Hidden)
        function chart = qeGetChart(this)
            chart = this.Chart;
        end

        function AxesGrid = qeGetAxesGrid(this)
            AxesGrid = this.AxesGrid;
        end

        function ResponseViews = qeGetResponseViews(this)
            ResponseViews = this.ResponseViews;
        end

        function viewStyle = qeGetStyle(this)
            viewStyle = this.Style;
        end

        function qeAddResponseView(this,varargin)
            addResponseView(this,varargin{:});
        end

        function registerResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
                responseView (1,1) controllib.chart.internal.view.wave.BaseResponseView
            end
            if isempty(this.ResponseViews)
                this.ResponseViews = responseView;
            else
                this.ResponseViews = [this.ResponseViews; responseView];
            end
            parentResponseViews(this);
        end

        function parentCustomCharacteristics(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.BaseAxesView
            end
            parentResponseViews(this);
        end

        function qeRegisterCharacteristicTypes(this,varargin)
            registerCharacteristicTypes(this,varargin{:});
        end

        function qeUpdateFocus(this,varargin)
            updateFocus(this);
        end

        function refreshGrid(this)
            updateGrid(this);
        end

        function updateAxesStyle(this)
            updateGrid(this);
            update(this.AxesGrid,UpdateLabels=true);
        end

        function createResponseDataTips(this)
            for k = 1:length(this.ResponseViews)
                if this.ResponseViews(k).Response.Visible
                    createResponseDataTips(this.ResponseViews(k));
                end
            end
        end
    end
end

function focus = localMergeFocus(focus1,focus2)
focus = focus1;
for kr = 1:size(focus1,1)
    for kc = 1:size(focus1,2)
        if size(focus2,1) >= kr && size(focus2,2) >= kc
            focus{kr,kc}(1) = min(focus1{kr,kc}(1),focus2{kr,kc}(1));
            focus{kr,kc}(2) = max(focus1{kr,kc}(2),focus2{kr,kc}(2));
        end
    end
end
end
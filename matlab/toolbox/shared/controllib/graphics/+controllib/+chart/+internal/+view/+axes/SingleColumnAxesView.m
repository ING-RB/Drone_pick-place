classdef (Abstract) SingleColumnAxesView < controllib.chart.internal.view.axes.BaseAxesView
    % controllib.chart.internal.view.OutputView manages the responses and the axes and all chart
    % properties associated with it
    %
    % h = OutputView(nOutputs)
    %   nOutputs    number of outputs
    %
    % h = OutputView(______,Name-Value)
    %   GridSize            size of grid of axes, default value is [nOutputs,nInputs]
    %   OuterPosition       [x0,y0,w,h] in normalized units, default value is [0 0 1 1]
    %   Title               string specifying chart title, default is ""
    %   XLabel              string specifying chart xlabel, default is ""
    %   YLabel              string specifying chart ylabel, default is ""
    %   OutputNames         string array specifying output names, should be compatible with nOutputs/GridSize
    %   Visible             matlab.lang.OnOffSwitchState scalar specifying visibility
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
    %   OutputLabelStyle    struct with FontSize,FontWeight,FontAngle,Color and Interpreter for output labels
    %   AxesStyle           struct with FontSize,FontWeight,FontAngle,Color and Interpreter for tick labels
    %
    % Public properties:
    %   Title               (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   XLabel              (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   YLabel              (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)
    %   OutputNames         (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property)    
    %   Visible             (implementation of <a href="matlab:help controllib.chart.internal.foundation.AbstractPlot">AbstractPlot</a> dependent property) 
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
    %       - systems is array of type controllib.chart.internal.system.AbstractSystem
    %
    %   updateResponseVisibility(this,system)
    %       - updates visibility of response linked to system based on system.Visible
    %   
    %   addResponse(this,system)
    %       - creates and adds response (controllib.chart.internal.response.BaseResponse) using 
    %       system (controllib.chart.internal.system.AbstractSystem)
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
    %       - create and return array of response (controllib.chart.internal.response.BaseResponse) 
    %       using systems
    
    % Copyright 2023 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        % Limits
        XLimitsSharing
        YLimitsSharing

        % Row
        RowNames
        RowVisible
        RowGrouping
    end

    properties (Dependent,SetAccess=private)
        NRows
    end

    properties (Access=protected, Transient,NonCopyable)
        RowSelectorWidget
    end

    properties (Access=private)
        IsUpdatingGridSize = false
    end

    %% Constructor
    methods
        function this = SingleColumnAxesView(chart,varargin)
            % Construct view
            arguments
                chart (1,1) controllib.chart.internal.foundation.SingleColumnPlot
            end

            arguments (Repeating)
                varargin
            end
            
            this@controllib.chart.internal.view.axes.BaseAxesView(chart,varargin{:});
        end

        function delete(this)
            delete(this.RowSelectorWidget);
            delete@controllib.chart.internal.view.axes.BaseAxesView(this);
        end
    end

    %% Public methods
    methods
        function responseViews = addResponseView(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse {mustBeNonempty}
            end
            idx = length(this.ResponseViews);
            for ii = 1:numel(responses)
                responseView = createResponseView(this,responses(ii));
                responseView.RowNames = this.RowNames;
                if isempty(this.ResponseViews)
                    this.ResponseViews = responseView;
                else
                    this.ResponseViews = [this.ResponseViews; responseView];
                end
            end
            responseViews = this.ResponseViews(idx+1:end);
            parentResponseViews(this);
            for ii = length(responseViews)
                postParentResponseView(this,responseViews(ii));
            end
        end

        function updateFocus(this)
            updateFocus@controllib.chart.internal.view.axes.BaseAxesView(this);
            switch this.RowGrouping
                case "all"
                    allXLimitsFocus = cell2mat(this.AxesGrid.XLimitsFocus(:));
                    this.AxesGrid.XLimitsFocus = [min(allXLimitsFocus(:,1)), max(allXLimitsFocus(:,2))];
                    allYLimitsFocus = cell2mat(this.AxesGrid.YLimitsFocus(:));
                    this.AxesGrid.YLimitsFocus = [min(allYLimitsFocus(:,1)), max(allYLimitsFocus(:,2))];
            end
            update(this.AxesGrid);
        end

        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse ...
                    {controllib.chart.internal.view.axes.SingleColumnAxesView.mustBeRowResponse(response)}
            end
            idx = find(arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews),1);
            responseView = this.ResponseViews(idx);
            hasDifferentCharacteristics = ~isempty(setdiff(...
                union(responseView.CharacteristicTypes,response.CharacteristicTypes),...
                intersect(responseView.CharacteristicTypes,response.CharacteristicTypes)));
            if responseView.Response.NResponses ~= response.NResponses ||...
                    responseView.Response.NRows ~= response.NRows ||...
                    ~isequal(responseView.PlotRowIdx,response.ResponseData.PlotOutputIdx) || ...
                    hasDifferentCharacteristics
                delete(responseView);
                this.ResponseViews = this.ResponseViews(isvalid(this.ResponseViews));
                responseView = createResponseView(this,response);
                responseView.OutputNames = this.RowNames;
                createResponseDataTips(responseView);
                this.ResponseViews = [this.ResponseViews(1:idx-1); responseView; this.ResponseViews(idx:end)];
                parentResponseViews(this);
                postParentResponseView(this,responseView);
            else
                update(responseView);
            end
        end

        function updateResponseVisibility(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            responseView = getResponseView(this,response);
            updateVisibility(responseView,response.Visible & response.ShowInView,RowVisible=this.RowVisible(responseView.PlotRowIdx),...
                ArrayVisible=response.ArrayVisible);
        end

        function showRowSelector(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
            end
            if isempty(this.RowSelectorWidget) || ~isvalid(this.RowSelectorWidget)
                this.RowSelectorWidget = controllib.chart.internal.widget.IOSelectorDialog(this,getString(message('Controllib:gui:strOutputSelector')));
            end
            show(this.RowSelectorWidget,ancestor(this.Chart,'figure'));
            updateUI(this.RowSelectorWidget);
            pack(this.RowSelectorWidget);
        end

        function updateAxesGridSize(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
            end
            newSize = this.NRows;
            oldSize = this.GridSize(1);

            if isequal(oldSize,newSize)
                return;
            end

            this.IsUpdatingGridSize = true;

            visible = this.AxesGrid.Visible;
            this.AxesGrid.Visible = 'off';

            % Set to default values
            if ~isempty(this.RowSelectorWidget) && isvalid(this.RowSelectorWidget)
                close(this.RowSelectorWidget);
            end

            % Update axes grid
            this.AxesGrid.GridSize(1) = newSize;
            this.AxesGrid.GridRowLabelsVisible = newSize~=1;
            update(this.AxesGrid);
            
            this.SyncChartWithAxesView = false;
            if newSize > oldSize
                this.RowVisible = [this.RowVisible;true(newSize-oldSize,1)];
            else
                this.RowVisible = this.RowVisible(1:newSize);
            end
            this.SyncChartWithAxesView = true;

            % Reset grouping
            setRowGrouping(this,false);

            this.AxesGrid.Visible = visible;

            this.IsUpdatingGridSize = false;
        end

        function syncAxesGridXLimits(this)
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.XLimitsSharing = this.XLimitsSharing;
            end
            syncAxesGridXLimits@controllib.chart.internal.view.axes.BaseAxesView(this);
        end

        function syncAxesGridYLimits(this)
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.YLimitsSharing = this.YLimitsSharing;
            end
            syncAxesGridYLimits@controllib.chart.internal.view.axes.BaseAxesView(this);
        end      

        function syncAxesGridLayout(this)
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                setRowGrouping(this)
            end
        end

        function syncAxesGridLabels(this)
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.GridRowLabels = generateStringForRowLabels(this);
                applySISOLabelOverride(this);
            end
        end
    end

    %% Get/Set
    methods
        % XLimitsSharing
        function XLimitsSharing = get.XLimitsSharing(this)
            XLimitsSharing = this.Chart.XLimitsSharing;
        end

        function set.XLimitsSharing(this,XLimitsSharing)
            this.Chart.XLimitsSharing = XLimitsSharing;
        end

        % YLimitsSharing
        function YLimitsSharing = get.YLimitsSharing(this)
            YLimitsSharing = this.Chart.YLimitsSharing;
        end

        function set.YLimitsSharing(this,YLimitsSharing)
            this.Chart.YLimitsSharing = YLimitsSharing;
        end

        % NRows
        function NRows = get.NRows(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
            end
            NRows = this.Chart.NRows;
        end

        % RowVisible
        function RowVisible = get.RowVisible(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
            end
            RowVisible = this.Chart.RowVisible;
        end

        function set.RowVisible(this,RowVisible)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
                RowVisible (:,1) matlab.lang.OnOffSwitchState
            end
            this.Chart.RowVisible = RowVisible;
        end

        % RowNames
        function RowNames = get.RowNames(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
            end
            RowNames = this.Chart.RowNames;
        end

        function set.RowNames(this,RowNames)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
                RowNames (:,1) string
            end
            this.Chart.RowNames = RowNames;
        end

        % RowGrouping
        function RowGrouping = get.RowGrouping(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
            end
            RowGrouping = this.Chart.RowGrouping;
        end

        function set.RowGrouping(this,RowGrouping)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
                RowGrouping (1,1) string {mustBeMember(RowGrouping,["none","all"])}
            end
            this.Chart.RowGrouping = RowGrouping;
        end
    end

    methods(Access = protected)
        function connectStyleToChart(this)
            connectStyleToChart@controllib.chart.internal.view.axes.BaseAxesView(this);
            L = addlistener(this.Chart.RowLabels,"LabelChanged",@(es,ed) cbLabelChanged(this,es,ed,"RowLabels"));
            registerListeners(this,L,"RowLabelsChanged");
            L = addlistener(this.Chart.RowLabels,"VisibilityChanged",@(es,ed) cbLabelVisibilityChanged(this,es,"RowLabels"));
            registerListeners(this,L,"RowLabelsVisibilityChanged");
        end

        function applySISOLabelOverride(this)
            if this.NRows == 1 && this.Chart.HasCustomRowNames
                this.AxesGrid.GridRowLabels = getString(message('Controllib:plots:strToLabel',this.RowNames));
                this.AxesGrid.GridRowLabelsVisible = true;
            end
            update(this.AxesGrid);
        end

        function cbLabelChanged(this,es,ed,labelType)
            switch labelType
                case "RowLabels"
                    if ~strcmp(ed.PropertyChanged,"String")
                        this.Style.(labelType).(ed.PropertyChanged) = es.(ed.PropertyChanged);
                    end
                    applySISOLabelOverride(this);
                otherwise
                    cbLabelChanged@controllib.chart.internal.view.axes.BaseAxesView(this,es,ed,labelType)
            end
        end

        function cbLabelVisibilityChanged(this,es,labelType)
            switch labelType
                case "RowLabels"
                    if this.NRows > 1
                        switch this.RowGrouping
                            case "none"
                                this.AxesGrid.GridRowLabelsVisible = es.Visible;
                                applySISOLabelOverride(this);
                        end
                    end
                otherwise
                    cbLabelVisibilityChanged@controllib.chart.internal.view.axes.BaseAxesView(this,es,labelType)
            end
        end

        function registerLabelStyleListeners(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
            end
            registerLabelStyleListeners@controllib.chart.internal.view.axes.BaseAxesView(this);
            oL = addlistener(this.Style.RowLabels,'LabelStyleChanged',@(es,ed) update(this.AxesGrid,UpdateLabels=true));
            registerListeners(this,oL,"RowLabelChangedListener");
        end
        
        function gridSize = getAxesGridGridSize(this)
            gridSize = [this.Chart.NRows 1];
        end

        function inputs = getAxesGridInputs(this)
            inputs = getAxesGridInputs@controllib.chart.internal.view.axes.BaseAxesView(this);
            inputs.XLimitsSharing = this.XLimitsSharing;
            inputs.YLimitsSharing = this.YLimitsSharing;
            inputs.RowLabels = generateStringForRowLabels(this);
            inputs.RowLabelStyle = this.Style.RowLabels;
            switch this.RowGrouping
                case 'all'
                    inputs.GridRowVisible = [true; false(this.NRows-1,1)];
                    inputs.RowLabelsVisible = false;
                case 'none'
                    inputs.GridRowVisible = this.RowVisible;
                    inputs.RowLabelsVisible = this.NRows > 1;
            end
        end
    end

    methods (Access = protected)
        function deleteAllDataTips(this,ed)
            % Select inputIdx and outputIdx based on OutputGrouping
            switch this.RowGrouping
                case 'none'
                    rowIdx = find(this.RowVisible,ed.Data.Row);
                    rowIdx = rowIdx(end);
                case 'all'
                    rowIdx = 1:this.NRows;
            end
            for k = 1:length(this.ResponseViews)
                deleteAllDataTips(this.ResponseViews(k),rowIdx,1);
            end
        end

        function postBuild(this)
            postBuild@controllib.chart.internal.view.axes.BaseAxesView(this);
            applySISOLabelOverride(this);
        end

        function setRowGrouping(this,reparent)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SingleColumnAxesView
                reparent (1,1) logical = true
            end

            visible = this.AxesGrid.Visible;
            this.AxesGrid.Visible = 'off';

            switch this.RowGrouping
                case 'all'
                    this.AxesGrid.GridRowVisible = [true; false(this.NRows-1,1)];

                    this.AxesGrid.GridRowLabelsVisible = false;
                case 'none'
                    % Modify AxesGrid GridSize
                    this.AxesGrid.GridRowVisible = this.RowVisible;

                    % Set row labels if multiple outputs
                    this.AxesGrid.GridRowLabelsVisible = this.NRows > 1;
            end
            applySISOLabelOverride(this);

            % Update grouped focuses
            updateFocus(this);

            % Reparent response views
            if reparent
                parentResponseViews(this);
                for k = 1:length(this.ResponseViews)
                    updateVisibility(this.ResponseViews(k),...
                        RowVisible=this.RowVisible(min(this.ResponseViews(k).PlotRowIdx,length(this.RowVisible))));
                end
            end

            this.AxesGrid.Visible = visible;
        end

        function ax = getParentAxes(this)
            switch this.RowGrouping
                case "all"
                    ax = getAxes(this.AxesGrid,Row=1);
                    ax = repmat(ax,this.NRows,1);
                case "none"
                    ax = getAxes(this.AxesGrid);
            end
        end

        function cbAxesGridXLimitsChanged(this)
            this.SyncChartWithAxesView = false;
            this.XLimitsSharing = this.AxesGrid.XLimitsSharing;
            this.SyncChartWithAxesView = true;
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.BaseAxesView(this);
        end

        function cbAxesGridYLimitsChanged(this)
            this.SyncChartWithAxesView = false;
            this.YLimitsSharing = this.AxesGrid.YLimitsSharing;
            this.SyncChartWithAxesView = true;
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.BaseAxesView(this);
        end

        function cbAxesGridLayoutChanged(this)
            if ~this.IsUpdatingGridSize
                for k = 1:length(this.ResponseViews)
                    updateVisibility(this.ResponseViews(k),...
                        RowVisible=this.RowVisible(min(this.ResponseViews(k).PlotRowIdx,length(this.RowVisible))));
                end
            end
        end

        function cbAxesGridLabelsChanged(this)
            % Modify Responses
            for k = 1:length(this.ResponseViews)
                this.ResponseViews(k).RowNames = this.RowNames;
            end
        end

        function rowLabels = generateStringForRowLabels(this)
            rowLabels = this.RowNames;
        end
    end

    %% Sealed static protected methods
    methods (Sealed,Static,Access=protected)
        function mustBeRowResponse(responses)
            arrayfun(@(x) mustBeA(x,'controllib.chart.internal.foundation.MixInRowResponse'),responses);
        end
    end

    %% Hidden methods
    methods(Hidden)
        function dlg = qeGetRowSelector(this)
            dlg = this.RowSelectorWidget;
        end
    end
end
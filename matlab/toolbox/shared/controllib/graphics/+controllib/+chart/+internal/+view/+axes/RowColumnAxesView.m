classdef (Abstract) RowColumnAxesView < controllib.chart.internal.view.axes.BaseAxesView & ...
        controllib.chart.internal.view.axes.MixInAxesViewLabels
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
    
    % Copyright 2021-2022 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        % Limits
        XLimitsSharing
        YLimitsSharing

        % Row/Column
        RowNames 
        ColumnNames
        RowVisible
        ColumnVisible
        RowColumnGrouping
    end

    properties (Dependent,SetAccess=private)
        NRows
        NColumns
    end

    properties (Access=protected, Transient, NonCopyable)
        RowColumnSelectorWidget
    end

    properties (Access=private)
        IsUpdatingGridSize = false
    end

    %% Constructor/destructor
    methods
        function this = RowColumnAxesView(chart,varargin)
            % Construct view
            arguments
                chart (1,1) controllib.chart.internal.foundation.RowColumnPlot
            end

            arguments (Repeating)
                varargin
            end

            this@controllib.chart.internal.view.axes.BaseAxesView(chart,varargin{:});
        end

        function delete(this)
            delete(this.RowColumnSelectorWidget);
            delete@controllib.chart.internal.view.axes.BaseAxesView(this);
        end
    end

    %% Public methods
    methods
        function responseViews = addResponseView(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse {mustBeNonempty}
            end
            idx = length(this.ResponseViews);
            for ii = 1:numel(responses)
                responseView = createResponseView(this,responses(ii));
                responseView.ColumnNames = this.ColumnNames;
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
            switch this.RowColumnGrouping
                case "all"
                    allXLimitsFocus = cell2mat(this.AxesGrid.XLimitsFocus(:));
                    this.AxesGrid.XLimitsFocus = [min(allXLimitsFocus(:,1)), max(allXLimitsFocus(:,2))];
                    allYLimitsFocus = cell2mat(this.AxesGrid.YLimitsFocus(:));
                    this.AxesGrid.YLimitsFocus = [min(allYLimitsFocus(:,1)), max(allYLimitsFocus(:,2))];
                case "columns"
                    xLimitsFocus = cell(this.NRows,1);
                    yLimitsFocus = cell(this.NRows,1);
                    for ko = 1:this.NRows
                        allXLimitsFocus = cell2mat(this.AxesGrid.XLimitsFocus(ko,:)');
                        xLimitsFocus{ko} = [min(allXLimitsFocus(:,1)), max(allXLimitsFocus(:,2))];

                        allYLimitsFocus = cell2mat(this.AxesGrid.YLimitsFocus(ko,:)');
                        yLimitsFocus{ko} = [min(allYLimitsFocus(:,1)), max(allYLimitsFocus(:,2))];
                    end
                    this.AxesGrid.XLimitsFocus = repmat(xLimitsFocus,1,this.NColumns);
                    this.AxesGrid.YLimitsFocus = repmat(yLimitsFocus,1,this.NColumns);
                case "rows"
                    xLimitsFocus = cell(1,this.NColumns);
                    yLimitsFocus = cell(1,this.NColumns);
                    for ki = 1:this.NColumns
                        allXLimitsFocus = cell2mat(this.AxesGrid.XLimitsFocus(:,ki));
                        xLimitsFocus{ki} = [min(allXLimitsFocus(:,1)), max(allXLimitsFocus(:,2))];

                        allYLimitsFocus = cell2mat(this.AxesGrid.YLimitsFocus(:,ki));
                        yLimitsFocus{ki} = [min(allYLimitsFocus(:,1)), max(allYLimitsFocus(:,2))];
                    end
                    this.AxesGrid.XLimitsFocus = repmat(xLimitsFocus,this.NRows,1);
                    this.AxesGrid.YLimitsFocus = repmat(yLimitsFocus,this.NRows,1);
            end
            update(this.AxesGrid);
        end

        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse ...
                    {controllib.chart.internal.view.axes.RowColumnAxesView.mustBeRowColumnResponse(response)}
            end
            idx = find(arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews),1);
            responseView = this.ResponseViews(idx);
            hasDifferentCharacteristics = ~isempty(setdiff(...
                union(responseView.CharacteristicTypes,response.CharacteristicTypes),...
                intersect(responseView.CharacteristicTypes,response.CharacteristicTypes)));
            if responseView.Response.NResponses ~= response.NResponses ||...
                    responseView.Response.NRows ~= response.NRows ||...
                    responseView.Response.NColumns ~= response.NColumns ||...
                    ~isequal(responseView.PlotColumnIdx,response.ResponseData.PlotInputIdx) || ...
                    ~isequal(responseView.PlotRowIdx,response.ResponseData.PlotOutputIdx) || ...
                    hasDifferentCharacteristics
                delete(responseView);
                this.ResponseViews = this.ResponseViews(isvalid(this.ResponseViews));
                responseView = createResponseView(this,response);
                responseView.ColumnNames = this.ColumnNames;
                responseView.RowNames = this.RowNames;
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
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            responseView = getResponseView(this,response);
            updateVisibility(responseView,response.Visible & response.ShowInView,ColumnVisible=this.ColumnVisible(responseView.PlotColumnIdx),...
                RowVisible=this.RowVisible(responseView.PlotRowIdx),ArrayVisible=response.ArrayVisible);
        end

        function showRowColumnSelector(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
            end
            if isempty(this.RowColumnSelectorWidget) || ~isvalid(this.RowColumnSelectorWidget)
                this.RowColumnSelectorWidget = controllib.chart.internal.widget.IOSelectorDialog(this,getString(message('Controllib:gui:strIOSelector')));
            end
            show(this.RowColumnSelectorWidget,ancestor(this.Chart,'figure'));
            updateUI(this.RowColumnSelectorWidget);
            pack(this.RowColumnSelectorWidget);
        end
        
        function updateAxesGridSize(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
            end
            newSize = [this.NRows this.NColumns];
            oldSize = this.GridSize;

            if isequal(oldSize,newSize)
                return;
            end

            this.IsUpdatingGridSize = true;

            visible = this.AxesGrid.Visible;
            this.AxesGrid.Visible = 'off';

            % Set to default values
            if ~isempty(this.RowColumnSelectorWidget) && isvalid(this.RowColumnSelectorWidget)
                close(this.RowColumnSelectorWidget);
            end

            % Update axes grid
            this.AxesGrid.GridSize = newSize;
            this.AxesGrid.GridRowLabelsVisible = newSize(1)~=1;
            this.AxesGrid.GridColumnLabelsVisible = newSize(2)~=1;

            update(this.AxesGrid);


            this.SyncChartWithAxesView = false;
            if newSize(1) > oldSize(1)
                this.RowVisible = [this.RowVisible;true(newSize(1)-oldSize(1),1)];
            else
                this.RowVisible = this.RowVisible(1:newSize(1));
            end
            if newSize(2) > oldSize(2)
                this.ColumnVisible = [this.ColumnVisible true(1,newSize(2)-oldSize(2))];
            else
                this.ColumnVisible = this.ColumnVisible(1:newSize(2));
            end
            this.SyncChartWithAxesView = true;

            % Reset grouping
            setRowColumnGrouping(this,false);

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
                setRowColumnGrouping(this)
            end
        end

        function syncAxesGridLabels(this)
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.GridRowLabels = generateStringForRowLabels(this);
                this.AxesGrid.GridColumnLabels = generateStringForColumnLabels(this);
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
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
            end
            NRows = this.Chart.NRows;
        end

        % NColumns
        function NColumns = get.NColumns(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
            end
            NColumns = this.Chart.NColumns;
        end

        % RowVisible
        function RowVisible = get.RowVisible(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
            end
            RowVisible = this.Chart.RowVisible;
        end

        function set.RowVisible(this,RowVisible)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                RowVisible (:,1) matlab.lang.OnOffSwitchState
            end
            this.Chart.RowVisible = RowVisible;
        end

        % ColumnVisible
        function ColumnVisible = get.ColumnVisible(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
            end
            ColumnVisible = this.Chart.ColumnVisible;
        end

        function set.ColumnVisible(this,ColumnVisible)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                ColumnVisible (1,:) matlab.lang.OnOffSwitchState
            end
            this.Chart.ColumnVisible = ColumnVisible;   
        end

        % ColumnNames
        function ColumnNames = get.ColumnNames(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
            end
            ColumnNames = this.Chart.ColumnNames;
        end

        function set.ColumnNames(this,ColumnNames)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                ColumnNames (1,:) string
            end
            this.Chart.ColumnNames = ColumnNames;
        end

        % RowNames
        function RowNames = get.RowNames(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
            end
            RowNames = this.Chart.RowNames;
        end

        function set.RowNames(this,RowNames)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                RowNames (:,1) string
            end
            this.Chart.RowNames = RowNames;
        end

        % RowColumnGrouping
        function RowColumnGrouping = get.RowColumnGrouping(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
            end
            RowColumnGrouping = this.Chart.RowColumnGrouping;
        end

        function set.RowColumnGrouping(this,RowColumnGrouping)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                RowColumnGrouping (1,1) string {mustBeMember(RowColumnGrouping,["all","none","columns","rows"])}
            end
            this.Chart.RowColumnGrouping = RowColumnGrouping;
        end
    end

    %% Protected methods
    methods(Access = protected)
        function connectStyleToChart(this)
            connectStyleToChart@controllib.chart.internal.view.axes.BaseAxesView(this);
            labelType = ["ColumnLabels";"RowLabels"];
            for ii = 1:length(labelType)
                L = addlistener(this.Chart.(labelType(ii)),"LabelChanged",@(es,ed) cbLabelChanged(this,es,ed,labelType(ii)));
                registerListeners(this,L,labelType(ii)+"Changed");
                L = addlistener(this.Chart.(labelType(ii)),"VisibilityChanged",@(es,ed) cbLabelVisibilityChanged(this,es,labelType(ii)));
                registerListeners(this,L,labelType(ii)+"VisibilityChanged");
            end
        end

        function applySISOLabelOverride(this)
            if (this.NRows == 1 && this.NColumns == 1) && (this.Chart.HasCustomRowNames || this.Chart.HasCustomColumnNames)
                this.AxesGrid.GridColumnLabels = getString(message('Controllib:plots:strFromLabel',this.ColumnNames)) + "  " + getString(message('Controllib:plots:strToLabel',this.RowNames));
                this.AxesGrid.GridColumnLabelsVisible = true;
            elseif this.NColumns == 1 && this.Chart.HasCustomColumnNames
                this.AxesGrid.GridColumnLabels = getString(message('Controllib:plots:strFromLabel',this.ColumnNames));
                this.AxesGrid.GridColumnLabelsVisible = true;
            elseif this.NRows == 1 && this.Chart.HasCustomRowNames
                this.AxesGrid.GridRowLabels = getString(message('Controllib:plots:strToLabel',this.RowNames));
                this.AxesGrid.GridRowLabelsVisible = true;
            end
            update(this.AxesGrid);
        end

        function cbLabelChanged(this,es,ed,labelType)
            switch labelType
                case {"ColumnLabels";"RowLabels"}
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
                        switch this.RowColumnGrouping
                            case {"none","columns"}
                                this.AxesGrid.GridRowLabelsVisible = es.Visible;
                                applySISOLabelOverride(this);
                        end
                    end
                case "ColumnLabels"
                    if this.NColumns > 1
                        switch this.RowColumnGrouping
                            case {"none","rows"}
                                this.AxesGrid.GridColumnLabelsVisible = es.Visible;
                                applySISOLabelOverride(this);
                        end
                    end
                otherwise
                    cbLabelVisibilityChanged@controllib.chart.internal.view.axes.BaseAxesView(this,es,labelType)
            end
        end

        function registerLabelStyleListeners(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
            end
            registerLabelStyleListeners@controllib.chart.internal.view.axes.BaseAxesView(this);
            rL = addlistener(this.Style.RowLabels,'LabelStyleChanged',@(es,ed) update(this.AxesGrid,UpdateLabels=true));
            cL = addlistener(this.Style.ColumnLabels,'LabelStyleChanged',@(es,ed) update(this.AxesGrid,UpdateLabels=true));
            registerListeners(this,[rL,cL],{'RowLabelChangedListener';'ColumnLabelChangedListener'});
        end

        function gridSize = getAxesGridGridSize(this)
            gridSize = [this.Chart.NRows this.Chart.NColumns];
        end

        function inputs = getAxesGridInputs(this)
            inputs = getAxesGridInputs@controllib.chart.internal.view.axes.BaseAxesView(this);
            inputs.XLimitsSharing = this.XLimitsSharing;
            inputs.YLimitsSharing = this.YLimitsSharing;
            inputs.RowLabels = generateStringForRowLabels(this);
            inputs.ColumnLabels = generateStringForColumnLabels(this);
            inputs.RowLabelStyle = this.Style.RowLabels;
            inputs.ColumnLabelStyle = this.Style.ColumnLabels;
            switch this.RowColumnGrouping
                case "all"
                    inputs.GridColumnVisible = [true,false(1,this.NColumns-1)];
                    inputs.GridRowVisible = [true; false(this.NRows-1,1)];
                    inputs.ColumnLabelsVisible = false;
                    inputs.RowLabelsVisible = false;
                case "columns"
                    inputs.GridColumnVisible = [true,false(1,this.NColumns-1)];
                    inputs.GridRowVisible = this.RowVisible;
                    inputs.RowLabelsVisible = this.NRows > 1;
                    inputs.ColumnLabelsVisible = false;
                case "rows"
                    inputs.GridRowVisible = [true;false(this.NRows-1,1)];
                    inputs.GridColumnVisible = this.ColumnVisible;
                    inputs.ColumnLabelsVisible = this.NColumns > 1;
                    inputs.RowLabelsVisible = false;
                case "none"
                    inputs.GridColumnVisible = this.ColumnVisible;
                    inputs.GridRowVisible = this.RowVisible;
                    inputs.ColumnLabelsVisible = this.NColumns > 1;
                    inputs.RowLabelsVisible = this.NRows > 1;
            end
        end
    end

    methods (Access = protected)
        function deleteAllDataTips(this,ed)
            % Select inputIdx and outputIdx based on IOGrouping
            switch this.RowColumnGrouping
                case 'none'
                    rowIdx = find(this.RowVisible,ed.Data.Row);
                    rowIdx = rowIdx(end);
                    columnIdx = find(this.ColumnVisible,ed.Data.Column);
                    columnIdx = columnIdx(end);
                case 'columns'
                    rowIdx = find(this.RowVisible,ed.Data.Row);
                    rowIdx = rowIdx(end);
                    columnIdx = 1:this.NColumns;
                case 'rows'
                    rowIdx = 1:this.NRows;
                    columnIdx = find(this.ColumnVisible,ed.Data.Column);
                    columnIdx = columnIdx(end);
                case 'all'
                    rowIdx = 1:this.NRows;
                    columnIdx = 1:this.NColumns;
            end
            for k = 1:length(this.ResponseViews)
                deleteAllDataTips(this.ResponseViews(k),rowIdx,columnIdx);
            end
        end

        function postBuild(this)
            postBuild@controllib.chart.internal.view.axes.BaseAxesView(this);
            applySISOLabelOverride(this);
        end

        function setRowColumnGrouping(this,reparent)
            arguments
                this (1,1) controllib.chart.internal.view.axes.RowColumnAxesView
                reparent (1,1) logical = true
            end

            visible = this.AxesGrid.Visible;
            this.AxesGrid.Visible = false;

            % Update grid layout
            switch this.RowColumnGrouping
                case "all"
                    this.AxesGrid.GridColumnVisible = [true,false(1,this.NColumns-1)];
                    this.AxesGrid.GridRowVisible = [true; false(this.NRows-1,1)];

                    this.AxesGrid.GridColumnLabelsVisible = false;
                    this.AxesGrid.GridRowLabelsVisible = false;
                case "columns"
                    this.AxesGrid.GridColumnVisible = [true,false(1,this.NColumns-1)];
                    this.AxesGrid.GridRowVisible = this.RowVisible;

                    % Set row labels if multiple outputs
                    this.AxesGrid.GridRowLabelsVisible = this.NRows > 1;
                    this.AxesGrid.GridColumnLabelsVisible = false;
                case "rows"
                    this.AxesGrid.GridRowVisible = [true;false(this.NRows-1,1)];
                    this.AxesGrid.GridColumnVisible = this.ColumnVisible;

                    % Set column labels if multiple inputs
                    this.AxesGrid.GridColumnLabelsVisible = this.NColumns > 1;
                    this.AxesGrid.GridRowLabelsVisible = false;
                case "none"
                    % Modify AxesGrid GridSize
                    this.AxesGrid.GridColumnVisible = this.ColumnVisible;
                    this.AxesGrid.GridRowVisible = this.RowVisible;

                    % Set column labels if multiple inputs
                    this.AxesGrid.GridColumnLabelsVisible = this.NColumns > 1;
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
                        RowVisible=this.RowVisible(min(this.ResponseViews(k).PlotRowIdx,length(this.RowVisible))),...
                        ColumnVisible=this.ColumnVisible(min(this.ResponseViews(k).PlotColumnIdx,length(this.ColumnVisible))));
                end
            end

            this.AxesGrid.Visible = visible;
        end

        function ax = getParentAxes(this)
            switch this.RowColumnGrouping
                case "all"
                    ax = getAxes(this.AxesGrid,Row=1,Column=1);
                    ax = repmat(ax,this.NRows,this.NColumns);
                case "columns"
                    ax = getAxes(this.AxesGrid,Column=1);
                    ax = repmat(ax,1,this.NColumns);
                case "rows"
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
                        RowVisible=this.RowVisible(min(this.ResponseViews(k).PlotRowIdx,length(this.RowVisible))),...
                        ColumnVisible=this.ColumnVisible(min(this.ResponseViews(k).PlotColumnIdx,length(this.ColumnVisible))));
                end
            end
        end

        function cbAxesGridLabelsChanged(this)
            % Modify Responses
            for k = 1:length(this.ResponseViews)
                if isvalid(this.ResponseViews(k).Response.getResponse())
                    this.ResponseViews(k).RowNames = this.RowNames;
                    this.ResponseViews(k).ColumnNames = this.ColumnNames;
                end
            end
        end
    end

    %% Sealed static protected methods
    methods (Sealed,Static,Access=protected)
        function mustBeRowColumnResponse(responses)
            arrayfun(@(x) mustBeA(x,'controllib.chart.internal.foundation.MixInRowResponse'),responses);
            arrayfun(@(x) mustBeA(x,'controllib.chart.internal.foundation.MixInColumnResponse'),responses);
        end
    end

    %% Hidden methods
    methods(Hidden)
        function dlg = qeGetRowColumnSelector(this)
            dlg = this.RowColumnSelectorWidget;
        end
    end
end
classdef HSVAxesView < controllib.chart.internal.view.axes.BaseAxesView
        
    % HSVAxesView

    % Copyright 2021-2022 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        StateContributionScale
    end

    properties (Access = protected)
        XLabelWithoutUnits = ""
        YLabelWithoutUnits = ""
        StateContributionScale_I
    end

    %% Constructor
    methods
        function this = HSVAxesView(chart)
            arguments
                chart (1,1) controllib.chart.HSVPlot
            end
            this@controllib.chart.internal.view.axes.BaseAxesView(chart);
            this.StateContributionScale = chart.YScale;
            this.SnapToDataVertexForDataTipInteraction = "vertex";
            
            build(this);
        end
    end

    %% Public methods
    methods
        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.HSVAxesView
                response (1,1) controllib.chart.response.HSVResponse
            end
            updateResponseView@controllib.chart.internal.view.axes.BaseAxesView(this,response);
            responseView = getResponseView(this,response);
            YLimits = this.YLimits;
            if iscell(YLimits)
                YLimits = YLimits{1};
            end
            updateInfiniteSVHeight(responseView,YLimits);
            updateErrorBoundBaseValue(responseView,this.StateContributionScale);
        end
    end
    
    %% Get/Set methods
    methods
        % StateContributionScale
        function StateContributionScale = get.StateContributionScale(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.HSVAxesView
            end
            StateContributionScale = this.StateContributionScale_I;
        end

        function set.StateContributionScale(this,StateContributionScale)
            arguments
                this (1,1) controllib.chart.internal.view.axes.HSVAxesView
                StateContributionScale (1,1) string {mustBeMember(StateContributionScale,["log","linear"])}
            end
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.YScale = StateContributionScale;
                update(this.AxesGrid);
            end
            this.StateContributionScale_I = StateContributionScale;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.HSVAxesView %#ok<INUSA>
                response (1,1) controllib.chart.response.HSVResponse
            end
            responseView = controllib.chart.internal.view.wave.HSVResponseView(response);
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.HSVAxesView
                responseView (1,1) controllib.chart.internal.view.wave.HSVResponseView
            end
            updateInfiniteSVHeight(responseView,this.YLimits);
            updateErrorBoundBaseValue(responseView,this.StateContributionScale);

            legendObjects = getLegendObjects(responseView);
            set(legendObjects,Parent=getAxes(this));
        end

        function cbAxesGridYLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.HSVAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.BaseAxesView(this);
            for k = 1:length(this.ResponseViews)
                updateInfiniteSVHeight(this.ResponseViews(k),this.AxesGrid.YLimits{1});
            end
        end

        function [orderAxisFocus, stateContributionAxisFocus] = updateFocus_(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.HSVAxesView
                responses (:,1) controllib.chart.response.HSVResponse
            end
            % Compute focus
            [orderAxisFocus, stateContributionAxisFocus] = computeFocus(this,responses);
        end

        function inputs = getAxesGridInputs(this)
            inputs = getAxesGridInputs@controllib.chart.internal.view.axes.BaseAxesView(this);
            inputs.YScale = this.StateContributionScale;
        end

        function XLabel = getXLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.HSVAxesView
            end
            XLabel = this.XLabelWithoutUnits;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.HSVAxesView
                XLabel (1,1) string
            end
            this.XLabelWithoutUnits = XLabel;
            this.AxesGrid.XLabel = this.XLabelWithoutUnits;
        end

        function YLabel = getYLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.HSVAxesView
            end
            YLabel = this.YLabelWithoutUnits;
        end

        function setYLabelString(this,YLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.HSVAxesView
                YLabel (1,1) string
            end
            this.YLabelWithoutUnits = YLabel;
            this.AxesGrid.YLabel = this.YLabelWithoutUnits;
        end

        function [orderAxisFocus, stateContributionAxisFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.HSVAxesView
                responses (:,1) controllib.chart.response.HSVResponse
            end
            orderAxisFocus = {[NaN NaN]};
            stateContributionAxisFocus = {[NaN NaN]};
            if ~isempty(responses)
                data = [responses.ResponseData];
                dataVisible = {responses.ArrayVisible};
                [orderAxisFocus, stateContributionAxisFocus] = getCommonFocusForMultipleData(data,this.StateContributionScale,dataVisible);
            end
        end
    end
end


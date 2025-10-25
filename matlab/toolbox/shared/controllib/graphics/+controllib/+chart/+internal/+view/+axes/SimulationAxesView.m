classdef SimulationAxesView < controllib.chart.internal.view.axes.TimeOutputAxesView
    % SimulationAxesView

    % Copyright 2023 The MathWorks, Inc.

    properties (AbortSet, SetObservable)
        InputVisible (1,1) matlab.lang.OnOffSwitchState
    end

    %% Constructor
    methods
        function this = SimulationAxesView(chart,varargin)
            arguments
                chart (1,1) controllib.chart.LSimPlot
            end

            arguments (Repeating)
                varargin
            end

            this@controllib.chart.internal.view.axes.TimeOutputAxesView(chart,varargin{:});
            this.InputVisible = chart.InputVisible;
            build(this);
        end
    end

    %% Public methods
    methods
        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SimulationAxesView
                response (1,1) controllib.chart.response.LinearSimulationResponse
            end
            idx = find(arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews),1);
            responseView = this.ResponseViews(idx);
            hasDifferentCharacteristics = ~isempty(setdiff(...
                union(responseView.CharacteristicTypes,response.CharacteristicTypes),...
                intersect(responseView.CharacteristicTypes,response.CharacteristicTypes)));
            if responseView.Response.NResponses ~= response.NResponses ||...
                    responseView.Response.NRows ~= response.NOutputs ||...
                    ~isequal(responseView.PlotRowIdx,response.ResponseData.PlotOutputIdx) || ...
                    responseView.IsDiscrete ~= response.IsDiscrete ||...
                    responseView.NInputs ~= response.NInputs ||...
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
    end

    %% Get/Set
    methods
        % ShowInput
        function set.InputVisible(this,InputVisible)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SimulationAxesView
                InputVisible (1,1) matlab.lang.OnOffSwitchState
            end
            for ii = 1:length(this.ResponseViews)
                this.ResponseViews(ii).ShowInput = InputVisible;
            end
            this.InputVisible = InputVisible;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SimulationAxesView
                response (1,1) controllib.chart.response.LinearSimulationResponse
            end
            responseView = controllib.chart.internal.view.wave.SimulationResponseView(response,...
                OutputVisible=this.RowVisible(1:response.NOutputs),...
                ShowMagnitude=this.ShowMagnitude,...
                ShowReal=this.ShowReal,...
                ShowImaginary=this.ShowImaginary);
            responseView.TimeUnit = this.TimeUnit;
            responseView.ShowInput = this.InputVisible;
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SimulationAxesView
                responseView (1,1) controllib.chart.internal.view.wave.SimulationResponseView
            end
            if ~responseView.Response.IsReal
                ax = getAxes(this);
                aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
                updateMarkers(responseView,AspectRatio=aspectRatio);
            end
        end
        
        function [timeFocus, amplitudeFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SimulationAxesView
                responses (:,1) controllib.chart.response.LinearSimulationResponse
            end
            timeFocus = repmat({[NaN NaN]},this.NRows,1);
            amplitudeFocus = repmat({[NaN NaN]},this.NRows,1);
            if ~isempty(responses)
                data = [responses.ResponseData];
                [timeFocus_, amplitudeFocus_, timeUnit] = getCommonFocusForMultipleData(data,...
                    this.InputVisible,{responses.ArrayVisible},...
                    ShowMagnitude=this.ShowMagnitude,...
                    ShowReal=this.ShowReal,...
                    ShowImaginary=this.ShowImaginary);
                timeFocus(1:size(timeFocus_,1),1:size(timeFocus_,2)) = timeFocus_;
                amplitudeFocus(1:size(amplitudeFocus_,1),1:size(amplitudeFocus_,2)) = amplitudeFocus_;
                timeConversionFcn = getTimeUnitConversionFcn(this,timeUnit,this.TimeUnit);
                for ko = 1:this.NRows
                    timeFocus{ko} = timeConversionFcn(timeFocus{ko});
                end
            end
        end

        function cbAxesGridXLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SimulationAxesView
            end
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.TimeOutputAxesView(this);
            if ~isempty(this.ResponseViews)
                allIsReal = true;
                for k = 1:length(this.ResponseViews)
                    allIsReal = allIsReal & all(this.ResponseViews(k).Response.IsReal(:));
                end
                if ~allIsReal
                    ax = getAxes(this);
                    aspectRatio = ax(1).PlotBoxAspectRatio;
                    for k = 1:length(this.ResponseViews)
                        if any(~this.ResponseViews(k).Response.IsReal)
                            updateMarkers(this.ResponseViews(k),AspectRatio=aspectRatio);
                        end
                    end
                end
            end
        end

        function cbAxesGridYLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SimulationAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.TimeOutputAxesView(this);
            if ~isempty(this.ResponseViews)
                allIsReal = true;
                for k = 1:length(this.ResponseViews)
                    allIsReal = allIsReal & all(this.ResponseViews(k).Response.IsReal(:));
                end
                if ~allIsReal
                    ax = getAxes(this);
                    aspectRatio = ax(1).PlotBoxAspectRatio;
                    for k = 1:length(this.ResponseViews)
                        if any(~this.ResponseViews(k).Response.IsReal)
                            updateMarkers(this.ResponseViews(k),AspectRatio=aspectRatio);
                        end
                    end
                end
            end
        end
    end
end


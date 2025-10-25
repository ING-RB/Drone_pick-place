classdef StepAxesView < controllib.chart.internal.view.axes.TimeRowColumnAxesView & ...
                        controllib.chart.internal.view.axes.MixInInputOutputAxesViewLabels

    % Copyright 2021 The MathWorks, Inc.
    methods
        function this = StepAxesView(chart,varargin)
            arguments
                chart (1,1) controllib.chart.StepPlot
            end

            arguments (Repeating)
                varargin
            end

            this@controllib.chart.internal.view.axes.TimeRowColumnAxesView(chart,varargin{:});
            build(this);
        end
    end

    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.StepAxesView
                response (1,1) controllib.chart.response.StepResponse
            end
            responseView = controllib.chart.internal.view.wave.StepResponseView(response,...
                ColumnVisible=this.ColumnVisible(1:response.NColumns),...
                RowVisible=this.RowVisible(1:response.NRows),...
                ShowMagnitude=this.ShowMagnitude,...
                ShowReal=this.ShowReal,...
                ShowImaginary=this.ShowImaginary);
            responseView.TimeUnit = this.TimeUnit;
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.StepAxesView
                responseView (1,1) controllib.chart.internal.view.wave.StepResponseView
            end
            if ~responseView.Response.IsReal
                ax = getAxes(this);
                aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
                updateMarkers(responseView,AspectRatio=aspectRatio);
            end
        end

        function [timeFocus, amplitudeFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.StepAxesView
                responses (:,1) controllib.chart.response.StepResponse
            end
            timeFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            amplitudeFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            if ~isempty(responses)
                data = [responses.ResponseData];
                crVisible =  isfield(this.CharacteristicsVisibility,'ConfidenceRegion') && this.CharacteristicsVisibility.ConfidenceRegion;
                brVisible =  isfield(this.CharacteristicsVisibility,'BoundaryRegion') && this.CharacteristicsVisibility.BoundaryRegion;
                [timeFocus_, amplitudeFocus_, timeUnit] = getCommonFocusForMultipleData(data,...
                    crVisible,brVisible,{responses.ArrayVisible},ShowMagnitude=this.ShowMagnitude,...
                    ShowReal=this.ShowReal,ShowImaginary=this.ShowImaginary);
                timeFocus(1:size(timeFocus_,1),1:size(timeFocus_,2)) = timeFocus_;
                amplitudeFocus(1:size(amplitudeFocus_,1),1:size(amplitudeFocus_,2)) = amplitudeFocus_;
                timeConversionFcn = getTimeUnitConversionFcn(this,timeUnit,this.TimeUnit);
                for ko = 1:this.NRows
                    for ki = 1:this.NColumns
                        timeFocus{ko,ki} = timeConversionFcn(timeFocus{ko,ki});
                    end
                end
            end
        end

        function postUpdateCharacteristic(this,characteristicType,~)
            if characteristicType=="ConfidenceRegion" || characteristicType=="BoundaryRegion"
                updateFocus(this);
            end
        end

        function cbAxesGridXLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.StepAxesView
            end
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.TimeRowColumnAxesView(this);
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
                this (1,1) controllib.chart.internal.view.axes.StepAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.TimeRowColumnAxesView(this);
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


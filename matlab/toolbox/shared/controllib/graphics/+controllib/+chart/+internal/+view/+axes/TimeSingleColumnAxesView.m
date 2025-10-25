classdef TimeSingleColumnAxesView < controllib.chart.internal.view.axes.SingleColumnAxesView & ...
        controllib.chart.internal.foundation.MixInTimeUnit
    % TimeOutputView

    % Copyright 2023 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet)
        Normalize
    end

    properties (Access = private)
        XLabelWithoutUnits string = ""
        Normalize_I matlab.lang.OnOffSwitchState = false
        YLimitsSharingBeforeNormalize
    end

    %% Constructor
    methods
        function this = TimeSingleColumnAxesView(chart)
            arguments
                chart (1,1) controllib.chart.internal.foundation.TimeSingleColumnPlot
            end
            this@controllib.chart.internal.foundation.MixInTimeUnit(chart.TimeUnit);
            this@controllib.chart.internal.view.axes.SingleColumnAxesView(chart);
            build(this);
        end
    end

    %% Get/Set
    methods
        % Normalize
        function Normalize = get.Normalize(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeSingleColumnAxesView
            end
            Normalize = this.Normalize_I;
        end

        function set.Normalize(this,Normalize)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeSingleColumnAxesView
                Normalize (1,1) matlab.lang.OnOffSwitchState
            end
            this.Normalize_I = Normalize;
            this.AxesGrid.ShowYTickLabels = ~Normalize;
            if Normalize
                this.YLimitsSharingBeforeNormalize = this.AxesGrid.YLimitsSharing;
                this.AxesGrid.YLimitsSharing = "none";
                this.AxesGrid.YLimitsMode = "auto";
            else
                this.AxesGrid.YLimitsSharing = this.YLimitsSharingBeforeNormalize;
            end
            update(this.AxesGrid);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function [timeFocus, amplitudeFocus] = updateFocus_(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeSingleColumnAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
            end
            % Compute focus
            [timeFocus, amplitudeFocus] = computeFocus(this,responses);
        end

        function cbTimeUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeSingleColumnAxesView
                conversionFcn (1,1) function_handle
            end
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).TimeUnit = this.TimeUnit;
            end

            % Convert Limits
            for ii = 1:numel(this.AxesGrid.XLimitsFocus)
                this.AxesGrid.XLimitsFocus{ii} = conversionFcn(this.AxesGrid.XLimitsFocus{ii});
            end

            for ii = 1:numel(this.AxesGrid.XLimits)
                if strcmp(this.AxesGrid.XLimitsMode{ii},'manual')
                    this.AxesGrid.XLimits{ii} = conversionFcn(this.AxesGrid.XLimits{ii});
                end
            end

            update(this.AxesGrid);

            % Modify Label
            setXLabelString(this,this.XLabelWithoutUnits);
        end

        function XLabel = getXLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeSingleColumnAxesView
            end
            XLabel = this.XLabelWithoutUnits;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeSingleColumnAxesView
                XLabel (1,1) string
            end
            this.XLabelWithoutUnits = XLabel;
            this.AxesGrid.XLabel = this.XLabelWithoutUnits + " (" + this.TimeUnitLabel + ")";
        end

        function responseView = createResponseView(this,response,idx)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeSingleColumnAxesView %#ok<INUSA>
                response (1,1) controllib.chart.internal.foundation.BaseResponse %#ok<INUSA>
                idx (1,1) double = length(this.ResponseViews)+1 %#ok<INUSA>
            end
            responseView = controllib.chart.internal.view.wave.BaseResponseView.empty;
        end

        function [timeFocus, amplitudeFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeSingleColumnAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
            end
            timeFocus = repmat({[NaN NaN]},this.NRows,1);
            amplitudeFocus = repmat({[NaN NaN]},this.NRows,1);
            if ~isempty(responses)
                data = [responses.ResponseData];
                [timeFocus_, amplitudeFocus_, timeUnit] = getCommonFocusForMultipleData(data,{responses.ArrayVisible});
                timeConversionFcn = getTimeUnitConversionFcn(this,timeUnit,this.TimeUnit);
                for ko = 1:length(timeFocus_)
                    timeFocus_{ko} = timeConversionFcn(timeFocus_{ko});
                end
                timeFocus(1:length(timeFocus_)) = timeFocus_;
                amplitudeFocus(1:length(amplitudeFocus_)) = amplitudeFocus_;
            end
        end
    end

    %% Hidden methods
    methods(Hidden)
        function registerResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.TimeSingleColumnAxesView
                responseView (1,1) controllib.chart.internal.view.wave.BaseResponseView
            end
            responseView.TimeUnit = this.TimeUnit;
            registerResponseView@controllib.chart.internal.view.axes.SingleColumnAxesView(this,responseView);
        end
    end
end


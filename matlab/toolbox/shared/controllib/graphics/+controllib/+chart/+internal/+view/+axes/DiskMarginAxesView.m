classdef DiskMarginAxesView < controllib.chart.internal.view.axes.BaseAxesView & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit & ...
        controllib.chart.internal.foundation.MixInPhaseUnit
    % BodeView

    % Copyright 2023 The MathWorks, Inc.
    properties (Dependent, AbortSet, SetObservable)
        MagnitudeScale
        FrequencyScale
    end
    properties (Access = protected)
        MagnitudeScale_I = "linear"
        FrequencyScale_I = "log"

        XLabelWithoutUnits = ""
        YLabelWithoutUnits = ""
    end

    methods
        function this = DiskMarginAxesView(chart)
            arguments
                chart (1,1) controllib.chart.DiskMarginPlot
            end
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(chart.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(chart.MagnitudeUnit);
            this@controllib.chart.internal.foundation.MixInPhaseUnit(chart.PhaseUnit);
            this@controllib.chart.internal.view.axes.BaseAxesView(chart);
            this.FrequencyScale = chart.FrequencyScale;
            this.MagnitudeScale = chart.MagnitudeScale;

            build(this);
        end

        function updateResponse(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            updateResponse@controllib.chart.internal.view.axes.BaseAxesView(this,response);
            responseView = getResponseView(this,response);
            if isa(responseView,'controllib.chart.internal.view.wave.DiskMarginBoundResponseView')
                XLimits = this.XLimits;
                magLimits = this.YLimits{1};
                phaseLimits = this.YLimits{2};
                updatePatchLimits(responseView,XLimits,magLimits,phaseLimits);
            end
        end
    end

    %% Get/Set
    methods
        % Frequency Scale
        function FrequencyScale = get.FrequencyScale(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
            end
            FrequencyScale = this.FrequencyScale_I;
        end

        function set.FrequencyScale(this,FrequencyScale)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
                FrequencyScale (1,1) string {mustBeMember(FrequencyScale,["log","linear"])}
            end
            for ii = 1:length(this.ResponseViews)
                this.ResponseViews(ii).FrequencyScale = FrequencyScale;
            end
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.XScale = FrequencyScale;
                update(this.AxesGrid);

                ax = getAxes(this);
                aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
                for ii = 1:length(this.ResponseViews)
                    updateArrows(this.ResponseViews(ii),AspectRatio=aspectRatio);
                end
            end

            this.FrequencyScale_I = FrequencyScale;
        end

        % Magnitude Scale
        function MagnitudeScale = get.MagnitudeScale(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
            end
            MagnitudeScale = this.MagnitudeScale_I;
        end

        function set.MagnitudeScale(this,MagnitudeScale)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
                MagnitudeScale (1,1) string {mustBeMember(MagnitudeScale,["log","linear"])}
            end
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.YScale(1) = MagnitudeScale;
                update(this.AxesGrid);
            end
            this.MagnitudeScale_I = MagnitudeScale;
        end
    end

    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
                response (1,1) controllib.chart.internal.foundation.BaseResponse
            end
            switch class(response)
                case {"controllib.chart.response.DiskMarginResponse",...
                        "controllib.chart.response.internal.DiskMarginSigmaResponse"}
                    responseView = controllib.chart.internal.view.wave.DiskMarginResponseView(response);
                case "controllib.chart.response.internal.DiskMarginBoundResponse"
                    responseView = controllib.chart.internal.view.wave.DiskMarginBoundResponseView(response);
            end
            responseView.FrequencyUnit = this.FrequencyUnit;
            responseView.MagnitudeUnit = this.MagnitudeUnit;
            responseView.PhaseUnit = this.PhaseUnit;
            responseView.FrequencyScale = this.FrequencyScale;
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
                responseView (1,1) controllib.chart.internal.view.wave.BaseResponseView
            end
            switch class(responseView)
                case "controllib.chart.internal.view.wave.DiskMarginResponseView"
                    ax = getAxes(this);
                    aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
                    updateArrows(responseView,AspectRatio=aspectRatio);
                case "controllib.chart.internal.view.wave.DiskMarginBoundResponseView"
                    XLimits = this.XLimits;
                    magLimits = this.YLimits{1};
                    phaseLimits = this.YLimits{2};
                    updatePatchLimits(responseView,XLimits,magLimits,phaseLimits);
            end
        end

        function cbAxesGridXLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
            end
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.BaseAxesView(this);
            for k = 1:length(this.ResponseViews)
                if isa(this.ResponseViews(k),'controllib.chart.internal.view.wave.DiskMarginBoundResponseView')
                    XLimits = this.AxesGrid.XLimits{1};
                    magLimits = this.AxesGrid.YLimits{1};
                    phaseLimits = this.AxesGrid.YLimits{2};
                    updatePatchLimits(this.ResponseViews(k),XLimits,magLimits,phaseLimits);
                else
                    ax = getAxes(this);
                    aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
                    updateArrows(this.ResponseViews(k),AspectRatio=aspectRatio);
                end
            end
        end

        function cbAxesGridYLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.BaseAxesView(this);
            for k = 1:length(this.ResponseViews)
                if isa(this.ResponseViews(k),'controllib.chart.internal.view.wave.DiskMarginBoundResponseView')
                    XLimits = this.AxesGrid.XLimits{1};
                    magLimits = this.AxesGrid.YLimits{1};
                    phaseLimits = this.AxesGrid.YLimits{2};
                    updatePatchLimits(this.ResponseViews(k),XLimits,magLimits,phaseLimits);
                else
                    ax = getAxes(this);
                    aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
                    updateArrows(this.ResponseViews(k),AspectRatio=aspectRatio);
                end
            end
        end

        function subGridSize = getAxesGridSubGridSize(~)
            subGridSize = [2 1];
        end

        function inputs = getAxesGridInputs(this)
            inputs = getAxesGridInputs@controllib.chart.internal.view.axes.BaseAxesView(this);
            inputs.XScale = this.FrequencyScale;
            inputs.YScale = [this.MagnitudeScale;"linear"];
            if strcmp(this.PhaseUnit,'deg')
                phaseLimitPickerBase = 45;
            else
                phaseLimitPickerBase = 10;
            end
            inputs.YLimitPickerBase = [10;phaseLimitPickerBase];
            inputs.SubGridRowLabelStyle = this.Style.YLabel;
            inputs.SubGridColumnLabelStyle = this.Style.XLabel;
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
                conversionFcn (1,1) function_handle
            end
            % Change FrequencyUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).FrequencyUnit = this.FrequencyUnit;
            end

            % Convert Limits
            this.AxesGrid.XLimitsFocus{1} = conversionFcn(this.AxesGrid.XLimitsFocus{1});
            this.AxesGrid.XLimitsFocus{2} = conversionFcn(this.AxesGrid.XLimitsFocus{2});
            if strcmp(this.AxesGrid.XLimitsMode{1},"manual")
                this.AxesGrid.XLimits{1} = conversionFcn(this.AxesGrid.XLimits{1});
            end
            update(this.AxesGrid);

            % Modify Label
            setXLabelString(this,this.XLabelWithoutUnits);
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
                conversionFcn (1,1) function_handle
            end
            % Change MagnitudeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).MagnitudeUnit = this.MagnitudeUnit;
            end

            % Convert Limits
            this.AxesGrid.YLimitsFocus{1} = conversionFcn(this.AxesGrid.YLimitsFocus{1});
            if strcmp(this.AxesGrid.YLimitsMode{1},"manual")
                this.AxesGrid.YLimits{1} = conversionFcn(this.AxesGrid.YLimits{1});
            end

            % Change AxesGrid SubGrid RowLabel
            this.AxesGrid.SubGridRowLabels(1) = string(getString(message('Controllib:plots:strDiskMarginMag')))...
                + " (" + this.MagnitudeUnitLabel + ")";
            
            % Update AxesGrid
            update(this.AxesGrid);
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
                conversionFcn (1,1) function_handle
            end
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).PhaseUnit = this.PhaseUnit;
            end

            % Convert Limits
            this.AxesGrid.YLimitsFocus{2} = conversionFcn(this.AxesGrid.YLimitsFocus{2});
            if strcmp(this.AxesGrid.YLimitsMode{2},"manual")
                this.AxesGrid.YLimits{2} = conversionFcn(this.AxesGrid.YLimits{2});
            end

            % Change Sub Grid Row Label
            this.AxesGrid.SubGridRowLabels(2) = string(getString(message('Controllib:plots:strDiskMarginPhase')))'...
                + " (" + this.PhaseUnitLabel + ")";

            switch this.PhaseUnit
                case "deg"
                    this.AxesGrid.YLimitPickerBase(2) = 45;
                case "rad"
                    this.AxesGrid.YLimitPickerBase(2) = 10;
            end

            % Update
            update(this.AxesGrid);
        end

        function deleteAllDataTips(this,ed)
            outputIdx = ceil(ed.Data.Row/2);
            inputIdx = ed.Data.Column;
            if mod(ed.Data.Row,2)
                responseToDelete = "gain";
            else
                responseToDelete = "phase";
            end

            for k = 1:length(this.ResponseViews)
                deleteAllDataTips(this.ResponseViews(k),outputIdx,inputIdx,responseToDelete);
            end
        end

        function [xLimitsFocus,yLimitsFocus] = updateFocus_(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
            end
            % Compute focus
            [frequencyFocus,gainFocus,phaseFocus] = computeFocus(this,responses);

            xLimitsFocus = [frequencyFocus;frequencyFocus];
            yLimitsFocus = [gainFocus;phaseFocus];
        end


        function [frequencyFocus,gainFocus,phaseFocus] = computeFocus(this,responses) 
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse
            end
            frequencyFocus = {[NaN NaN]};
            gainFocus = {[NaN NaN]};
            phaseFocus = {[NaN NaN]};
            if ~isempty(responses)
                data = [responses.ResponseData];
                isDiskMarginResponse = arrayfun(@(x) isa(x,"controllib.chart.response.DiskMarginResponse"),responses);
                diskMarginData = data(isDiskMarginResponse);
                diskMarginBoundData = data(~isDiskMarginResponse);
                dataVisible = {responses.ArrayVisible};
                diskMarginVisible = dataVisible(isDiskMarginResponse);
                diskMarginBoundVisible = dataVisible(~isDiskMarginResponse);
                if ~isempty(diskMarginData)
                    [frequencyFocus_,frequencyUnit] = getCommonFrequencyFocus(diskMarginData,this.FrequencyScale,diskMarginVisible);
                    frequencyConversionFcn = getFrequencyUnitConversionFcn(this,frequencyUnit,this.FrequencyUnit);
                    frequencyFocus_{1} = frequencyConversionFcn(frequencyFocus_{1});
                    frequencyFocus{1} = [min(frequencyFocus{1}(1),frequencyFocus_{1}(1)),max(frequencyFocus{1}(2),frequencyFocus_{1}(2))];
                end
                if ~isempty(diskMarginBoundData)
                    [frequencyFocus_,frequencyUnitBounds] = getCommonFrequencyFocus(diskMarginBoundData,diskMarginBoundVisible);
                    frequencyConversionFcn = getFrequencyUnitConversionFcn(this,frequencyUnitBounds,this.FrequencyUnit);
                    frequencyFocus_{1} = frequencyConversionFcn(frequencyFocus_{1});
                    frequencyFocus{1} = [min(frequencyFocus{1}(1),frequencyFocus_{1}(1)),max(frequencyFocus{1}(2),frequencyFocus_{1}(2))];
                end
                if strcmp(this.FrequencyScale,"linear") && any(arrayfun(@(x) ~all(x.IsReal),diskMarginData))
                    frequencyFocus{1}(1) = -frequencyFocus{1}(2); % mirror common focus
                end
                if strcmp(this.MagnitudeUnit,"dB")
                    magnitudeScaleData = "log";
                else
                    magnitudeScaleData = this.MagnitudeScale;
                end
                if ~isempty(diskMarginData)
                    frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.FrequencyUnit,frequencyUnit);
                    frequencyFocusData{1} = frequencyConversionFcn(frequencyFocus{1});
                    [gainFocus_,magnitudeUnit] = getCommonGainFocus(diskMarginData,frequencyFocusData,magnitudeScaleData,diskMarginVisible);
                    magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,magnitudeUnit,this.MagnitudeUnit);
                    gainFocus_{1} = magnitudeConversionFcn(gainFocus_{1});
                    gainFocus{1} = [min(gainFocus{1}(1),gainFocus_{1}(1)),max(gainFocus{1}(2),gainFocus_{1}(2))];
                    [phaseFocus_,phaseUnit] = getCommonPhaseFocus(diskMarginData,frequencyFocusData,diskMarginVisible);
                    phaseConversionFcn = getPhaseUnitConversionFcn(this,phaseUnit,this.PhaseUnit);
                    phaseFocus_{1} = phaseConversionFcn(phaseFocus_{1});
                    phaseFocus{1} = [min(phaseFocus{1}(1),phaseFocus_{1}(1)),max(phaseFocus{1}(2),phaseFocus_{1}(2))];
                end
                if ~isempty(diskMarginBoundData)
                    [gainFocus_,magnitudeUnit] = getCommonGainFocus(diskMarginBoundData,diskMarginBoundVisible);
                    magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,magnitudeUnit,this.MagnitudeUnit);
                    gainFocus_{1} = magnitudeConversionFcn(gainFocus_{1});
                    gainFocus{1} = [min(gainFocus{1}(1),gainFocus_{1}(1)),max(gainFocus{1}(2),gainFocus_{1}(2))];
                    [phaseFocus_,phaseUnit] = getCommonPhaseFocus(diskMarginBoundData,diskMarginBoundVisible);
                    phaseConversionFcn = getPhaseUnitConversionFcn(this,phaseUnit,this.PhaseUnit);
                    phaseFocus_{1} = phaseConversionFcn(phaseFocus_{1});
                    phaseFocus{1} = [min(phaseFocus{1}(1),phaseFocus_{1}(1)),max(phaseFocus{1}(2),phaseFocus_{1}(2))];
                end
            end
        end

        function XLabel = getXLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
            end
            XLabel = this.XLabelWithoutUnits;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
                XLabel (1,1) string
            end
            this.XLabelWithoutUnits = XLabel;
            this.AxesGrid.XLabel = this.XLabelWithoutUnits + " (" + this.FrequencyUnitLabel + ")";
        end
        
        function yLabel = getYLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
            end
            yLabel = this.YLabelWithoutUnits;
        end

        function setYLabelString(this,YLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.DiskMarginAxesView
                YLabel (2,1) string
            end
            this.YLabelWithoutUnits = YLabel;
            gainLabel = YLabel(1) + " (" + this.MagnitudeUnitLabel + ")";
            phaseLabel = YLabel(2) + " (" + this.PhaseUnitLabel + ")";
            this.AxesGrid.SubGridRowLabels(1) = gainLabel;
            this.AxesGrid.SubGridRowLabels(2) = phaseLabel;
            update(this.AxesGrid);
        end
    end
end
classdef SigmaAxesView < controllib.chart.internal.view.axes.BaseAxesView & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit
    % SIGMAVIEW     Construct view to manage axes and responses for SIGMAPLOT     

    % Copyright 2022 The MathWorks, Inc.
    
    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        MagnitudeScale
        FrequencyScale
    end

    properties (Access = protected)
        XLabelWithoutUnits = ""
        YLabelWithoutUnits = ""
        MagnitudeScale_I
        FrequencyScale_I
    end
    
    %% Constructor
    methods
        function this = SigmaAxesView(chart)
            arguments
                chart (1,1) controllib.chart.SigmaPlot
            end
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(chart.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(chart.MagnitudeUnit);
            this@controllib.chart.internal.view.axes.BaseAxesView(chart);
            this.FrequencyScale = chart.FrequencyScale;
            this.MagnitudeScale = chart.MagnitudeScale;

            build(this);
        end
    end

    %% Public methods
    methods
        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
                response (1,1) controllib.chart.internal.foundation.ModelResponse
            end
            idx = find(arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews),1);
            responseView = this.ResponseViews(idx);
            hasDifferentCharacteristics = ~isempty(setdiff(...
                union(responseView.CharacteristicTypes,response.CharacteristicTypes),...
                intersect(responseView.CharacteristicTypes,response.CharacteristicTypes)));
            if isa(responseView,'controllib.chart.internal.view.wave.SigmaBoundResponseView')
                hasDifferentNumLines = responseView.NPatches ~= size(response.ResponseData.SingularValue{1},1);
            else
                hasDifferentNumLines = responseView.NLines ~= size(response.ResponseData.SingularValue{1},1);
            end
            if responseView.Response.NResponses ~= response.NResponses ||...
                    hasDifferentCharacteristics || hasDifferentNumLines
                delete(responseView);
                this.ResponseViews = this.ResponseViews(isvalid(this.ResponseViews));
                responseView = createResponseView(this,response);
                createResponseDataTips(responseView);
                this.ResponseViews = [this.ResponseViews(1:idx-1); responseView; this.ResponseViews(idx:end)];
                parentResponseViews(this);
                postParentResponseView(this,responseView);
            else
                update(responseView);
                if isa(responseView,'controllib.chart.internal.view.wave.SigmaBoundResponseView')
                    updatePatchHeight(responseView,this.YLimits);
                end
            end
        end

        function updateSingularValueFocus(this,~)
            responses = this.VisibleResponses;
            if isempty(responses)
                return;
            end
            [~,yLimitsFocus] = updateFocus_(this,responses,UseXLimitsFocus=true);
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                if this.YLimitsFocusFromResponses
                    this.AxesGrid.YLimitsFocus = yLimitsFocus;
                end
                update(this.AxesGrid);
            end
        end
    end

    %% Get/Set methods
    methods
        % FrequencyScale
        function FrequencyScale = get.FrequencyScale(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
            end
            FrequencyScale = this.FrequencyScale_I;
        end

        function set.FrequencyScale(this,FrequencyScale)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
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

        % MagnitudeScale
        function MagnitudeScale = get.MagnitudeScale(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
            end
            MagnitudeScale = this.MagnitudeScale_I;
        end

        function set.MagnitudeScale(this,MagnitudeScale)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
                MagnitudeScale (1,1) string {mustBeMember(MagnitudeScale,["log","linear"])}
            end
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.YScale = MagnitudeScale;
                update(this.AxesGrid);
            end
            this.MagnitudeScale_I = MagnitudeScale;
        end
    end
    
    %% Protected methods
    methods (Access = protected)        
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
                response (1,1) controllib.chart.internal.foundation.ModelResponse
            end
            switch class(response)
                case "controllib.chart.response.SigmaResponse"
                    responseView = controllib.chart.internal.view.wave.SigmaResponseView(response);
                case "controllib.chart.response.internal.SigmaBoundResponse"
                    responseView = controllib.chart.internal.view.wave.SigmaBoundResponseView(response);
            end
            responseView.FrequencyUnit = this.FrequencyUnit;
            responseView.MagnitudeUnit = this.MagnitudeUnit;
            responseView.FrequencyScale = this.FrequencyScale;
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
                responseView (1,1) controllib.chart.internal.view.wave.BaseResponseView
            end
            if isa(responseView,"controllib.chart.internal.view.wave.SigmaBoundResponseView")
                updatePatchHeight(responseView,this.YLimits);
            end
            ax = getAxes(this);
            aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
            updateArrows(responseView,AspectRatio=aspectRatio);
        end

        function cbAxesGridXLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
            end
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.BaseAxesView(this);
            ax = getAxes(this);
            aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
            for k = 1:length(this.ResponseViews)
                updateArrows(this.ResponseViews(k),AspectRatio=aspectRatio);
            end
        end

        function cbAxesGridYLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.BaseAxesView(this);
            ax = getAxes(this);
            aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
            for k = 1:length(this.ResponseViews)
                if isa(this.ResponseViews(k),"controllib.chart.internal.view.wave.SigmaBoundResponseView")
                    updatePatchHeight(this.ResponseViews(k),this.AxesGrid.YLimits{1});
                end
                updateArrows(this.ResponseViews(k),AspectRatio=aspectRatio);
            end
        end

        function [frequencyFocus,singularValueFocus] = updateFocus_(this,responses,optionalArguments)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
                responses (:,1) controllib.chart.internal.foundation.ModelResponse
                optionalArguments.UseXLimitsFocus = false
            end
            % Compute focus
            [frequencyFocus, singularValueFocus] = computeFocus(this,responses,...
                UseXLimitsFocus=optionalArguments.UseXLimitsFocus);
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
                conversionFcn (1,1) function_handle
            end
            % Change FrequencyUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).FrequencyUnit = this.FrequencyUnit;
            end

            % Convert Limits
            this.AxesGrid.XLimitsFocus{1} = conversionFcn(this.AxesGrid.XLimitsFocus{1});
            if strcmp(this.AxesGrid.XLimitsMode{1},"manual")
                this.AxesGrid.XLimits{1} = conversionFcn(this.AxesGrid.XLimits{1});
            end
            update(this.AxesGrid);

            setXLabelString(this,this.XLabelWithoutUnits);
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
                conversionFcn (1,1) function_handle
            end
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).MagnitudeUnit = this.MagnitudeUnit;
            end

            % Convert Limits
            this.AxesGrid.YLimitsFocus{1} = conversionFcn(this.AxesGrid.YLimitsFocus{1});
            if strcmp(this.AxesGrid.YLimitsMode{1},"manual")
                this.AxesGrid.YLimits{1} = conversionFcn(this.AxesGrid.YLimits{1});
            end
            update(this.AxesGrid);

            setYLabelString(this,this.YLabelWithoutUnits);
        end

        function inputs = getAxesGridInputs(this)
            inputs = getAxesGridInputs@controllib.chart.internal.view.axes.BaseAxesView(this);
            inputs.XScale = this.FrequencyScale;
            inputs.YScale = this.MagnitudeScale;
        end

        function XLabel = getXLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
            end
            XLabel = this.XLabelWithoutUnits;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
                XLabel (1,1) string
            end
            this.XLabelWithoutUnits = XLabel;
            this.AxesGrid.XLabel = this.XLabelWithoutUnits + " (" + this.FrequencyUnitLabel + ")";
        end

        function YLabel = getYlabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
            end
            YLabel = this.YLabelWithoutUnits;
        end

        function setYLabelString(this,YLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
                YLabel (1,1) string
            end
            this.YLabelWithoutUnits = YLabel;
            this.AxesGrid.YLabel = this.YLabelWithoutUnits + " (" + this.MagnitudeUnitLabel + ")";
        end

        function [frequencyFocus, singularValueFocus] = computeFocus(this,responses,optionalArguments)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SigmaAxesView
                responses (:,1) controllib.chart.internal.foundation.ModelResponse
                optionalArguments.UseXLimitsFocus = false
            end
            frequencyFocus = {[NaN NaN]};
            singularValueFocus = {[NaN NaN]};
            if ~isempty(responses)
                data = [responses.ResponseData];
                isSigmaResponse = arrayfun(@(x) isa(x,"controllib.chart.response.SigmaResponse"),responses);
                sigmaData = data(isSigmaResponse);
                sigmaBoundData = data(~isSigmaResponse);
                dataVisible = {responses.ArrayVisible};
                sigmaVisible = dataVisible(isSigmaResponse);
                sigmaBoundVisible = dataVisible(~isSigmaResponse);

                % Computing frequency focus
                if ~optionalArguments.UseXLimitsFocus
                    if ~isempty(sigmaData)
                        [frequencyFocus_,frequencyUnit] = getCommonFrequencyFocus(sigmaData,this.FrequencyScale,sigmaVisible);
                        frequencyConversionFcn = getFrequencyUnitConversionFcn(this,frequencyUnit,this.FrequencyUnit);
                        frequencyFocus_{1} = frequencyConversionFcn(frequencyFocus_{1});
                        frequencyFocus{1} = [min(frequencyFocus{1}(1),frequencyFocus_{1}(1)),max(frequencyFocus{1}(2),frequencyFocus_{1}(2))];
                    end
                    if ~isempty(sigmaBoundData)
                        [frequencyFocus_,frequencyUnitBounds] = getCommonFrequencyFocus(sigmaBoundData,this.FrequencyScale,sigmaBoundVisible);
                        frequencyConversionFcn = getFrequencyUnitConversionFcn(this,frequencyUnitBounds,this.FrequencyUnit);
                        frequencyFocus_{1} = frequencyConversionFcn(frequencyFocus_{1});
                        frequencyFocus{1} = [min(frequencyFocus{1}(1),frequencyFocus_{1}(1)),max(frequencyFocus{1}(2),frequencyFocus_{1}(2))];
                    end
                    if this.FrequencyScale=="linear" && ...
                            (any(arrayfun(@(x) ~all(x.IsReal),sigmaData)) || any(arrayfun(@(x) ~all(x.IsReal),sigmaBoundData)))
                        frequencyFocus{1}(1) = -frequencyFocus{1}(2); % mirror common focus
                    end
                else
                    frequencyFocus = this.XLimitsFocus;
                    frequencyUnit = this.FrequencyUnit;
                    frequencyUnitBounds = this.FrequencyUnit;
                end

                if strcmp(this.MagnitudeUnit,"dB")
                    magnitudeScaleData = "log";
                else
                    magnitudeScaleData = this.MagnitudeScale;
                end                
                if ~isempty(sigmaData)
                    frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.FrequencyUnit,frequencyUnit);
                    frequencyFocusDefaultUnits{1} = frequencyConversionFcn(frequencyFocus{1});
                    [singularValueFocus_,magnitudeUnit] = getCommonSingularValueFocus(sigmaData,frequencyFocusDefaultUnits,magnitudeScaleData,sigmaVisible);
                    magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,magnitudeUnit,this.MagnitudeUnit);
                    singularValueFocus_{1} = magnitudeConversionFcn(singularValueFocus_{1});
                    singularValueFocus{1} = [min(singularValueFocus{1}(1),singularValueFocus_{1}(1)),max(singularValueFocus{1}(2),singularValueFocus_{1}(2))];
                end
                if ~isempty(sigmaBoundData)
                    frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.FrequencyUnit,frequencyUnitBounds);
                    frequencyFocusDefaultUnits{1} = frequencyConversionFcn(frequencyFocus{1});
                    [singularValueFocus_,magnitudeUnit] = getCommonSingularValueFocus(sigmaBoundData,frequencyFocusDefaultUnits,magnitudeScaleData,sigmaBoundVisible);
                    magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,magnitudeUnit,this.MagnitudeUnit);
                    singularValueFocus_{1} = magnitudeConversionFcn(singularValueFocus_{1});
                    singularValueFocus{1} = [min(singularValueFocus{1}(1),singularValueFocus_{1}(1)),max(singularValueFocus{1}(2),singularValueFocus_{1}(2))];
                end
            end
        end
    end
end


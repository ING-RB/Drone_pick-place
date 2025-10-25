classdef SectorAxesView < controllib.chart.internal.view.axes.BaseAxesView & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit
    % SIGMAVIEW     Construct view to manage axes and responses for SIGMAPLOT     

    % Copyright 2022 The MathWorks, Inc.
    
    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        IndexScale
        FrequencyScale
    end

    properties (Access = protected)
        XLabelWithoutUnits = ""
        YLabelWithoutUnits = ""
        IndexScale_I
        FrequencyScale_I
    end
    
    %% Constructor
    methods
        function this = SectorAxesView(chart)
            arguments
                chart (1,1) controllib.chart.SectorPlot
            end
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(chart.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(chart.IndexUnit);
            this@controllib.chart.internal.view.axes.BaseAxesView(chart);
            this.FrequencyScale = chart.FrequencyScale;
            this.IndexScale = chart.IndexScale;
            
            build(this);
        end
    end

    %% Public methods
    methods
        function updateResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
                response (1,1) controllib.chart.internal.foundation.ModelResponse
            end
            idx = find(arrayfun(@(x) x.Response.Tag == response.Tag,this.ResponseViews),1);
            responseView = this.ResponseViews(idx);
            hasDifferentCharacteristics = ~isempty(setdiff(...
                union(responseView.CharacteristicTypes,response.CharacteristicTypes),...
                intersect(responseView.CharacteristicTypes,response.CharacteristicTypes)));
            if isa(responseView,'controllib.chart.internal.view.wave.SectorBoundResponseView')
                hasDifferentNumLines = responseView.NPatches ~= size(response.ResponseData.RelativeIndex{1},1);
            else
                hasDifferentNumLines = responseView.NLines ~= size(response.ResponseData.RelativeIndex{1},1);
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
                if isa(responseView,'controllib.chart.internal.view.wave.SectorBoundResponseView')
                    updatePatchHeight(responseView,this.YLimits);
                end
            end
        end
    end

    %% Get/Set methods
    methods
        % FrequencyScale
        function FrequencyScale = get.FrequencyScale(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
            end
            FrequencyScale = this.FrequencyScale_I;
        end

        function set.FrequencyScale(this,FrequencyScale)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
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

        % IndexScale
        function IndexScale = get.IndexScale(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
            end
            IndexScale = this.IndexScale_I;
        end

        function set.IndexScale(this,IndexScale)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
                IndexScale (1,1) string {mustBeMember(IndexScale,["log","linear"])}
            end
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.YScale = IndexScale;
                update(this.AxesGrid);
            end
            this.IndexScale_I = IndexScale;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
                response (1,1) controllib.chart.internal.foundation.ModelResponse
            end
            switch class(response)
                case "controllib.chart.response.SectorResponse"
                    responseView = controllib.chart.internal.view.wave.SectorResponseView(response);
                case "controllib.chart.response.internal.SectorBoundResponse"
                    responseView = controllib.chart.internal.view.wave.SectorBoundResponseView(response);
            end
            responseView.FrequencyUnit = this.FrequencyUnit;
            responseView.MagnitudeUnit = this.MagnitudeUnit;
            responseView.FrequencyScale = this.FrequencyScale;
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
                responseView (1,1) controllib.chart.internal.view.wave.BaseResponseView
            end
            if isa(responseView,"controllib.chart.internal.view.wave.SectorBoundResponseView")
                updatePatchHeight(responseView,this.YLimits);
            end
            ax = getAxes(this);
            aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
            updateArrows(responseView,AspectRatio=aspectRatio);
        end

        function cbAxesGridXLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
            end
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.BaseAxesView(this);
            ax = getAxes(this);
            aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
            for k = 1:length(this.ResponseViews)
                updateArrows(this.ResponseViews(k),aspectRatio=aspectRatio);
            end
        end

        function cbAxesGridYLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.BaseAxesView(this);
            ax = getAxes(this);
            aspectRatio = ax(1).PlotBoxAspectRatio(1:2);
            for k = 1:length(this.ResponseViews)
                if isa(this.ResponseViews(k),"controllib.chart.internal.view.wave.SectorBoundResponseView")
                    updatePatchHeight(this.ResponseViews(k),this.AxesGrid.YLimits{1});
                end
                updateArrows(this.ResponseViews(k),aspectRatio=aspectRatio);
            end
        end

        function [frequencyFocus, relativeIndexFocus] = updateFocus_(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
                responses (:,1) controllib.chart.internal.foundation.ModelResponse
            end
            % Compute focus
            [frequencyFocus, relativeIndexFocus] = computeFocus(this,responses);
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
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
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
                conversionFcn (1,1) function_handle
            end

            minYData = NaN;
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).MagnitudeUnit = this.MagnitudeUnit;
                if strcmp(this.MagnitudeUnit,'dB')
                    % check response ydata to compute minimum yLimit in the
                    % case of negative index values
                    if ~isa(this.ResponseViews(n),'controllib.chart.internal.view.wave.SectorBoundResponseView')
                        yData = this.ResponseViews(n).ResponseLines.YData;
                    end
                    yData(yData < -80) = [];
                    minYData = min(minYData,min(yData));
                end
            end

            % Convert Limits
            newYLimitsFocus = conversionFcn(this.AxesGrid.YLimitsFocus{1});
            if isnan(newYLimitsFocus(1)) || newYLimitsFocus(1) < -80
                % Set minimum yLimit as the minimum ydata of the response
                % when YLimitsFocus converts to NaN (in case of negative
                % index values)
                newYLimitsFocus(1) = minYData;
            end
            this.AxesGrid.YLimitsFocus{1} = newYLimitsFocus;

            if strcmp(this.AxesGrid.YLimitsMode{1},"manual")
                this.AxesGrid.YLimits{1} = conversionFcn(this.AxesGrid.YLimits{1});
            end
            update(this.AxesGrid);

            setYLabelString(this,this.YLabelWithoutUnits);
        end

        function inputs = getAxesGridInputs(this)
            inputs = getAxesGridInputs@controllib.chart.internal.view.axes.BaseAxesView(this);
            inputs.XScale = this.FrequencyScale;
            inputs.YScale = this.IndexScale;
        end

        function XLabel = getXLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
            end
            XLabel = this.XLabelWithoutUnits;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
                XLabel (1,1) string
            end
            this.XLabelWithoutUnits = XLabel;
            this.AxesGrid.XLabel = this.XLabelWithoutUnits + " (" + this.FrequencyUnitLabel + ")";
        end

        function YLabel = getYlabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
            end
            YLabel = this.YLabelWithoutUnits;
        end

        function setYLabelString(this,YLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
                YLabel (1,1) string
            end
            this.YLabelWithoutUnits = YLabel;
            this.AxesGrid.YLabel = this.YLabelWithoutUnits + " (" + this.MagnitudeUnitLabel + ")";
        end

        function [frequencyFocus, relativeIndexFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.SectorAxesView
                responses (:,1) controllib.chart.internal.foundation.ModelResponse
            end
            frequencyFocus = {[NaN NaN]};
            relativeIndexFocus = {[NaN NaN]};
            if ~isempty(responses)
                data = [responses.ResponseData];
                isSectorResponse = arrayfun(@(x) isa(x,"controllib.chart.response.SectorResponse"),responses);
                sectorData = data(isSectorResponse);
                sectorBoundData = data(~isSectorResponse);
                dataVisible = {responses.ArrayVisible};
                sectorVisible = dataVisible(isSectorResponse);
                sectorBoundVisible = dataVisible(~isSectorResponse);
                if ~isempty(sectorData)
                    [frequencyFocus_,frequencyUnit] = getCommonFrequencyFocus(sectorData,this.FrequencyScale,sectorVisible);
                    frequencyConversionFcn = getFrequencyUnitConversionFcn(this,frequencyUnit,this.FrequencyUnit);
                    frequencyFocus_{1} = frequencyConversionFcn(frequencyFocus_{1});
                    frequencyFocus{1} = [min(frequencyFocus{1}(1),frequencyFocus_{1}(1)),max(frequencyFocus{1}(2),frequencyFocus_{1}(2))];
                end
                if ~isempty(sectorBoundData)
                    [frequencyFocus_,frequencyUnitBounds] = getCommonFrequencyFocus(sectorBoundData,this.FrequencyScale,sectorBoundVisible);
                    frequencyConversionFcn = getFrequencyUnitConversionFcn(this,frequencyUnitBounds,this.FrequencyUnit);
                    frequencyFocus_{1} = frequencyConversionFcn(frequencyFocus_{1});
                    frequencyFocus{1} = [min(frequencyFocus{1}(1),frequencyFocus_{1}(1)),max(frequencyFocus{1}(2),frequencyFocus_{1}(2))];
                end
                if strcmp(this.FrequencyScale,"linear") && ...
                        (any(arrayfun(@(x) ~all(x.IsReal),sectorData)) || any(arrayfun(@(x) ~all(x.IsReal),sectorBoundData)))
                    frequencyFocus{1}(1) = -frequencyFocus{1}(2); % mirror common focus
                end
                if strcmp(this.MagnitudeUnit,"dB")
                    indexScale = "log";
                else
                    indexScale = this.IndexScale;
                end       
                if ~isempty(sectorData)
                    frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.FrequencyUnit,frequencyUnit);
                    frequencyFocusDefaultUnits{1} = frequencyConversionFcn(frequencyFocus{1});
                    [relativeIndexFocus_,magnitudeUnit] = getCommonIndexFocus(sectorData,frequencyFocusDefaultUnits,indexScale,sectorVisible);
                    magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,magnitudeUnit,this.MagnitudeUnit);
                    relativeIndexFocus_{1} = magnitudeConversionFcn(relativeIndexFocus_{1});
                    relativeIndexFocus{1} = [min(relativeIndexFocus{1}(1),relativeIndexFocus_{1}(1)),max(relativeIndexFocus{1}(2),relativeIndexFocus_{1}(2))];
                end
                if ~isempty(sectorBoundData)
                    frequencyConversionFcn = getFrequencyUnitConversionFcn(this,this.FrequencyUnit,frequencyUnitBounds);
                    frequencyFocusDefaultUnits{1} = frequencyConversionFcn(frequencyFocus{1});
                    [relativeIndexFocus_,magnitudeUnit] = getCommonIndexFocus(sectorBoundData,frequencyFocusDefaultUnits,indexScale,sectorBoundVisible);
                    magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,magnitudeUnit,this.MagnitudeUnit);
                    relativeIndexFocus_{1} = magnitudeConversionFcn(relativeIndexFocus_{1});
                    relativeIndexFocus{1} = [min(relativeIndexFocus{1}(1),relativeIndexFocus_{1}(1)),max(relativeIndexFocus{1}(2),relativeIndexFocus_{1}(2))];
                end
            end
        end
    end

    %% Static sealed protected methods
    methods (Static,Sealed,Access=protected)
        function mustBeValidFrequencyUnit(frequencyUnit)
            validFrequencyUnits = controllibutils.utGetValidFrequencyUnits;
            mustBeMember(frequencyUnit,string(validFrequencyUnits(:,1)));
        end
        function mustBeValidIndexUnit(indexUnit)
            validIndexUnits = ["dB","abs"];
            mustBeMember(indexUnit,validIndexUnits);
        end
    end
end


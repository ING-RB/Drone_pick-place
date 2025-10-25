classdef MagnitudePhaseFrequencyAxesView < controllib.chart.internal.view.axes.RowColumnAxesView & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit & ...
        controllib.chart.internal.foundation.MixInPhaseUnit & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        MagnitudeScale
        FrequencyScale

        MagnitudeVisible
        PhaseVisible
    end

    properties (AbortSet, SetObservable)
        MinimumGainEnabled (1,1) matlab.lang.OnOffSwitchState = false
        MinimumGainValue (1,1) double = 0
        PhaseWrappingEnabled (1,1) matlab.lang.OnOffSwitchState = false
        PhaseMatchingEnabled (1,1) matlab.lang.OnOffSwitchState = false
    end

    properties (Access = protected)
        MagnitudeScale_I = "linear"
        FrequencyScale_I = "log";

        XLabelWithoutUnits = ""
        YLabelWithoutUnits = ""
    end

    methods
        function this = MagnitudePhaseFrequencyAxesView(chart)
            arguments
                chart (1,1) controllib.chart.internal.foundation.RowColumnPlot
            end

            % Initialize units mixin
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(chart.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(chart.MagnitudeUnit);
            this@controllib.chart.internal.foundation.MixInPhaseUnit(chart.PhaseUnit);

            % Initialize FrequencyView and AbstractView
            this@controllib.chart.internal.view.axes.RowColumnAxesView(chart);

            % Set BodeView properties
            this.FrequencyScale = chart.FrequencyScale;
            this.MagnitudeScale = chart.MagnitudeScale;
            this.PhaseWrappingEnabled = chart.PhaseWrappingEnabled;
            this.PhaseMatchingEnabled = chart.PhaseMatchingEnabled;
            this.MinimumGainEnabled = chart.MinimumGainEnabled;
            this.MinimumGainValue = chart.MinimumGainValue;
        end

    end

    methods
        function updateFocus(this)
            updateFocus@controllib.chart.internal.view.axes.BaseAxesView(this);
            switch this.RowColumnGrouping
                case "all"
                    allXLimitsFocus = cell2mat(this.AxesGrid.XLimitsFocus(:));
                    this.AxesGrid.XLimitsFocus = [min(allXLimitsFocus(:,1)), max(allXLimitsFocus(:,2))];
                    allYLimitsFocus = cell2mat(this.AxesGrid.YLimitsFocus(:));
                    magFocus = allYLimitsFocus(1:2:end,:);
                    magFocus = [min(magFocus(:,1)), max(magFocus(:,2))];
                    phaseFocus = allYLimitsFocus(2:2:end,:);
                    phaseFocus = [min(phaseFocus(:,1)), max(phaseFocus(:,2))];
                    this.AxesGrid.YLimitsFocus = repmat({magFocus;phaseFocus},this.NRows,this.NColumns);
                case "columns"
                    xLimitsFocus = cell(2*this.NRows,1);
                    yLimitsFocus = cell(2*this.NRows,1);
                    for ko = 1:this.NRows
                        allXLimitsFocus = cell2mat(this.AxesGrid.XLimitsFocus(2*ko-1:2*ko,:)');
                        xLimitsFocus(2*ko-1:2*ko) = {[min(allXLimitsFocus(:,1)), max(allXLimitsFocus(:,2))]};

                        magFocus = cell2mat(this.AxesGrid.YLimitsFocus(2*ko-1,:)');
                        magFocus = [min(magFocus(:,1)), max(magFocus(:,2))];
                        phaseFocus = cell2mat(this.AxesGrid.YLimitsFocus(2*ko,:)');
                        phaseFocus = [min(phaseFocus(:,1)), max(phaseFocus(:,2))];
                        yLimitsFocus(2*ko-1:2*ko) = {magFocus;phaseFocus};
                    end
                    this.AxesGrid.XLimitsFocus = repmat(xLimitsFocus,1,this.NColumns);
                    this.AxesGrid.YLimitsFocus = repmat(yLimitsFocus,1,this.NColumns);
                case "rows"
                    xLimitsFocus = cell(2,this.NColumns);
                    yLimitsFocus = cell(2,this.NColumns);
                    for ki = 1:this.NColumns
                        allXLimitsFocus = cell2mat(this.AxesGrid.XLimitsFocus(:,ki));
                        xLimitsFocus(:,ki) = {[min(allXLimitsFocus(:,1)), max(allXLimitsFocus(:,2))]};

                        allYLimitsFocus = cell2mat(this.AxesGrid.YLimitsFocus(:,ki));
                        magFocus = allYLimitsFocus(1:2:end,:);
                        magFocus = [min(magFocus(:,1)), max(magFocus(:,2))];
                        phaseFocus = allYLimitsFocus(2:2:end,:);
                        phaseFocus = [min(phaseFocus(:,1)), max(phaseFocus(:,2))];
                        yLimitsFocus(:,ki) = {magFocus;phaseFocus};
                    end
                    this.AxesGrid.XLimitsFocus = repmat(xLimitsFocus,this.NRows,1);
                    this.AxesGrid.YLimitsFocus = repmat(yLimitsFocus,this.NRows,1);
            end
            update(this.AxesGrid);
        end
    end

    methods
        % Magnitude Visible
        function MagnitudeVisible = get.MagnitudeVisible(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
            end
            MagnitudeVisible = this.AxesGrid.SubGridRowVisible(1);
        end

        function set.MagnitudeVisible(this,MagnitudeVisible)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                MagnitudeVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.AxesGrid.SubGridRowVisible(1) = MagnitudeVisible;
            update(this.AxesGrid);
            setYLabelString(this);
        end

        % Phase visible
        function PhaseVisible = get.PhaseVisible(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
            end
            PhaseVisible = this.AxesGrid.SubGridRowVisible(2);
        end

        function set.PhaseVisible(this,PhaseVisible)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                PhaseVisible (1,1) matlab.lang.OnOffSwitchState
            end
            this.AxesGrid.SubGridRowVisible(2) = PhaseVisible;
            update(this.AxesGrid);
            setYLabelString(this);
        end

        % Magnitude Scale
        function MagnitudeScale = get.MagnitudeScale(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
            end
            MagnitudeScale = this.MagnitudeScale_I;
        end

        function set.MagnitudeScale(this,MagnitudeScale)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                MagnitudeScale (1,1) string {mustBeMember(MagnitudeScale,["log","linear"])}
            end
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.YScale(1) = MagnitudeScale;
                update(this.AxesGrid);
            end
            this.MagnitudeScale_I = MagnitudeScale;
        end

        % Frequency Scale
        function FrequencyScale = get.FrequencyScale(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
            end
            FrequencyScale = this.FrequencyScale_I;
        end

        function set.FrequencyScale(this,FrequencyScale)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                FrequencyScale (1,1) string {mustBeMember(FrequencyScale,["log","linear"])}
            end
            for ii = 1:length(this.ResponseViews)
                this.ResponseViews(ii).FrequencyScale = FrequencyScale;
            end
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.XScale = FrequencyScale;
                update(this.AxesGrid,true);
                
                if strcmp(FrequencyScale,"log")
                    ax = getAxes(this);
                    aspectRatio = ax(1).PlotBoxAspectRatio;
                    for ii = 1:length(this.ResponseViews)
                        updateArrows(this.ResponseViews(ii),AspectRatio=aspectRatio);
                    end
                else
                    for ii = 1:length(this.ResponseViews)
                        hideArrows(this.ResponseViews(ii));
                    end
                end
            end           
            this.FrequencyScale_I = FrequencyScale;
        end

        % PhaseWrappingEnabled
        function set.PhaseWrappingEnabled(this,PhaseWrappingEnabled)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                PhaseWrappingEnabled (1,1) logical
            end
            this.PhaseWrappingEnabled = PhaseWrappingEnabled;
            for ii = 1:length(this.ResponseViews)
                this.ResponseViews(ii).PhaseWrappingEnabled = PhaseWrappingEnabled;
            end
        end

        % PhaseMatchingEnabled
        function set.PhaseMatchingEnabled(this,PhaseMatchingEnabled)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                PhaseMatchingEnabled (1,1) logical
            end
            this.PhaseMatchingEnabled = PhaseMatchingEnabled;
            for ii = 1:length(this.ResponseViews)
                this.ResponseViews(ii).PhaseMatchingEnabled = PhaseMatchingEnabled;
            end
        end
    end

    methods(Access=protected)
        function subGridSize = getAxesGridSubGridSize(~)
            subGridSize = [2 1];
        end

        function inputs = getAxesGridInputs(this)
            inputs = getAxesGridInputs@controllib.chart.internal.view.axes.RowColumnAxesView(this);
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
            inputs.SubGridRowVisible = [this.Chart.MagnitudeVisible;this.Chart.PhaseVisible];
        end

        function [xLimitsFocus,yLimitsFocus] = updateFocus_(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                responses (:,1) controllib.chart.response.BodeResponse
            end
            % Compute focus
            [frequencyFocus,magnitudeFocus,phaseFocus] = computeFocus(this,responses);
            
            xLimitsFocus = cell(size(frequencyFocus,1)*2,size(frequencyFocus,2));
            yLimitsFocus = cell(size(magnitudeFocus,1)*2,size(magnitudeFocus,2));
            xLimitsFocus(1:2:end,:) = frequencyFocus;
            xLimitsFocus(2:2:end,:) = frequencyFocus;
            yLimitsFocus(1:2:end,:) = magnitudeFocus;
            yLimitsFocus(2:2:end,:) = phaseFocus;
        end

        function [frequencyFocus,magnitudeFocus,phaseFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                responses (:,1) controllib.chart.response.BodeResponse
            end
            frequencyFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            magnitudeFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            phaseFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            if ~isempty(responses)
                data = [responses.ResponseData];
                minStabVisible =  isfield(this.CharacteristicsVisibility,'MinimumStabilityMargins') && this.CharacteristicsVisibility.MinimumStabilityMargins;
                allStabVisible =  isfield(this.CharacteristicsVisibility,'AllStabilityMargins') && this.CharacteristicsVisibility.AllStabilityMargins;
                [frequencyFocus_,frequencyUnit] = getCommonFrequencyFocus(data,this.FrequencyScale,...
                    MinimumStabilityMarginsVisible=minStabVisible,AllStabilityMarginsVisible=allStabVisible,ArrayVisible={responses.ArrayVisible});
                frequencyFocus(1:size(frequencyFocus_,1),1:size(frequencyFocus_,2)) = frequencyFocus_;
                crVisible =  isfield(this.CharacteristicsVisibility,'ConfidenceRegion') && this.CharacteristicsVisibility.ConfidenceRegion;
                brVisible =  isfield(this.CharacteristicsVisibility,'BoundaryRegion') && this.CharacteristicsVisibility.BoundaryRegion;
                [magnitudeFocus_,magnitudeUnit] = getCommonMagnitudeFocus(data,frequencyFocus,this.MagnitudeScale,...
                    ConfidenceRegionVisible=crVisible,BoundaryRegionVisible=brVisible,ArrayVisible={responses.ArrayVisible});
                [phaseFocus_,phaseUnit] = getCommonPhaseFocus(data,frequencyFocus,...
                    ConfidenceRegionVisible=crVisible,BoundaryRegionVisible=brVisible,ArrayVisible={responses.ArrayVisible},...
                    PhaseMatchingEnabled=this.PhaseMatchingEnabled,PhaseWrappingEnabled=this.PhaseWrappingEnabled);
                magnitudeFocus(1:size(magnitudeFocus_,1),1:size(magnitudeFocus_,2)) = magnitudeFocus_;
                phaseFocus(1:size(phaseFocus_,1),1:size(phaseFocus_,2)) = phaseFocus_;
                frequencyConversionFcn = getFrequencyUnitConversionFcn(this,frequencyUnit,this.FrequencyUnit);
                magnitudeConversionFcn = getMagnitudeUnitConversionFcn(this,magnitudeUnit,this.MagnitudeUnit);
                phaseConversionFcn = getPhaseUnitConversionFcn(this,phaseUnit,this.PhaseUnit);
                for ko = 1:this.NRows
                    for ki = 1:this.NColumns
                        frequencyFocus{ko,ki} = frequencyConversionFcn(frequencyFocus{ko,ki});
                        magnitudeFocus{ko,ki} = magnitudeConversionFcn(magnitudeFocus{ko,ki});
                        phaseFocus{ko,ki} = phaseConversionFcn(phaseFocus{ko,ki});
                    end
                end
            end
            if this.MinimumGainEnabled
                for ko = 1:this.NRows
                    for ki = 1:this.NColumns
                        magnitudeFocus{ko,ki}(1) = this.MinimumGainValue;
                        if this.MinimumGainValue >= magnitudeFocus{ko,ki}(2)
                            magnitudeFocus{ko,ki}(2) = this.MinimumGainValue+10;
                        end
                    end
                end
            end
        end

        function deleteAllDataTips(this,ed)
            % Select inputIdx and outputIdx based on IOGrouping
            switch this.RowColumnGrouping
                case 'none'
                    if this.MagnitudeVisible && this.PhaseVisible
                        rowIdx = find(this.RowVisible,ceil(ed.Data.Row/2));
                        rowIdx = rowIdx(end);
                    else
                        rowIdx = find(this.RowVisible,ed.Data.Row);
                        rowIdx = rowIdx(end);
                    end
                    columnIdx = find(this.ColumnVisible,ed.Data.Column);
                    columnIdx = columnIdx(end);
                case 'columns'
                    if this.MagnitudeVisible && this.PhaseVisible
                        rowIdx = find(this.RowVisible,ceil(ed.Data.Row/2));
                        rowIdx = rowIdx(end);
                    else
                        rowIdx = find(this.RowVisible,ed.Data.Row);
                        rowIdx = rowIdx(end);
                    end
                    columnIdx = 1:this.NColumns;
                case 'rows'
                    rowIdx = 1:this.NRows;
                    columnIdx = find(this.ColumnVisible,ed.Data.Column);
                    columnIdx = columnIdx(end);
                case 'all'
                    rowIdx = 1:this.NRows;
                    columnIdx = 1:this.NColumns;
            end

            if this.MagnitudeVisible && this.PhaseVisible
                if mod(ed.Data.Row,2)
                    responseToDelete = "magnitude";
                else
                    responseToDelete = "phase";
                end
            elseif this.MagnitudeVisible
                responseToDelete = "magnitude";
            elseif this.PhaseVisible
                responseToDelete = "phase";
            end

            for k = 1:length(this.ResponseViews)
                deleteAllDataTips(this.ResponseViews(k),rowIdx,columnIdx,responseToDelete);
            end
        end

        function cbFrequencyUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                conversionFcn (1,1) function_handle
            end
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).FrequencyUnit = this.FrequencyUnit;
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
            
            % Update AxesGrid
            update(this.AxesGrid);
            
            % Modify Label
            setXLabelString(this,this.XLabelWithoutUnits);
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                conversionFcn (1,1) function_handle
            end
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).MagnitudeUnit = this.MagnitudeUnit;
            end

            % Convert Limits
            for ii = 1:2:numel(this.AxesGrid.YLimitsFocus)
                this.AxesGrid.YLimitsFocus{ii} = conversionFcn(this.AxesGrid.YLimitsFocus{ii});
            end

            if this.AxesGrid.SubGridRowVisible(1)
                spacing = 1 + this.AxesGrid.SubGridRowVisible(2);
                for ii = 1:spacing:numel(this.AxesGrid.YLimits)
                    if strcmp(this.AxesGrid.YLimitsMode{ii},'manual')
                        this.AxesGrid.YLimits{ii} = conversionFcn(this.AxesGrid.YLimits{ii});
                    end
                end
            end

            % Change AxesGrid SubGrid RowLabel
            setYLabelString(this,this.YLabelWithoutUnits);
            
            % Update AxesGrid
            update(this.AxesGrid);

            % Modify Minimum Gain
            this.MinimumGainValue = conversionFcn(this.MinimumGainValue);
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                conversionFcn (1,1) function_handle
            end
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).PhaseUnit = this.PhaseUnit;
            end

            % Convert Limits
            for ii = 2:2:numel(this.AxesGrid.YLimitsFocus)
                this.AxesGrid.YLimitsFocus{ii} = conversionFcn(this.AxesGrid.YLimitsFocus{ii});
            end

            if this.AxesGrid.SubGridRowVisible(2)
                spacing = 1 + this.AxesGrid.SubGridRowVisible(1);
                for ii = 1:spacing:numel(this.AxesGrid.YLimits)
                    if strcmp(this.AxesGrid.YLimitsMode{ii},'manual')
                        this.AxesGrid.YLimits{ii} = conversionFcn(this.AxesGrid.YLimits{ii});
                    end
                end
            end

            % Change Sub Grid Row Label
            setYLabelString(this,this.YLabelWithoutUnits);

            if strcmp(this.PhaseUnit,'deg')
                this.AxesGrid.YLimitPickerBase(2) = 45;
            else
                this.AxesGrid.YLimitPickerBase(2) = 10;
            end

            % Update
            update(this.AxesGrid);
        end

        function XLabel = getXLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
            end
            XLabel = this.XLabelWithoutUnits;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                XLabel (1,1) string
            end
            this.XLabelWithoutUnits = XLabel;
            this.AxesGrid.XLabel = this.XLabelWithoutUnits + " (" + this.FrequencyUnitLabel + ")";
        end

        function yLabel = getYLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
            end
            yLabel = this.YLabelWithoutUnits;
        end

        function setYLabelString(this,YLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.MagnitudePhaseFrequencyAxesView
                YLabel (2,1) string = this.YLabelWithoutUnits
            end
            this.YLabelWithoutUnits = YLabel;
            magnitudeLabel = YLabel(1) + " (" + this.MagnitudeUnitLabel + ")";
            phaseLabel = YLabel(2) + " (" + this.PhaseUnitLabel + ")";
            if isequal(this.AxesGrid.GridSize,[1 1])
                this.AxesGrid.YLabel = "";
                this.AxesGrid.SubGridRowLabels(1) = magnitudeLabel;
                this.AxesGrid.SubGridRowLabels(2) = phaseLabel;
            else
                this.AxesGrid.SubGridRowLabels(1) = "";
                this.AxesGrid.SubGridRowLabels(2) = "";
                if all(this.AxesGrid.SubGridRowVisible) || ~any(this.AxesGrid.SubGridRowVisible)
                    % If magnitude and phase are both visible, or none
                    % visible
                    this.AxesGrid.YLabel = magnitudeLabel + "; " + phaseLabel; 
                elseif this.AxesGrid.SubGridRowVisible(1)
                    % If only magnitude is visible
                    this.AxesGrid.YLabel = magnitudeLabel;
                else
                    % If only phase is visible
                    this.AxesGrid.YLabel = phaseLabel;
                end
            end
            update(this.AxesGrid);
        end

        function magnitudeLabel = generateStringForMagnitudeLabel(this)
            % If more than one output, then put unit in a new line below
            % the label because axes height is small
            if this.NRows > 1
                separator = newline;
            else
                separator = " ";
            end
            magnitudeLabel = string(getString(message('Controllib:plots:strMagnitude'))) + separator + ...
                "(" + this.MagnitudeUnitLabel + ")";
        end

        function phaseLabel = generateStringForPhaseLabel(this)
            % If more than one output, then put unit in a new line below
            % the label because axes height is small
            if this.NRows > 1
                separator = newline;
            else
                separator = " ";
            end
            phaseLabel = string(getString(message('Controllib:plots:strPhase')))' + separator + ...
                "(" + this.PhaseUnitLabel + ")";
        end
    end

end
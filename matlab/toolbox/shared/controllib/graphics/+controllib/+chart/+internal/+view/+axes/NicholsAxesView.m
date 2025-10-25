classdef NicholsAxesView < controllib.chart.internal.view.axes.RowColumnAxesView & ...
        controllib.chart.internal.view.axes.MixInInputOutputAxesViewLabels & ...
        controllib.chart.internal.foundation.MixInMagnitudeUnit & ...
        controllib.chart.internal.foundation.MixInPhaseUnit & ...
        controllib.chart.internal.foundation.MixInFrequencyUnit
    % NicholsView

    % Copyright 2023 The MathWorks, Inc.

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        MagnitudeScale
    end

    properties (AbortSet, SetObservable)
        MinimumGainEnabled (1,1) matlab.lang.OnOffSwitchState = false
        MinimumGainValue (1,1) double = 0
        PhaseWrappingEnabled (1,1) matlab.lang.OnOffSwitchState = false
        PhaseMatchingEnabled (1,1) matlab.lang.OnOffSwitchState = false
        GridOptions (1,1) struct = gridopts('nichols')
    end

    properties (Access = protected)
        MagnitudeScale_I = "linear"
        XLabelWithoutUnits = ""
        YLabelWithoutUnits = ""

        GridLines
        GridLineLabels
    end


    %% Constructor
    methods
        function this = NicholsAxesView(chart)
            arguments
                chart (1,1) controllib.chart.NicholsPlot
            end

            % Initialize units mixin
            this@controllib.chart.internal.foundation.MixInFrequencyUnit(chart.FrequencyUnit);
            this@controllib.chart.internal.foundation.MixInMagnitudeUnit(chart.MagnitudeUnit);
            this@controllib.chart.internal.foundation.MixInPhaseUnit(chart.PhaseUnit);

            this@controllib.chart.internal.view.axes.RowColumnAxesView(chart);

            % Set NicholsView properties
            this.PhaseWrappingEnabled = chart.PhaseWrappingEnabled;
            this.PhaseMatchingEnabled = chart.PhaseMatchingEnabled;
            this.MinimumGainEnabled = chart.MinimumGainEnabled;
            this.MinimumGainValue = chart.MinimumGainValue;

            this.GridOptions.PhaseUnits = char(chart.PhaseUnit);

            build(this);
        end
    end

    %% Get/Set
    methods
        % PhaseWrappingEnabled
        function set.PhaseWrappingEnabled(this,PhaseWrappingEnabled)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
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
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
                PhaseMatchingEnabled (1,1) logical
            end
            this.PhaseMatchingEnabled = PhaseMatchingEnabled;
            for ii = 1:length(this.ResponseViews)
                this.ResponseViews(ii).PhaseMatchingEnabled = PhaseMatchingEnabled;
            end
        end

        % Magnitude Scale
        function MagnitudeScale = get.MagnitudeScale(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
            end
            MagnitudeScale = this.MagnitudeScale_I;
        end

        function set.MagnitudeScale(this,MagnitudeScale)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
                MagnitudeScale (1,1) string {mustBeMember(MagnitudeScale,["log","linear"])}
            end
            this.MagnitudeScale_I = MagnitudeScale;
            if ~isempty(this.AxesGrid) && isvalid(this.AxesGrid)
                this.AxesGrid.YScale = MagnitudeScale;
                update(this.AxesGrid);
            end
            updateGrid(this);
        end
    end

    %% Public methods
    methods
        function updateFocus(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
            end
            updateFocus@controllib.chart.internal.view.axes.RowColumnAxesView(this);
            if this.Chart.AxesStyle.GridVisible && this.Chart.HasCustomGrid
                if this.Chart.XLimitsFocusFromResponses
                    this.AxesGrid.XLimitsFocus{1} = this.getAutoLimits("phase",this.AxesGrid.XLimitsFocus{1},this.PhaseUnit);
                end
                if this.Chart.YLimitsFocusFromResponses
                    this.AxesGrid.YLimitsFocus{1} = this.getAutoLimits("mag",this.AxesGrid.YLimitsFocus{1},this.MagnitudeUnit);
                end
            end
            update(this.AxesGrid);
        end

        function updateAxesGridSize(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
            end
            updateAxesGridSize@controllib.chart.internal.view.axes.RowColumnAxesView(this);
            updateGrid(this);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function responseView = createResponseView(this,response)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
                response (1,1) controllib.chart.response.NicholsResponse
            end
            responseView = controllib.chart.internal.view.wave.NicholsResponseView(response,...
                PhaseMatchingEnabled=this.PhaseMatchingEnabled,...
                PhaseWrappingEnabled=this.PhaseWrappingEnabled,...
                ColumnVisible=this.ColumnVisible(1:response.NInputs),...
                RowVisible=this.RowVisible(1:response.NOutputs));
            responseView.PhaseUnit = this.PhaseUnit;
            responseView.MagnitudeUnit = this.MagnitudeUnit;
            responseView.FrequencyUnit = this.FrequencyUnit;
        end

        function cbPhaseUnitChanged(this,conversionFcn)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
                conversionFcn (1,1) function_handle
            end
            % Change TimeUnit on each response
            for n = 1:length(this.ResponseViews)
                this.ResponseViews(n).PhaseUnit = this.PhaseUnit;
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

            % Modify Label
            setXLabelString(this,this.XLabelWithoutUnits);

            if strcmp(this.PhaseUnit,'deg')
                this.AxesGrid.XLimitPickerBase = 45;
            else
                this.AxesGrid.XLimitPickerBase = 10;
            end

            % Update
            update(this.AxesGrid);

            this.GridOptions.PhaseUnits = char(this.PhaseUnit);
            updateGrid(this);
        end

        function cbMagnitudeUnitChanged(this,conversionFcn)
            % Change FrequencyUnit on each response
            for k = 1:length(this.ResponseViews)
                this.ResponseViews(k).MagnitudeUnit = this.MagnitudeUnit;
            end

            % Convert Limits
            for ii = 1:numel(this.AxesGrid.YLimitsFocus)
                this.AxesGrid.YLimitsFocus{ii} = conversionFcn(this.AxesGrid.YLimitsFocus{ii});
            end

            for ii = 1:numel(this.AxesGrid.YLimits)
                if strcmp(this.AxesGrid.YLimitsMode{ii},'manual')
                    this.AxesGrid.YLimits{ii} = conversionFcn(this.AxesGrid.YLimits{ii});
                end
            end

            % Modify Label
            setYLabelString(this,this.YLabelWithoutUnits);

            % Update
            update(this.AxesGrid);

            this.GridOptions.MagUnits = char(this.MagnitudeUnit);
            updateGrid(this);
        end

        function cbFrequencyUnitChanged(this,~)
            % Change FrequencyUnit on each response
            for k = 1:length(this.ResponseViews)
                this.ResponseViews(k).FrequencyUnit = this.FrequencyUnit;
            end
        end

        function inputs = getAxesGridInputs(this)
            inputs = getAxesGridInputs@controllib.chart.internal.view.axes.RowColumnAxesView(this);
            inputs.YScale = this.MagnitudeScale;
            if strcmp(this.PhaseUnit,'deg')
                inputs.XLimitPickerBase = 45;
            else
                inputs.XLimitPickerBase = 10;
            end
        end

        function postParentResponseView(this,responseView)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
                responseView (1,1) controllib.chart.internal.view.wave.NicholsResponseView
            end
            updateCriticalMarkers(responseView,this.XLimits)
        end

        function cbAxesGridXLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
            end
            cbAxesGridXLimitsChanged@controllib.chart.internal.view.axes.RowColumnAxesView(this);
            for ii = 1:length(this.ResponseViews)
                updateCriticalMarkers(this.ResponseViews(ii),this.XLimits);
            end
            updateGrid(this);
        end

        function cbAxesGridYLimitsChanged(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
            end
            cbAxesGridYLimitsChanged@controllib.chart.internal.view.axes.RowColumnAxesView(this);
            updateGrid(this);
        end

        function [phaseFocus,magnitudeFocus] = updateFocus_(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
                responses (:,1) controllib.chart.response.NicholsResponse
            end            
            % Compute focus
            phaseFocus = computePhaseFocus(this,responses);
            magnitudeFocus = computeMagnitudeFocus(this,responses);
        end

        function updateGrid_(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
            end
            delete(this.GridLines);
            delete(this.GridLineLabels);
            if this.Chart.AxesStyle.GridVisible && this.Chart.HasCustomGrid
                % Update Limits
                [this.GridLines, this.GridLineLabels] = nicchart(getAxes(this),this.GridOptions);
                
                this.GridLines = handle(this.GridLines);
                this.GridLineLabels = handle(this.GridLineLabels);

                % Set Color
                updateCustomGridColor(this);

                % Set PickableParts to 'none' to avoid datatips
                set(this.GridLines,Serializable='off',LineWidth=this.Style.Axes.GridLineWidth);
                for ii = 1:numel(this.GridLines)
                    if isprop(this.GridLines(ii),"LineStyle")
                        this.GridLines(ii).LineStyle = this.Style.Axes.GridLineStyle;
                    end
                end
                set(this.GridLineLabels,Serializable='off',Visible=this.Chart.AxesStyle.GridLabelsVisible);

                for ii = 1:length(this.ResponseViews)
                    this.ResponseViews(ii).ShowMagnitudeLines = false;
                end
                this.Style.Axes.HasCustomGrid = true;
            else
                for ii = 1:length(this.ResponseViews)
                    this.ResponseViews(ii).ShowMagnitudeLines = true;
                end
                this.Style.Axes.HasCustomGrid = false;
            end
        end

        function updateCustomGridColor(this)
            if ~isempty(this.GridLines) && all(isvalid(this.GridLines))
                if strcmp(this.Style.Axes.GridColorMode,"auto")
                    controllib.plot.internal.utils.setColorProperty(this.GridLines,...
                        "Color","--mw-graphics-borderColor-axes-tertiary");
                    controllib.plot.internal.utils.setColorProperty(this.GridLineLabels,...
                        "Color","--mw-graphics-borderColor-axes-tertiary");
                else
                    controllib.plot.internal.utils.setColorProperty(this.GridLines,...
                        "Color",this.Style.Axes.GridColor);
                    controllib.plot.internal.utils.setColorProperty(this.GridLineLabels,...
                        "Color",this.Style.Axes.GridColor);
                end
            end
        end

        function magnitudeFocus = computeMagnitudeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
                responses (:,1) controllib.chart.response.NicholsResponse
            end
            magnitudeFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            % Compute common focus for all systems
            if ~isempty(responses)
                % Get conversion function for magnitude units
                data = [responses.ResponseData];
                [magnitudeFocus_,magnitudeUnit] = getCommonMagnitudeFocus(data,ArrayVisible={responses.ArrayVisible});
                conversionFcn = getMagnitudeUnitConversionFcn(this,magnitudeUnit,this.MagnitudeUnit);
                for ko = 1:size(magnitudeFocus_,1)
                    for ki = 1:size(magnitudeFocus_,2)
                        magnitudeFocus_{ko,ki} = [conversionFcn(magnitudeFocus_{ko,ki}(1)) conversionFcn(magnitudeFocus_{ko,ki}(2))];
                    end
                end
                magnitudeFocus(1:size(magnitudeFocus_,1),1:size(magnitudeFocus_,2)) = magnitudeFocus_;
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

        function phaseFocus = computePhaseFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
                responses (:,1) controllib.chart.response.NicholsResponse
            end
            phaseFocus = repmat({[NaN NaN]},this.NRows,this.NColumns);
            % Compute common focus for all systems
            if ~isempty(responses)
                % Get conversion function for magnitude units
                data = [responses.ResponseData];
                [phaseFocus_,phaseUnit] = getCommonPhaseFocus(data,ArrayVisible={responses.ArrayVisible},...
                    PhaseWrappingEnabled=this.PhaseWrappingEnabled,PhaseMatchingEnabled=this.PhaseMatchingEnabled);
                conversionFcn = getPhaseUnitConversionFcn(this,phaseUnit,this.PhaseUnit);
                for ko = 1:size(phaseFocus_,1)
                    for ki = 1:size(phaseFocus_,2)
                        phaseFocus_{ko,ki} = [conversionFcn(phaseFocus_{ko,ki}(1)) conversionFcn(phaseFocus_{ko,ki}(2))];
                    end
                end
                phaseFocus(1:size(phaseFocus_,1),1:size(phaseFocus_,2)) = phaseFocus_;
            end
        end

        function XLabel = getXLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
            end
            XLabel = this.XLabelWithoutUnits;
        end

        function setXLabelString(this,XLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
                XLabel (1,1) string
            end
            this.XLabelWithoutUnits = XLabel;
            this.AxesGrid.XLabel = this.XLabelWithoutUnits + " (" + this.PhaseUnitLabel + ")";
        end

        function XLabel = getYLabelString(this)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
            end
            XLabel = this.YLabelWithoutUnits;
        end

        function setYLabelString(this,YLabel)
            arguments
                this (1,1) controllib.chart.internal.view.axes.NicholsAxesView
                YLabel (1,1) string
            end
            this.YLabelWithoutUnits = YLabel;
            this.AxesGrid.YLabel = this.YLabelWithoutUnits + " (" + this.MagnitudeUnitLabel + ")";
        end
    end

    %% Static sealed protected methods
    methods (Static,Sealed,Access=protected)
        function limits = getAutoLimits(action,Lim,Units)
            switch action
                case "phase"
                    % Adjust phase limits
                    % Adjust X limits so that grid is clipped at multiples of 180 degrees
                    switch Units
                        case 'deg'
                            Pi = 180;  TwoPi = 360;
                        case 'rad'
                            Pi = pi;   TwoPi = 2*pi;
                    end
                    Pmax = TwoPi*ceil(Lim(2)/TwoPi);
                    Pmin = min(Pmax-TwoPi,TwoPi*floor(Lim(1)/TwoPi));
                    if Pmax-Pmin>TwoPi
                        % Delete empty 180 degree portions
                        Pmax = Pi*ceil(Lim(2)/Pi);
                        Pmin = Pi*floor(Lim(1)/Pi);
                    end
                    limits = [Pmin Pmax];
                case "mag"
                    % Adjust gain limits
                    switch Units
                        case 'dB'
                            Gmin = min([-20 20*floor(Lim(1)/20)]);
                            Gmax = max([40 20*ceil(Lim(2)/20)]);
                        otherwise
                            Gmin = Lim(1);
                            Gmax = Lim(2);
                    end
                    limits = [Gmin Gmax];
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function [gridLines,gridLineLabels] = qeGetGridLines(this)
            gridLines = this.GridLines;
            gridLineLabels = this.GridLineLabels;
        end
    end
end
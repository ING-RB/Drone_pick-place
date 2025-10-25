classdef MagnitudePhaseFrequencyPlot < controllib.chart.internal.foundation.RowColumnPlot
    % MagnitudePhaseFrequencyPlot is an AbstractPlot that manages the
    % following API and equivalent interactive (property editor dialog and
    % context menu) functionality for a magnitude/phase based plot
    %   - Units and Scale
    %   - Visibility
    %   - PhaseWrapping, PhaseMatching
    %   - MinimumGain

    %% Properties
    properties (Dependent, AbortSet, SetObservable)
        FrequencyUnit
        MagnitudeUnit
        PhaseUnit

        FrequencyScale
        MagnitudeScale

        MagnitudeVisible
        PhaseVisible

        PhaseWrappingEnabled
        PhaseWrappingBranch

        PhaseMatchingEnabled
        PhaseMatchingFrequency
        PhaseMatchingValue

        MinimumGainEnabled
        MinimumGainValue
    end

    properties (Dependent,GetAccess=protected,SetAccess=protected)
        NumberOfStandardDeviations
    end

    properties (Access = protected,Transient,NonCopyable)
        MagnitudeResponseWidget
        PhaseResponseWidget
        ConfidenceRegionWidget

        ShowMenu
        ShowSubMenu
    end

    properties (GetAccess=protected,SetAccess=private)
        FrequencyUnit_I = "rad/s"
        MagnitudeUnit_I = "dB"
        PhaseUnit_I = "deg"
        FrequencyScale_I = "log"
        MagnitudeScale_I = "linear"

        MagnitudeVisible_I = matlab.lang.OnOffSwitchState(true)
        PhaseVisible_I = matlab.lang.OnOffSwitchState(true)

        PhaseWrappingEnabled_I = matlab.lang.OnOffSwitchState(false)
        PhaseWrappingBranch_I = controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot.createDefaultOptions().PhaseWrappingBranch

        PhaseMatchingEnabled_I = matlab.lang.OnOffSwitchState(false)
        PhaseMatchingFrequency_I = controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot.createDefaultOptions().PhaseWrappingBranch
        PhaseMatchingValue_I = controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot.createDefaultOptions().PhaseMatchingValue

        MinimumGainEnabled_I = matlab.lang.OnOffSwitchState(false)
        MinimumGainValue_I = controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot.createDefaultOptions().MagLowerLim

        NumberOfStandardDeviations_I = controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot.createDefaultOptions().ConfidenceRegionNumberSD
    end

    methods
        function this = MagnitudePhaseFrequencyPlot(bodePlotInputs,inputOutputPlotArguments)
            arguments
                bodePlotInputs.Options (1,1) plotopts.BodeOptions = controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot.createDefaultOptions();
                inputOutputPlotArguments.?controllib.chart.internal.foundation.AbstractPlotOptionalInputs
            end
            % Extract name-value inputs for AbstractPlot
            inputOutputPlotArguments = namedargs2cell(inputOutputPlotArguments);
            this@controllib.chart.internal.foundation.RowColumnPlot(inputOutputPlotArguments{:},...
                Options=bodePlotInputs.Options);
        end

        function options = getoptions(this,propertyName)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                propertyName string {mustBeScalarOrEmpty,validateOptionPropertyName(this,propertyName)} = string.empty
            end
            if isempty(propertyName)
                options = getoptions@controllib.chart.internal.foundation.RowColumnPlot(this);
                options.FreqUnits = char(this.FrequencyUnit);
                options.MagUnits = char(this.MagnitudeUnit);
                options.FreqScale = char(this.FrequencyScale);
                options.MagScale = char(this.MagnitudeScale);
                options.PhaseUnits = char(this.PhaseUnit);

                options.MagVisible = char(this.MagnitudeVisible);
                options.PhaseVisible = char(this.PhaseVisible);

                options.PhaseWrappingBranch = this.PhaseWrappingBranch;
                options.PhaseWrapping = char(this.PhaseWrappingEnabled);
                options.PhaseMatchingFreq = this.PhaseMatchingFrequency;
                options.PhaseMatchingValue = this.PhaseMatchingValue;
                options.PhaseMatching = char(this.PhaseMatchingEnabled);
                if this.MinimumGainEnabled
                    options.MagLowerLimMode = 'manual';
                else
                    options.MagLowerLimMode = 'auto';
                end
                options.MagLowerLim = this.MinimumGainValue;

                options.ConfidenceRegionNumberSD = this.NumberOfStandardDeviations;
            else
                switch propertyName
                    case 'FreqUnits'
                        options = char(this.FrequencyUnit);
                    case 'MagUnits'
                        options = char(this.MagnitudeUnit);
                    case 'FreqScale'
                        options = char(this.FrequencyScale);
                    case 'MagScale'
                        options = char(this.MagnitudeScale);
                    case 'PhaseUnits'
                        options = char(this.PhaseUnit);
                    case 'MagVisible'
                        options = char(this.MagnitudeVisible);
                    case 'PhaseVisible'
                        options = char(this.PhaseVisible);
                    case 'PhaseWrappingBranch'
                        options = this.PhaseWrappingBranch;
                    case 'PhaseWrapping'
                        options = char(this.PhaseWrappingEnabled);
                    case 'PhaseMatchingFreq'
                        options = this.PhaseMatchingFrequency;
                    case 'PhaseMatchingValue'
                        options = this.PhaseMatchingValue;
                    case 'PhaseMatching'
                        options = char(this.PhaseMatchingEnabled);
                    case 'MagLowerLimMode'
                        if this.MinimumGainEnabled
                            options = 'manual';
                        else
                            options = 'auto';
                        end
                    case 'MagLowerLim'
                        options = this.MinimumGainValue;
                    case 'ConfidenceRegionNumberSD'
                        options = this.NumberOfStandardDeviations;
                    otherwise
                        options = getoptions@controllib.chart.internal.foundation.RowColumnPlot(this,propertyName);
                end
            end
        end

        %setoptions
        function setoptions(this,options,nameValueInputs)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                options (1,1) plotopts.BodeOptions = getoptions(this)
                nameValueInputs.?plotopts.BodeOptions
            end

            options = copy(options);
            
            % Update options with name-value inputs
            nameValueInputsCell = namedargs2cell(nameValueInputs);
            if ~isempty(nameValueInputsCell)
                set(options,nameValueInputsCell{:});
            end

            % Magnitude Visible
            this.MagnitudeVisible = options.MagVisible;

            % Phase Visible
            this.PhaseVisible = options.PhaseVisible;

            % Frequency Unit & Scale
            if strcmp(options.FreqUnits,'auto')
                if isempty(this.Responses)
                    this.FrequencyUnit = "rad/s";
                else
                    this.FrequencyUnit = this.Responses(1).FrequencyUnit;
                end
            else
                this.FrequencyUnit = options.FreqUnits;
            end
            this.FrequencyScale = options.FreqScale;

            % Magnitude Unit & Scale
            this.MagnitudeUnit = options.MagUnits;
            try %#ok<TRYNC>
                this.MagnitudeScale = options.MagScale;
            end

            % Phase Unit
            this.PhaseUnit = options.PhaseUnits;                       

            % Phase wrapping
            this.PhaseWrappingBranch = options.PhaseWrappingBranch;
            this.PhaseWrappingEnabled = options.PhaseWrapping;

            % Phase Matching
            this.PhaseMatchingFrequency = options.PhaseMatchingFreq;
            this.PhaseMatchingValue = options.PhaseMatchingValue;
            this.PhaseMatchingEnabled = options.PhaseMatching;

            % Min Gain
            this.MinimumGainEnabled = strcmp(options.MagLowerLimMode,'manual');
            this.MinimumGainValue = options.MagLowerLim;            

            % Set characteristic options
            this.NumberOfStandardDeviations = options.ConfidenceRegionNumberSD;

            % Call base class
            setoptions@controllib.chart.internal.foundation.RowColumnPlot(this,options);
        end
    end

    methods % set/get
        % FrequencyUnit
        function FrequencyUnit = get.FrequencyUnit(this)
            FrequencyUnit = this.FrequencyUnit_I;
        end

        function set.FrequencyUnit(this,FrequencyUnit)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                FrequencyUnit (1,1) string {controllib.chart.internal.utils.mustBeValidFrequencyUnit}
            end
            frequencyConversionFcn = controllib.chart.internal.utils.getFrequencyUnitConversionFcn(...
                this.FrequencyUnit,FrequencyUnit);

            this.FrequencyUnit_I = FrequencyUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.FrequencyUnit = FrequencyUnit;
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.FrequencyUnits = FrequencyUnit;
            end

            this.PhaseMatchingFrequency = frequencyConversionFcn(this.PhaseMatchingFrequency);

            % Update Requirements
            for k = 1:length(this.Requirements)
                if contains(getUID(this.Requirements(k)),'bodegain')
                    this.Requirements(k).setDisplayUnits('xunits',char(FrequencyUnit));
                    this.Requirements(k).TextEditor.setDisplayUnits('xunits',char(FrequencyUnit));
                end
                update(this.Requirements(k));
            end
        end

        % MagnitudeUnit
        function MagnitudeUnit = get.MagnitudeUnit(this)
            MagnitudeUnit = this.MagnitudeUnit_I;
        end

        function set.MagnitudeUnit(this,MagnitudeUnit)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                MagnitudeUnit (1,1) string {controllib.chart.internal.utils.mustBeValidMagnitudeUnit}
            end
            if MagnitudeUnit == "dB"
                this.MagnitudeScale = "linear";
            end
            magnitudeConversionFcn = controllib.chart.internal.utils.getMagnitudeUnitConversionFcn(...
                this.MagnitudeUnit,MagnitudeUnit);

            this.MagnitudeUnit_I = MagnitudeUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.MagnitudeUnit = MagnitudeUnit;
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.MagnitudeUnits = MagnitudeUnit;
            end

            this.MinimumGainValue = magnitudeConversionFcn(this.MinimumGainValue);

            % Update Requirements
            for k = 1:length(this.Requirements)
                if contains(getUID(this.Requirements(k)),'bodegain') || ...
                        contains(getUID(this.Requirements(k)),'bodegpm')
                    this.Requirements(k).setDisplayUnits('yunits',char(MagnitudeUnit));
                    this.Requirements(k).TextEditor.setDisplayUnits('yunits',char(MagnitudeUnit));
                end
                update(this.Requirements(k));
            end
        end

        % PhaseUnit
        function PhaseUnit = get.PhaseUnit(this)
            PhaseUnit = this.PhaseUnit_I;
        end

        function set.PhaseUnit(this,PhaseUnit)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                PhaseUnit (1,1) string {controllib.chart.internal.utils.mustBeValidPhaseUnit}
            end
            phaseConversionFcn = controllib.chart.internal.utils.getPhaseUnitConversionFcn(...
                this.PhaseUnit,PhaseUnit);

            this.PhaseUnit_I = PhaseUnit;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.PhaseUnit = PhaseUnit;
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.PhaseUnits = PhaseUnit;
            end

            this.PhaseMatchingValue = phaseConversionFcn(this.PhaseMatchingValue);
            this.PhaseWrappingBranch = phaseConversionFcn(this.PhaseWrappingBranch);

            % Update Requirements
            for k = 1:length(this.Requirements)
                if contains(getUID(this.Requirements(k)),'bodegpm')
                    this.Requirements(k).setDisplayUnits('xunits',char(PhaseUnit));
                    this.Requirements(k).TextEditor.setDisplayUnits('xunits',char(PhaseUnit));
                end
                update(this.Requirements(k));
            end
        end

        % Frequency scale
        function FrequencyScale = get.FrequencyScale(this)
            FrequencyScale = this.FrequencyScale_I;
        end

        function set.FrequencyScale(this,FrequencyScale)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                FrequencyScale (1,1) string {mustBeMember(FrequencyScale,["log","linear"])}
            end
            this.FrequencyScale_I = FrequencyScale;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.FrequencyScale = FrequencyScale;
                updateFocus(this.View);
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.FrequencyScale = FrequencyScale;
            end
        end

        % Magnitude scale
        function MagnitudeScale = get.MagnitudeScale(this)
            MagnitudeScale = this.MagnitudeScale_I;
        end

        function set.MagnitudeScale(this,MagnitudeScale)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                MagnitudeScale (1,1) string {mustBeMember(MagnitudeScale,["log","linear"])}
            end
            if this.MagnitudeUnit == "dB" && MagnitudeScale == "log"
                error(message('Controllib:plots:magUnitScaleIncompatible'));
            end
            this.MagnitudeScale_I = MagnitudeScale;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.MagnitudeScale = MagnitudeScale;
                updateFocus(this.View);
            end

            % Modify property editor widgets
            if ~isempty(this.UnitsWidget) && isvalid(this.UnitsWidget)
                this.UnitsWidget.MagnitudeScale = MagnitudeScale;
            end
        end

        % MagnitudeVisible
        function MagnitudeVisible = get.MagnitudeVisible(this)
            MagnitudeVisible = this.MagnitudeVisible_I;
        end

        function set.MagnitudeVisible(this,MagnitudeVisible)
             arguments
                this (1,1) controllib.chart.BodePlot
                MagnitudeVisible (1,1) matlab.lang.OnOffSwitchState
            end
            oldXLimitsSize = getXLimitsSize(this);
            oldYLimitsSize = getYLimitsSize(this);

            this.MagnitudeVisible_I = MagnitudeVisible;

            newXLimitsSize = getXLimitsSize(this);
            if newXLimitsSize(1) > oldXLimitsSize(1)
                this.XLimits_I = [this.XLimits_I;repmat({[1 10]},newXLimitsSize(1)-oldXLimitsSize(1),newXLimitsSize(2))];
                this.XLimitsMode_I = [this.XLimitsMode_I;repmat({"auto"},newXLimitsSize(1)-oldXLimitsSize(1),newXLimitsSize(2))];
            else
                this.XLimits_I = this.XLimits_I(1:newXLimitsSize(1),:);
                this.XLimitsMode_I = this.XLimitsMode_I(1:newXLimitsSize(1),:);
            end
            newYLimitsSize = getYLimitsSize(this);
            if newYLimitsSize(1) > oldYLimitsSize(1)
                this.YLimits_I = [this.YLimits_I;repmat({[1 10]},newYLimitsSize(1)-oldXLimitsSize(1),newYLimitsSize(2))];
                this.YLimitsMode_I = [this.YLimitsMode_I;repmat({"auto"},newYLimitsSize(1)-oldXLimitsSize(1),newYLimitsSize(2))];
            else
                this.YLimits_I = this.YLimits_I(1:newYLimitsSize(1),:);
                this.YLimitsMode_I = this.YLimitsMode_I(1:newYLimitsSize(1),:);
            end

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.MagnitudeVisible = MagnitudeVisible;
            end

            % Update legend
            if strcmp(this.LegendAxesMode,"auto")
                updateLegendAxesInAutoMode(this);
            end
            setAxesForLegend(this);

            % Update data axes
            updateDataAxes(this);

            updateYLimitsWidget(this);
        end

        % PhaseVisible
        function PhaseVisible = get.PhaseVisible(this)
            PhaseVisible = this.PhaseVisible_I;
        end

        function set.PhaseVisible(this,PhaseVisible)
            arguments
                this (1,1) controllib.chart.BodePlot
                PhaseVisible (1,1) matlab.lang.OnOffSwitchState
            end
            oldXLimitsSize = getXLimitsSize(this);
            oldYLimitsSize = getYLimitsSize(this);

            this.PhaseVisible_I = PhaseVisible;

            newXLimitsSize = getXLimitsSize(this);
            if newXLimitsSize(1) > oldXLimitsSize(1)
                this.XLimits_I = [this.XLimits_I;repmat({[1 10]},newXLimitsSize(1)-oldXLimitsSize(1),newXLimitsSize(2))];
                this.XLimitsMode_I = [this.XLimitsMode_I;repmat({"auto"},newXLimitsSize(1)-oldXLimitsSize(1),newXLimitsSize(2))];
            else
                this.XLimits_I = this.XLimits_I(1:newXLimitsSize(1),:);
                this.XLimitsMode_I = this.XLimitsMode_I(1:newXLimitsSize(1),:);
            end
            newYLimitsSize = getYLimitsSize(this);
            if newYLimitsSize(1) > oldYLimitsSize(1)
                this.YLimits_I = [this.YLimits_I;repmat({[1 10]},newYLimitsSize(1)-oldXLimitsSize(1),newYLimitsSize(2))];
                this.YLimitsMode_I = [this.YLimitsMode_I;repmat({"auto"},newYLimitsSize(1)-oldXLimitsSize(1),newYLimitsSize(2))];
            else
                this.YLimits_I = this.YLimits_I(1:newYLimitsSize(1),:);
                this.YLimitsMode_I = this.YLimitsMode_I(1:newYLimitsSize(1),:);
            end

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.PhaseVisible = PhaseVisible;
            end

            % Update legend
            if strcmp(this.LegendAxesMode,"auto")
                updateLegendAxesInAutoMode(this);
            end
            setAxesForLegend(this);

            % Update data axes
            updateDataAxes(this);

            updateYLimitsWidget(this);
        end

        % PhaseWrappingEnabled
        function PhaseWrappingEnabled = get.PhaseWrappingEnabled(this)
            PhaseWrappingEnabled = this.PhaseWrappingEnabled_I;
        end

        function set.PhaseWrappingEnabled(this,PhaseWrappingEnabled)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                PhaseWrappingEnabled (1,1) matlab.lang.OnOffSwitchState
            end
            this.PhaseWrappingEnabled_I = PhaseWrappingEnabled;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.PhaseWrappingEnabled = PhaseWrappingEnabled;
                updateFocus(this.View);
            end

            updatePhaseResponseWidget(this);
        end

        % PhaseWrappingBranch
        function PhaseWrappingBranch = get.PhaseWrappingBranch(this)
            PhaseWrappingBranch = this.PhaseWrappingBranch_I;
        end

        function set.PhaseWrappingBranch(this,PhaseWrappingBranch)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                PhaseWrappingBranch (1,1) double {mustBeReal,mustBeFinite,mustBeNonNan}
            end
            this.PhaseWrappingBranch_I = PhaseWrappingBranch;

            for ii = 1:length(this.Responses)
                phaseConversionFcn = controllib.chart.internal.utils.getPhaseUnitConversionFcn(...
                    this.PhaseUnit,this.Responses(ii).PhaseUnit);
                this.Responses(ii).PhaseWrappingBranch = phaseConversionFcn(PhaseWrappingBranch);
                notify(this.Responses(ii),'ResponseChanged');
            end

            updatePhaseResponseWidget(this);
        end

        % PhaseMatchingEnabled
        function PhaseMatchingEnabled = get.PhaseMatchingEnabled(this)
            PhaseMatchingEnabled = this.PhaseMatchingEnabled_I;
        end

        function set.PhaseMatchingEnabled(this,PhaseMatchingEnabled)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                PhaseMatchingEnabled (1,1) matlab.lang.OnOffSwitchState
            end
            this.PhaseMatchingEnabled_I = PhaseMatchingEnabled;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.PhaseMatchingEnabled = PhaseMatchingEnabled;
                updateFocus(this.View);
            end

            updatePhaseResponseWidget(this);
        end

        % PhaseMatchingFrequency
        function PhaseMatchingFrequency = get.PhaseMatchingFrequency(this)
            PhaseMatchingFrequency = this.PhaseMatchingFrequency_I;
        end

        function set.PhaseMatchingFrequency(this,PhaseMatchingFrequency)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                PhaseMatchingFrequency (1,1) double {mustBeReal,mustBeFinite,mustBeNonNan}
            end
            this.PhaseMatchingFrequency_I = PhaseMatchingFrequency;

            for ii = 1:length(this.Responses)
                freqConversionFcn = controllib.chart.internal.utils.getFrequencyUnitConversionFcn(...
                    this.FrequencyUnit,this.Responses(ii).FrequencyUnit);
                this.Responses(ii).PhaseMatchingFrequency = freqConversionFcn(PhaseMatchingFrequency);
                notify(this.Responses(ii),'ResponseChanged');
            end

            updatePhaseResponseWidget(this);
        end

        % PhaseMatchingValue
        function PhaseMatchingValue = get.PhaseMatchingValue(this)
            PhaseMatchingValue = this.PhaseMatchingValue_I;
        end

        function set.PhaseMatchingValue(this,PhaseMatchingValue)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                PhaseMatchingValue (1,1) double {mustBeReal,mustBeFinite,mustBeNonNan}
            end
            this.PhaseMatchingValue_I = PhaseMatchingValue;

            for ii = 1:length(this.Responses)
                phaseConversionFcn = controllib.chart.internal.utils.getPhaseUnitConversionFcn(...
                    this.PhaseUnit,this.Responses(ii).PhaseUnit);
                this.Responses(ii).PhaseMatchingValue = phaseConversionFcn(PhaseMatchingValue);
                notify(this.Responses(ii),'ResponseChanged');
            end

            updatePhaseResponseWidget(this);
        end

        % MinimumGainEnabled
        function MinimumGainEnabled = get.MinimumGainEnabled(this)
            MinimumGainEnabled = this.MinimumGainEnabled_I;
        end

        function set.MinimumGainEnabled(this,MinimumGainEnabled)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                MinimumGainEnabled (1,1) matlab.lang.OnOffSwitchState
            end
            this.MinimumGainEnabled_I = MinimumGainEnabled;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.MinimumGainEnabled = MinimumGainEnabled;
                updateFocus(this.View);
            end

            updateMagnitudeResponseWidget(this);
        end

        % MinimumGainValue
        function MinimumGainValue = get.MinimumGainValue(this)
            MinimumGainValue = this.MinimumGainValue_I;
        end

        function set.MinimumGainValue(this,MinimumGainValue)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                MinimumGainValue (1,1) double {mustBeReal,mustBeNonNan}
            end
            this.MinimumGainValue_I = MinimumGainValue;

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                this.View.MinimumGainValue = MinimumGainValue;
                updateFocus(this.View);
            end

            updateMagnitudeResponseWidget(this);
        end

        % NumberOfStandardDeviations
        function NumberOfStandardDeviations = get.NumberOfStandardDeviations(this)
            NumberOfStandardDeviations = this.NumberOfStandardDeviations_I;
        end

        function set.NumberOfStandardDeviations(this,NumberOfStandardDeviations)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                NumberOfStandardDeviations (1,1) double {mustBePositive,mustBeFinite}
            end
            this.NumberOfStandardDeviations_I = NumberOfStandardDeviations;
            if ~isempty(this.Characteristics) && isprop(this.Characteristics,'ConfidenceRegion')
                this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations = NumberOfStandardDeviations;
            end
        end
    end

     methods (Access = protected)
        function initialize(this)
            initialize@controllib.chart.internal.foundation.RowColumnPlot(this);
            this.Type = 'magphase';
            this.SynchronizeResponseUpdates = true;
            if this.MagnitudeVisible && this.PhaseVisible
                this.YLimits = repmat({[1 10];[1 10]},this.NOutputs,1);
                this.YLimitsMode = repmat({"auto"; "auto"},this.NOutputs,1);
                this.YLimitsFocus = repmat({[1 10];[1 10]},this.NOutputs,1);
                this.YLimitsFocusFromResponses = true;
            end
            build(this);
        end

        %% Context menu
        function createContextMenu(this)
            createContextMenu@controllib.chart.internal.foundation.RowColumnPlot(this);
            this.ShowMenu = uimenu(Parent=[],...
                Text=getString(message('Controllib:plots:strShow')),...
                Tag="show");
            this.ShowSubMenu = createArray([2,1],'matlab.ui.container.Menu');
            this.ShowSubMenu(1) = uimenu(this.ShowMenu,...
                Text=getString(message('Controllib:plots:strMagnitude')),...
                Tag="showMagnitude",...
                Checked=this.MagnitudeVisible,...
                MenuSelectedFcn=@(es,ed) set(this,'MagnitudeVisible',~this.PhaseVisible | ~this.MagnitudeVisible));
            this.ShowSubMenu(2) = uimenu(this.ShowMenu,...
                Text=getString(message('Controllib:plots:strPhase')),...
                Tag="showPhase",...
                Checked=this.PhaseVisible,...
                MenuSelectedFcn=@(es,ed) set(this,'PhaseVisible',~this.PhaseVisible | ~this.MagnitudeVisible));
            addMenu(this,this.ShowMenu,Above='grid',CreateNewSection=true);
        end        

        function cbContextMenuOpening(this)
            % Update state of menu items dynamically when context menu is opened
            cbContextMenuOpening@controllib.chart.internal.foundation.RowColumnPlot(this);
            % Show Menu
            this.ShowSubMenu(1).Checked = this.MagnitudeVisible;
            this.ShowSubMenu(2).Checked = this.PhaseVisible;
        end

        %% Characteristics
        function cm = createCharacteristicOptions_(this,charType)
            switch charType
                case "FrequencyPeakResponse"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strPeakResponse')),...
                        Visible=false);
                case "MinimumStabilityMargins"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strMinimumStabilityMargins')),...
                        Visible=false);
                case "AllStabilityMargins"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strAllStabilityMargins')),...
                        Visible=false);
                case "ConfidenceRegion"
                    cm = controllib.chart.options.CharacteristicOption(...
                        MenuLabel=getString(message('Controllib:plots:strConfidenceRegion')),...
                        Visible=false);
                    cm.VisibilityChangedFcn = @(es,ed) cbConfidenceRegionVisibility(this);
                    addCharacteristicProperty(cm,"NumberOfStandardDeviations",...
                        this.NumberOfStandardDeviations);
                    p = findprop(cm,"NumberOfStandardDeviations");
                    p.SetMethod = @(~,value) updateNumberOfStandardDeviations(this,value);
            end
        end

        function applyCharacteristicOptionsToResponse(this,response)
            freqConversionFcn = controllib.chart.internal.utils.getFrequencyUnitConversionFcn(...
                this.FrequencyUnit,response.FrequencyUnit);
            phaseConversionFcn = controllib.chart.internal.utils.getPhaseUnitConversionFcn(...
                this.PhaseUnit,response.PhaseUnit);
            response.PhaseWrappingBranch = phaseConversionFcn(this.PhaseWrappingBranch);
            response.PhaseMatchingFrequency = freqConversionFcn(this.PhaseMatchingFrequency);
            response.PhaseMatchingValue = phaseConversionFcn(this.PhaseMatchingValue);
            if isprop(response,'NumberOfStandardDeviations')
                response.NumberOfStandardDeviations = this.NumberOfStandardDeviations;
            end
        end

        function cbConfidenceRegionVisibility(this)
            setCharacteristicVisibility(this,"ConfidenceRegion");
            updateFocus(this.View);
        end

        function updateNumberOfStandardDeviations(this,value)
            arguments
                this (1,1) controllib.chart.internal.foundation.MagnitudePhaseFrequencyPlot
                value (1,1) double {mustBePositive,mustBeFinite}
            end
            this.NumberOfStandardDeviations_I = value;
            this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations_I = value;

            % Update responses
            for k = 1:length(this.Responses)
                if isprop(this.Responses(k),'NumberOfStandardDeviations')
                    this.Responses(k).NumberOfStandardDeviations = this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations;
                end
            end

            % Update View
            if ~isempty(this.View) && isvalid(this.View)
                updateCharacteristic(this.View,"ConfidenceRegion",this.Responses);
            end

            % Update property editor widget
            if ~isempty(this.ConfidenceRegionWidget) && isvalid(this.ConfidenceRegionWidget)
                disableListeners(this,'ConfidenceNumSDChangedInPropertyEditor');
                this.ConfidenceRegionWidget.ConfidenceNumSD = this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations;
                enableListeners(this,'ConfidenceNumSDChangedInPropertyEditor');
            end
        end

        %% Property editor
        function limitNames = getLimitNamesForYLimitsWidget(this) %#ok<MANU>
            limitNames = string({getString(message('Controllib:plots:strMagnitude')),...
                getString(message('Controllib:plots:strPhase'))});
        end

        function cbYLimitsChangedInPropertyEditor(this,es,ed)
            disableListeners(this,'YLimitsChangedInPropertyEditor');
            this.YLimitsWidget.Enable = false;
            limitsWidget = ed.AffectedObject;
            switch es.Name
                case 'AutoScale'
                    value = limitsWidget.AutoScale;
                    if value
                        yLimMode = "auto";
                    else
                        yLimMode = "manual";
                    end

                    switch limitsWidget.SelectedGroupIdx
                        case 1
                            % Set yLimMode for all
                            this.YLimitsSharing = "all";
                            this.YLimitsMode = yLimMode;
                        otherwise
                            % Set yLimMode for specific row
                            this.YLimitsSharing = "row";
                            outputIdx = limitsWidget.SelectedGroupIdx-1;
                            if this.MagnitudeVisible && this.PhaseVisible
                                this.YLimitsMode((outputIdx*2-1):outputIdx*2) = {yLimMode};
                            elseif this.MagnitudeVisible || this.PhaseVisible
                                this.YLimitsMode{outputIdx} = yLimMode;
                            end
                    end
                    this.YLimitsWidget.Enable = true;
                    updateYLimitsWidget(this);
                case 'Limits'
                    magLimits = limitsWidget.Limits{1};
                    phaseLimits = limitsWidget.Limits{2};
                    % NaN limits indicate the different group limits are not equal and
                    % common group is selected
                    if this.MagnitudeVisible && this.PhaseVisible
                        if ~any(isnan(magLimits)) && ~any(isnan(phaseLimits))
                            switch limitsWidget.SelectedGroupIdx
                                case 1
                                    % Common group selected and all limits are equal
                                    this.YLimitsSharing = "all";
                                    this.YLimits = {magLimits;phaseLimits};
                                otherwise
                                    % Set for individual group
                                    this.YLimitsSharing = "row";
                                    outputIdx = limitsWidget.SelectedGroupIdx-1;
                                    this.YLimits((outputIdx*2-1):outputIdx*2) = {magLimits;phaseLimits};
                            end
                            this.YLimitsWidget.Enable = true;
                            updateYLimitsWidget(this);
                        else
                            this.YLimitsWidget.Enable = true;
                        end
                    elseif this.MagnitudeVisible
                        if ~any(isnan(magLimits))
                            switch limitsWidget.SelectedGroupIdx
                                case 1
                                    % Common group selected and all limits are equal
                                    this.YLimitsSharing = "all";
                                    this.YLimits = magLimits;
                                otherwise
                                    % Set for individual group
                                    this.YLimitsSharing = "row";
                                    outputIdx = limitsWidget.SelectedGroupIdx-1;
                                    this.YLimits{outputIdx} = magLimits;
                            end
                            this.YLimitsWidget.Enable = true;
                            updateYLimitsWidget(this);
                        else
                            this.YLimitsWidget.Enable = true;
                        end
                    elseif this.PhaseVisible
                        if ~any(isnan(phaseLimits))
                            switch limitsWidget.SelectedGroupIdx
                                case 1
                                    % Common group selected and all limits are equal
                                    this.YLimitsSharing = "all";
                                    this.YLimits = phaseLimits;
                                otherwise
                                    % Set for individual group
                                    this.YLimitsSharing = "row";
                                    outputIdx = limitsWidget.SelectedGroupIdx-1;
                                    this.YLimits{outputIdx} = phaseLimits;
                            end
                            this.YLimitsWidget.Enable = true;
                            updateYLimitsWidget(this);
                        else
                            this.YLimitsWidget.Enable = true;
                        end
                    end
            end
            enableListeners(this,'YLimitsChangedInPropertyEditor');
        end


        function updateYLimitsWidget(this)
            if ~isempty(this.YLimitsWidget) && isvalid(this.YLimitsWidget) && this.YLimitsWidget.Enable
                names = getGroupNamesForYLimitsWidget(this);
                this.YLimitsWidget.NGroups = length(names);
                this.YLimitsWidget.GroupItems = names;
                if ~ismember(this.YLimitsWidget.SelectedGroup,names)
                    if length(names) > 1
                        this.YLimitsWidget.SelectedGroup = names(2);
                    else
                        this.YLimitsWidget.SelectedGroup = names(1);
                    end
                end
                switch this.RowColumnGrouping
                    case {"all","columns"}
                        if this.MagnitudeVisible && this.PhaseVisible
                            setLimits(this.YLimitsWidget,this.YLimits_I{1},1,1);
                            setLimits(this.YLimitsWidget,this.YLimits_I{2},1,2);
                            isAuto = strcmp(this.YLimitsMode_I{1},"auto") && strcmp(this.YLimitsMode_I{2},"auto");
                            setAutoScale(this.YLimitsWidget,isAuto);
                        elseif this.MagnitudeVisible
                            setLimits(this.YLimitsWidget,this.YLimits_I{1},1,1);
                            setLimits(this.YLimitsWidget,[NaN NaN],1,2);
                            setAutoScale(this.YLimitsWidget,strcmp(this.YLimitsMode{1},"auto"));
                        elseif this.PhaseVisible
                            setLimits(this.YLimitsWidget,[NaN NaN],1,1);
                            setLimits(this.YLimitsWidget,this.YLimits_I{1},1,2);
                            setAutoScale(this.YLimitsWidget,strcmp(this.YLimitsMode{1},"auto"));
                        else
                            setLimits(this.YLimitsWidget,[NaN NaN],1,1);
                            setLimits(this.YLimitsWidget,[NaN NaN],1,2);
                            setAutoScale(this.YLimitsWidget,false);
                        end
                    otherwise
                        if any(this.RowVisible) && any(this.ColumnVisible)
                            switch this.YLimitsSharing
                                case "all"
                                    if this.MagnitudeVisible && this.PhaseVisible
                                        setLimits(this.YLimitsWidget,this.YLimits_I{1},1,1);
                                        setLimits(this.YLimitsWidget,this.YLimits_I{2},1,2);
                                        isAuto = strcmp(this.YLimitsMode_I{1},"auto") && strcmp(this.YLimitsMode_I{2},"auto");
                                        setAutoScale(this.YLimitsWidget,isAuto);
                                        for ii = 2:this.YLimitsWidget.NGroups
                                            setLimits(this.YLimitsWidget,this.YLimits_I{1},ii,1);
                                            setLimits(this.YLimitsWidget,this.YLimits_I{2},ii,2);
                                            setAutoScale(this.YLimitsWidget,false,ii);
                                        end
                                    elseif this.MagnitudeVisible
                                        setLimits(this.YLimitsWidget,this.YLimits_I{1},1,1);
                                        setLimits(this.YLimitsWidget,[NaN NaN],1,2);
                                        isAuto = strcmp(this.YLimitsMode_I{1},"auto");
                                        setAutoScale(this.YLimitsWidget,isAuto);
                                        for ii = 2:this.YLimitsWidget.NGroups
                                            setLimits(this.YLimitsWidget,this.YLimits_I{1},ii,1);
                                            setLimits(this.YLimitsWidget,[NaN NaN],ii,2);
                                            setAutoScale(this.YLimitsWidget,false,ii);
                                        end
                                    elseif this.PhaseVisible
                                        setLimits(this.YLimitsWidget,[NaN NaN],1,1);
                                        setLimits(this.YLimitsWidget,this.YLimits_I{1},1,2);
                                        isAuto = strcmp(this.YLimitsMode_I{1},"auto");
                                        setAutoScale(this.YLimitsWidget,isAuto);
                                        for ii = 2:this.YLimitsWidget.NGroups
                                            setLimits(this.YLimitsWidget,[NaN NaN],ii,1);
                                            setLimits(this.YLimitsWidget,this.YLimits_I{1},ii,2);
                                            setAutoScale(this.YLimitsWidget,false,ii);
                                        end
                                    else
                                        for ii = 1:this.YLimitsWidget.NGroups
                                            setLimits(this.YLimitsWidget,[NaN NaN],ii,1);
                                            setLimits(this.YLimitsWidget,[NaN NaN],ii,2);
                                            setAutoScale(this.YLimitsWidget,false,ii);
                                        end
                                    end
                                case "row"
                                    if this.YLimitsWidget.NGroups == 1
                                        if this.MagnitudeVisible && this.PhaseVisible
                                            setLimits(this.YLimitsWidget,this.YLimits_I{1},1,1);
                                            setLimits(this.YLimitsWidget,this.YLimits_I{2},1,2);
                                            isAuto = strcmp(this.YLimitsMode_I{1},"auto") && strcmp(this.YLimitsMode_I{2},"auto");
                                            setAutoScale(this.YLimitsWidget,isAuto);
                                        elseif this.MagnitudeVisible
                                            setLimits(this.YLimitsWidget,this.YLimits_I{1},1,1);
                                            setLimits(this.YLimitsWidget,[NaN NaN],1,2);
                                            isAuto = strcmp(this.YLimitsMode_I{1},"auto");
                                            setAutoScale(this.YLimitsWidget,isAuto);
                                        elseif this.PhaseVisible
                                            setLimits(this.YLimitsWidget,[NaN NaN],1,1);
                                            setLimits(this.YLimitsWidget,this.YLimits_I{1},1,2);
                                            isAuto = strcmp(this.YLimitsMode_I{1},"auto");
                                            setAutoScale(this.YLimitsWidget,isAuto);
                                        else
                                            setLimits(this.YLimitsWidget,[NaN NaN],1,1);
                                            setLimits(this.YLimitsWidget,[NaN NaN],1,2);
                                            setAutoScale(this.YLimitsWidget,false);
                                        end
                                    else
                                        setLimits(this.YLimitsWidget,[NaN NaN],1,1);
                                        setLimits(this.YLimitsWidget,[NaN NaN],1,2);
                                        setAutoScale(this.YLimitsWidget,false,1);
                                        for ii = 2:this.YLimitsWidget.NGroups
                                            if this.MagnitudeVisible && this.PhaseVisible
                                                outputIdx = ii-1;
                                                setLimits(this.YLimitsWidget,this.YLimits_I{outputIdx*2-1},ii,1);
                                                setLimits(this.YLimitsWidget,this.YLimits_I{outputIdx*2},ii,2);
                                                isAuto = strcmp(this.YLimitsMode_I{outputIdx*2-1},"auto") && strcmp(this.YLimitsMode_I{outputIdx*2},"auto");
                                                setAutoScale(this.YLimitsWidget,isAuto,ii);
                                            elseif this.MagnitudeVisible
                                                setLimits(this.YLimitsWidget,this.YLimits_I{ii-1},ii,1);
                                                setLimits(this.YLimitsWidget,[NaN NaN],ii,2);
                                                isAuto = strcmp(this.YLimitsMode_I{ii-1},"auto");
                                                setAutoScale(this.YLimitsWidget,isAuto,ii);
                                            elseif this.PhaseVisible
                                                setLimits(this.YLimitsWidget,[NaN NaN],ii,1);
                                                setLimits(this.YLimitsWidget,this.YLimits_I{ii-1},ii,2);
                                                isAuto = strcmp(this.YLimitsMode_I{ii-1},"auto");
                                                setAutoScale(this.YLimitsWidget,isAuto,ii);
                                            else
                                                setLimits(this.YLimitsWidget,[NaN NaN],ii,1);
                                                setLimits(this.YLimitsWidget,[NaN NaN],ii,2);
                                                setAutoScale(this.YLimitsWidget,false,ii);
                                            end
                                        end
                                    end
                                case "none"
                                    for ii = 1:this.YLimitsWidget.NGroups
                                        setLimits(this.YLimitsWidget,[NaN NaN],ii,1);
                                        setLimits(this.YLimitsWidget,[NaN NaN],ii,2);
                                        setAutoScale(this.YLimitsWidget,false,ii);
                                    end
                            end
                        end
                end
            end
        end

        function str = getValidLabelString(this,str,label)
            switch label
                case "YLabel"
                    if ~this.MagnitudeVisible && ~this.PhaseVisible
                        str = this.YLabel.String;
                    elseif ~this.MagnitudeVisible
                        str = [this.YLabel.String(1);str];
                    elseif ~this.PhaseVisible
                        str = [str;this.YLabel.String(2)];
                    end
                otherwise
                    str = getValidLabelString@controllib.chart.internal.foundation.RowColumnPlot(this,str,label);
            end
        end

        function mustConvertToValidLabelString(this,str,label)
            switch label
                case "YLabel"
                    controllib.chart.internal.utils.validators.mustBeSize(str,[this.MagnitudeVisible+this.PhaseVisible 1]);
                otherwise
                    mustConvertToValidLabelString@controllib.chart.internal.foundation.RowColumnPlot(this,str,label);
            end
        end

        function buildUnitsWidget(this)
            % Create UnitsContainer
            this.UnitsWidget = controllib.widget.internal.cstprefs.UnitsContainer('FrequencyUnits',...
                'MagnitudeUnits','PhaseUnits','FrequencyScale','MagnitudeScale');
            % Remove 'auto' from frequency unit list
            this.UnitsWidget.ValidFrequencyUnits(1,:) = [];

            this.UnitsWidget.FrequencyUnits = this.FrequencyUnit;
            this.UnitsWidget.MagnitudeUnits = this.MagnitudeUnit;
            this.UnitsWidget.PhaseUnits = this.PhaseUnit;
            this.UnitsWidget.FrequencyScale = this.FrequencyScale;
            this.UnitsWidget.MagnitudeScale = this.MagnitudeScale;

            % Add listeners for widget to data
            L = [addlistener(this.UnitsWidget,'FrequencyUnits','PostSet',...
                @(es,ed) cbFrequencyUnitChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'FrequencyScale','PostSet',...
                @(es,ed) cbFrequencyScaleChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'MagnitudeUnits','PostSet',...
                @(es,ed) cbMagnitudeUnitChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'MagnitudeScale','PostSet',...
                @(es,ed) cbMagnitudeScaleChangedInPropertyEditor(this,ed)),...
                addlistener(this.UnitsWidget,'PhaseUnits','PostSet',...
                @(es,ed) cbPhaseUnitChangedInPropertyEditor(this,ed))];
            registerListeners(this,L,["FrequencyUnitChangedInPropertEditor",...
                "FrequencyScaleChangedInPropertyEditor","MagnitudeUnitChangedInPropertyEditor",...
                "MagnitudeScaleChangedInPropertyEditor","PhaseUnitChangedInPropertyEditor"]);

            % Local callback functions
            function cbFrequencyUnitChangedInPropertyEditor(this,ed)
                this.FrequencyUnit = ed.AffectedObject.FrequencyUnits;
            end

            function cbFrequencyScaleChangedInPropertyEditor(this,ed)
                this.FrequencyScale = ed.AffectedObject.FrequencyScale;
            end

            function cbMagnitudeUnitChangedInPropertyEditor(this,ed)
                this.MagnitudeUnit = ed.AffectedObject.MagnitudeUnits;
            end

            function cbMagnitudeScaleChangedInPropertyEditor(this,ed)
                this.MagnitudeScale = ed.AffectedObject.MagnitudeScale;
            end

            function cbPhaseUnitChangedInPropertyEditor(this,ed)
                this.PhaseUnit = ed.AffectedObject.PhaseUnits;
            end
        end

        function buildOptionsTab(this)
            % Build layout
            layout = uigridlayout(Parent=[],RowHeight={'fit','fit','fit'},ColumnWidth={'1x'},Padding=0);

            % Build widgets if needed
            buildMagnitudeResponseWidget(this);
            buildPhaseResponseWidget(this);
            buildConfidenceRegionWidget(this);

            w = getWidget(this.MagnitudeResponseWidget);
            w.Parent = layout;
            w.Layout.Row = 1;
            w.Layout.Column = 1;

            w = getWidget(this.PhaseResponseWidget);
            w.Parent = layout;
            w.Layout.Row = 2;
            w.Layout.Column = 1;

            w = getWidget(this.ConfidenceRegionWidget);
            w.Parent = layout;
            w.Layout.Row = 3;
            w.Layout.Column = 1;

            % Add layout/widget to tab
            addTab(this.PropertyEditorDialog,getString(message('Controllib:gui:strOptions')),layout);
        end

        function buildConfidenceRegionWidget(this)
            % Build Time Response widget
            this.ConfidenceRegionWidget = controllib.widget.internal.cstprefs.ConfidenceRegionContainer();

            this.ConfidenceRegionWidget.ConfidenceNumSD = this.NumberOfStandardDeviations;

            % Add listeners
            registerListeners(this,addlistener(this.ConfidenceRegionWidget,'ConfidenceNumSD','PostSet',...
                @(es,ed) cbConfidenceNumSDChangedInPropertyEditor(this,ed)),...
                'ConfidenceNumSDChangedInPropertyEditor');

            % Local callback functions
            function cbConfidenceNumSDChangedInPropertyEditor(this,ed)
                this.Characteristics.ConfidenceRegion.NumberOfStandardDeviations = ed.AffectedObject.ConfidenceNumSD;
            end
        end

        function buildMagnitudeResponseWidget(this)
            % Create MagnitudeResponseContainer
            this.MagnitudeResponseWidget = controllib.widget.internal.cstprefs.MagnitudeResponseContainer();

            updateMagnitudeResponseWidget(this);

            % Add listeners
            registerListeners(this,...
                addlistener(this.MagnitudeResponseWidget,'MinGainLimit','PostSet',...
                @(es,ed) set(this,'MinimumGainEnabled',ed.AffectedObject.MinGainLimit.Enable,...
                'MinimumGainValue',ed.AffectedObject.MinGainLimit.MinGain)),...
                'MinGainLimitChangedInPropertyEditor');
        end

        function updateMagnitudeResponseWidget(this)
            if ~isempty(this.MagnitudeResponseWidget) && isvalid(this.MagnitudeResponseWidget)
                % Set units
                this.MagnitudeResponseWidget.MagnitudeUnits = this.MagnitudeUnit;
                % Set minimum gain values
                this.MagnitudeResponseWidget.MinGainLimit.Enable = char(this.MinimumGainEnabled);
                this.MagnitudeResponseWidget.MinGainLimit.MinGain = this.MinimumGainValue;
            end
        end

        function buildPhaseResponseWidget(this)
            % Create PhaseResponseContainer
            this.PhaseResponseWidget = controllib.widget.internal.cstprefs.PhaseResponseContainer();
            
            updatePhaseResponseWidget(this);

            % Add listeners
            registerListeners(this,...
                addlistener(this.PhaseResponseWidget,'UnwrapPhase','PostSet',...
                @(es,ed) set(this,'PhaseWrappingEnabled',~strcmp(ed.AffectedObject.UnwrapPhase,'on'))),...
                'PhaseWrappingEnabledChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.PhaseResponseWidget,'PhaseWrappingBranch','PostSet',...
                @(es,ed) set(this,'PhaseWrappingBranch',ed.AffectedObject.PhaseWrappingBranch)),...
                'PhaseWrappingBranchChangedInPropertyEditor');
            registerListeners(this,...
                addlistener(this.PhaseResponseWidget,'ComparePhase','PostSet',...
                @(es,ed) set(this,'PhaseMatchingEnabled',ed.AffectedObject.ComparePhase.Enable,...
                'PhaseMatchingFrequency',ed.AffectedObject.ComparePhase.Freq,...
                'PhaseMatchingValue',ed.AffectedObject.ComparePhase.Phase)),...
                'ComparePhaseChangedInPropertyEditor');
        end

        function updatePhaseResponseWidget(this)
            if ~isempty(this.PhaseResponseWidget) && isvalid(this.PhaseResponseWidget)
                % Set units
                this.PhaseResponseWidget.PhaseUnits = this.PhaseUnit;
                this.PhaseResponseWidget.FrequencyUnits = this.FrequencyUnit;
                % Set phase wrapping values
                this.PhaseResponseWidget.UnwrapPhase = char(~this.PhaseWrappingEnabled);
                this.PhaseResponseWidget.PhaseWrappingBranch = this.PhaseWrappingBranch;
                % Set phase matching values
                this.PhaseResponseWidget.ComparePhase.Enable = char(this.PhaseMatchingEnabled);
                this.PhaseResponseWidget.ComparePhase.Freq = this.PhaseMatchingFrequency;
                this.PhaseResponseWidget.ComparePhase.Phase = this.PhaseMatchingValue;
            end
        end

        function names = getCustomPropertyGroupNames(this)
            names = ["FrequencyUnit","FrequencyScale",...
                "MagnitudeUnit","MagnitudeScale","PhaseUnit",...
                "MagnitudeVisible","PhaseVisible",...
                "PhaseWrappingEnabled","PhaseWrappingBranch","PhaseMatchingEnabled",...
                "PhaseMatchingFrequency","PhaseMatchingValue","MinimumGainEnabled",...
                "MinimumGainValue"];
         end
     end

     methods (Static, Access=protected)
         function n = getNumYLabels()
             n = 2;
         end
     end

     %% Static hidden methods
     methods (Static,Hidden)
         function options = createDefaultOptions()
             options = bodeoptions('cstprefs');
         end
     end

     methods (Hidden)
         function sz = getVisibleAxesSize(this)
             rowVisible = this.RowVisible;
             columnVisible = this.ColumnVisible;
             magVisible = this.MagnitudeVisible;
             phaseVisible = this.PhaseVisible;
             switch this.RowColumnGrouping
                 case "none"
                     sz = [nnz(rowVisible)*(magVisible+phaseVisible) nnz(columnVisible)];
                 case "columns"
                     sz = [nnz(rowVisible)*(magVisible+phaseVisible) 1];
                 case "rows"
                     sz = [1*(magVisible+phaseVisible) nnz(columnVisible)];
                 case "all"
                     sz = [1*(magVisible+phaseVisible) 1];
             end
         end

         function sz = getYLimitsSize(this)
            columnVisible = this.ColumnVisible;
            switch this.YLimitsSharing
                case "all"
                    sz = [this.MagnitudeVisible+this.PhaseVisible any(columnVisible)];
                case "row"
                    sz = getVisibleAxesSize(this);
                    sz = [sz(1) any(columnVisible)];
                case "none"
                    sz = getVisibleAxesSize(this);
            end
            sz = double(sz);
        end
     end
end
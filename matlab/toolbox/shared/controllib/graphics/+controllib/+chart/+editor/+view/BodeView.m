classdef BodeView < controllib.chart.editor.internal.EditorView
    % BodeEditor Wrapper

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent)
        FrequencyUnit
        MagnitudeScale
        MagnitudeUnit
        PhaseUnit

        MagnitudeVisible
        PhaseVisible

        MinimumGainEnabled
        MinimumGainValue
        PhaseMatchingEnabled
        PhaseMatchingFrequency
        PhaseMatchingValue
        PhaseWrappingBranch
        PhaseWrappingEnabled
    end
    
    properties (Dependent,SetAccess=private)
        Characteristics
    end

    %% Constructor
    methods
        function this = BodeView(chart)
            arguments
                chart (1,1) controllib.chart.editor.BodeEditor
            end
            this = this@controllib.chart.editor.internal.EditorView(chart);
        end
    end

    %% Get/Set
    methods
        % Characteristics
        function Characteristics = get.Characteristics(this)
            Characteristics = this.Chart.Characteristics;
        end

        % FrequencyUnit
        function FrequencyUnit = get.FrequencyUnit(this)
            FrequencyUnit = this.Chart.FrequencyUnit;
        end

        function set.FrequencyUnit(this,FrequencyUnit)
            try
                this.Chart.FrequencyUnit = FrequencyUnit;
            catch ME
                throw(ME);
            end
        end

        % MagnitudeScale
        function MagnitudeScale = get.MagnitudeScale(this)
            MagnitudeScale = this.Chart.MagnitudeScale;
        end

        function set.MagnitudeScale(this,MagnitudeScale)
            try
                this.Chart.MagnitudeScale = MagnitudeScale;
            catch ME
                throw(ME);
            end
        end

        % MagnitudeUnit
        function MagnitudeUnit = get.MagnitudeUnit(this)
            MagnitudeUnit = this.Chart.MagnitudeUnit;
        end

        function set.MagnitudeUnit(this,MagnitudeUnit)
            try
                this.Chart.MagnitudeUnit = MagnitudeUnit;
            catch ME
                throw(ME);
            end
        end

        % MagnitudeVisible
        function MagnitudeVisible = get.MagnitudeVisible(this)
            MagnitudeVisible = this.Chart.MagnitudeVisible;
        end

        function set.MagnitudeVisible(this,MagnitudeVisible)
            try
                this.Chart.MagnitudeVisible = MagnitudeVisible;
            catch ME
                throw(ME);
            end
        end

        % MinimumGainEnabled
        function MinimumGainEnabled = get.MinimumGainEnabled(this)
            MinimumGainEnabled = this.Chart.MinimumGainEnabled;
        end

        function set.MinimumGainEnabled(this,MinimumGainEnabled)
            try
                this.Chart.MinimumGainEnabled = MinimumGainEnabled;
            catch ME
                throw(ME);
            end
        end

        % MinimumGainValue
        function MinimumGainValue = get.MinimumGainValue(this)
            MinimumGainValue = this.Chart.MinimumGainValue;
        end

        function set.MinimumGainValue(this,MinimumGainValue)
            try
                this.Chart.MinimumGainValue = MinimumGainValue;
            catch ME
                throw(ME);
            end
        end

        % PhaseMatchingEnabled
        function PhaseMatchingEnabled = get.PhaseMatchingEnabled(this)
            PhaseMatchingEnabled = this.Chart.PhaseMatchingEnabled;
        end

        function set.PhaseMatchingEnabled(this,PhaseMatchingEnabled)
            try
                this.Chart.PhaseMatchingEnabled = PhaseMatchingEnabled;
            catch ME
                throw(ME);
            end
        end

        % PhaseMatchingFrequency
        function PhaseMatchingFrequency = get.PhaseMatchingFrequency(this)
            PhaseMatchingFrequency = this.Chart.PhaseMatchingFrequency;
        end

        function set.PhaseMatchingFrequency(this,PhaseMatchingFrequency)
            try
                this.Chart.PhaseMatchingFrequency = PhaseMatchingFrequency;
            catch ME
                throw(ME);
            end
        end

        % PhaseMatchingValue
        function PhaseMatchingValue = get.PhaseMatchingValue(this)
            PhaseMatchingValue = this.Chart.PhaseMatchingValue;
        end

        function set.PhaseMatchingValue(this,PhaseMatchingValue)
            try
                this.Chart.PhaseMatchingValue = PhaseMatchingValue;
            catch ME
                throw(ME);
            end
        end

        % PhaseUnit
        function PhaseUnit = get.PhaseUnit(this)
            PhaseUnit = this.Chart.PhaseUnit;
        end

        function set.PhaseUnit(this,PhaseUnit)
            try
                this.Chart.PhaseUnit = PhaseUnit;
            catch ME
                throw(ME);
            end
        end

        % PhaseVisible
        function PhaseVisible = get.PhaseVisible(this)
            PhaseVisible = this.Chart.PhaseVisible;
        end

        function set.PhaseVisible(this,PhaseVisible)
            try
                this.Chart.PhaseVisible = PhaseVisible;
            catch ME
                throw(ME);
            end
        end

        % PhaseWrappingBranch
        function PhaseWrappingBranch = get.PhaseWrappingBranch(this)
            PhaseWrappingBranch = this.Chart.PhaseWrappingBranch;
        end

        function set.PhaseWrappingBranch(this,PhaseWrappingBranch)
            try
                this.Chart.PhaseWrappingBranch = PhaseWrappingBranch;
            catch ME
                throw(ME);
            end
        end

        % PhaseWrappingEnabled
        function PhaseWrappingEnabled = get.PhaseWrappingEnabled(this)
            PhaseWrappingEnabled = this.Chart.PhaseWrappingEnabled;
        end

        function set.PhaseWrappingEnabled(this,PhaseWrappingEnabled)
            try
                this.Chart.PhaseWrappingEnabled = PhaseWrappingEnabled;
            catch ME
                throw(ME);
            end
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function props = getCopyableProperties()
            props = [controllib.chart.editor.internal.EditorView.getCopyableProperties();...
                "FrequencyUnit";"MagnitudeUnit";"MagnitudeScale";...
                "MagnitudeVisible";"MinimumGainEnabled";"MinimumGainValue";"PhaseMatchingEnabled";...
                "PhaseMatchingFrequency";"PhaseMatchingValue";"PhaseUnit";"PhaseVisible";...
                "PhaseWrappingBranch";"PhaseWrappingEnabled"];
        end
    end
end
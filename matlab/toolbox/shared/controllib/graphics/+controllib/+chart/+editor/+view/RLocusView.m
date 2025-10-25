classdef RLocusView < controllib.chart.editor.internal.EditorView
    % RLocusEditor Wrapper

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent)
        FrequencyUnit
        TimeUnit
    end

    %% Constructor
    methods
        function this = RLocusView(chart)
            arguments
                chart (1,1) controllib.chart.editor.RLocusEditor
            end
            this = this@controllib.chart.editor.internal.EditorView(chart);
        end
    end

    %% Get/Set
    methods
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

        % TimeUnit
        function TimeUnit = get.TimeUnit(this)
            TimeUnit = this.Chart.TimeUnit;
        end

        function set.TimeUnit(this,TimeUnit)
            try
                this.Chart.TimeUnit = TimeUnit;
            catch ME
                throw(ME);
            end
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function props = getCopyableProperties()
            props = [controllib.chart.editor.internal.EditorView.getCopyableProperties();...
                "FrequencyUnit";"TimeUnit"];
        end
    end
end
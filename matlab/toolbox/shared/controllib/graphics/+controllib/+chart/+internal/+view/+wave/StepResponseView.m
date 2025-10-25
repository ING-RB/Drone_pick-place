classdef StepResponseView < controllib.chart.internal.view.wave.TimeInputOutputResponseView
    % Object containing all response (line) and characteristics (markers,
    % lines) handles for a StepSystem
    %
    % response = controllib.chart.internal.view.wave.StepResponseView(StepSystem)

    %% Constructor
    methods
        function this = StepResponseView(response,varargin,optionalInputs)
            arguments
                response (1,1) controllib.chart.response.StepResponse
            end

            arguments (Repeating)
                varargin
            end

            arguments
                optionalInputs.ColumnVisible (1,:) logical = true(1,response.NColumns);
                optionalInputs.RowVisible (:,1) logical = true(response.NRows,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end

            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.TimeInputOutputResponseView(response,...
                optionalInputs{:},varargin{:});
            build(this);
        end
    end

    %% Protected Methods
    methods (Access = protected)
        function createCharacteristics(this,data)
            c = controllib.chart.internal.view.characteristic.BaseCharacteristicView.empty;
            % PeakResponse
            if isprop(data,"PeakResponse") && ~isempty(data.PeakResponse)
                c = controllib.chart.internal.view.characteristic.TimeInputOutputPeakResponseView(this,data.PeakResponse);
            end
            % RiseTime
            if isprop(data,"RiseTime") && ~isempty(data.RiseTime)
                c = [c; controllib.chart.internal.view.characteristic.TimeInputOutputRiseTimeView(this,data.RiseTime)];
            end
            % SettlingTime
            if isprop(data,"SettlingTime") && ~isempty(data.SettlingTime)
                c = [c; controllib.chart.internal.view.characteristic.TimeInputOutputSettlingTimeView(this,data.SettlingTime)];
            end
            % TransientTime
            if isprop(data,"TransientTime") && ~isempty(data.TransientTime)
                c = [c; controllib.chart.internal.view.characteristic.TimeInputOutputTransientTimeView(this,data.TransientTime)];
            end
            % SteadyState
            if isprop(data,"SteadyState") && ~isempty(data.SteadyState)
                c = [c; controllib.chart.internal.view.characteristic.TimeInputOutputSteadyStateView(this,data.SteadyState)];
            end
            % ConfidenceRegion
            if isprop(data,"ConfidenceRegion") && ~isempty(data.ConfidenceRegion)
                c = [c; controllib.chart.internal.view.characteristic.StepConfidenceRegionView(this,...
                        data.ConfidenceRegion)];
            end
            this.Characteristics = c;
        end

        function createResponseObjects(this)
            createResponseObjects@controllib.chart.internal.view.wave.TimeInputOutputResponseView(this);
            set(this.ResponseLines,Tag='StepResponseLine');
        end

        function createSupportingObjects(this)
            createSupportingObjects@controllib.chart.internal.view.wave.TimeInputOutputResponseView(this);
            set(this.SteadyStateYLines,Tag='StepSteadyStateLine');
        end

        function cbTimeUnitChanged(this,conversionFcn)
            cbTimeUnitChanged@controllib.chart.internal.view.wave.TimeInputOutputResponseView(this,conversionFcn);
            for k = 1:length(this.Characteristics)
                if isa(this.Characteristics(k),'controllib.chart.internal.foundation.MixInTimeUnit')
                    this.Characteristics(k).TimeUnit = this.TimeUnit;
                end
            end
        end
    end
end
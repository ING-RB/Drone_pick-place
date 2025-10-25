classdef ImpulseResponseView < controllib.chart.internal.view.wave.TimeInputOutputResponseView
    % Object containing all response (line) and characteristics (markers,
    % lines) handles for a StepSystem
    %
    % response = controllib.chart.internal.response.StepResponse(StepSystem)

    %% Constructor
    methods
        function this = ImpulseResponseView(response,varargin,optionalInputs)
           arguments
                response (1,1) controllib.chart.response.ImpulseResponse
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

            if isa(this.Response.Model,"idlti")
                this.DiscreteResponseLineType = "stem";
            end
            build(this);
        end
    end

    %% Protected Methods
    methods (Access = protected)
        function createSupportingObjects(this)
            createSupportingObjects@controllib.chart.internal.view.wave.TimeInputOutputResponseView(this);
            set(this.SteadyStateYLines,Tag='ImpulseSteadyStateLine');
        end

        function createCharacteristics(this,data)
            c = controllib.chart.internal.view.characteristic.BaseCharacteristicView.empty;
            % PeakResponse
            if isprop(data,"PeakResponse") && ~isempty(data.PeakResponse)
                c = controllib.chart.internal.view.characteristic.TimeInputOutputPeakResponseView(this,data.PeakResponse);
            end
            % TransientTime
            if isprop(data,"TransientTime") && ~isempty(data.TransientTime)
                c = [c; controllib.chart.internal.view.characteristic.TimeInputOutputTransientTimeView(this,data.TransientTime)];
            end
            % ConfidenceRegion
            if isprop(data,"ConfidenceRegion") && ~isempty(data.ConfidenceRegion)
                c = [c; controllib.chart.internal.view.characteristic.ImpulseConfidenceRegionView(this,...
                        data.ConfidenceRegion)];
            end
            this.Characteristics = c;
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
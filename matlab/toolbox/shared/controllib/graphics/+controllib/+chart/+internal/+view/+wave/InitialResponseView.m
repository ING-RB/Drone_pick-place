classdef InitialResponseView < controllib.chart.internal.view.wave.TimeOutputResponseView
    % Object containing all response (line) and characteristics (markers,
    % lines) handles for an InitialSystem
    %
    % response = controllib.chart.internal.view.wave.InitialResponseView(InitialSystem)

    %% Constructor
    methods
        function this = InitialResponseView(response,optionalInputs)
            arguments
                response (1,1) controllib.chart.response.InitialResponse
                optionalInputs.ShowSteadyStateLine (1,1) logical = true
                optionalInputs.ShowMagnitude (1,1) logical = false
                optionalInputs.ShowReal (1,1) logical = true
                optionalInputs.ShowImaginary (1,1) logical = true
                optionalInputs.OutputVisible (:,1) logical = true(response.NOutputs,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.TimeOutputResponseView(response,optionalInputs{:});
            build(this);
        end
    end

    %% Protected Methods
    methods (Access = protected)
        function cbTimeUnitChanged(this,conversionFcn)
            cbTimeUnitChanged@controllib.chart.internal.view.wave.TimeOutputResponseView(this,conversionFcn);
            this.Characteristics(1).TimeUnit = this.TimeUnit;
            this.Characteristics(2).TimeUnit = this.TimeUnit;
        end

        function createCharacteristics(this,data)
            c = controllib.chart.internal.view.characteristic.BaseCharacteristicView.empty;
            % PeakResponse
            if isprop(data,"PeakResponse") && ~isempty(data.PeakResponse)
                c = controllib.chart.internal.view.characteristic.TimeOutputPeakResponseView(this,data.PeakResponse);
            end
            % TransientTime
            if isprop(data,"TransientTime") && ~isempty(data.TransientTime)
                c = [c;controllib.chart.internal.view.characteristic.TimeOutputTransientTimeView(this,data.TransientTime)];
            end
            this.Characteristics = c;
        end

        function createResponseObjects(this)
            createResponseObjects@controllib.chart.internal.view.wave.TimeOutputResponseView(this);
            set(this.ResponseLines,Tag='InitialResponseLine');
        end

        function createSupportingObjects(this)
            createSupportingObjects@controllib.chart.internal.view.wave.TimeOutputResponseView(this);
            set(this.SteadyStateYLines,Tag='InitialSteadyStateLine');
        end
    end
end
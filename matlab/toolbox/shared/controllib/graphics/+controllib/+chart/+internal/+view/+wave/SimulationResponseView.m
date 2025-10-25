classdef SimulationResponseView < controllib.chart.internal.view.wave.TimeOutputResponseView
    % Object containing all response (line) and characteristics (markers,
    % lines) handles for an LinearSimulationResponse
    %
    % responseView = controllib.chart.internal.view.wave.SimulationResponseView(LinearSimulationResponse)
    
    % Copyright 2023 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = {?controllib.chart.internal.view.wave.BaseResponseView,...
            ?controllib.chart.internal.view.axes.BaseAxesView})
        ShowInput = true
    end

    properties (SetAccess = protected)
        InputYLines
        ImaginaryInputYLines
    end

    properties (SetAccess = {?controllib.chart.internal.view.wave.BaseResponseView,...
            ?controllib.chart.internal.view.axes.BaseAxesView})
        NInputs
        InputNames
    end

    %% Constructor
    methods
        function this = SimulationResponseView(response,simulationOptionalInputs,optionalInputs)
            arguments
                response (1,1) controllib.chart.response.LinearSimulationResponse
                simulationOptionalInputs.ShowInput (1,1) logical = true
                optionalInputs.ShowSteadyStateLine (1,1) logical = true
                optionalInputs.ShowMagnitude (1,1) logical = false
                optionalInputs.ShowReal (1,1) logical = true
                optionalInputs.ShowImaginary (1,1) logical = true
                optionalInputs.OutputVisible (:,1) logical = true(response.NOutputs,1);
                optionalInputs.ArrayVisible logical = response.ArrayVisible
            end
            optionalInputs = namedargs2cell(optionalInputs);
            this@controllib.chart.internal.view.wave.TimeOutputResponseView(response,optionalInputs{:},ShowSteadyStateLine=false);
            this.NInputs = response.NInputs;
            this.InputNames = response.InputNames;
            build(this);
            this.ShowInput = simulationOptionalInputs.ShowInput;    
        end
    end

    %% Get/Set
    methods
        % ShowInput
        function set.ShowInput(this,ShowInput)
            this.ShowInput = ShowInput;
            updateInputVisibility(this);
        end
    end

    %% Protected Methods
    methods (Access = protected)
        function createCharacteristics(this,data)
            c = controllib.chart.internal.view.characteristic.BaseCharacteristicView.empty;
            % PeakResponse
            if isprop(data,"PeakResponse") && ~isempty(data.PeakResponse)
                 c = controllib.chart.internal.view.characteristic.TimeOutputPeakResponseView(this,data.PeakResponse);
            end
            this.Characteristics = c;
        end

        function createResponseObjects(this)
            createResponseObjects@controllib.chart.internal.view.wave.TimeOutputResponseView(this);
            set(this.ResponseLines,'Tag','SimulationResponseLine');
        end

        function createSupportingObjects(this)
            this.InputYLines = createGraphicsObjects(this,"line",this.Response.NOutputs,this.NInputs,...
                this.Response.NResponses,Tag='SimulationInputLine');
            this.ImaginaryInputYLines = createGraphicsObjects(this,"line",this.Response.NOutputs,this.NInputs,...
                this.Response.NResponses,Tag='SimulationImaginaryInputLine');
            % Set style on input lines
            LineStyles = {'-';'--';':';'-.'};
            for ki = 1:this.NInputs
                set(this.InputYLines(:,ki,:),LineStyle=LineStyles{rem(ki-1,4)+1});
                set(this.ImaginaryInputYLines(:,ki,:),LineStyle=LineStyles{rem(ki-1,4)+1});
            end
            controllib.plot.internal.utils.setColorProperty([this.InputYLines(:); this.ImaginaryInputYLines(:)],...
                "Color","--mw-graphics-colorNeutral-line-primary");
        end

        function supportingLines = getSupportingObjects_(this,ko,~,ka)
            supportingLines = permute(this.InputYLines(ko,:,ka),[1 3 2]);
        end

        function createResponseDataTips_(this,ko,ka,nameDataTipRow,outputDataTipRow,customDataTipRows)
            createResponseDataTips_@controllib.chart.internal.view.wave.TimeOutputResponseView(this,ko,ka,nameDataTipRow,outputDataTipRow,customDataTipRows)
            % Time row
            timeDataTipRow = dataTipTextRow(...
                [getString(message('Controllib:plots:strTime')),' (',char(this.TimeUnitLabel),')'],...
                'XData','%0.3g');

            % Amplitude row
            amplitudeDataTipRow = dataTipTextRow(...
                getString(message('Controllib:plots:strAmplitude')),'YData','%0.3g');

            % Create data tip for input lines
            for ko = 1:this.Response.NOutputs
                for ki = 1:this.NInputs
                    for ka = 1:this.Response.NResponses
                        % Input row
                        inputRow = dataTipTextRow(getString(message('Controllib:plots:strInput')),@(x) string(this.InputNames(ki)));

                        % System name
                        nameRow = dataTipTextRow(getString(message('Controllib:plots:strInputResponse')),@(x) this.Response.Name);

                        % Add to DataTipTemplate
                        this.InputYLines(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                            [inputRow; nameRow; timeDataTipRow; amplitudeDataTipRow];
                    end
                end
            end
        end

        function updateOutputDataTipRow(this)
            updateOutputDataTipRow@controllib.chart.internal.view.wave.TimeOutputResponseView(this);
            for ko = 1:this.Response.NOutputs
                for ki = 1:this.NInputs
                    inputRow = dataTipTextRow(getString(message('Controllib:plots:strInput')),@(x) string(this.InputNames(ki)));
                    for ka = 1:this.Response.NResponses
                        idx = find(contains({this.InputYLines(ko,ki,ka).DataTipTemplate.DataTipRows.Label},...
                            getString(message('Controllib:plots:strInput'))),1);
                        this.InputYLines(ko,ki,ka).DataTipTemplate.DataTipRows(idx) = inputRow;
                    end
                end
            end
        end

        function updateResponseData(this)
            updateResponseData@controllib.chart.internal.view.wave.TimeOutputResponseView(this);
            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            for ko = 1:this.Response.NOutputs
                for ki = 1:this.NInputs
                    for ka = 1:this.Response.NResponses
                        % Only populate if input signal is defined
                        if size(this.Response.SourceData.InputSignal,2) == this.NInputs && ~all(isnan(this.ResponseLines(ko,1,ka).YData))
                            time = getTime(this.Response.ResponseData,{ko,1},ka);
                            this.InputYLines(ko,ki,ka).XData = conversionFcn(time);
                            this.InputYLines(ko,ki,ka).YData = this.Response.ResponseData.InputSignal(:,ki);
                        else
                            this.InputYLines(ko,ki,ka).XData = NaN;
                            this.InputYLines(ko,ki,ka).YData = NaN;
                        end
                    end
                end
            end
        end

        function updateResponseStyle_(this,style,ko,ki,ka)
            if ko <= this.Response.NOutputs && ki <= this.NInputs
                this.InputYLines(ko,ki,ka).LineWidth = style.LineWidth;
            end
        end

        function updateInputVisibility(this)
            for ko = 1:this.Response.NOutputs
                for ka = 1:this.Response.NResponses
                    visibilityFlag = this.ResponseLines(ko,1,ka).Visible && this.ShowInput;
                    set(this.InputYLines(ko,:,ka),Visible=visibilityFlag);
                end
            end
        end

        function updateResponseVisibility(this,outputVisible,~,arrayVisible)
            updateResponseVisibility@controllib.chart.internal.view.wave.TimeOutputResponseView(this,outputVisible,[],arrayVisible);
            updateInputVisibility(this);
        end
        
        function cbTimeUnitChanged(this,conversionFcn)
            cbTimeUnitChanged@controllib.chart.internal.view.wave.TimeOutputResponseView(this,conversionFcn);
            for k = 1:length(this.Characteristics)
                if isa(this.Characteristics(k),'controllib.chart.internal.foundation.MixInTimeUnit')
                    this.Characteristics(k).TimeUnit = this.TimeUnit;
                end
            end
            for ka = 1:this.Response.NResponses
                for ko = 1:this.Response.NOutputs
                    for ki = 1:this.NInputs
                        this.InputYLines(ko,ki,ka).XData = conversionFcn(this.InputYLines(ko,ki,ka).XData);
                        if this.IsResponseDataTipsCreated
                            this.replaceDataTipRowLabel(this.InputYLines(ko,ki,ka),...
                                getString(message('Controllib:plots:strTime')),...
                                getString(message('Controllib:plots:strTime')) + ...
                                " (" + this.TimeUnitLabel + ")");
                        end
                    end
                end
            end
        end
    end
end
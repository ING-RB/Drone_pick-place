classdef TimeMagnitudeInputOutputSteadyStateView < controllib.chart.internal.view.characteristic.InputOutputCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        SteadyStateMagnitudeMarkers
        SteadyStatePhaseMarkers
    end
    
    %% Constructor
    methods
        function this = TimeMagnitudeInputOutputSteadyStateView(responseView,data)
            this@controllib.chart.internal.view.characteristic.InputOutputCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.SteadyStateMagnitudeMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='TimeMagnitudeSteadyStateScatter');
            this.SteadyStatePhaseMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='TimePhaseSteadyStateScatter');
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.SteadyState;
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);

            m = this.SteadyStateMagnitudeMarkers(ko,ki,ka);

            m.XData = 1e20;
            m.YData = responseLine.YData(end);
            m.UserData.ValueOutsideLimits = isinf(real(data.Value{ka}(ko,ki)));

            m = this.SteadyStatePhaseMarkers(ko,ki,ka);
            m.XData = 1e20;
            m.YData = this.ResponseView.PhaseResponseLines(ko,ki,ka).YData(end);
            m.UserData.ValueOutsideLimits = isinf(real(data.Value{ka}(ko,ki)));
        end

        function updateDataByLimits(this,ko,ki,ka)
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);
            ax = responseLine.Parent;
            
            if ~isempty(ax)
                m = this.SteadyStateMagnitudeMarkers(ko,ki,ka);

                x = ax.XLim(2);
                [~,idx] = min(abs(responseLine.XData - x));
                m.XData = x;
                m.YData = responseLine.YData(idx);

                m = this.SteadyStatePhaseMarkers(ko,ki,ka);
                m.XData = x;
                m.YData = this.ResponseView.PhaseResponseLines(ko,ki,ka).YData(idx);
            end
        end

        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.SteadyState;

            valueRow = dataTipTextRow(getString(message('Controllib:plots:strFinalValue')),data.Value{ka}(ko,ki),'%0.3g');
            this.SteadyStateMagnitudeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; valueRow; customDataTipRows(:)];
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = this.SteadyStateMagnitudeMarkers(ko,ki,ka);
        end
    end
end
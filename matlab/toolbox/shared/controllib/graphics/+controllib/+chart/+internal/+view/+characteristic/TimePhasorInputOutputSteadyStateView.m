classdef TimePhasorInputOutputSteadyStateView < controllib.chart.internal.view.characteristic.InputOutputCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        SteadyStateMarkers
    end
    
    %% Constructor
    methods
        function this = TimePhasorInputOutputSteadyStateView(responseView,data)
            this@controllib.chart.internal.view.characteristic.InputOutputCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.SteadyStateMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='TimeSteadyStateScatter');
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.SteadyState;

            m = this.SteadyStateMarkers(ko,ki,ka);
            realValue = real(data.Value{ka}(ko,ki));
            imaginaryValue = imag(data.Value{ka}(ko,ki));

            m.XData = realValue;
            m.YData = imaginaryValue;
            m.UserData.ValueOutsideLimits = isinf(data.Value{ka}(ko,ki));
        end

        % function updateDataByLimits(this,ko,ki,ka)
        %     responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
        %     responseLine = responseObjects{1}(this.ResponseLineIdx);
        %     ax = responseLine.Parent;
        % 
        %     m = this.SteadyStateMarkers(ko,ki,ka);
        % 
        %     x = ax.XLim(2);
        %     [~,idx] = min(abs(responseLine.XData - x));
        %     m.XData = x;
        %     m.YData = responseLine.YData(idx);
        % 
        %     if ~this.Response.IsReal(ka)
        %         mIm = this.ImaginarySteadyStateMarkers(ko,ki,ka);
        %         imaginaryResponseLine = responseObjects{1}(2*this.ResponseLineIdx);
        %         [~,idx] = min(abs(imaginaryResponseLine.XData - x));
        %         mIm.XData = x;
        %         mIm.YData = imaginaryResponseLine.YData(idx);
        %     end
        % end

        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.SteadyState;

            valueRow = dataTipTextRow(getString(message('Controllib:plots:strFinalValue')),data.Value{ka}(ko,ki),'%0.3g');
            this.SteadyStateMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; valueRow; customDataTipRows(:)];
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = this.SteadyStateMarkers(ko,ki,ka);
        end
    end
end
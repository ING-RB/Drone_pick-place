classdef TimeInputOutputSteadyStateView < controllib.chart.internal.view.characteristic.InputOutputCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        RealSteadyStateMarkers
        ImaginarySteadyStateMarkers
    end
    
    %% Constructor
    methods
        function this = TimeInputOutputSteadyStateView(responseView,data)
            this@controllib.chart.internal.view.characteristic.InputOutputCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.RealSteadyStateMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='TimeSteadyStateScatter');
            if any(~this.Response.IsReal)
                this.ImaginarySteadyStateMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                    this.Response.NColumns,this.Response.NResponses,Tag='ImaginaryTimeSteadyStateScatter');
            end
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.SteadyState;
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);

            m = this.RealSteadyStateMarkers(ko,ki,ka);

            m.XData = 1e20;
            m.YData = responseLine.YData(end);
            m.UserData.ValueOutsideLimits = isinf(real(data.Value{ka}(ko,ki)));

            if ~this.Response.IsReal(ka)
                mIm = this.ImaginarySteadyStateMarkers(ko,ki,ka);
                imaginaryResponseLine = responseObjects{1}(2*this.ResponseLineIdx);
                mIm.XData = 1e20;
                mIm.YData = imaginaryResponseLine.YData(end);
                mIm.UserData.ValueOutsideLimits = isinf(imag(data.Value{ka}(ko,ki)));
            end
        end

        function updateDataByLimits(this,ko,ki,ka)
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);
            ax = responseLine.Parent;

            if ~isempty(ax)
                m = this.RealSteadyStateMarkers(ko,ki,ka);

                x = ax.XLim(2);
                [~,idx] = min(abs(responseLine.XData - x));
                m.XData = x;
                m.YData = responseLine.YData(idx);

                if ~this.Response.IsReal(ka)
                    mIm = this.ImaginarySteadyStateMarkers(ko,ki,ka);
                    imaginaryResponseLine = responseObjects{1}(2*this.ResponseLineIdx);
                    [~,idx] = min(abs(imaginaryResponseLine.XData - x));
                    mIm.XData = x;
                    mIm.YData = imaginaryResponseLine.YData(idx);
                end
            end
        end

        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.SteadyState;

            valueRow = dataTipTextRow(getString(message('Controllib:plots:strFinalValue')),...
                real(data.Value{ka}(ko,ki)),'%0.3g');
            this.RealSteadyStateMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; valueRow; customDataTipRows(:)];

            if ~this.Response.IsReal(ka)
                valueRow = dataTipTextRow(getString(message('Controllib:plots:strFinalValue')),...
                    imag(data.Value{ka}(ko,ki)),'%0.3g');
                this.ImaginarySteadyStateMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                    [nameDataTipRow; ioDataTipRow; valueRow; customDataTipRows(:)];
            end
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = this.RealSteadyStateMarkers(ko,ki,ka);
            if ~this.Response.IsReal(ka)
                c = cat(3,c,this.ImaginarySteadyStateMarkers(ko,ki,ka));
            end
        end
    end
end
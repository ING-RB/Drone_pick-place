classdef TimeInputOutputTransientTimeView < controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        RealTransientTimeMarkers
        TransientTimeUpperYLines
        TransientTimeLowerYLines
        TransientTimeXLines
        ImaginaryTransientTimeMarkers
    end

    %% Constructor
    methods
        function this = TimeInputOutputTransientTimeView(response,data)
            this@controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView(response,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.RealTransientTimeMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='TimeTransientTimeScatter');
            this.TransientTimeXLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeTransientTimeXLine');
            set(this.TransientTimeXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.TransientTimeXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.TransientTimeUpperYLines = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeTransientTimeYLineHigh');
            set(this.TransientTimeUpperYLines,LineStyle='-.',InterceptAxis='y')
            controllib.plot.internal.utils.setColorProperty(...
                this.TransientTimeUpperYLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.TransientTimeLowerYLines = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeTransientTimeYLineLow');
            set(this.TransientTimeLowerYLines,LineStyle='-.',InterceptAxis='y')
            controllib.plot.internal.utils.setColorProperty(...
                this.TransientTimeLowerYLines,"Color","--mw-graphics-colorNeutral-line-primary");

            if any(~this.Response.IsReal)
                this.ImaginaryTransientTimeMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                    this.Response.NColumns,this.Response.NResponses,Tag='ImaginaryTimeTransientTimeScatter');
            end
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.TransientTime;

            m = this.RealTransientTimeMarkers(ko,ki,ka);
            xl = this.TransientTimeXLines(ko,ki,ka);
            yl1 = this.TransientTimeUpperYLines(ko,ki,ka);
            yl2 = this.TransientTimeLowerYLines(ko,ki,ka);

            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            transientTime = conversionFcn(data.Time{ka}(ko,ki));
            realValue = real(data.Value{ka}(ko,ki));

            % Marker
            m.XData(end) = transientTime;
            m.YData(end) = realValue;
            % XLines
            xl.XData = [transientTime, transientTime];
            xl.YData = [-1e20, realValue];

            if this.Response.IsReal(ka)
                % Upper and lower y lines
                yl1.Value = data.UpperValue{ka}(ko,ki);
                yl2.Value = data.LowerValue{ka}(ko,ki);
            else
                yl1.Value = NaN;
                yl2.Value = NaN;

                imaginaryValue = imag(data.Value{ka}(ko,ki));
                mIm = this.ImaginaryTransientTimeMarkers(ko,ki,ka);
                mIm.XData(end) = transientTime;
                mIm.YData(end) = imaginaryValue;
                
                xl.YData = [-1e20, max(realValue,imaginaryValue)];
            end
        end

        function updateDataByLimits(this,ko,ki,ka)
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);
            ax = responseLine.Parent;

            if ~isempty(ax)
                m = this.RealTransientTimeMarkers(ko,ki,ka);
                xl = this.TransientTimeXLines(ko,ki,ka);

                peakTime = xl.XData(1);
                xLim = ax.XLim;
                yLim = ax.YLim;
                m.UserData.ValueLessThanLimits = peakTime < xLim(1);
                m.UserData.ValueGreaterThanLimits = peakTime > xLim(2);
                if m.UserData.ValueLessThanLimits || m.UserData.ValueGreaterThanLimits
                    if m.UserData.ValueLessThanLimits
                        % Value is less than lower x-limit of axes
                        x = xLim(1);
                        xData = responseLine.XData;
                        yData = responseLine.YData;
                        idx = find(xData >= xLim(1),1,'first');
                        if idx > 1
                            y = interp1(xData(idx-1:idx),yData(idx-1:idx),x);
                        else
                            y = yData(1);
                        end
                    else
                        % Value is greater than higher x-limit of axes
                        x = xLim(2);
                        xData = responseLine.XData;
                        yData = responseLine.YData;
                        idx = find(xData <= xLim(2),1,'last');
                        if idx < length(yData)
                            y = interp1(xData(idx:idx+1),yData(idx:idx+1),x);
                        else
                            y = yData(end);
                        end
                    end
                    m.XData = x;
                    m.YData = y;
                    xl.YData(1) = yLim(1);
                else
                    % Value is within x-limits
                    updateData(this,ko,ki,ka);
                end

            end
        end

        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.TransientTime;
            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            valueRow = dataTipTextRow(getString(message('Controllib:plots:strTransientTime')) + " (" + ...
                this.TimeUnitLabel + ")",conversionFcn(data.Time{ka}(ko,ki)),'%0.3g');
            this.RealTransientTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; valueRow; customDataTipRows(:)];
            this.ImaginaryTransientTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; valueRow; customDataTipRows(:)];
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.RealTransientTimeMarkers(ko,ki,ka).XData = conversionFcn(this.RealTransientTimeMarkers(ko,ki,ka).XData);
                            this.TransientTimeXLines(ko,ki,ka).XData = conversionFcn(this.TransientTimeXLines(ko,ki,ka).XData);

                            rowNum = this.replaceDataTipRowLabel(this.RealTransientTimeMarkers(ko,ki,ka),getString(message('Controllib:plots:strTransientTime')),...
                                getString(message('Controllib:plots:strTransientTime')) + " (" + this.TimeUnitLabel + ")");
                            this.RealTransientTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value = ...
                                conversionFcn(this.RealTransientTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value);
                        end
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = this.RealTransientTimeMarkers(ko,ki,ka);
            if ~this.Response.IsReal(ka)
                c = cat(3,c,this.ImaginaryTransientTimeMarkers(ko,ki,ka));
            end
        end

        function l = getSupportingObjects_(this,ko,ki,ka)
            l = cat(3,this.TransientTimeUpperYLines(ko,ki,ka),...
                this.TransientTimeLowerYLines(ko,ki,ka),...
                this.TransientTimeXLines(ko,ki,ka));
        end
    end
end
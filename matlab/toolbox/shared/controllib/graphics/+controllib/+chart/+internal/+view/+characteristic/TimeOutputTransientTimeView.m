classdef TimeOutputTransientTimeView < controllib.chart.internal.view.characteristic.TimeOutputCharacteristicView
    % this = controllib.chart.internal.response.PeakResponseCharacteristic(data)
    %
    % Copyright 2021 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        TransientTimeUpperYLines
        TransientTimeLowerYLines
        TransientTimeXLines
        RealTransientTimeMarkers
        ImaginaryTransientTimeMarkers
    end

    %% Constructor
    methods
        function this = TimeOutputTransientTimeView(response,data)
            this@controllib.chart.internal.view.characteristic.TimeOutputCharacteristicView(response,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)
            this.RealTransientTimeMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                1,this.Response.NResponses,Tag='TimeTransientTimeScatter');
            this.TransientTimeXLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                1,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeTransientTimeXLine');
            set(this.TransientTimeXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.TransientTimeXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.TransientTimeUpperYLines = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                1,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeTransientTimeYLineHigh');
            set(this.TransientTimeUpperYLines,LineStyle='-.',InterceptAxis='y')
            controllib.plot.internal.utils.setColorProperty(...
                this.TransientTimeUpperYLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.TransientTimeLowerYLines = createGraphicsObjects(this,"constantLine",this.Response.NRows,...
                1,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeTransientTimeYLineLow');
            set(this.TransientTimeLowerYLines,LineStyle='-.',InterceptAxis='y')
            controllib.plot.internal.utils.setColorProperty(...
                this.TransientTimeLowerYLines,"Color","--mw-graphics-colorNeutral-line-primary");

            if any(~this.Response.IsReal)
                this.ImaginaryTransientTimeMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                    1,this.Response.NResponses,Tag='ImaginaryTimeTransientTimeScatter');
            end
        end

        function updateData(this,ko,~,ka)
            data = this.Response.ResponseData.TransientTime;

            m = this.RealTransientTimeMarkers(ko,1,ka);
            xl = this.TransientTimeXLines(ko,1,ka);
            yl1 = this.TransientTimeUpperYLines(ko,1,ka);
            yl2 = this.TransientTimeLowerYLines(ko,1,ka);

            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            t = conversionFcn(data.Time{ka}(ko,1));
            realValue = real(data.Value{ka}(ko,1));

            % Marker
            m.XData = t;
            m.YData = realValue;
            % XLines
            xl.XData = [t, t];
            xl.YData = [-1e20, realValue];
            
            if this.Response.IsReal(ka)
                % Upper and lower Y Lines
                yl1.Value = data.UpperValue{ka}(ko,1);
                yl2.Value = data.LowerValue{ka}(ko,1);
            else
                yl1.Value = NaN;
                yl2.Value = NaN;
                
                imaginaryValue = imag(data.Value{ka}(ko,1));
                mIm = this.ImaginaryTransientTimeMarkers(ko,1,ka);
                mIm.XData = [t, t];
                mIm.YData = [-1e20 imaginaryValue];

                xl.YData = [-1e20, max(realValue,imaginaryValue)];
            end

            
        end

        function updateDataByLimits(this,ko,~,ka)
            responseObjects = getResponseObjects(this.ResponseView,ko,1,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);
            ax = responseLine.Parent;
            
            if ~isempty(ax)
                m = this.RealTransientTimeMarkers(ko,1,ka);
                xl = this.TransientTimeXLines(ko,1,ka);

                t = xl.XData(1);
                xLim = ax.XLim;
                yLim = ax.YLim;
                valueLessThanLimits = t < xLim(1);
                valueGreaterThanLimits = t > xLim(2);
                m.UserData.ValueOutsideLimits = valueLessThanLimits || valueGreaterThanLimits;
                if valueLessThanLimits
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
                elseif valueGreaterThanLimits
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
                else
                    % Value is within x-limits
                    x = t;
                    xData = responseLine.XData;
                    yData = responseLine.YData;
                    [~,idx] = min(abs(xData - x));
                    y = yData(idx);
                end
                m.XData = x;
                m.YData = y;
                xl.YData(1) = yLim(1);
            end
        end

        function updateDataTips_(this,ko,ka,nameDataTipRow,outputDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.TransientTime;

            valueRow = dataTipTextRow(getString(message('Controllib:plots:strTransientTime')) + " (" + ...
                this.TimeUnitLabel + ")",data.Time{ka}(ko,1),'%0.3g');
            this.RealTransientTimeMarkers(ko,1,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; outputDataTipRow; valueRow; customDataTipRows(:)];
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ka = 1:this.Response.NResponses
                        this.RealTransientTimeMarkers(ko,1,ka).XData = conversionFcn(this.RealTransientTimeMarkers(ko,1,ka).XData);
                        this.TransientTimeXLines(ko,1,ka).XData = conversionFcn(this.TransientTimeXLines(ko,1,ka).XData);

                        row = this.replaceDataTipRowLabel(this.RealTransientTimeMarkers(ko,1,ka),getString(message('Controllib:plots:strTransientTime')),...
                            getString(message('Controllib:plots:strTransientTime')) + " (" + this.TimeUnitLabel + ")");
                        this.RealTransientTimeMarkers(ko,1,ka).DataTipTemplate.DataTipRows(row).Value = ...
                            conversionFcn(this.RealTransientTimeMarkers(ko,1,ka).DataTipTemplate.DataTipRows(row).Value);
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,~,ka)
            c = this.RealTransientTimeMarkers(ko,1,ka);
            if ~this.Response.IsReal(ka)
                c = cat(3,c,this.ImaginaryTransientTimeMarkers(ko,1,ka));
            end
        end

        function l = getSupportingObjects_(this,ko,~,ka)
            l = cat(3,this.TransientTimeUpperYLines(ko,1,ka),...
                this.TransientTimeLowerYLines(ko,1,ka),...
                this.TransientTimeXLines(ko,1,ka));
        end
    end
end
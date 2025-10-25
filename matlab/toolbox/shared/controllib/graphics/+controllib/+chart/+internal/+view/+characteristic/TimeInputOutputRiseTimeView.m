classdef TimeInputOutputRiseTimeView < controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView
    % this = controllib.chart.internal.view.characteristic.TimePeakResponseView(data)
    %
    % Copyright 2021 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess = protected)
        RiseTimeHighXLines
        RiseTimeLowXLines

        RealRiseTimeMarkers
        RealRiseTimeYLines

        ImaginaryRiseTimeMarkers
        ImaginaryRiseTimeYLines        
    end

    %% Constructor
    methods
        function this = TimeInputOutputRiseTimeView(responseView,data)
            this@controllib.chart.internal.view.characteristic.TimeInputOutputCharacteristicView(responseView,data);
        end
    end

    %% Protected methods
    methods (Access = protected)
        function build_(this)   
            this.RealRiseTimeMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,Tag='TimeRiseTimeScatter');
            this.RiseTimeHighXLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeRiseTimeXLineHigh');
            set(this.RiseTimeHighXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.RiseTimeHighXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.RiseTimeLowXLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeRiseTimeXLineLow');
            set(this.RiseTimeLowXLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.RiseTimeLowXLines,"Color","--mw-graphics-colorNeutral-line-primary");
            this.RealRiseTimeYLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeRiseTimeYLine');
            set(this.RealRiseTimeYLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
            controllib.plot.internal.utils.setColorProperty(...
                this.RealRiseTimeYLines,"Color","--mw-graphics-colorNeutral-line-primary");

            if any(~this.Response.IsReal)
                this.ImaginaryRiseTimeMarkers = createGraphicsObjects(this,"scatter",this.Response.NRows,...
                    this.Response.NColumns,this.Response.NResponses,Tag='TimeRiseTimeScatter');
                this.ImaginaryRiseTimeYLines = createGraphicsObjects(this,"line",this.Response.NRows,...
                    this.Response.NColumns,this.Response.NResponses,HitTest='off',PickableParts='none',Tag='TimeRiseTimeYLine');
                set(this.ImaginaryRiseTimeYLines,LineStyle='-.',XData=[NaN NaN],YData=[NaN NaN])
                controllib.plot.internal.utils.setColorProperty(...
                    this.ImaginaryRiseTimeYLines,"Color","--mw-graphics-colorNeutral-line-primary");

            end
        end

        function updateData(this,ko,ki,ka)
            data = this.Response.ResponseData.RiseTime;

            m = this.RealRiseTimeMarkers(ko,ki,ka);
            xl1 = this.RiseTimeHighXLines(ko,ki,ka);
            xl2 = this.RiseTimeLowXLines(ko,ki,ka);
            yl = this.RealRiseTimeYLines(ko,ki,ka);

            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            tLow = conversionFcn(data.TimeLow{ka}(ko,ki));
            tHigh = conversionFcn(data.TimeHigh{ka}(ko,ki));

            realValue = real(data.Value{ka}(ko,ki));

            m.XData(end) = tHigh;
            m.YData(end) = realValue;
            % High XLines
            xl1.XData = [tHigh, tHigh];
            xl1.YData = [-1e20, realValue];
            % Low XLines
            xl2.XData = [tLow, tLow];                
            xl2.YData = [-1e20, realValue];
            % YLines
            yl.XData = [-1e20, tHigh];
            yl.YData = [realValue, realValue];

            if ~this.Response.IsReal(ka)
                imaginaryValue = imag(data.Value{ka}(ko,ki));
                mIm = this.ImaginaryRiseTimeMarkers(ko,ki,ka);
                ylIm = this.ImaginaryRiseTimeYLines(ko,ki,ka);

                % Imaginary marker
                mIm.XData(end) = tHigh;
                mIm.YData(end) = imaginaryValue;
                
                % Imaginary YLine
                ylIm.XData = [-1e20, tHigh];
                ylIm.YData = [imaginaryValue, imaginaryValue];

                % Update XLines
                xl1.YData = [-1e20, max(realValue,imaginaryValue)];
                xl2.YData = [-1e20, max(realValue,imaginaryValue)];
            end
        end

        function updateDataByLimits(this,ko,ki,ka)
            responseObjects = getResponseObjects(this.ResponseView,ko,ki,ka);
            responseLine = responseObjects{1}(this.ResponseLineIdx);
            ax = responseLine.Parent;

            if ~isempty(ax)
                m = this.RealRiseTimeMarkers(ko,ki,ka);
                xl1 = this.RiseTimeHighXLines(ko,ki,ka);
                xl2 = this.RiseTimeLowXLines(ko,ki,ka);
                yl = this.RealRiseTimeYLines(ko,ki,ka);

                tHigh = xl1.XData(1);
                xLim = ax.XLim;
                yLim = ax.YLim;
                valueLessThanLimits = tHigh < xLim(1);
                valueGreaterThanLimits = tHigh > xLim(2);

                valueOutsideLimits = valueLessThanLimits || valueGreaterThanLimits;
                m.UserData.ValueOutsideLimits = valueOutsideLimits;
                if valueOutsideLimits
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
                    % xl1.YData(1) = yLim(1);
                    % xl2.YData(1) = yLim(1);
                    % yl.XData(1) = xLim(1);
                else
                    % Value is within x-limits
                    updateData(this,ko,ki,ka);
                end
                
            end
        end

        function updateDataTips_(this,ko,ki,ka,nameDataTipRow,ioDataTipRow,customDataTipRows)
            data = this.Response.ResponseData.RiseTime;
            conversionFcn = getTimeUnitConversionFcn(this,this.Response.ResponseData.TimeUnit,this.TimeUnit);
            timeValue = conversionFcn(data.TimeHigh{ka}(ko,ki) - data.TimeLow{ka}(ko,ki));
            valueRow = dataTipTextRow(getString(message('Controllib:plots:strRiseTime')) + " (" + ...
                this.TimeUnitLabel + ")",timeValue,'%0.3g');
            this.RealRiseTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; valueRow; customDataTipRows(:)];
            this.ImaginaryRiseTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows = ...
                [nameDataTipRow; ioDataTipRow; valueRow; customDataTipRows(:)];
        end

        function cbTimeUnitChanged(this,conversionFcn)
            if this.IsInitialized
                for ko = 1:this.Response.NRows
                    for ki = 1:this.Response.NColumns
                        for ka = 1:this.Response.NResponses
                            this.RealRiseTimeMarkers(ko,ki,ka).XData = conversionFcn(this.RealRiseTimeMarkers(ko,ki,ka).XData);
                            this.RiseTimeLowXLines(ko,ki,ka).XData = conversionFcn(this.RiseTimeLowXLines(ko,ki,ka).XData);
                            this.RiseTimeHighXLines(ko,ki,ka).XData = conversionFcn(this.RiseTimeHighXLines(ko,ki,ka).XData);
                            this.RealRiseTimeYLines(ko,ki,ka).XData(2) = conversionFcn(this.RealRiseTimeYLines(ko,ki,ka).XData(2));

                            rowNum = this.replaceDataTipRowLabel(this.RealRiseTimeMarkers(ko,ki,ka),getString(message('Controllib:plots:strRiseTime')),...
                                getString(message('Controllib:plots:strRiseTime')) + " (" + this.TimeUnitLabel + ")");
                            this.RealRiseTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value = ...
                                conversionFcn(this.RealRiseTimeMarkers(ko,ki,ka).DataTipTemplate.DataTipRows(rowNum).Value);
                        end
                    end
                end
            end
        end

        function c = getMarkerObjects_(this,ko,ki,ka)
            c = this.RealRiseTimeMarkers(ko,ki,ka);
            if ~this.Response.IsReal(ka)
                c = cat(3,c,this.ImaginaryRiseTimeMarkers(ko,ki,ka));
            end
        end

        function l = getSupportingObjects_(this,ko,ki,ka)
            l = cat(3,this.RiseTimeHighXLines(ko,ki,ka),...
                this.RiseTimeLowXLines(ko,ki,ka),...
                this.RealRiseTimeYLines(ko,ki,ka));
            if ~this.Response.IsReal(ka)
                l = cat(3,l,this.ImaginaryRiseTimeYLines(ko,ki,ka));
            end
        end
    end
end
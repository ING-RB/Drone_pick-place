classdef SimulationMagnitudePhaseAxesView < controllib.chart.internal.view.axes.TimeMagnitudePhaseOutputAxesView

methods (Access = protected)
    function [timeFocus, amplitudeFocus] = computeFocus(this,responses)
            arguments
                this (1,1) controllib.chart.internal.view.axes.OutputAxesView
                responses (:,1) controllib.chart.internal.foundation.BaseResponse ...
                    {controllib.chart.internal.view.axes.SingleColumnAxesView.mustBeRowResponse(responses)}
            end

            if ~isempty(responses)
                data = [responses.ResponseData];
                [timeFocus_, amplitudeFocus_, timeUnit] = getCommonFocusForMultipleData(data,...
                    false,{responses.ArrayVisible},ShowMagnitude=true,ShowReal=false,...
                    ShowImaginary=false);
                timeFocus(1:size(timeFocus_,1),1:size(timeFocus_,2)) = timeFocus_;
                amplitudeFocus(1:size(amplitudeFocus_,1),1:size(amplitudeFocus_,2)) = amplitudeFocus_;
                timeConversionFcn = getTimeUnitConversionFcn(this,timeUnit,this.TimeUnit);
                for ko = 1:this.NRows
                    timeFocus{ko} = timeConversionFcn(timeFocus{ko});
                end
            end
    end
end
end
classdef StepTransientTimeData < controllib.chart.internal.data.characteristics.TimeTransientTimeData
    % controllib.chart.internal.data.StepTransientTimeData
    %   - class for computing transient time of step plots
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.characteristics.TimeTransientTimeData">controllib.chart.internal.data.characteristics.TimeTransientTimeData</a>
    
    % Copyright 2022-2024 The MathWorks, Inc.

    methods
        function this = StepTransientTimeData(varargin)
            this@controllib.chart.internal.data.characteristics.TimeTransientTimeData(varargin{:});
        end
    end

    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;

            nrows = data.DataDimensions(1);
            ncols = data.DataDimensions(2);
            nArray = data.NData;

            for ka = 1:nArray
                t = getTime(data,[1 1],ka);
                [yReal,yImaginary] = getAmplitude(data,"all",ka);
                [yfReal,yfImaginary] = getFinalValue(data,"all",ka);
                [y0Real,y0Imaginary] = getFinalValue(data,"all",ka);
                
                y = yReal + 1i*yImaginary;
                yf = yfReal + 1i*yfImaginary;
                y0 = y0Real+ 1i*y0Imaginary;
                
                ySettle = NaN(nrows,ncols);
                yUpper = NaN(nrows,ncols);
                yLower = NaN(nrows,ncols);
                if isempty(y)
                    % NaN model
                    tTransient = NaN(nrows,ncols);
                else
                    ns = length(t);
                    s = lsiminfo(y(1:ns-1,:,:),t(1:ns-1),yf,y0,'SettlingTimeThreshold',this.Threshold);
                    tTransient = real(reshape(cat(1,s.TransientTime),nrows,ncols));
                    % Compute Y value at settling time
                    for ct=1:nrows*ncols
                        if this.ResponseData.IsDiscrete
                            idx = find(t > tTransient(ct),1,'first');
                            if ~isempty(idx)
                                tTransient(ct) = t(idx);
                            end
                        end
                        if isfinite(tTransient(ct))
                            ySettle(ct) = utInterp1(t,y(:,ct),tTransient(ct));
                            if ySettle(ct) < yf(ct)
                                yUpper(ct) = ySettle(ct);
                                yLower(ct) = 2*yf(ct) - ySettle(ct);
                            else
                                yUpper(ct) = 2*yf(ct) - ySettle(ct);
                                yLower(ct) = ySettle(ct);
                            end
                        end
                    end
                end
                this.Time{ka} = tTransient;
                this.Value{ka} = ySettle;
                this.UpperValue{ka} = yUpper;
                this.LowerValue{ka} = yLower;
            end
        end
    end
end

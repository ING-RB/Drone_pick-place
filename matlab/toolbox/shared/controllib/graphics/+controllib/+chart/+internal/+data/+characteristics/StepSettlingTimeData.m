classdef StepSettlingTimeData < controllib.chart.internal.data.characteristics.TimeSettlingTimeData
    % controllib.chart.internal.data.StepSettlingTimeData
    %   - class for computing settling time of step plots
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.characteristics.TimeSettlingTimeData">controllib.chart.internal.data.characteristics.TimeSettlingTimeData</a>
    
    % Copyright 2022-2024 The MathWorks, Inc.

    methods
        function this = StepSettlingTimeData(varargin)
            this@controllib.chart.internal.data.characteristics.TimeSettlingTimeData(varargin{:});
        end
    end

    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;
            nrows = data.DataDimensions(1);
            ncols = data.DataDimensions(2);
            nArray = data.NData;

            for ka = 1:nArray
                t = getTime(data,{1:nrows,1:ncols},ka);
                [yReal,yImaginary] = getAmplitude(data,{1:nrows,1:ncols},ka);
                [yfReal,yfImaginary] = getFinalValue(data,{1:nrows,1:ncols},ka);
                [y0Real,y0Imaginary] = getInitialValue(data,{1:nrows,1:ncols},ka);

                y = yReal + 1i*yImaginary;
                yf = yfReal + 1i*yfImaginary;
                y0 = y0Real+ 1i*y0Imaginary;

                ySettle = NaN(nrows,ncols);
                yUpper = NaN(nrows,ncols);
                yLower = NaN(nrows,ncols);
                if isempty(y)
                    % NaN model
                    tSettle = NaN(nrows,ncols);
                else
                    ns = size(t,1);
                    s = lsiminfo(y(1:ns-1,:,:),t(1:ns-1,1,1),yf,y0,'SettlingTimeThreshold',this.Threshold);
                    tSettle = real(reshape(cat(1,s.SettlingTime),nrows,ncols));
                    % Compute Y value at settling time
                    for kr = 1:nrows
                        for kc = 1:ncols
                            if this.ResponseData.IsDiscrete
                                idx = find(t(:,kr,kc) > tSettle(kr,kc),1,'first');
                                if ~isempty(idx)
                                    tSettle(kr,kc) = t(idx,kr,kc);
                                end
                            end
                            if isfinite(tSettle(kr,kc))
                                ySettle(kr,kc) = utInterp1(t(:,kr,kc),y(:,kr,kc),tSettle(kr,kc));
                                if ySettle(kr,kc) < yf(kr,kc)
                                    yUpper(kr,kc) = ySettle(kr,kc);
                                    yLower(kr,kc) = 2*yf(kr,kc) - ySettle(kr,kc);
                                else
                                    yUpper(kr,kc) = 2*yf(kr,kc) - ySettle(kr,kc);
                                    yLower(kr,kc) = ySettle(kr,kc);
                                end
                            end
                        end
                    end
                end
                this.Time{ka} = tSettle;
                this.Value{ka} = ySettle;
                this.UpperValue{ka} = yUpper;
                this.LowerValue{ka} = yLower;
            end
        end
    end
end

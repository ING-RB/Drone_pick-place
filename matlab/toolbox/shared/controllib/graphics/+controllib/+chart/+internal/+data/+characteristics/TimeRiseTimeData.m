classdef TimeRiseTimeData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.TimeRiseTimeData
    %   - class for computing rise response of time plots
    %   - inherited from controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %
    % h = TimeRiseTimeData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData            response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                    type of characteristics, string scalar
    %   IsDirty                 flag if response needs to be computed, logical scalar
    %   Time                    rise time
    %   Value                   rise value
    %   TimeLow                 time lower limit met
    %   TimeHigh                time upper limit met
    %   Limits                  limits for rise time
    %
    % Events:
    %   DataChanged             notified in update()
    %
    % Public methods:
    %   update(this)
    %       Update the the characteristic data using ResponseData. Marks IsDirty as true.
    %   compute(this)
    %       Computes the characteristic data with stored Data. Marks IsDirty as false.
    %
    % Protected methods (override in subclass):
    %   compute_(this)
    %       Compute the characteristic data. Called in compute(). Implement in subclass.
    %   postUpdate(this)
    %       Called after updating the data. Implement in subclass if needed.
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.characteristics.BaseCharacteristicData">controllib.chart.internal.data.characteristics.BaseCharacteristicData</a>
    
    % Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess = protected)
        Time
        Value
        TimeLow
        TimeHigh
        Limits
    end

    methods
        function this = TimeRiseTimeData(data,limits)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "RiseTime";
            this.Limits = limits;
        end

        function update(this,limits)
            arguments
                this
                limits double = this.Limits
            end
            this.Limits = limits;
            update@controllib.chart.internal.data.characteristics.BaseCharacteristicData(this);
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
                
                y = yReal + 1i*yImaginary;
                yf = yfReal + 1i*yfImaginary;

                amplitude = NaN(nrows,ncols);
                if isempty(y)
                    % NaN model
                    tLow = NaN(nrows,ncols);
                    tHigh = NaN(nrows,ncols);                    
                else
                    ns = length(t);
                    [~,xt] = stepinfo(y(1:ns-1,:,:),t(1:ns-1),yf,'RiseTimeLimits',this.Limits);
                    % Store data
                    tLow = reshape(cat(1,xt.RiseTimeLow),nrows,ncols);
                    tHigh = reshape(cat(1,xt.RiseTimeHigh),nrows,ncols);
                    % Compute YHigh = upper rise time target
                    amplitude = zeros(nrows,ncols);
                    for kr = 1:nrows
                        for kc = 1:ncols
                            if this.ResponseData.IsDiscrete
                                idx = find(t > tHigh(kr,kc),1,'first');
                                if ~isempty(idx)
                                    tHigh(kr,kc) = t(idx);
                                end

                                idx = find(t > tLow(kr,kc),1,'first');
                                if ~isempty(idx)
                                    tLow(kr,kc) = t(idx);
                                end
                            end
                            [~,idx] = min(abs(t-tHigh(kr,kc)));
                            if idx > 1
                                if t(idx) < tHigh(kr,kc)
                                    ydiff = y(idx+1,kr,kc) - y(idx,kr,kc);
                                    tdiff = t(idx+1) - t(idx);
                                    amplitude(kr,kc) = y(idx,kr,kc) + ydiff*(tHigh(kr,kc) - t(idx))/tdiff;
                                else
                                    ydiff = y(idx,kr,kc) - y(idx-1,kr,kc);
                                    tdiff = t(idx) - t(idx-1);
                                    amplitude(kr,kc) = y(idx-1,kr,kc) + ydiff*(tHigh(kr,kc) - t(idx-1))/tdiff;
                                end
                            else
                                amplitude(kr,kc) = y(idx,kr,kc);
                            end
                        end
                    end
                end
                this.TimeLow{ka} = tLow;
                this.TimeHigh{ka} = tHigh;
                this.Time{ka} = tHigh-tLow;
                this.Value{ka} = amplitude;
            end
        end
    end
end

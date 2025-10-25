classdef TimePeakResponseData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.TimePeakResponseData
    %   - class for computing peak response of time plots
    %   - inherited from controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %
    % h = TimePeakResponseData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData            response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                    type of characteristics, string scalar
    %   IsDirty                 flag if response needs to be computed, logical scalar
    %   Time                    peak time
    %   Value                   peak value
    %   Overshoot               percent overshoot
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

    properties (SetAccess=protected)
        Time
        Value
        Overshoot
    end

    methods
        function this = TimePeakResponseData(data)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "PeakResponse";
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
                
                timeFocus = getTimeFocus(data,"all",ka);
                if ~iscell(timeFocus)
                    timeFocus = {timeFocus};
                end
                
                ns = length(t);
                if ~all(isfinite(y(ns,:)))
                    t = t(1:ns-1);   
                    y = y(1:ns-1,:,:);
                end
                
                % Compute peak abs value and overshoot
                if all(isnan(t),'all') && all(isnan(y),'all')
                    tPeak = NaN(nrows,ncols);
                    yPeak = NaN(nrows,ncols);
                    this.Overshoot{ka} = NaN(nrows,ncols);
                elseif all(isfinite(yf(:)))
                    % Stable case
                    s = stepinfo(y,t,yf);
                    % Store data
                    tPeak = reshape(cat(1,s.PeakTime),nrows,ncols);
                    OS = reshape(cat(1,s.Overshoot),nrows,ncols);
                    % Compute Y value at peak time
                    yPeak = zeros(nrows,ncols);
                    for ct=1:nrows*ncols
                        if this.ResponseData.IsDiscrete
                            idx = find(t > tPeak(ct),1,'first');
                            if ~isempty(idx)
                                if abs(y(idx-1,ct)) > abs(y(idx,ct))
                                    tPeak(ct) = t(idx-1);
                                else
                                    tPeak(ct) = t(idx);
                                end
                            end
                        end
                        yPeak(ct) = y(t==tPeak(ct),ct);
                        if tPeak(ct) > timeFocus{ct}(2)
                            tPeak(ct) = Inf;
                        end
                    end
                    this.Overshoot{ka} = OS;
                elseif all(isnan(yf(:)))
                    % nlarx case, final value is NaN
                    for ct=1:nrows*ncols
                        [~,idx] = max(abs(y(:,ct)));
                        tPeak(ct) = t(idx);
                        yPeak(ct) = y(idx,ct);
                    end
                    yPeak = reshape(yPeak,nrows,ncols);
                    tPeak = reshape(tPeak,nrows,ncols);
                    this.Overshoot{ka} = NaN(nrows,ncols);
                else
                    % Unstable case: final value is Inf, show peak value so
                    % far and set overshoot to NaN
                    for ct=1:nrows*ncols
                        [~,idx] = max(abs(y(:,ct)));
                        tPeak(ct) = Inf;
                        yPeak(ct) = Inf*sign(y(idx,ct));
                    end
                    yPeak = reshape(yPeak,nrows,ncols);
                    tPeak = reshape(tPeak,nrows,ncols);
                    this.Overshoot{ka} = NaN(nrows,ncols);
                end
                this.Time{ka} = tPeak;
                this.Value{ka} = yPeak;
            end
        end
    end
end

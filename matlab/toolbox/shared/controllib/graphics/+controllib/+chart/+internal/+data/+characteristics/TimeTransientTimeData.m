classdef TimeTransientTimeData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.TimeTransientTimeData
    %   - class for computing transient time of time plots
    %   - inherited from controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %
    % h = TimeTransientTimeData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData            response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                    type of characteristics, string scalar
    %   IsDirty                 flag if response needs to be computed, logical scalar
    %   Time                    transient time
    %   Value                   transient value
    %   UpperValue              upper value for transient behavior
    %   LowerValue              lower value for transient behavior
    %   Threshold               threshold for transient behavior
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
        UpperValue
        LowerValue
        Threshold
    end

    methods
        function this = TimeTransientTimeData(data,threshold)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "TransientTime";
            this.Threshold = threshold;
        end

        function update(this,threshold)
            arguments
                this (1,1) controllib.chart.internal.data.characteristics.TimeTransientTimeData
                threshold (1,1) double = this.Threshold
            end
            update@controllib.chart.internal.data.characteristics.BaseCharacteristicData(this);
            this.Threshold = threshold;
        end
    end

    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;

            nrows = data.DataDimensions(1);
            ncols = data.DataDimensions(2);
            nArray = data.NData;

            for ka = 1:nArray
                t = real(getTime(data,[1 1],ka));
                [yReal,yImaginary] = getAmplitude(data,"all",ka);
                [yfReal,yfImaginary] = getFinalValue(data,"all",ka);

                y = yReal + 1i*yImaginary;
                yf = yfReal + 1i*yfImaginary;

                ySettle = NaN(nrows,ncols);
                yUpper = NaN(nrows,ncols);
                yLower = NaN(nrows,ncols);
                if isempty(y)
                    % NaN model
                    tTransient = NaN(nrows,ncols);
                else
                    ns = length(t);
                    s = lsiminfo(y(1:ns-1,:,:),t(1:ns-1),yf,'SettlingTimeThreshold',this.Threshold);
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

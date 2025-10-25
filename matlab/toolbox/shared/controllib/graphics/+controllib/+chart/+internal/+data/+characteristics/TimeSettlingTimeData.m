classdef TimeSettlingTimeData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.TimeSettlingTimeData
    %   - class for computing settling time of time plots
    %   - inherited from controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %
    % h = TimeSettlingTimeData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData            response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                    type of characteristics, string scalar
    %   IsDirty                 flag if response needs to be computed, logical scalar
    %   Time                    settling time
    %   Value                   settling value
    %   UpperValue              upper value for settling behavior
    %   LowerValue              lower value for settling behavior
    %   Threshold               threshold for settling behavior
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
        UpperValue
        LowerValue
        Threshold
    end

    methods
        function this = TimeSettlingTimeData(data,threshold)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "SettlingTime";
            this.Threshold = threshold;
        end

        function update(this,threshold)
            arguments
                this
                threshold double = this.Threshold
            end
            this.Threshold = threshold;
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
                t = getTime(data,{1:nrows,1:ncols},ka);
                y = real(getAmplitude(data,{1:nrows,1:ncols},ka));
                yf = real(getFinalValue(data,{1:nrows,1:ncols},ka));

                ySettle = NaN(nrows,ncols);
                yUpper = NaN(nrows,ncols);
                yLower = NaN(nrows,ncols);
                if isempty(y)
                    % NaN model
                    tSettle = NaN(nrows,ncols);
                else
                    ns = size(t,1);
                    s = lsiminfo(y(1:ns-1,:,:),t(1:ns-1,1,1),yf,'SettlingTimeThreshold',this.Threshold);
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

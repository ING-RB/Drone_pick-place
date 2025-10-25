 classdef TimeBoundaryRegionData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.TimeBoundaryRegionData
    %   - class for computing boundary region of time plots
    %   - inherited from controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %
    % h = TimeBoundaryRegionData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData            response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                    type of characteristics, string scalar
    %   IsDirty                 flag if response needs to be computed, logical scalar
    %   Time                    time data of region
    %   UpperBoundaryAmplitude  upper amplitude data of region
    %   LowerBoundaryAmplitude  lower amplitude data of region
    %   AmplitudeFocus              amplitude focus of region
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
        UpperBoundaryAmplitude
        LowerBoundaryAmplitude
        AmplitudeFocus
    end

    methods
        function this = TimeBoundaryRegionData(data)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "BoundaryRegion";
        end
    end

    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;
            nrows = data.DataDimensions(1);
            ncols = data.DataDimensions(2);
            nArray = data.NData;

            N = 0;
            for ct = 1:nArray
                N = N + length(getTime(data,{1,1},ct));
            end
            t = zeros(N,1);
            ctr = 1;
            for ct = 1:nArray
                time = getTime(data,{1,1},ct);
                N = length(time);
                t(ctr:ctr+N-1) = time;
                ctr = ctr + N;
            end
            this.Time = unique(t);   

            Amplitude = zeros(length(this.Time),nrows,ncols,nArray);
            for ct = 1:nArray
                for kr = 1:nrows
                    for kc = 1:ncols
                        realAmplitude = getAmplitude(data,{kr,kc},ct);
                        Amplitude(:,kr,kc,ct) = utInterp1(getTime(data,{kr,kc},ct),...
                                realAmplitude,this.Time);
                    end
                end
            end            
            this.UpperBoundaryAmplitude = max(Amplitude,[],4);
            this.LowerBoundaryAmplitude = min(Amplitude,[],4);

            this.AmplitudeFocus = cell(nrows,ncols);
            for kr = 1:nrows
                for kc = 1:ncols
                    this.AmplitudeFocus{kr,kc} = [min(squeeze(this.LowerBoundaryAmplitude(:,kr,kc))),...
                                                  max(squeeze(this.UpperBoundaryAmplitude(:,kr,kc)))];
                end
            end
        end
    end
end

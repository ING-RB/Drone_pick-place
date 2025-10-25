classdef ImpulseConfidenceRegionData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.ImpulseConfidenceRegionData
    %   - class for computing confidence region data of an impulse response
    %
    % h = ImpulseConfidenceRegionData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData                response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                        type of characteristics, string scalar
    %   IsDirty                     flag if response needs to be computed, logical scalar
    %   Time                        time data of region
    %   UpperBoundaryAmplitude      upper amplitude data of region
    %   LowerBoundaryAmplitude      lower amplitude data of region
    %   IsValid                     flag if region is valid
    %   NumberOfStandardDeviations  number of standard deviations for confidence
    %   AmplitudeFocus              amplitude focus of region
    %
    % Events:
    %   DataChanged             notified in update()
    %
    % Public methods:
    %   update(this,numberOfSD)
    %       Update the the characteristic data using ResponseData. Marks IsDirty as true.
    %   compute(this)
    %       Computes the characteristic data with stored Data. Marks IsDirty as false.
    %
    % Protected methods (override in subclass):
    %   postUpdate(this)
    %       Called after updating the data. Implement in subclass if needed.
    %
    % Abstract methods
    %   compute_(this)
    %       Compute the characteristic data. Called in compute(). Implement in subclass.
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.characteristics.BaseCharacteristicData">controllib.chart.internal.data.characteristics.BaseCharacteristicData</a>

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (SetAccess = protected)
        IsValid = false
        NumberOfStandardDeviations
        AmplitudeFocus
        Time
        UpperBoundaryAmplitude
        LowerBoundaryAmplitude
    end

    methods
        function this = ImpulseConfidenceRegionData(data,numberOfSD)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "ConfidenceRegion";
            this.NumberOfStandardDeviations = numberOfSD;
        end

        function update(this,numberOfSD)
            arguments
                this (1,1) controllib.chart.internal.data.characteristics.ImpulseConfidenceRegionData
                numberOfSD (1,1) double = this.NumberOfStandardDeviations
            end
            this.NumberOfStandardDeviations = numberOfSD;
            update@controllib.chart.internal.data.characteristics.BaseCharacteristicData(this);
        end
    end

    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;

            nrows = data.NOutputs;
            ncols = data.NInputs;
            nArray = data.NResponses;

            this.AmplitudeFocus = cell(1,nArray);
            this.Time = cell(1,nArray);

            this.UpperBoundaryAmplitude = cell(1,nArray);
            this.LowerBoundaryAmplitude = cell(1,nArray);
            for ka = 1:nArray
                amplitudeSD = NaN(size(getAmplitude(data,"all",ka)));
                this.AmplitudeFocus{ka} = cell(nrows,ncols);
                this.Time{ka} = NaN(size(getTime(data,[],ka)));
                try
                    % Determine if the last time point is an extension or a computed
                    % timestep
                    tvec = getTime(data,"all",ka);
                    if (size(tvec,1)>2)
                        TEndDiff = tvec(end,1,1)-tvec(end-1,1,1);
                        TBeginDiff = tvec(2,1,1)-tvec(1,1,1);
                        if abs(TEndDiff-TBeginDiff) > 0.01*TBeginDiff
                            tvec = tvec(1:end-1,:,:);
                        end
                    end
                catch ME
                    times = getTime(data,"all",ka);
                    tvec = times(1:end-1,:,:);
                end
                
                [ysd,t] = getTimeConfidenceRegionData_(data.ModelValue,tvec,data.Config,...
                                'impulse',ka);
                
                if ~isempty(ysd)
                    this.IsValid(ka) = true;
                    for yct = 1:nrows
                        for uct = 1:ncols
                            % Remove trailing NaNs
                            idx = find(isfinite(ysd(:,yct,uct)),1,'last');
                            amplitudeSD(1:idx,yct,uct) = ysd(1:idx,yct,uct);
                            realAmplitude = getAmplitude(this.ResponseData,"all",ka);
                            this.UpperBoundaryAmplitude{ka}(:,yct,uct) = 0*realAmplitude(:,yct,uct) + ...
                                this.NumberOfStandardDeviations*amplitudeSD(:,yct,uct);
                            this.LowerBoundaryAmplitude{ka}(:,yct,uct) = 0*realAmplitude(:,yct,uct) - ...
                                this.NumberOfStandardDeviations*amplitudeSD(:,yct,uct);
                            this.AmplitudeFocus{ka}{yct,uct}(1) = min(this.LowerBoundaryAmplitude{ka}(:,yct,uct));
                            this.AmplitudeFocus{ka}{yct,uct}(2) = max(this.UpperBoundaryAmplitude{ka}(:,yct,uct));
                        end
                    end
                    this.Time{ka}(1:idx) = t(1:idx);
                else
                    this.IsValid(ka) = false;
                end
            end
        end
    end
end

classdef NyquistConfidenceRegionData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.NyquistConfidenceRegionData
    %   - class for computing confidence region data of a nyquist response
    %
    % h = NyquistConfidenceRegionData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData                response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                        type of characteristics, string scalar
    %   IsDirty                     flag if response needs to be computed, logical scalar
    %   PositiveFrequencyResponse   positive frequency response data
    %   PositiveFrequency           positive frequency data
    %   CovarianceData              data for confidence region covariance
    %   EllipseData                 data for confidence region ellipses
    %   IsValid                     flag if region is valid
    %   NumberOfStandardDeviations  number of standard deviations for confidence
    %   ConfidenceDisplaySampling   sample spacing for boundary computation
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
    
    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        IsValid
        NumberOfStandardDeviations
        PositiveFrequencyResponse
        PositiveFrequency
        CovarianceData
        EllipseData
        ConfidenceDisplaySampling = 5
    end

    %% Constructor
    methods
        function this = NyquistConfidenceRegionData(data,numberOfSD,displaySampling)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "ConfidenceRegion";
            this.NumberOfStandardDeviations = numberOfSD;
            this.ConfidenceDisplaySampling = displaySampling;
        end
    end

    %% Public methods
    methods
        function update(this,numberOfSD,displaySampling)
            arguments
                this (1,1) controllib.chart.internal.data.characteristics.NyquistConfidenceRegionData
                numberOfSD (1,1) double = this.NumberOfStandardDeviations
                displaySampling (1,1) double = this.ConfidenceDisplaySampling
            end
            update@controllib.chart.internal.data.characteristics.BaseCharacteristicData(this);
            this.NumberOfStandardDeviations = numberOfSD;
            this.ConfidenceDisplaySampling = displaySampling;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;

            nOutputs = data.NOutputs;
            nInputs = data.NInputs;
            nArray = data.NResponses;

            this.PositiveFrequencyResponse = cell(1,nArray);
            this.PositiveFrequency = cell(1,nArray);
            this.CovarianceData = cell(1,nArray);
            this.EllipseData = cell(1,nArray);

            for ka = 1:nArray
                f = data.PositiveFrequency{ka}(1:this.ConfidenceDisplaySampling:end);

                % Compute covariance data
                covarianceData = getFrequencyResponseCovarianceData_(data.ModelValue,f,ka);
                if isempty(covarianceData)
                    this.IsValid(ka) = false;
                else
                    this.PositiveFrequencyResponse{ka} = ...
                        data.PositiveFrequencyResponse{ka}(1:this.ConfidenceDisplaySampling:end,:,:);
                    this.PositiveFrequency{ka} = f;
                    this.CovarianceData = (this.NumberOfStandardDeviations)^2*covarianceData;

                    % Compute data to create ellipses
                    theta = [0:0.1:2*pi,0];
                    theta = theta(:);
                    circle = exp(1i*theta);
                    for ko = 1:nOutputs
                        for ki = 1:nInputs
                            for k = 1:length(f)
                                covarianceMatrix = squeeze(this.CovarianceData(ko,ki,k,:,:));
                                this.EllipseData{ka}(k,ko,ki).Frequencies = ...
                                    this.transformCircle(this.PositiveFrequencyResponse{ka}(k,ko,ki),...
                                    covarianceMatrix,1,circle);
                                this.EllipseData{ka}(k,ko,ki).Centers = this.PositiveFrequencyResponse{ka}(k,ko,ki);
                            end
                        end
                    end
                    this.IsValid(ka) = true;
                end
            end
        end
    end

    %% Static sealed protected methods
    methods (Static,Sealed,Access=protected)
        function Circle = transformCircle(H,CovH,sd,Circle)
            %transformCircle Transform circle to confidence region using Covariance and
            % Standard Deviation.
            %
            if imag(H)==0
                rp=real(H+sd*sqrt(CovH(1,1))*[-1 1]);
                Circle = rp(:);
            else
                if all(isfinite(CovH))
                    [V,D]=eig(CovH);
                    z1=real(Circle)'*sd*sqrt(max(0,D(1,1)));
                    z2=imag(Circle)'*sd*sqrt(max(0,D(2,2)));
                    X=V*[z1;z2];
                    Circle = (X(1,:)'+real(H)) + 1i*(X(2,:)'+imag(H));
                else
                    Circle = NaN(size(Circle));
                end
            end
        end
    end
end


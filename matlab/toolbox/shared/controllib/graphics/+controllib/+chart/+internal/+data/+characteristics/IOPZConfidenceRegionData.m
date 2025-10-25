classdef IOPZConfidenceRegionData < controllib.chart.internal.data.characteristics.BaseCharacteristicData
    % controllib.chart.internal.data.IOPZConfidenceRegionData
    %   - class for computing confidence region data of a iopz response
    %
    % h = IOPZConfidenceRegionData(data)
    %   data   controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % Read-only Properties:
    %   ResponseData                response data object, controllib.chart.internal.data.response.BaseResponseDataSource
    %   Type                        type of characteristics, string scalar
    %   IsDirty                     flag if response needs to be computed, logical scalar
    %   NumberOfStandardDeviations  number of standard deviations for confidence
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
    
    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        IsValid
        NumberOfStandardDeviations
        EllipsePoleData
        EllipseZeroData
        RealAxisFocus
        ImaginaryAxisFocus
    end

    %% Constructor
    methods
        function this = IOPZConfidenceRegionData(data,numberOfSD)
            this@controllib.chart.internal.data.characteristics.BaseCharacteristicData(data);
            this.Type = "ConfidenceRegion";
            this.NumberOfStandardDeviations = numberOfSD;
        end
    end

    %% Public methods
    methods
        function update(this,numberOfSD)
            arguments
                this (1,1) controllib.chart.internal.data.characteristics.IOPZConfidenceRegionData
                numberOfSD (1,1) double = this.NumberOfStandardDeviations
            end
            update@controllib.chart.internal.data.characteristics.BaseCharacteristicData(this);
            this.NumberOfStandardDeviations = numberOfSD;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function compute_(this)
            data = this.ResponseData;

            nOutputs = data.NOutputs;
            nInputs = data.NInputs;
            nArray = data.NResponses;

            this.EllipseZeroData = repmat({repmat({},nOutputs,nInputs)},nArray);
            this.EllipsePoleData = repmat({repmat({},nOutputs,nInputs)},nArray);
            focus = repmat({[NaN NaN]},nOutputs,nInputs);
            this.RealAxisFocus = repmat({focus},nArray,1);
            this.ImaginaryAxisFocus = repmat({focus},nArray,1);

            for ka = 1:nArray
                % Compute covariance data
                [covZ,covP] = getZPKCovarianceData_(data.ModelValue,ka);
                if isempty(covZ) || isempty(covP)
                    this.IsValid(ka) = false;
                else
                    covarianceZeroData = cellfun(@(x) (this.NumberOfStandardDeviations)^2*x,covZ,UniformOutput=false);
                    covariancePoleData = cellfun(@(x) (this.NumberOfStandardDeviations)^2*x,covP,UniformOutput=false);

                    % Compute data to create ellipses
                    theta = [0:0.1:2*pi,0];
                    theta = theta(:);
                    circle = exp(1i*theta);
                    for ko = 1:nOutputs
                        for ki = 1:nInputs
                            zeros = data.Zeros{ko,ki,ka};
                            if isempty(zeros) || isempty(covarianceZeroData)
                                this.EllipseZeroData{ka}{ko,ki} = {};
                            else
                                for ct = 1:length(zeros)
                                    covarianceMatrix = squeeze(covarianceZeroData{ko,ki}(ct,:,:));
                                    ellipseData = this.transformCircle(zeros(ct),covarianceMatrix,1,circle);
                                    this.EllipseZeroData{ka}{ko,ki}{ct} = ellipseData;
                                    this.RealAxisFocus{ka}{ko,ki} = [min(this.RealAxisFocus{ka}{ko,ki}(1),min(real(ellipseData))),...
                                        max(this.RealAxisFocus{ka}{ko,ki}(2),max(real(ellipseData)))];
                                    this.ImaginaryAxisFocus{ka}{ko,ki} = [min(this.ImaginaryAxisFocus{ka}{ko,ki}(1),min(imag(ellipseData))),...
                                        max(this.ImaginaryAxisFocus{ka}{ko,ki}(2),max(imag(ellipseData)))];
                                end
                            end
                            poles = data.Poles{ko,ki,ka};
                            if isempty(poles) || isempty(covariancePoleData)
                                this.EllipsePoleData{ka}{ko,ki} = {};
                            else
                                for ct = 1:length(poles)
                                    covarianceMatrix = squeeze(covariancePoleData{ko,ki}(ct,:,:));
                                    ellipseData = this.transformCircle(poles(ct),covarianceMatrix,1,circle);
                                    this.EllipsePoleData{ka}{ko,ki}{ct} = ellipseData;
                                    this.RealAxisFocus{ka}{ko,ki} = [min(this.RealAxisFocus{ka}{ko,ki}(1),min(real(ellipseData))),...
                                        max(this.RealAxisFocus{ka}{ko,ki}(2),max(real(ellipseData)))];
                                    this.ImaginaryAxisFocus{ka}{ko,ki} = [min(this.ImaginaryAxisFocus{ka}{ko,ki}(1),min(imag(ellipseData))),...
                                        max(this.ImaginaryAxisFocus{ka}{ko,ki}(2),max(imag(ellipseData)))];
                                end
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


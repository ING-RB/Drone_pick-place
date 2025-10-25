classdef PZBoundResponseDataSource < controllib.chart.internal.data.response.BaseResponseDataSource
    % controllib.chart.internal.data.response.PZBoundResponseDataSource
    %   - base class for managing source and data objects for given pz bound response
    %   - inherited from controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % h = PZBoundResponseDataSource()
    %
    % h = PZBoundResponseDataSource(_____,Name-Value)
    %   MinDecay                minimum decay rate of poles, 0 (default)
    %   MinDamping              minimum damping ratio of poles, 0 (default)
    %   MaxFrequency            maximum natrual frequency of poles, Inf (default)
    %   Ts                      sample time of closed-loop system, 0 (default)
    %
    % Read-only properties:
    %   Type                  type of response for subclass, string
    %   ArrayDim              array dimensions of response data, double
    %   NResponses            number of elements of response data, double
    %   CharacteristicTypes   types of Characteristics, string
    %   Characteristics       characteristics of response data, controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %   MinDecay              minimum decay rate of poles, double
    %   MinDamping            minimum damping ratio of poles, double
    %   MaxFrequency          maximum natrual frequency of poles, double
    %   Ts                    sample time of closed-loop system, double
    %   SpectralRadius        spectral radius data of response, cell
    %   SpectralAbscissa      spectral abscissa data of response, cell
    %   RealAxisFocus         real axis focus of response, cell
    %   ImaginaryAxisFocus    imaginary axis focus of response, cell
    %   XLimits               x limits of pzplot axes, double
    %   YLimits               y limits of pzplot axes, double
    %   TimeUnit              time unit of Model, char
    %
    % Events:
    %   DataChanged           notified after update is called
    %
    % Public methods:
    %   update(this)
    %       Update the response data with new parameter values.
    %   getCharacteristics(this,characteristicType)
    %       Get characteristics corresponding to types.
    %
    % Protected methods (sealed):
    %   createCharacteristics(this)
    %       Create characteristics based on response data.
    %   updateCharacteristicsData(this,characteristicType)
    %       Update the characteristic data. Call in update().
    %
    % Protected methods (to override in subclass):
    %   createCharacteristics_(this)
    %       Create the characteristic data. Called in createCharacteristics().
    %   updateData(this,Name-Value)
    %       Update the response data. Called in update().
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.response.BaseResponseDataSource">controllib.chart.internal.data.response.BaseResponseDataSource</a>

    %   Copyright 2023-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        % "MinDecay": double scalar
        % Minimum decay rate of poles.
        MinDecay
        % "MinDamping": double scalar
        % Minimum damping ratio of poles.
        MinDamping
        % "MaxFrequency": double scalar
        % Maximum natrual frequency of poles.
        MaxFrequency
        % "Ts": double scalar
        % Sample time of closed-loop system.
        Ts
        % "SpectralRadius": cell scalar
        % Spectral radius data of response.
        SpectralRadius
        % "SpectralAbscissa": cell scalar
        % Spectral abscissa data of response.
        SpectralAbscissa
        % "RealAxisFocus": cell vector
        % Real axis focus data of response.
        RealAxisFocus
        % "ImaginaryAxisFocus": cell vector
        % Imaginary axis focus data of response.
        ImaginaryAxisFocus
        % "XLimits": 1x2 double
        % X limits of pzplot axes.
        XLimits = [0 1]
        % "YLimits": cell vector
        % Y limits of pzplot axes.
        YLimits = [0 1]
    end

    properties (Constant)
        % "TimeUnit": char array
        % Get TimeUnit of Model.
        TimeUnit = 'seconds'
    end

    %% Constructor
    methods
        function this = PZBoundResponseDataSource(pzBoundResponseOptionalInputs)
            arguments
                pzBoundResponseOptionalInputs.MinDecay = 0
                pzBoundResponseOptionalInputs.MinDamping = 0
                pzBoundResponseOptionalInputs.MaxFrequency = inf
                pzBoundResponseOptionalInputs.Ts = 0
            end
            this@controllib.chart.internal.data.response.BaseResponseDataSource();
            this.MinDecay = pzBoundResponseOptionalInputs.MinDecay;
            this.MinDamping = pzBoundResponseOptionalInputs.MinDamping;
            this.MaxFrequency = pzBoundResponseOptionalInputs.MaxFrequency;
            this.Ts = pzBoundResponseOptionalInputs.Ts;
            this.Type = "PZBoundResponse";

            % Update (build)
            update(this);
        end
    end

    %% Public methods
    methods
        function [commonRealAxisFocus, commonImaginaryAxisFocus, timeUnit] = getCommonFocusForMultipleData(this,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.PZBoundResponseDataSource
                arrayVisible (:,1) cell = repmat({true},length(this),1)
            end
            % Initialize variables
            commonRealAxisFocus = {[NaN,NaN]};
            commonImaginaryAxisFocus = {[NaN,NaN]};
            timeUnit = 'seconds';

            for k = 1:length(this) % loop for number of data objects
                if arrayVisible{k}
                    % Conversion Factor
                    cf = tunitconv(this(k).TimeUnit,timeUnit);

                    % Make sure focus includes unit circle for discrete systems
                    if this(k).Ts ~= 0
                        minRealAxisValue = -1;
                        maxRealAxisValue = 1;
                        minImaginaryAxisValue = -1;
                        maxImaginaryAxisValue = 1;
                    else
                        minRealAxisValue = NaN;
                        maxRealAxisValue = NaN;
                        minImaginaryAxisValue = NaN;
                        maxImaginaryAxisValue = NaN;
                    end

                    % Real Axis
                    realAxisFocus = (1/cf)*this(k).RealAxisFocus{1};
                    commonRealAxisFocus{1}(1) = ...
                        min([commonRealAxisFocus{1}(1),realAxisFocus(1),minRealAxisValue]);
                    commonRealAxisFocus{1}(2) = ...
                        max([commonRealAxisFocus{1}(2),realAxisFocus(2),maxRealAxisValue]);

                    % Imaginary Axis
                    imaginaryAxisFocus = (1/cf)*this(k).ImaginaryAxisFocus{1};
                    commonImaginaryAxisFocus{1}(1) = ...
                        min([commonImaginaryAxisFocus{1}(1),imaginaryAxisFocus(1),minImaginaryAxisValue]);
                    commonImaginaryAxisFocus{1}(2) = ...
                        max([commonImaginaryAxisFocus{1}(2),imaginaryAxisFocus(2),maxImaginaryAxisValue]);
                end
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,pzBoundResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.PZBoundResponseDataSource
                pzBoundResponseOptionalInputs.MinDecay = this.MinDecay
                pzBoundResponseOptionalInputs.MinDamping = this.MinDamping
                pzBoundResponseOptionalInputs.MaxFrequency = this.MaxFrequency
                pzBoundResponseOptionalInputs.Ts = this.Ts
            end
            this.MinDecay = pzBoundResponseOptionalInputs.MinDecay;
            this.MinDamping = pzBoundResponseOptionalInputs.MinDamping;
            this.MaxFrequency = pzBoundResponseOptionalInputs.MaxFrequency;
            this.Ts = pzBoundResponseOptionalInputs.Ts;
            if this.Ts == 0
                % MaxFrequency
                if isfinite(this.MaxFrequency)
                    theta = (pi/50) * (-50:50);
                    Circle =  this.MaxFrequency*exp(complex(0,theta));
                    Xmin = min(-this.MaxFrequency,this.XLimits(1));
                    Xmax = max(this.MaxFrequency,this.XLimits(2));
                    Ymax = max(this.MaxFrequency,this.YLimits(2));
                    XData = [Xmin real(Circle) Xmin Xmin Xmax Xmax Xmin];
                    YData = [0 imag(Circle) 0 Ymax Ymax -Ymax -Ymax];
                    this.SpectralRadius = {XData+YData*1i};
                else
                    this.SpectralRadius = {-this.MinDecay};
                end
                % MinDecay and MinDamping
                tau = tan(acos(this.MinDamping));
                Xmin = this.XLimits(1);
                Xmax = this.XLimits(2)+1;
                Ymax = this.YLimits(2);
                X1 = -this.MinDecay;  % abscissa of decay rate constraint
                X2 = -Ymax/tau;  % abscissa where damping ratio sector leaves box
                if X2<Xmin
                    XData = [X1,X1,Xmin,Xmin,Xmax,Xmax,Xmin,Xmin,X1,X1];
                    YData = [0,-tau*X1,-tau*Xmin,Ymax,Ymax,-Ymax,-Ymax,tau*Xmin,tau*X1,0];
                elseif X2<X1
                    XData = [X1,X1,X2,Xmax,Xmax,X2,X1,X1];
                    YData = [0,-tau*X1,Ymax,Ymax,-Ymax,-Ymax,tau*X1,0];
                else
                    XData = [X1,X1,Xmax,Xmax,X1];
                    YData = [-Ymax,Ymax,Ymax,-Ymax,-Ymax];
                end
                this.SpectralAbscissa = {XData+YData*1i};
            else
                % Discrete time
                wnTs = this.MaxFrequency * this.Ts;
                if wnTs<=pi
                    theta = (wnTs / 50) * (0:50);
                    rho = exp(-sqrt(wnTs^2-theta.^2));
                    theta = [theta fliplr(theta)];
                    rho = [rho fliplr(1./rho)];
                    z = rho .* exp(complex(0,theta));
                    z = [z fliplr(conj(z))];
                    Zmax = exp(wnTs);
                    Xmin = min(-1,this.XLimits(1));  
                    Xmax = max(Zmax,this.XLimits(2));
                    Ymax = max(1,this.YLimits(2));
                    XData = [Xmin real(z) Xmin Xmin Xmax Xmax Xmin];
                    YData = [0 imag(z) 0 -Ymax -Ymax Ymax Ymax];
                    this.SpectralRadius = {XData+YData*1i};
                else
                    this.SpectralRadius = {NaN};
                end
                % MinDecay and MinDamping
                theta = (pi/50) * (-50:50);
                rho = min(exp(-this.MinDecay*this.Ts),exp(-this.MinDamping/sqrt(1-this.MinDamping^2)*abs(theta)));
                z = rho .* exp(complex(0,theta));
                z([1 end]) = real(z([1 end]));
                Xmin = min(-1,this.XLimits(1));
                Xmax = max(1,this.XLimits(2));
                Ymax = max(1,this.YLimits(2));
                XData = [Xmin real(z) Xmin Xmin Xmax Xmax Xmin];
                YData = [0 imag(z) 0 Ymax Ymax -Ymax -Ymax];
                this.SpectralAbscissa = {XData+YData*1i};
            end

            % Compute Focus
            if this.Ts == 0
                if this.MinDecay ~= 0
                    this.RealAxisFocus = {[-this.MinDecay 0]};
                else
                    this.RealAxisFocus = {[-1e-20 0]};
                end
            else
                this.RealAxisFocus = {[-1 1]};
            end
            this.ImaginaryAxisFocus = {[-1 1]};
        end
    end

    %% Hidden TuningGoal methods
    methods (Hidden, Access= ?controllib.chart.response.internal.PZBoundResponse)
        function updateSpectralLimits(this,XLimits,YLimits)
            arguments
                this (1,1) controllib.chart.internal.data.response.PZBoundResponseDataSource
                XLimits (1,2) double
                YLimits (1,2) double
            end
            this.XLimits = XLimits;
            this.YLimits = YLimits;
            update(this);
        end
    end
end

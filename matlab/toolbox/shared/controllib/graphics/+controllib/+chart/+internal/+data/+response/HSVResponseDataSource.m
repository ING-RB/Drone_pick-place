classdef HSVResponseDataSource < controllib.chart.internal.data.response.BaseResponseDataSource
    % controllib.chart.internal.data.response.HSVResponseDataSource
    %   - manage source and data objects for given hsv response
    %   - inherited from controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % h = HSVResponseDataSource(R)
    %   R                     mor.GenericBTSpec
    %
    % Read-only / Internal properties (for subclasses):
    %   Type                  type of response for subclass, string
    %   ArrayDim              array dimensions of response data, double
    %   NResponses            number of elements of response data, double
    %   CharacteristicTypes   types of Characteristics, string
    %   Characteristics       characteristics of response data, controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %   R                     mor.GenericBTSpec for response data
    %   PlotType              type of HSV response to generate, string
    %   HSV                   hankel singular values for response, double
    %   ErrorBound            error bound values for response, double
    %   ErrorType             type of error for response, string
    %
    % Events:
    %   DataChanged           notified after update is called
    %
    % Public methods:
    %   update(this)
    %       Update the response data with new parameter values.
    %   getCharacteristics(this,characteristicType)
    %       Get characteristics corresponding to types.
    %   getCommonFocusForMultipleData(this,YAxisScale)
    %       Get focus values for an array of response data.
    %   getBaseValue(this,YAxisScale)
    %       Get base value of bar graph.
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

    %   Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        % "R": mor.GenericBTSpec scalar
        % GenericBTSpec object used to plot response.
        R
        % "HSVType": string scalar
        % Type of HSV response.
        HSVType
    end

    properties (Dependent,SetAccess=private)
        % "HSV": double vector
        % Hankel singular values for response.
        HSV
        % "ErrorBound": double vector
        % Error bound for response.
        ErrorBound
        % "ErrorType": string scalar
        % Error type for response.
        ErrorType
    end

    %% Constructor
    methods
        function this = HSVResponseDataSource(R,hsvOptionalInputs)
            arguments
                R
                hsvOptionalInputs.HSVType = "sigma";
            end
            this@controllib.chart.internal.data.response.BaseResponseDataSource();
            this.Type = 'HSVResponse';
            this.R = R;
            this.HSVType = hsvOptionalInputs.HSVType;

            % Update response
            update(this);
        end
    end

    %% Public methods
    methods
        function [orderAxisFocus, stateContributionAxisFocus] = getCommonFocusForMultipleData(this,YAxisScale,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.HSVResponseDataSource
                YAxisScale (1,1) string {mustBeMember(YAxisScale,["linear","log"])}
                arrayVisible (:,1) cell = arrayfun(@(x) {true},this)
            end
            orderAxisFocus = {[0,NaN]};
            stateContributionAxisFocus = {[NaN,NaN]};
            for k = 1:length(this)
                nsv = size(this(k).HSV,1);
                if this(k).HSVType == "loss"
                    orderAxisFocus{1}(1) = -1;
                    nsv = nsv-1;
                end
                if arrayVisible{k}
                    orderAxisFocus{1}(2) = max(orderAxisFocus{1}(2),nsv+1);
                    hsv = this(k).HSV;
                    baseValue = getBaseValue(this(k),YAxisScale);
                    if YAxisScale=="linear"
                        hsvf = hsv(isfinite(hsv));
                        if isempty(hsvf)
                            hsvmax = 10;
                        else
                            hsvmax = 1.25*max(hsvf);
                        end
                    else
                        hsvf = hsv(isfinite(hsv) & hsv>0);
                        if isempty(hsvf)
                            hsvmax = 100;
                        else
                            hsvmax = 3*max(hsvf);
                        end
                    end
                    % Get Y Axis Focus
                    hsvFocus = [baseValue hsvmax];
                    stateContributionAxisFocus{1}(1) = ...
                        min(stateContributionAxisFocus{1}(1),hsvFocus(1));
                    stateContributionAxisFocus{1}(2) = ...
                        max(stateContributionAxisFocus{1}(2),hsvFocus(2));
                end
            end
        end

        function baseValue = getBaseValue(this,YAxisScale)
            arguments
                this (1,1) controllib.chart.internal.data.response.HSVResponseDataSource
                YAxisScale (1,1) string {mustBeMember(YAxisScale,["linear","log"])}
            end
            if YAxisScale=="linear"
                baseValue = 0;
            else
                hsvf = this.HSV(isfinite(this.HSV) & this.HSV>0);
                if isempty(hsvf)
                    baseValue = 0.01;
                else
                    maxhsv = max(hsvf);
                    baseValue = max(0.3*min(hsvf),eps(maxhsv));
                end
            end
        end
    end

    %% Get/Set
    methods
        function HSV = get.HSV(this)
            switch this.HSVType
                case "sigma"
                    HSV = this.R.Sigma;
                case "energy"
                    HSV = this.R.Energy;
                case "loss"
                    HSV = [this.R.Loss; 0];
            end
        end

        function ErrorBound = get.ErrorBound(this)
            switch this.HSVType
                case "loss"
                    ErrorBound = [this.R.Error; 0; 0];
                otherwise
                    ErrorBound = [this.R.Error; 0];
            end
        end

        function ErrorType = get.ErrorType(this)
            switch class(this.R)
                case 'mor.BalancedTruncation'
                    ErrorType = string(this.R.Options.Goal);
                otherwise
                    ErrorType = "absolute";
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,hsvOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.HSVResponseDataSource
                hsvOptionalInputs.R = this.R
                hsvOptionalInputs.HSVType = this.HSVType
            end
            this.R = hsvOptionalInputs.R;
            this.HSVType = hsvOptionalInputs.HSVType;
        end
    end
end

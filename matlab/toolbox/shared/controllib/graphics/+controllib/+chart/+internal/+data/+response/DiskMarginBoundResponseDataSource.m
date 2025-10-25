classdef DiskMarginBoundResponseDataSource < controllib.chart.internal.data.response.BaseResponseDataSource
    % controllib.chart.internal.data.response.DiskMarginBoundResponseDataSource
    %   - manage source and data objects for given disk margin bound response
    %   - inherited from controllib.chart.internal.data.response.BaseResponseDataSource
    %
    % h = DiskMarginBoundResponseDataSource()
    %
    % h = DiskMarginBoundResponseDataSource(_____,Name-Value)
    %   BoundType             type of bound, "lower" (default) plots below response data
    %   Focus                 focus of Tuning Goal, [0 Inf] (default)
    %   GM                    gain margin of Tuning Goal, 7.6 (default)
    %   PM                    phase margin of Tuning Goal, 45 (default)
    %   Ts                    sample time of closed-loop system, 0 (default)
    %
    % Read-only properties:
    %   Type                  type of response for subclass, string
    %   ArrayDim              array dimensions of response data, double
    %   NResponses            number of elements of response data, double
    %   CharacteristicTypes   types of Characteristics, string
    %   Characteristics       characteristics of response data, controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %   BoundType             type of bound, string
    %   Focus                 focus of Tuning Goal, double
    %   GM                    gain margin of Tuning Goal, double
    %   PM                    phase margin of Tuning Goal, double
    %   Ts                    sample time of closed-loop system, double
    %   Frequency             frequency data of response, double
    %   GainMargin            gain margin data of response, double
    %   PhaseMargin           phase margin data of response, double
    %   FrequencyFocus        frequency focus of response, cell
    %   GainFocus             gain focus of response, cell
    %   PhaseFocus            phase focus of response, cell
    %
    % Events:
    %   DataChanged           notified after update is called
    %
    % Public methods:
    %   update(this)
    %       Update the response data with new parameter values.
    %   getCharacteristics(this,characteristicType)
    %       Get characteristics corresponding to types.
    %   getCommonFrequencyFocus(this,arrayVisible)
    %       Get frequency focus values for an array of response data.
    %   getCommonMagnitudeFocus(this,arrayVisible)
    %       Get magnitude focus values for an array of response data.
    %   getCommonPhaseFocus(this,arrayVisible)
    %       Get phase focus values for an array of response data.
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
    %   computeGainFocus(this)
    %       Compute the magnitude focus. Called in updateData().
    %   computePhaseFocus(this,frequencyFocuses)
    %       Compute the phase focus. Called in updateData().
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.response.BaseResponseDataSource">controllib.chart.internal.data.response.BaseResponseDataSource</a>

    % Copyright 2023-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        % "BoundType": string scalar
        % Type of response bound.
        BoundType
        % "Focus": 1x2 double
        % Frequency focus of Tuning Goal.
        Focus
        % "GM": double scalar
        % Gain margin of Tuning Goal in dB.
        GM
        % "PM": double scalar
        % Phase margin of Tuning Goal in deg.
        PM
        % "Ts": double scalar
        % Sample time of closed-loop system.
        Ts
        % "Frequency": double vector
        % Frequency data of response.
        Frequency
        % "GainMargin": double vector
        % Gain margin data of response.
        GainMargin
        % "PhaseMargin": double vector
        % Phase margin data of response.
        PhaseMargin
        % "FrequencyFocus": cell scalar
        % Frequency focus data of response.
        FrequencyFocus
        % "GainFocus": cell scalar
        % Gain focus data of response.
        GainFocus
        % "PhaseFocus": cell scalar
        % Phase focus data of response.
        PhaseFocus
    end

    %% Constructor
    methods
        function this = DiskMarginBoundResponseDataSource(diskMarginBoundResponseOptionalInputs)
            arguments
                diskMarginBoundResponseOptionalInputs.BoundType = "lower"
                diskMarginBoundResponseOptionalInputs.Focus = [0 Inf]
                diskMarginBoundResponseOptionalInputs.GM = 7.6
                diskMarginBoundResponseOptionalInputs.PM = 45
                diskMarginBoundResponseOptionalInputs.Ts = 0
            end
            this@controllib.chart.internal.data.response.BaseResponseDataSource();
            this.Type = "DiskMarginBoundResponse";

            this.BoundType = diskMarginBoundResponseOptionalInputs.BoundType;
            this.GM = diskMarginBoundResponseOptionalInputs.GM;
            this.PM = diskMarginBoundResponseOptionalInputs.PM;
            this.Ts = diskMarginBoundResponseOptionalInputs.Ts;
            this.Focus = diskMarginBoundResponseOptionalInputs.Focus;

            % Update response
            update(this);
        end
    end

    %% Public methods
    methods
        function [commonFrequencyFocus,frequencyUnit] = getCommonFrequencyFocus(this,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.DiskMarginBoundResponseDataSource
                arrayVisible (:,1) cell = repmat({true},length(this),1)
            end
            commonFrequencyFocus = {[NaN,NaN]};
            frequencyUnit = 'rad/s';
            for k = 1:length(this) % loop for number of data objects
                % Frequency Focus
                if arrayVisible{k}
                    frequencyFocus = this(k).FrequencyFocus{1};
                    commonFrequencyFocus{1}(1) = ...
                        min(commonFrequencyFocus{1}(1),frequencyFocus(1));
                    commonFrequencyFocus{1}(2) = ...
                        max(commonFrequencyFocus{1}(2),frequencyFocus(2));
                end
            end
        end

        function [commonGainFocus,gainUnit] = getCommonGainFocus(this,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.DiskMarginBoundResponseDataSource
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            commonGainFocus = {[NaN,NaN]};
            gainUnit = 'dB';
            for k = 1:length(this) % loop for number of data objects
                % Gain Focus
                if arrayVisible{k}
                    gainFocus = this(k).GainFocus{1};
                    commonGainFocus{1}(1) = ...
                        min(commonGainFocus{1}(1),gainFocus(1));
                    commonGainFocus{1}(2) = ...
                        max(commonGainFocus{1}(2),gainFocus(2));
                end
            end
        end

        function [commonPhaseFocus,phaseUnit] = getCommonPhaseFocus(this,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.DiskMarginBoundResponseDataSource
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            commonPhaseFocus = {[NaN,NaN]};
            phaseUnit = 'deg';
            for k = 1:length(this) % loop for number of data objects
                % Phase Focus
                if arrayVisible{k}
                    phaseFocus = this(k).PhaseFocus{1};
                    commonPhaseFocus{1}(1) = ...
                        min(commonPhaseFocus{1}(1),phaseFocus(1));
                    commonPhaseFocus{1}(2) = ...
                        max(commonPhaseFocus{1}(2),phaseFocus(2));
                end
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,diskMarginBoundResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.DiskMarginBoundResponseDataSource
                diskMarginBoundResponseOptionalInputs.BoundType = this.BoundType
                diskMarginBoundResponseOptionalInputs.GM = this.GM
                diskMarginBoundResponseOptionalInputs.PM = this.PM
                diskMarginBoundResponseOptionalInputs.Ts = this.Ts
                diskMarginBoundResponseOptionalInputs.Focus = this.Focus
            end
            this.BoundType = diskMarginBoundResponseOptionalInputs.BoundType;
            this.GM = diskMarginBoundResponseOptionalInputs.GM;
            this.PM = diskMarginBoundResponseOptionalInputs.PM;
            this.Ts = diskMarginBoundResponseOptionalInputs.Ts;
            this.Focus = diskMarginBoundResponseOptionalInputs.Focus;

            w = [0 ; min([Inf,pi/this.Ts])];
            focus = [0.1,10];  % default
            if this.Focus(1)>w(1) || this.Focus(2)<w(2)
                if this.Focus(1)>w(1)
                    w = [this.Focus(1) ; w(2)];
                end
                if this.Focus(2)<w(2)
                    w = [w(1) ; this.Focus(2)];
                end
                fMin = 0.9*max(this.Focus(1),w(1));
                fMax = 1.1*min(this.Focus(2),w(2));
                Span = min(100,fMax/fMin);
                if focus(1)<fMin
                    focus = [fMin fMin*Span];  % Slide right
                elseif focus(2)>fMax
                    focus = [fMax/Span fMax];  % Slide left
                end
            end
            this.Frequency = w;
            this.GainMargin = [this.GM;this.GM];
            this.PhaseMargin = [this.PM;this.PM];
            this.FrequencyFocus = {focus};
            this.GainFocus = computeGainFocus(this);
            this.PhaseFocus = computePhaseFocus(this);
        end
        function gainFocus = computeGainFocus(this)
            gainFocus = {[NaN, NaN]};
            value = db2mag(this.GM);
            if value == 0 || isnan(value)
                gainFocus{1}(2) = 1.1;
            else
                absValue = abs(value);
                gainFocus{1}(2) = value + 0.1*absValue;
            end
            gainFocus{1}(1) = 0;
            gainFocus{1}(2) = mag2db(min(100,max(gainFocus{1}(2),5)));
        end
        function phaseFocus = computePhaseFocus(this)
            phaseFocus = {[NaN, NaN]};
            value = this.PM;
            if value == 0 || isnan(value)
                phaseFocus{1}(1) = -0.1;
                phaseFocus{1}(2) = 0.1;
            else
                absValue = abs(value);
                phaseFocus{1}(1) = value - 0.1*absValue;
                phaseFocus{1}(2) = value + 0.1*absValue;
            end
            phaseFocus{1}(1) = max(0,10*floor(phaseFocus{1}(1)/10));
            phaseFocus{1}(2) = min(180,10*ceil(phaseFocus{1}(2)/10));
        end
    end
end



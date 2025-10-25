classdef DiskMarginSigmaResponseDataSource < controllib.chart.internal.data.response.DiskMarginResponseDataSource
    % controllib.chart.internal.data.response.DiskMarginSigmaResponseDataSource
    %   - manage source and data objects for given disk margin sigma response
    %   - inherited from controllib.chart.internal.data.response.DiskMarginResponseDataSource
    %
    % h = DiskMarginSigmaResponseDataSource(model)
    %
    % h = DiskMarginSigmaResponseDataSource(_____,Name-Value)
    %   Frequency             frequency specification used to generate data, [] (default) auto generates frequency specification
    %   Skew                  skew of uncertainty region used to compute the stability margins, 0 (default)
    %
    % Read-only properties:
    %   Type                  type of response for subclass, string
    %   ArrayDim              array dimensions of response data, double
    %   NResponses            number of elements of response data, double
    %   CharacteristicTypes   types of Characteristics, string
    %   Characteristics       characteristics of response data, controllib.chart.internal.data.characteristics.BaseCharacteristicData
    %   NInputs               number of inputs in Model, double
    %   NOutputs              number of outputs in Model, double
    %   IsDiscrete            logical value to specify if Model is discrete
    %   IsReal                logical array to specify if Model is real
    %   FrequencyInput        frequency specification used to generate data, double or cell
    %   Frequency             frequency data of response, cell
    %   FrequencyFocus        frequency focus of response, cell
    %   FrequencyUnit         frequency unit of Model, char
    %
    % Read-only / Internal properties:
    %   Model                 Dynamic system of response
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
    % Public methods (sealed):
    %   getCommonFrequencyFocus(this,frequencyScale,arrayVisible)
    %       Get frequency focus values for an array of response data.
    %   getCommonGainFocus(this,commonFrequencyFocus,gainScale,arrayVisible)
    %       Get magnitude focus values for an array of response data.
    %   getCommonPhaseFocus(this,commonFrequencyFocus,arrayVisible)
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
    %   computeGainFocus(this,frequencyFocuses,magnitudeScale)
    %       Compute the gain focus. Called in getCommonGainFocus().
    %   computePhaseFocus(this,frequencyFocuses)
    %       Compute the phase focus. Called in getCommonPhaseFocus().
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.response.DiskMarginResponseDataSource">controllib.chart.internal.data.response.DiskMarginResponseDataSource</a>

    % Copyright 2023-2024 The MathWorks, Inc.

    %% Constructor
    methods
        function this = DiskMarginSigmaResponseDataSource(varargin)
            this@controllib.chart.internal.data.response.DiskMarginResponseDataSource(varargin{:});
            this.Type = "DiskMarginSigmaResponse";
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,diskMarginResponseOptionalInputs,frequencyResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.DiskMarginSigmaResponseDataSource
                diskMarginResponseOptionalInputs.Skew = this.Skew
                diskMarginResponseOptionalInputs.IsStable = this.IsStable
                frequencyResponseOptionalInputs.Frequency = this.FrequencyInput
                frequencyResponseOptionalInputs.Model = this.Model
            end
            frequencyResponseOptionalInputs = namedargs2cell(frequencyResponseOptionalInputs);
            updateData@controllib.chart.internal.data.response.FrequencyResponseDataSource(this,frequencyResponseOptionalInputs{:});
            this.Skew = diskMarginResponseOptionalInputs.Skew;
            this.IsStable = diskMarginResponseOptionalInputs.IsStable;
            this.DiskMargin = repmat({NaN},this.NResponses,1);
            this.GainMargin = repmat({NaN},this.NResponses,1);
            this.PhaseMargin = repmat({NaN},this.NResponses,1);
            this.Frequency = repmat({NaN},this.NResponses,1);
            this.FrequencyFocus = repmat({{[NaN NaN]}},this.NResponses,1);
            try
                for ka = 1:this.NResponses
                    % Compute disk margin as a function of frequency
                    % Used by TuningGoal.Margins
                    [nL,~] = size(this.ModelValue(:,:,ka));
                    M = kron([(1+this.Skew)/2 1;-1 -1],eye(nL));
                    Se = lft(createGain(this.ModelData(ka),M),this.ModelData(ka),nL+1:2*nL,nL+1:2*nL,1:nL,1:nL);
                    if isa(this.ModelData(ka),'ltipack.frddata')
                        stable = true;
                    else
                        stable = this.IsStable;
                        if isempty(stable)
                            stable = isstable(Se);
                        else
                            stable = stable(ka);
                        end
                    end
                    if stable
                        [sv,w,focus] = sigmaresp(Se,0,this.FrequencyInput,true);
                        alpha = 1./sv(1,:)';
                    else
                        focus = struct();
                        focus.Focus = ltipack.getFreqFocus(this.FrequencyInput,this.ModelData(ka).Ts,'log'); % 1x2, may contain NaNs
                        AutoFocus = any(isnan(focus.Focus));
                        if isempty(this.FrequencyInput) || iscell(this.FrequencyInput)
                            % No frequency grid specified
                            if AutoFocus
                                w = logspace(-20,min(20,log10(pi/this.ModelData(ka).Ts)),10)';
                            else
                                w = logspace(log10(focus.Focus(1)),log10(focus.Focus(2)),10)';
                            end
                        else
                            % User-defined grid
                            w = this.FrequencyInput(:);  w = w(w>=0);
                        end
                        alpha = zeros(size(w));
                    end
                    % Compute gain and phase margin data to plot
                    [gainMargin,phaseMargin,alpha] = dm2gmPlot(alpha,this.Skew);
                    this.DiskMargin{ka} = alpha;
                    this.GainMargin{ka} = gainMargin;
                    if all(gainMargin(:)==0)
                        this.PhaseMargin{ka} = NaN(size(phaseMargin));
                    else
                        this.PhaseMargin{ka} = phaseMargin;
                    end
                    this.Frequency{ka} = w;

                    % Round focus if frequency grid is automatically computed
                    roundedFocus = focus.Focus;
                    if isempty(this.FrequencyInput)
                        roundedFocus(1) = 10^floor(log10(roundedFocus(1)));
                        roundedFocus(2) = 10^ceil(log10(roundedFocus(2)));
                    end

                    % Remove NaNs from focus
                    if any(isnan(roundedFocus))
                        % Check if focus contains NaN
                        roundedFocus = [1 10];
                    elseif roundedFocus(1) >= roundedFocus(2)
                        % Check if focus is not monotonically increasing
                        roundedFocus(1) = roundedFocus(1) - 0.1*abs(roundedFocus(1));
                        roundedFocus(2) = roundedFocus(2) + 0.1*abs(roundedFocus(2));
                    end
                    this.FrequencyFocus{ka} = roundedFocus;
                end
            catch ME
                this.DataException = ME;
            end
        end
    end
end



classdef BodeResponseDataSource < controllib.chart.internal.data.response.FrequencyResponseDataSource
   % controllib.chart.internal.data.response.BodeResponseDataSource
   %   - manage source and data objects for given bode response
   %   - inherited from controllib.chart.internal.data.response.FrequencyResponseDataSource
   %
   % h = BodeResponseDataSource(model)
   %   model           DynamicSystem
   %
   % h = BodeResponseDataSource(_____,Name-Value)
   %   Frequency                   frequency specification used to generate data, [] (default) auto generates frequency specification
   %   NumberOfStandardDeviations  number of SDs for confidence region, 1 (default)
   %
   % Read-only properties:
   %   Type                        type of response for subclass, string
   %   ArrayDim                    array dimensions of response data, double
   %   NResponses                  number of elements of response data, double
   %   CharacteristicTypes         types of Characteristics, string
   %   Characteristics             characteristics of response data, controllib.chart.internal.data.characteristics.BaseCharacteristicData
   %   NInputs                     number of inputs in Model, double
   %   NOutputs                    number of outputs in Model, double
   %   IsDiscrete                  logical value to specify if Model is discrete
   %   IsReal                      logical array to specify if Model is real
   %   FrequencyInput              frequency specification used to generate data, double or cell
   %   Frequency                   frequency data of response, cell
   %   FrequencyFocus              frequency focus of response, cell
   %   FrequencyUnit               frequency unit of Model, char
   %   Magnitude                   magnitude for response, cell
   %   Phase                       phase for response, cell
   %   NumberOfStandardDeviations  number of SDs for confidence region, double
   %   BodePeakResponse            peak response characteristic, controllib.chart.internal.data.characteristics.FrequencyPeakResponseData
   %   AllStabilityMargin          all stability margin characteristic (only for siso), controllib.chart.internal.data.characteristics.FrequencyAllStabilityMarginData
   %   MinimumStabilityMargin      min stability margin characteristic (only for siso), controllib.chart.internal.data.characteristics.FrequencyMinimumStabilityMarginData
   %   ConfidenceRegion            confidence region characteristic (only for ident), controllib.chart.internal.data.characteristics.BodeConfidenceRegionData
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
   %   getCommonFrequencyFocus(this,frequencyScale,arrayVisible)
   %       Get frequency focus values for an array of response data.
   %   getCommonMagnitudeFocus(this,commonFrequencyFocus,magnitudeScale,arrayVisible)
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
   %   computeMagnitudeFocus(this,frequencyFocuses,magnitudeScale)
   %       Compute the magnitude focus. Called in getCommonMagnitudeFocus().
   %   computePhaseFocus(this,frequencyFocuses)
   %       Compute the phase focus. Called in getCommonPhaseFocus().
   %
   % See Also:
   %   <a href="matlab:help controllib.chart.internal.data.response.FrequencyResponseDataSource">controllib.chart.internal.data.response.FrequencyResponseDataSource</a>

   % Copyright 2021-2024 The MathWorks, Inc.

   %% Properties
   properties (SetAccess = protected)
      % "Magnitude": cell vector
      % Magnitude for response.
      Magnitude
      % "Phase": cell vector
      % Phase for response.
      Phase
      % "NumberOfStandardDeviations": double scalar
      % Number of standard deviations for confidence region.
      NumberOfStandardDeviations
   end

   properties (Dependent,SetAccess=private)
      % "BodePeakResponse": controllib.chart.internal.data.characteristics.FrequencyPeakResponseData scalar
      % Peak response characteristic.
      BodePeakResponse
      % "AllStabilityMargin": controllib.chart.internal.data.characteristics.FrequencyAllStabilityMarginData scalar
      % All stability margin characteristic.
      AllStabilityMargin
      % "MinimumStabilityMargin": controllib.chart.internal.data.characteristics.FrequencyMinimumStabilityMarginData scalar
      % Minimum stability margin characteristic.
      MinimumStabilityMargin
      % "ConfidenceRegion": controllib.chart.internal.data.characteristics.BodeConfidenceRegionData scalar
      % Confidence region characteristic.
      ConfidenceRegion
      % "WrappedPhase": cell vector
      % Wrapped phase for response.
      WrappedPhase
      % "MatchedPhase": cell vector
      % Matched phase for response.
      MatchedPhase
      % "WrappedAndMatchedPhase": cell vector
      % Wrapped and matched phase for response.
      WrappedAndMatchedPhase
   end

   properties (SetAccess=?controllib.chart.response.BodeResponse)
      PhaseWrappingBranch
      PhaseMatchingFrequency
      PhaseMatchingValue
   end

   %% Constructor
   methods
      function this = BodeResponseDataSource(model,bodeResponseOptionalArguments,frequencyResponseOptionalInputs)
         arguments
            model
            bodeResponseOptionalArguments.NumberOfStandardDeviations = 1
            bodeResponseOptionalArguments.PhaseWrappingBranch = -180
            bodeResponseOptionalArguments.PhaseMatchingFrequency = 0
            bodeResponseOptionalArguments.PhaseMatchingValue = 0
            frequencyResponseOptionalInputs.Frequency = []
         end
         frequencyResponseOptionalInputs = namedargs2cell(frequencyResponseOptionalInputs);
         this@controllib.chart.internal.data.response.FrequencyResponseDataSource(model,frequencyResponseOptionalInputs{:});
         this.Type = "BodeResponse";
         this.NumberOfStandardDeviations = bodeResponseOptionalArguments.NumberOfStandardDeviations;

         this.PhaseWrappingBranch = bodeResponseOptionalArguments.PhaseWrappingBranch;
         this.PhaseMatchingFrequency = bodeResponseOptionalArguments.PhaseMatchingFrequency;
         this.PhaseMatchingValue = bodeResponseOptionalArguments.PhaseMatchingValue;
         % Update response
         update(this);
      end
   end

   %% Public methods
   methods
      function [commonFrequencyFocus,frequencyUnit] = getCommonFrequencyFocus(this,frequencyScale,optionalInputs)
         arguments
            this (:,1) controllib.chart.internal.data.response.BodeResponseDataSource
            frequencyScale (1,1) string {mustBeMember(frequencyScale,["linear","log"])}
            optionalInputs.MinimumStabilityMarginsVisible (1,1) logical = false
            optionalInputs.AllStabilityMarginsVisible (1,1) logical = false
            optionalInputs.ArrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
         end
         optionalInputs = namedargs2cell(optionalInputs);
         [commonFrequencyFocus,frequencyUnit] = getCommonFrequencyFocus@controllib.chart.internal.data.response.FrequencyResponseDataSource(this,optionalInputs{:});
         if frequencyScale=="linear" && any(arrayfun(@(x) ~all(x.IsReal),this))
            commonFrequencyFocus{1}(1) = -commonFrequencyFocus{1}(2); %mirror focus
         end
      end

      function [commonMagnitudeFocus,magnitudeUnit] = getCommonMagnitudeFocus(this,commonFrequencyFocus,magnitudeScale,optionalInputs)
         arguments
            this (:,1) controllib.chart.internal.data.response.BodeResponseDataSource
            commonFrequencyFocus (:,:) cell
            magnitudeScale (1,1) string {mustBeMember(magnitudeScale,["linear","log"])}
            optionalInputs.ConfidenceRegionVisible (1,1) logical = false
            optionalInputs.BoundaryRegionVisible (1,1) logical = false
            optionalInputs.ArrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
         end
         csz = getCommonResponseSize(this);
         commonMagnitudeFocus = repmat({[NaN,NaN]},csz);
         magnitudeUnit = 'abs';
         BVis = optionalInputs.BoundaryRegionVisible;
         CVis = optionalInputs.ConfidenceRegionVisible;
         for k = 1:length(this) % loop for number of data objects
            magnitudeFocuses = computeMagnitudeFocus(this(k),commonFrequencyFocus,magnitudeScale);
            if CVis && ~isempty(this(k).ConfidenceRegion) && any(this(k).ConfidenceRegion.IsValid)
               crMagnitudeFocuses = computeMagnitudeFocus(this(k).ConfidenceRegion,commonFrequencyFocus,magnitudeScale);
            end
            if BVis && ~isempty(getCharacteristics(this(k),"BoundaryRegion"))
               br = getCharacteristics(this(k),"BoundaryRegion");
               brMagnitudeFocuses = computeMagnitudeFocus(br,commonFrequencyFocus,magnitudeScale);
            end

            iPlot = getResponseIndices(this(k));
            for ka = 1:this(k).NResponses % loop for system array
               if optionalInputs.ArrayVisible{k}(ka)
                  for kch = 1:numel(iPlot)
                     kr = iPlot(kch);
                     magnitudeFocus = magnitudeFocuses{ka}{kch};
                     commonMagnitudeFocus{kr}(1) = min(commonMagnitudeFocus{kr}(1),magnitudeFocus(1));
                     commonMagnitudeFocus{kr}(2) = max(commonMagnitudeFocus{kr}(2),magnitudeFocus(2));
                     if CVis && ~isempty(this(k).ConfidenceRegion) && this(k).ConfidenceRegion.IsValid
                        magnitudeFocus = crMagnitudeFocuses{ka}{kch};
                        commonMagnitudeFocus{kr}(1) = min(commonMagnitudeFocus{kr}(1),magnitudeFocus(1));
                        commonMagnitudeFocus{kr}(2) = max(commonMagnitudeFocus{kr}(2),magnitudeFocus(2));
                     end
                     if BVis && ~isempty(getCharacteristics(this(k),"BoundaryRegion"))
                        magnitudeFocus = brMagnitudeFocuses{kch};
                        commonMagnitudeFocus{kr}(1) = ...
                           min(commonMagnitudeFocus{kr}(1),magnitudeFocus(1));
                        commonMagnitudeFocus{kr}(2) = ...
                           max(commonMagnitudeFocus{kr}(2),magnitudeFocus(2));
                     end
                  end

               end
            end
         end
      end

      function [commonPhaseFocus,phaseUnit] = getCommonPhaseFocus(this,commonFrequencyFocus,optionalInputs)
         arguments
            this (:,1) controllib.chart.internal.data.response.BodeResponseDataSource
            commonFrequencyFocus (:,:) cell
            optionalInputs.ConfidenceRegionVisible (1,1) logical = false
            optionalInputs.BoundaryRegionVisible (1,1) logical = false
            optionalInputs.ArrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            optionalInputs.PhaseWrappingEnabled (1,1) logical = false
            optionalInputs.PhaseMatchingEnabled (1,1) logical = false
         end
         csz = getCommonResponseSize(this);
         commonPhaseFocus = repmat({[NaN,NaN]},csz);
         phaseUnit = 'rad';
         BVis = optionalInputs.BoundaryRegionVisible;
         CVis = optionalInputs.ConfidenceRegionVisible;

         for k = 1:length(this) % loop for number of data objects
            phaseFocuses = computePhaseFocus(this(k),commonFrequencyFocus,...
               optionalInputs.PhaseWrappingEnabled,optionalInputs.PhaseMatchingEnabled);
            if CVis && ~isempty(this(k).ConfidenceRegion) && this(k).ConfidenceRegion.IsValid
               crPhaseFocuses = computePhaseFocus(this(k).ConfidenceRegion,commonFrequencyFocus,...
                  optionalInputs.PhaseWrappingEnabled,optionalInputs.PhaseMatchingEnabled);
            end
            if BVis && ~isempty(getCharacteristics(this(k),"BoundaryRegion"))
               br = getCharacteristics(this(k),"BoundaryRegion");
               brPhaseFocuses = computePhaseFocus(br,commonFrequencyFocus,...
                  optionalInputs.PhaseWrappingEnabled,optionalInputs.PhaseMatchingEnabled);
            end

            iPlot = getResponseIndices(this(k));
            for ka = 1:this(k).NResponses % loop for system array
               if optionalInputs.ArrayVisible{k}(ka)
                  for kch = 1:numel(iPlot)
                     kr = iPlot(kch);
                     % Magnitude Focus
                     phaseFocus = phaseFocuses{ka}{kch};
                     commonPhaseFocus{kr}(1) = min(commonPhaseFocus{kr}(1),phaseFocus(1));
                     commonPhaseFocus{kr}(2) = max(commonPhaseFocus{kr}(2),phaseFocus(2));
                     if CVis && ~isempty(this(k).ConfidenceRegion) && this(k).ConfidenceRegion.IsValid
                        phaseFocus = crPhaseFocuses{ka}{kch};
                        commonPhaseFocus{kr}(1) = min(commonPhaseFocus{kr}(1),phaseFocus(1));
                        commonPhaseFocus{kr}(2) = max(commonPhaseFocus{kr}(2),phaseFocus(2));
                     end
                     if BVis && ~isempty(getCharacteristics(this(k),"BoundaryRegion"))
                        phaseFocus = brPhaseFocuses{kch};
                        commonPhaseFocus{kr}(1) = min(commonPhaseFocus{kr}(1),phaseFocus(1));
                        commonPhaseFocus{kr}(2) = max(commonPhaseFocus{kr}(2),phaseFocus(2));
                     end
                  end
               end
            end
         end
      end
   end

   %% Get/Set methods
   methods
      % BodePeakResponse
      function BodePeakResponse = get.BodePeakResponse(this)
         arguments
            this (1,1) controllib.chart.internal.data.response.BodeResponseDataSource
         end
         BodePeakResponse = getCharacteristics(this,"FrequencyPeakResponse");
      end

      % AllStabilityMargin
      function AllStabilityMargin = get.AllStabilityMargin(this)
         arguments
            this (1,1) controllib.chart.internal.data.response.BodeResponseDataSource
         end
         AllStabilityMargin = getCharacteristics(this,"AllStabilityMargins");
      end

      % MinimumStabilityMargin
      function MinimumStabilityMargin = get.MinimumStabilityMargin(this)
         arguments
            this (1,1) controllib.chart.internal.data.response.BodeResponseDataSource
         end
         MinimumStabilityMargin = getCharacteristics(this,"MinimumStabilityMargins");
      end

      % ConfidenceRegion
      function ConfidenceRegion = get.ConfidenceRegion(this)
         arguments
            this (1,1) controllib.chart.internal.data.response.BodeResponseDataSource
         end
         ConfidenceRegion = getCharacteristics(this,"ConfidenceRegion");
      end

      % NumberOfStandardDeviations
      function set.NumberOfStandardDeviations(this,NumberOfStandardDeviations)
         arguments
            this (1,1) controllib.chart.internal.data.response.BodeResponseDataSource
            NumberOfStandardDeviations
         end
         this.NumberOfStandardDeviations = NumberOfStandardDeviations;
         if ~isempty(this.ConfidenceRegion) %#ok<MCSUP>
            update(this.ConfidenceRegion,NumberOfStandardDeviations); %#ok<MCSUP>
         end
      end

      %WrappedPhase
      function WrappedPhase = get.WrappedPhase(this)
         WrappedPhase = computeWrappedPhase(this,this.Phase);
      end

      %MatchedPhase
      function MatchedPhase = get.MatchedPhase(this)
         MatchedPhase = computeMatchedPhase(this,this.Phase);
      end

      %WrappedAndMatchedPhase
      function WrappedAndMatchedPhase = get.WrappedAndMatchedPhase(this)
         wrappedPhase = computeWrappedPhase(this,this.Phase);
         WrappedAndMatchedPhase = computeMatchedPhase(this,wrappedPhase);
      end
   end

   %% Protected methods
   methods (Access = protected)
      function varargout = computeResponse(this, ka)
         [varargout{1:nargout}] = getMagPhaseData_(this.ModelValue,...
                                        this.FrequencyInput,"bode",ka);
      end

      function updateData(this,bodeResponseOptionalArguments,frequencyResponseOptionalInputs)
         arguments
            this (1,1) controllib.chart.internal.data.response.BodeResponseDataSource
            bodeResponseOptionalArguments.NumberOfStandardDeviations = this.NumberOfStandardDeviations
            frequencyResponseOptionalInputs.Model = this.Model
            frequencyResponseOptionalInputs.Frequency = this.FrequencyInput
         end
         try
            sysList.System = frequencyResponseOptionalInputs.Model;
            ParamList = {frequencyResponseOptionalInputs.Frequency};
            [sysList,w] = DynamicSystem.checkBodeInputs(sysList,ParamList);
            frequencyResponseOptionalInputs.Model = sysList.System;
            frequencyResponseOptionalInputs.Frequency = w;
            if isempty(sysList.System)
               error(message('Controllib:plots:PlotEmptyModel'))
            end
         catch ME
            this.DataException = ME;
         end
         
         frequencyResponseOptionalInputs = namedargs2cell(frequencyResponseOptionalInputs);
         updateData@controllib.chart.internal.data.response.FrequencyResponseDataSource(this,frequencyResponseOptionalInputs{:});
         sz = getResponseSize(this);
         this.NumberOfStandardDeviations = bodeResponseOptionalArguments.NumberOfStandardDeviations;
         this.Magnitude = repmat({NaN(sz)},this.NResponses,1);
         this.Phase = repmat({NaN(sz)},this.NResponses,1);
         this.Frequency = repmat({NaN},this.NResponses,1);
         focus = repmat({[NaN NaN]},sz);
         this.FrequencyFocus = repmat({focus},this.NResponses,1);
         isFrequencyFocusSoft = false(sz);
         this.IsFrequencyFocusSoft = repmat({isFrequencyFocusSoft},this.NResponses,1);
         if ~isempty(this.DataException)
            return;
         end
         try
            for ka = 1:this.NResponses
               [mag,phase,w,focus] = computeResponse(this, ka);
               if size(mag,3) == 0 %idnlmodel idpoly
                  mag = NaN(size(mag,1),size(mag,2),1);
                  phase = NaN(size(phase,1),size(phase,2),1);
               end
               this.Magnitude{ka} = mag;
               zeroMag = (iscell(mag) && all(cellfun(@(x)all(x(:)==0),mag))) || (isnumeric(mag) && all(mag(:)==0));
               if zeroMag
                  this.Phase{ka} = NaN(size(phase));
               else
                  this.Phase{ka} = phase;
               end
               this.Frequency{ka} = w;

               % Round focus if frequency grid is automatically computed
               roundedFocus = focus.Focus;
               roundUpperFocus = false;
               roundLowerFocus = false;
               if isempty(this.FrequencyInput)
                  roundUpperFocus = true;
                  roundLowerFocus = true;
               elseif iscell(this.FrequencyInput)
                  if isinf(this.FrequencyInput{2})
                     roundUpperFocus = true;
                  else
                     roundedFocus(2) = this.FrequencyInput{2};
                  end
                  if this.FrequencyInput{1} == 0
                     roundLowerFocus = true;
                  else
                     roundedFocus(1) = this.FrequencyInput{1};
                  end
               end

               if roundLowerFocus
                  roundedFocus(1) = 10^floor(log10(roundedFocus(1)));
               end
               if roundUpperFocus
                  roundedFocus(2) = 10^ceil(log10(roundedFocus(2)));
               end

               % Remove NaNs from focus
               if isequal(isnan(roundedFocus),[true,false])
                  roundedFocus(1) = 10^floor(log10(roundedFocus(2)/10));
               elseif isequal(isnan(roundedFocus),[false,true])
                  roundedFocus(2) = 10^ceil(log10(roundedFocus(1)*10));
               elseif isequal(isnan(roundedFocus),[true,true])
                  if this.IsDiscrete
                     nyquistFreq = pi/abs(this.Model.Ts);
                     roundedFocus = [1 10^ceil(log10(nyquistFreq))];
                  else
                     % Check if focus contains NaN
                     roundedFocus = [1 10];
                  end
               elseif roundedFocus(1) >= roundedFocus(2)
                  if isvector(this.FrequencyInput) && all(this.FrequencyInput==roundedFocus(1))
                     % If frequency vector is just a single
                     % frequency
                     roundedFocus(2) = 2*roundedFocus(1);
                     roundedFocus(1) = roundedFocus(1)/2;
                  else
                     roundedFocus(1) = roundedFocus(1) - 0.1*abs(roundedFocus(1));
                     roundedFocus(2) = roundedFocus(2) + 0.1*abs(roundedFocus(2));
                  end
               end
               this.FrequencyFocus{ka} = repmat({roundedFocus},sz);
               this.IsFrequencyFocusSoft{ka} = repmat(focus.Soft,sz);
            end
         catch ME
            this.DataException = ME;
         end
      end

      function characteristics = createCharacteristics_(this)
         arguments
            this (1,1) controllib.chart.internal.data.response.BodeResponseDataSource
         end
         characteristics = controllib.chart.internal.data.characteristics.FrequencyPeakResponseData(this);
         if this.NInputs == 1 && this.NOutputs == 1
            c1 = controllib.chart.internal.data.characteristics.FrequencyAllStabilityMarginData(this);
            c2 = controllib.chart.internal.data.characteristics.FrequencyMinimumStabilityMarginData(this);
            characteristics = [characteristics,c1,c2];
         end
         % Create confidence region data if applicable
         if isa(this.Model,'idlti')
            c = controllib.chart.internal.data.characteristics.BodeConfidenceRegionData(this,...
               this.NumberOfStandardDeviations);
            characteristics = [characteristics,c];
         end
      end

      function magFocus = computeMagnitudeFocus(this,frequencyFocuses,magnitudeScale)
         arguments
            this (1,1) controllib.chart.internal.data.response.BodeResponseDataSource
            frequencyFocuses (:,:) cell
            magnitudeScale (1,1) string {mustBeMember(magnitudeScale,["linear","log"])}
         end
         sz = getResponseSize(this);
         magFocus = cell(1,this.NResponses);
         for ka = 1:this.NResponses
            magFocus{ka} = repmat({[NaN, NaN]},sz);
            f = this.Frequency{ka};
            NonUniformFreq = iscell(f);
            for kch = 1:prod(sz)
               % Get indices of frequencies within the focus (note
               % that these values are not necessarily equal to
               % focus values)
               frequencyFocus = frequencyFocuses{kch};
               if NonUniformFreq
                  f_kch = f{kch};
               else
                  f_kch = f;
               end               

               idx1 = find(f_kch >= frequencyFocus(1),1,'first');
               idx2 = find(f_kch <= frequencyFocus(2),1,'last');

               if ~isempty(idx1) &&  ~isempty(idx2)
                  [magMin,magMax] = computeMagnitudeFocusFromIndices(this,frequencyFocus,idx1,idx2,kch,ka);
               else
                  magMin = NaN;
                  magMax = NaN;
               end

               if (~this.IsReal(ka) || this.IsFRD) && any(f_kch < 0)
                  idx3 = find(f_kch >= -frequencyFocus(2),1,'first');
                  idx4 = find(f_kch <= -frequencyFocus(1),1,'last');

                  if ~isempty(idx3) && ~isempty(idx4)
                     [magMinForNegativeFrequency,magMaxForNegativeFrequency] = ...
                        computeMagnitudeFocusFromIndices(this,-fliplr(frequencyFocus),idx3,idx4,kch,ka);
                     magMin = min(magMin,magMinForNegativeFrequency);
                     magMax = max(magMax,magMaxForNegativeFrequency);
                  end
               else
                  idx3 = [];
                  idx4 = [];
               end

               if (isempty(idx1) || isempty(idx2)) && (isempty(idx3) || isempty(idx4))
                  continue;
               end

               % Check if value close to 0 (which results in error when
               % converting setting axis limits)
               if magnitudeScale == "log"
                  if magMin == 0 && magMax == 0
                     magMin = eps;
                     magMax = 1;
                  elseif magMin == 0
                     magMin = eps;
                     magMax = max(magMax,2*eps);
                     magMax = min(magMax,realmax);
                  end
               end

               magFocus{ka}{kch} = [magMin,magMax];
               if (magFocus{ka}{kch}(1) == magFocus{ka}{kch}(2)) || any(isnan(magFocus{ka}{kch}))
                  value = magFocus{ka}{kch}(1);
                  if value == 0 || isnan(value)
                     magFocus{ka}{kch}(1) = 0.9;
                     magFocus{ka}{kch}(2) = 1.1;
                  else
                     absValue = abs(value);
                     magFocus{ka}{kch}(1) = value - 0.1*absValue;
                     magFocus{ka}{kch}(2) = value + 0.1*absValue;
                  end
               end
            end
         end
      end

      function phaseFocus = computePhaseFocus(this,frequencyFocuses,phaseWrapped,phaseMatched)
         arguments
            this (1,1) controllib.chart.internal.data.response.BodeResponseDataSource
            frequencyFocuses (:,:) cell
            phaseWrapped (1,1) logical
            phaseMatched (1,1) logical
         end
         phaseFocus = cell(1,this.NResponses);
         if phaseWrapped && phaseMatched
            phase = this.WrappedAndMatchedPhase;
         elseif phaseWrapped
            phase = this.WrappedPhase;
         elseif phaseMatched
            phase = this.MatchedPhase;
         else
            phase = this.Phase;
         end

         sz = getResponseSize(this);
         for ka = 1:this.NResponses
            phaseFocus{ka} = repmat({[NaN, NaN]},sz);
            f = this.Frequency{ka};
            NonUniformFreq = iscell(f);
            for kch = 1:prod(sz)
               % Get indices of frequencies within the focus (note
               % that these values are not necessarily equal to
               % focus values)
               frequencyFocus = frequencyFocuses{kch};
               if NonUniformFreq
                  f_kch = f{kch};
               else
                  f_kch = f;
               end 
               idx1 = find(f_kch >= frequencyFocus(1),1,'first');
               idx2 = find(f_kch <= frequencyFocus(2),1,'last');

               if isempty(idx1) || isempty(idx2)
                  continue; % data lies outside focus
               end

               [phaseMin,phaseMax] = computePhaseFocusFromIndices(this,phase,frequencyFocus,...
                  idx1,idx2,kch,ka);

               if (~this.IsReal(ka) || this.IsFRD) && any(f_kch < 0)
                  idx3 = find(f_kch >= -frequencyFocus(2),1,'first');
                  idx4 = find(f_kch <= -frequencyFocus(1),1,'last');
                  [phaseMinForNegativeFrequency,phaseMaxForNegativeFrequency] = ...
                     computePhaseFocusFromIndices(this,phase,-fliplr(frequencyFocus),...
                     idx3,idx4,kch,ka);
                  phaseMin = min(phaseMin,phaseMinForNegativeFrequency);
                  phaseMax = max(phaseMax,phaseMaxForNegativeFrequency);
               end

               phaseFocus{ka}{kch} = [phaseMin,phaseMax];
               if (phaseFocus{ka}{kch}(1) == phaseFocus{ka}{kch}(2)) || any(isnan(phaseFocus{ka}{kch}))
                  value = phaseFocus{ka}{kch}(1);
                  if value == 0 || isnan(value)
                     phaseFocus{ka}{kch}(1) = -0.1;
                     phaseFocus{ka}{kch}(2) = 0.1;
                  else
                     absValue = abs(value);
                     phaseFocus{ka}{kch}(1) = value - 0.1*absValue;
                     phaseFocus{ka}{kch}(2) = value + 0.1*absValue;
                  end
               end
            end
         end
      end

      function wrappedPhase = computeWrappedPhase(this,unwrappedPhase)
         arguments
            this (1,1) controllib.chart.internal.data.response.BodeResponseDataSource
            unwrappedPhase cell
         end
         wrappedPhase = unwrappedPhase;
         sz = getResponseSize(this);
         for ka = 1:this.NResponses
            ph = unwrappedPhase{ka};
            for kch = 1:prod(sz)
               if iscell(ph)
                  phk = ph{kch};
               else
                  phk = ph(:,kch);
               end
               wph = mod(phk -this.PhaseWrappingBranch,2*pi) + this.PhaseWrappingBranch;
               if iscell(ph)
                  wrappedPhase{ka}{kch} = wph;
               else
                  wrappedPhase{ka}(:,kch) = wph;
               end
            end
         end
      end

      function matchedPhase = computeMatchedPhase(this,unmatchedPhase)
         arguments
            this (1,1) controllib.chart.internal.data.response.BodeResponseDataSource
            unmatchedPhase cell
         end
         matchedPhase = unmatchedPhase;
         sz = getResponseSize(this);
         
         for ka = 1:this.NResponses
            f = this.Frequency{ka};
            ph = unmatchedPhase{ka};
            NonUniformFreq = iscell(f);
            for kch = 1:prod(sz)
               if NonUniformFreq
                  w = f{kch};
                  phk = ph{kch};
               else
                  w = f;
                  phk = ph(:,kch);
               end
               w(isnan(phk)) = NaN;
               [~,idx] = min(abs(flipud(w)-this.PhaseMatchingFrequency));  % favor positive match when tie
               idx = numel(w)+1-idx;
               if ~isempty(idx)
                  mph = phk - 2*pi*round((phk(idx) - this.PhaseMatchingValue)/(2*pi));
                  if NonUniformFreq
                     matchedPhase{ka}{kch} = mph;
                  else
                     matchedPhase{ka}(:,kch) = mph;
                  end
               end
            end
         end
      end
   end

   methods (Access = private)
      function [magMin,magMax] = computeMagnitudeFocusFromIndices(this,frequencyFocus,idx1,idx2,kch,ka)

         mag = this.Magnitude{ka};
         f = this.Frequency{ka};
         if iscell(f)
            f = f{kch};
            mag = mag{kch};
         else
            mag = mag(:,kch);
         end

         if idx1 >= idx2
            % focus lies between two data points
            mag_k = mag([idx1 idx2]);
            mag_k(isinf(mag_k)) = NaN;
            magMin = min(mag_k);
            magMax = max(mag_k);
         else
            % Get min and max of yData
            mag_k = mag(idx1:idx2);               
            mag_k(isinf(mag_k)) = NaN;
            [magMin, idxMin] = min(mag_k);
            [magMax, idxMax] = max(mag_k);

            % Check if first data point is minimum
            if idxMin == 1 && idx1>1
               % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
               fi = f(idx1-1:idx1);
               y = mag(idx1-1:idx1);
               magMin = interp1(fi,y,frequencyFocus(1));
            end

            % Check if last data point is maximum
            if idxMax == length(mag_k) && idx2<length(f)
               % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
               fi = f(idx2:idx2+1);
               fi(fi==Inf) = realmax;
               fi(fi==-Inf) = -realmax;
               y = mag(idx2:idx2+1);
               magMax = interp1(fi,y,frequencyFocus(2));
            end
         end
      end

      function [phaseMin,phaseMax] = computePhaseFocusFromIndices(this,phase,frequencyFocus,idx1,idx2,kch,ka)
         f = this.Frequency{ka};
         ph = phase{ka};
         if iscell(f)
            f = f{kch};
            ph = ph{kch};
         else
            ph = ph(:,kch);
         end 
            
         if idx1 >= idx2
            % focus lies between two data points
            phase_k = ph([idx1 idx2]);
            phaseMin = min(phase_k);
            phaseMax = max(phase_k);
         else
            % Get min and max of yData
            phase_k = ph(idx1:idx2);

            [phaseMin, idxMin] = min(phase_k);
            [phaseMax, idxMax] = max(phase_k);

            % Check if first data point is minimum
            if idxMin == 1 && idx1>1
               % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
               fi = f(idx1-1:idx1);
               y = ph(idx1-1:idx1);
               phaseMin = interp1(fi,y,frequencyFocus(1));
            end

            % Check if last data point is maximum
            if idxMax == length(phase_k) && idx2<length(this.Frequency{ka})
               % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
               fi = f(idx2:idx2+1);
               fi(fi==Inf) = realmax;
               fi(fi==-Inf) = -realmax;
               y = ph(idx2:idx2+1);
               phaseMax = interp1(fi,y,frequencyFocus(2));
            end
         end
      end
   end
end



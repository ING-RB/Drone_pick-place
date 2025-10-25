classdef FrequencyResponseDataSource < controllib.chart.internal.data.response.ModelResponseDataSource
   % controllib.chart.internal.data.response.FrequencyResponseDataSource
   %   - base class for managing source and data objects for given frequency response
   %   - inherited from controllib.chart.internal.data.response.ModelResponseDataSource
   %
   % h = FrequencyResponseDataSource(model)
   %   model           DynamicSystem
   %
   % h = FrequencyResponseDataSource(_____,Name-Value)
   %   Frequency             frequency specification used to generate data, [] (default) auto generates frequency specification
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
   %   getCommonFrequencyFocus(this,arrayVisible)
   %       Get frequency focus values for an array of response data.
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
   %   <a href="matlab:help controllib.chart.internal.data.response.ModelResponseDataSource">controllib.chart.internal.data.response.ModelResponseDataSource</a>

   % Copyright 2021-2024 The MathWorks, Inc.

   %% Properties
   properties (SetAccess = protected)
      % "FrequencyInput": double vector or 1x2 cell
      % Frequency specification used to generate data.
      FrequencyInput
      % "Frequency": cell
      % Frequency data of response.
      Frequency cell
      % "FrequencyFocus": cell
      % Frequency focus of response.
      FrequencyFocus
      % "IsFrequencyFocusSoft":
      IsFrequencyFocusSoft
   end

   properties (Dependent, SetAccess=private)
      % "FrequencyUnit": char array
      % Get FrequencyUnit of Model.
      FrequencyUnit
      % "IsFRD": logical scalar
      % Gets if model is frd or not
      IsFRD
   end
   

   %% Constructor
   methods
      function this = FrequencyResponseDataSource(model,optionalInputs)
         arguments
            model
            optionalInputs.Frequency = []
         end
         this@controllib.chart.internal.data.response.ModelResponseDataSource(model);
         this.Type = "FrequencyResponse";
         this.FrequencyInput = optionalInputs.Frequency;
      end
   end

   %% Public methods
   methods
      function [commonFrequencyFocus,frequencyUnit] = getCommonFrequencyFocus(this,optionalInputs)
         arguments
            this (:,1) controllib.chart.internal.data.response.FrequencyResponseDataSource
            optionalInputs.MinimumStabilityMarginsVisible (1,1) logical = false
            optionalInputs.AllStabilityMarginsVisible (1,1) logical = false
            optionalInputs.ArrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
         end
         csz = getCommonResponseSize(this);
         commonFrequencyFocus = repmat({[NaN,NaN]},csz);
         frequencyUnit = this(1).FrequencyUnit;
         isSoftAll = isAllFrequencyFocusSoft(this, csz);
         areAllModelsStatic = all([this.IsStatic]);
         for k = 1:length(this) % loop for number of data objects
            iPlot = getResponseIndices(this(k)); 
            for ka = 1:this(k).NResponses % loop for system array
               if optionalInputs.ArrayVisible{k}(ka)
                  for kch = 1:numel(iPlot)
                     kr = iPlot(kch);
                     cf = funitconv(this(k).FrequencyUnit,frequencyUnit);
                     isSoft_k = this(k).IsFrequencyFocusSoft{ka}(kch);
                     if ~isSoft_k || (isSoftAll(kr) && ~areAllModelsStatic) || areAllModelsStatic                           
                        % Frequency Focus
                        frequencyFocus = cf*this(k).FrequencyFocus{ka}{kch};
                        commonFrequencyFocus{kr}(1) = min(commonFrequencyFocus{kr}(1),frequencyFocus(1));
                        commonFrequencyFocus{kr}(2) = max(commonFrequencyFocus{kr}(2),frequencyFocus(2));
                     end
                  end
                  if optionalInputs.MinimumStabilityMarginsVisible && ...
                        ~isempty(this(k).MinimumStabilityMargin) && ...
                        ~this(k).IsStatic
                     frequencyFocus = cf*this(k).MinimumStabilityMargin.FrequencyFocus{ka};
                     commonFrequencyFocus{1}(1) = ...
                        min(commonFrequencyFocus{1}(1),frequencyFocus(1));
                     commonFrequencyFocus{1}(2) = ...
                        max(commonFrequencyFocus{1}(2),frequencyFocus(2));
                  end
                  if optionalInputs.AllStabilityMarginsVisible && ...
                        ~isempty(this(k).AllStabilityMargin) && ...
                        ~this(k).IsStatic
                     frequencyFocus = cf*this(k).AllStabilityMargin.FrequencyFocus{ka};
                     commonFrequencyFocus{1}(1) = ...
                        min(commonFrequencyFocus{1}(1),frequencyFocus(1));
                     commonFrequencyFocus{1}(2) = ...
                        max(commonFrequencyFocus{1}(2),frequencyFocus(2));
                  end
               end
            end
         end
      end
   end

   %% Get/Set
   methods
      % FrequencyUnit
      function FrequencyUnit = get.FrequencyUnit(this)
         arguments
            this (1,1) controllib.chart.internal.data.response.FrequencyResponseDataSource
         end
         if strcmp(this.Model.TimeUnit,'seconds')
            timeUnit = 's';
         else
            timeUnit = this.Model.TimeUnit(1:end-1);
         end
         FrequencyUnit = ['rad/',timeUnit];
      end

      % IsFRD
      function IsFRD = get.IsFRD(this)
          IsFRD = isa(this.ModelValue,'frd');
      end
   end

   %% Protected methods
   methods (Access = protected)
      function updateData(this,modelResponseOptionalInputs,frequencyResponseOptionalInputs)
         arguments
            this (1,1) controllib.chart.internal.data.response.FrequencyResponseDataSource
            modelResponseOptionalInputs.Model = this.Model
            frequencyResponseOptionalInputs.Frequency = this.FrequencyInput
         end
         updateData@controllib.chart.internal.data.response.ModelResponseDataSource(this,Model=modelResponseOptionalInputs.Model)
         this.FrequencyInput = frequencyResponseOptionalInputs.Frequency;
      end

      function out = isAllFrequencyFocusSoft(this,csz)
         out = true(1,prod(csz));
         for k = 1:numel(this)
            iPlot = getResponseIndices(this(k));
            for kch = 1:numel(iPlot)
               kr = iPlot(kch);
               if out(kr)
                  for ka = 1:this(k).NResponses
                     out(kr) = out(kr) && this(k).IsFrequencyFocusSoft{ka}(kch);
                     if ~out(kr)
                        break;
                     end
                  end
               end
            end
         end
      end

   end
end
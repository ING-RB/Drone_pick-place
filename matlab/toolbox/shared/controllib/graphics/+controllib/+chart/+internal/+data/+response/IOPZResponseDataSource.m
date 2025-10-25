classdef IOPZResponseDataSource < controllib.chart.internal.data.response.ModelResponseDataSource
    % controllib.chart.internal.data.response.IOPZResponseDataSource
    %   - base class for managing source and data objects for given iopz response
    %   - inherited from controllib.chart.internal.data.response.ModelResponseDataSource
    %
    % h = IOPZResponseDataSource(model)
    %   model           DynamicSystem
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
    %   Poles                 poles of Model, cell
    %   Zeros                 zeros of Model, cell
    %   Ts                    sample time of Model, cell
    %   RealAxisFocus         real axis focus of response, cell
    %   ImaginaryAxisFocus    imaginary axis focus of response, cell
    %   ShowIO                show pz map for input/output pairs, logical
    %   TimeUnit              time unit of Model, char
    %   NumberOfStandardDeviations  number of SDs for confidence region, double
    %   ConfidenceRegion            confidence region characteristic (only for ident), controllib.chart.internal.data.characteristics.IOPZConfidenceRegionData
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
    %   getCommonFocusForMultipleData(this,arrayVisible)
    %       Get real and imaginary axis focues values for an array of response data.
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
    %   computeFocuses(this)
    %       Compute real and imaginary focus data. Called in updateData().
    %   getShowIO(this)
    %       Get logical value for ShowIO property.
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.response.ModelResponseDataSource">controllib.chart.internal.data.response.ModelResponseDataSource</a>

    %   Copyright 2023-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        % "Poles": cell vector
        % Poles of Model.  
        Poles
        % "Zeros": cell vector
        % Zeros of Model.  
        Zeros
        % "RealAxisFocus": cell vector
        % Real axis focus data of response.
        RealAxisFocus
        % "ImaginaryAxisFocus": cell vector
        % Imaginary axis focus data of response.
        ImaginaryAxisFocus
        % "NumberOfStandardDeviations": double scalar
        % Number of standard deviations for confidence region.
        NumberOfStandardDeviations
    end

    properties (Dependent, SetAccess=private)
        % "TimeUnit": char array
        % Get TimeUnit of Model.
        TimeUnit
        % "Ts": double scalar
        % Get sample time of Model.
        Ts
        % "ConfidenceRegion": controllib.chart.internal.data.characteristics.IOPZConfidenceRegionData scalar
        % Confidence region characteristic.
        ConfidenceRegion
    end

    %% Constructor
    methods
        function this = IOPZResponseDataSource(model,iopzResponseOptionalInputs)
            arguments
                model
                iopzResponseOptionalInputs.NumberOfStandardDeviations = 1
            end
            this@controllib.chart.internal.data.response.ModelResponseDataSource(model);
            this.Type = "IOPZResponse";

            this.NumberOfStandardDeviations = iopzResponseOptionalInputs.NumberOfStandardDeviations;

            % Update (build)
            update(this);
        end
    end

    %% Public methods
    methods
        function [commonRealAxisFocus, commonImaginaryAxisFocus, timeUnit] = getCommonFocusForMultipleData(this,confidenceRegionVisible,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.IOPZResponseDataSource
                confidenceRegionVisible (1,1) logical = false
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            % Initialize variables
            nInputs = max([this.NInputs]);
            nOutputs = max([this.NOutputs]);
            commonRealAxisFocus = repmat({[NaN NaN]},nOutputs,nInputs);
            commonImaginaryAxisFocus = repmat({[NaN NaN]},nOutputs,nInputs);
            timeUnit = this(1).TimeUnit;

            for k = 1:length(this) % loop for number of data objects
                for ka = 1:this(k).NResponses % loop for system array
                    if arrayVisible{k}(ka)
                        % Conversion Factor
                        cf = tunitconv(this(k).TimeUnit,timeUnit);

                        % Make sure focus includes unit circle for discrete systems
                        if this(k).IsDiscrete
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

                        for ko = 1:nOutputs % loop for outputs
                            ko_idx = mapDataToPlotOutputIdx(this(k),ko);
                            for ki = 1:nInputs % loop for inputs
                                ki_idx = mapDataToPlotInputIdx(this(k),ki);
                                % Compute focus if plot i/o index is non empty
                                if ~isempty(ko_idx) && ~isempty(ki_idx)
                                    % Real axis
                                    realAxisFocus = (1/cf)*this(k).RealAxisFocus{ka}{ko_idx,ki_idx};
                                    commonRealAxisFocus{ko,ki}(1) = ...
                                        min([commonRealAxisFocus{ko,ki}(1),realAxisFocus(1),minRealAxisValue]);
                                    commonRealAxisFocus{ko,ki}(2) = ...
                                        max([commonRealAxisFocus{ko,ki}(2),realAxisFocus(2),maxRealAxisValue]);

                                    % Imaginary axis
                                    imaginaryAxisFocus = (1/cf)*this(k).ImaginaryAxisFocus{ka}{ko_idx,ki_idx};
                                    commonImaginaryAxisFocus{ko,ki}(1) = ...
                                        min([commonImaginaryAxisFocus{ko,ki}(1),imaginaryAxisFocus(1),minImaginaryAxisValue]);
                                    commonImaginaryAxisFocus{ko,ki}(2) = ...
                                        max([commonImaginaryAxisFocus{ko,ki}(2),imaginaryAxisFocus(2),maxImaginaryAxisValue]);

                                    if confidenceRegionVisible && ~isempty(this(k).ConfidenceRegion) && any(this(k).ConfidenceRegion.IsValid)
                                        realAxisFocus = this(k).ConfidenceRegion.RealAxisFocus{ka}{ko_idx,ki_idx};
                                        commonRealAxisFocus{ko,ki}(1) = ...
                                            min(commonRealAxisFocus{ko,ki}(1),realAxisFocus(1));
                                        commonRealAxisFocus{ko,ki}(2) = ...
                                            max(commonRealAxisFocus{ko,ki}(2),realAxisFocus(2));
                                        imaginaryAxisFocus = this(k).ConfidenceRegion.ImaginaryAxisFocus{ka}{ko_idx,ki_idx};
                                        commonImaginaryAxisFocus{ko,ki}(1) = ...
                                            min(commonImaginaryAxisFocus{ko,ki}(1),imaginaryAxisFocus(1));
                                        commonImaginaryAxisFocus{ko,ki}(2) = ...
                                            max(commonImaginaryAxisFocus{ko,ki}(2),imaginaryAxisFocus(2));
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    %% Get/Set
    methods
        % TimeUnit
        function TimeUnit = get.TimeUnit(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.IOPZResponseDataSource
            end
            TimeUnit = this.Model.TimeUnit;
        end

        % Ts
        function Ts = get.Ts(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.IOPZResponseDataSource
            end
            Ts = this.Model.Ts;
        end

        % NumberOfStandardDeviations
        function set.NumberOfStandardDeviations(this,NumberOfStandardDeviations)
            arguments
                this (1,1) controllib.chart.internal.data.response.IOPZResponseDataSource
                NumberOfStandardDeviations
            end
            this.NumberOfStandardDeviations = NumberOfStandardDeviations;
            if isprop(this,'ConfidenceRegion') && ~isempty(this.ConfidenceRegion) %#ok<MCSUP>
                update(this.ConfidenceRegion,NumberOfStandardDeviations); %#ok<MCSUP>
            end
        end

        % ConfidenceRegion
        function ConfidenceRegion = get.ConfidenceRegion(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.IOPZResponseDataSource
            end            
            ConfidenceRegion = getCharacteristics(this,"ConfidenceRegion");
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,modelResponseOptionalInputs,iopzResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.IOPZResponseDataSource
                modelResponseOptionalInputs.Model = this.Model
                iopzResponseOptionalInputs.NumberOfStandardDeviations = this.NumberOfStandardDeviations
            end
            try
                sysList.System = modelResponseOptionalInputs.Model;
                sysList = DynamicSystem.checkPZInputs(sysList,{});
                modelResponseOptionalInputs.Model = sysList.System;
                if isempty(sysList.System)
                    error(message('Controllib:plots:PlotEmptyModel'))
                end
            catch ME
                this.DataException = ME;
            end
            updateData@controllib.chart.internal.data.response.ModelResponseDataSource(this,Model=modelResponseOptionalInputs.Model);
            this.NumberOfStandardDeviations = iopzResponseOptionalInputs.NumberOfStandardDeviations;
            this.Poles = repmat({NaN},this.NOutputs,this.NInputs,this.NResponses);
            this.Zeros = repmat({NaN},this.NOutputs,this.NInputs,this.NResponses);
            focus = repmat({[NaN NaN]},this.NOutputs,this.NInputs);
            this.RealAxisFocus = repmat({focus},this.NResponses,1);
            this.ImaginaryAxisFocus = repmat({focus},this.NResponses,1);
            if ~isempty(this.DataException)
                return;
            end
            try
                if issparse(this.Model)
                    error(message('Control:analysis:NotSupportedPoleZero',class(this.Model)));
                end
                for ka = 1:this.NResponses
                    [p,z] = getPoleZeroData_(this.ModelValue,"iopz",ka);

                    this.Zeros(:,:,ka) = z;
                    this.Poles(:,:,ka) = p;
                end
                [realAxisFocus,imaginaryAxisFocus] = computeFocuses(this);
                this.RealAxisFocus = realAxisFocus;
                this.ImaginaryAxisFocus = imaginaryAxisFocus;
            catch ME
                this.DataException = ME;
            end
        end

        function [realAxisFocus,imaginaryAxisFocus] = computeFocuses(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.IOPZResponseDataSource
            end
            realAxisFocus = cell(1,this.NResponses);
            imaginaryAxisFocus = cell(1,this.NResponses);
            for ka = 1:this.NResponses
                realAxisFocus{ka} = cell(this.NOutputs,this.NInputs);
                imaginaryAxisFocus{ka} = cell(this.NOutputs,this.NInputs);
                for ko = 1:this.NOutputs
                    for ki = 1:this.NInputs
                        allPolesAndZeros = [cell2mat(squeeze(this.Poles(ko,ki,:))); ...
                            cell2mat(squeeze(this.Zeros(ko,ki,:)))];
                        [realAxisFocus_,imagAxisFocus_] = this.computeFocusesFromPolesAndZeros(allPolesAndZeros);
                        realAxisFocus{ka}{ko,ki} = realAxisFocus_;
                        imaginaryAxisFocus{ka}{ko,ki} = imagAxisFocus_;
                    end
                end
            end
        end

        function characteristics = createCharacteristics_(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.IOPZResponseDataSource
            end            
            characteristics = controllib.chart.internal.data.characteristics.BaseCharacteristicData.empty;
            % Create confidence region data if applicable
            if isa(this.Model,'idlti')
                characteristics = controllib.chart.internal.data.characteristics.IOPZConfidenceRegionData(this,...
                    this.NumberOfStandardDeviations);
            end
        end
    end

    %% Static private methods
    methods (Static,Access=private)
        function [realAxisFocus_,imagAxisFocus_] = computeFocusesFromPolesAndZeros(allPolesAndZeros)
            arguments
                allPolesAndZeros (:,1) double
            end
            if ~isempty(allPolesAndZeros)
                realAxisFocus_ = [min([real(allPolesAndZeros);0]), max([real(allPolesAndZeros);0])];
                imagAxisFocus_ = [min(imag(allPolesAndZeros)), max(imag(allPolesAndZeros))];
                if realAxisFocus_(1) == realAxisFocus_(2) || any(isnan(realAxisFocus_))
                    value = realAxisFocus_(1);
                    if value == 0 || isnan(value)
                        realAxisFocus_(1) = -1;
                        realAxisFocus_(2) = 1;
                    else
                        absValue = abs(value);
                        realAxisFocus_(1) = realAxisFocus_(1) - 0.1*absValue;
                        realAxisFocus_(2) = realAxisFocus_(2) + 0.1*absValue;
                    end
                end
                if imagAxisFocus_(1) == imagAxisFocus_(2) || any(isnan(imagAxisFocus_))
                    value = imagAxisFocus_(1);
                    if value == 0 || isnan(value)
                        imagAxisFocus_(1) = -1;
                        imagAxisFocus_(2) = 1;
                    else
                        absValue = abs(value);
                        imagAxisFocus_(1) = imagAxisFocus_(1) - 0.1*absValue;
                        imagAxisFocus_(2) = imagAxisFocus_(2) + 0.1*absValue;
                    end
                end
            else
                realAxisFocus_ = [NaN,NaN];
                imagAxisFocus_ = [NaN,NaN];
            end
        end
    end
end

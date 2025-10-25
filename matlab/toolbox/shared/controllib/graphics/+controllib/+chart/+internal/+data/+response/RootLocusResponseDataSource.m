classdef RootLocusResponseDataSource < controllib.chart.internal.data.response.ModelResponseDataSource
    % controllib.chart.internal.data.response.RootLocusResponseDataSource
    %   - base class for managing source and data objects for given rlocus response
    %   - inherited from controllib.chart.internal.data.response.ModelResponseDataSource
    %
    % h = RootLocusResponseDataSource(model)
    %   model           DynamicSystem
    %
    % h = RootLocusResponseDataSource(_____,Name-Value)
    %   FeedbackGains         feedback gain values pertaining to pole locations, [] (default) auto generates feedback gains
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
    %   FeedbackGainsInput    feedback gains used to generate data, double
    %   SystemPoles           poles of Model, cell
    %   SystemZeros           zeros of Model, cell
    %   SystemGains           gains of Model, cell
    %   Gains                 feedback gains of response, cell
    %   Roots                 roots of response, cell
    %   RealAxisFocus         real axis focus of response, cell
    %   ImaginaryAxisFocus    imaginary axis focus of response, cell
    %   TimeUnit              time unit of Model, char
    %
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
    %
    % See Also:
    %   <a href="matlab:help controllib.chart.internal.data.response.ModelResponseDataSource">controllib.chart.internal.data.response.ModelResponseDataSource</a>

    %   Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        % "FeedbackGainsInput": double vector
        % Feedback gains used to generate data.   
        FeedbackGainsInput 
        % "SystemPoles": cell vector
        % Poles of Model.  
        SystemPoles
        % "SystemZeros": cell vector
        % Zeros of Model.  
        SystemZeros
        % "SystemGains": cell vector
        % Gains of Model. 
        SystemGains
        % "Gains": cell vector
        % Feedback gain data of response.   
        Gains
        % "Roots": cell vector
        % Root data of response.   
        Roots
        % "RealAxisFocus": cell vector
        % Real axis focus data of response.      
        RealAxisFocus
        % "ImaginaryAxisFocus": cell vector
        % Imaginary axis focus data of response.
        ImaginaryAxisFocus
    end

    properties (Dependent, SetAccess=private)
        % "TimeUnit": char array
        % Get TimeUnit of Model.
        TimeUnit
        % "Ts": double scalar
        % Get sample time of Model.
        Ts
    end

    %% Constructor
    methods
        function this = RootLocusResponseDataSource(model,rootLocusOptionalArguments)
            arguments
                model
                rootLocusOptionalArguments.FeedbackGains = []
            end
            this@controllib.chart.internal.data.response.ModelResponseDataSource(model);
            this.Type = 'RootLocusResponse';
            this.FeedbackGainsInput = rootLocusOptionalArguments.FeedbackGains;

            % Update (build)
            update(this);
        end
    end

    %% Public methods
    methods
        function [commonRealAxisFocus, commonImaginaryAxisFocus, timeUnit] = getCommonFocusForMultipleData(this,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.RootLocusResponseDataSource
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            commonRealAxisFocus = {[NaN,NaN]};
            commonImaginaryAxisFocus = {[NaN,NaN]};
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

                        % Real axis
                        realAxisFocus = (1/cf)*this(k).RealAxisFocus{ka}{1};
                        commonRealAxisFocus{1}(1) = ...
                            min([commonRealAxisFocus{1}(1),realAxisFocus(1),minRealAxisValue]);
                        commonRealAxisFocus{1}(2) = ...
                            max([commonRealAxisFocus{1}(2),realAxisFocus(2),maxRealAxisValue]);

                        % Imaginary axis
                        imaginaryAxisFocus = (1/cf)*this(k).ImaginaryAxisFocus{ka}{1};
                        commonImaginaryAxisFocus{1}(1) = ...
                            min([commonImaginaryAxisFocus{1}(1),imaginaryAxisFocus(1),minImaginaryAxisValue]);
                        commonImaginaryAxisFocus{1}(2) = ...
                            max([commonImaginaryAxisFocus{1}(2),imaginaryAxisFocus(2),maxImaginaryAxisValue]);
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
                this (1,1) controllib.chart.internal.data.response.RootLocusResponseDataSource
            end
            TimeUnit = this.Model.TimeUnit;
        end
        % Ts
        function Ts = get.Ts(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.RootLocusResponseDataSource
            end
            Ts = this.Model.Ts;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,modelResponseOptionalInputs,rootLocusOptionalArguments)
            arguments
                this (1,1) controllib.chart.internal.data.response.RootLocusResponseDataSource
                modelResponseOptionalInputs.Model = this.Model
                rootLocusOptionalArguments.FeedbackGains = this.FeedbackGainsInput
            end
            try
                sysList.System = modelResponseOptionalInputs.Model;
                ParamList = {rootLocusOptionalArguments.FeedbackGains};
                [sysList,gains] =  DynamicSystem.checkRootLocusInputs(sysList,ParamList);
                modelResponseOptionalInputs.Model = sysList.System;
                rootLocusOptionalArguments.FeedbackGains = gains;
                if isempty(sysList.System)
                    error(message('Controllib:plots:PlotEmptyModel'))
                end
            catch ME
                this.DataException = ME;
            end
            updateData@controllib.chart.internal.data.response.ModelResponseDataSource(this,Model=modelResponseOptionalInputs.Model)
            this.FeedbackGainsInput = rootLocusOptionalArguments.FeedbackGains;

            % Pole/zero map for individual I/O pairs
            this.SystemPoles = repmat({NaN},this.NResponses,1);
            this.SystemZeros = repmat({NaN},this.NResponses,1);
            this.Gains = repmat({NaN},this.NResponses,1);
            this.Roots = repmat({NaN},this.NResponses,1);
            this.SystemGains = repmat({NaN},this.NResponses,1);
            % Focus
            this.RealAxisFocus = repmat({{[NaN NaN]}},this.NResponses,1);
            this.ImaginaryAxisFocus = repmat({{[NaN NaN]}},this.NResponses,1);
            if ~isempty(this.DataException)
                return;
            end
            try
                for ka = 1:this.NResponses
                    [rk,gk,xfocus,yfocus,info] = getRootLocusData_(this.ModelValue,...
                                                        this.FeedbackGainsInput,ka);

                    if ~all(isnan(rk)) 
                        % model is finite
                        rk = rk.';
                        gk = gk(:);
                        if info.InverseFlag
                            sz = info.Pole;
                            sp = info.Zero;
                            g = 1/info.Gain;
                        else
                            sz = info.Zero;
                            sp = info.Pole;
                            g = info.Gain;
                        end
                        % Compute system gains
                        gains = zeros(size(rk));
                        for ii = 1:size(rk,1)
                            for jj = 1:size(rk,2)
                                z = rk(ii,jj);
                                den = g*prod(sz-z);
                                if den == 0
                                    gains(ii,jj) = Inf;
                                else
                                    gains(ii,jj) = abs(prod(sp-z)/den);
                                end
                                sn = sign(gk(ii));
                                if sn~=0
                                    gains(ii,jj) = gains(ii,jj)*sn;
                                end
                            end
                        end
                    else
                        % model is infinite
                        gains = NaN;
                        sz = NaN;
                        sp = NaN;
                    end
                    this.Gains{ka} = gk;
                    this.Roots{ka} = rk;
                    this.SystemZeros{ka} = sz;
                    this.SystemPoles{ka} = sp;
                    this.SystemGains{ka} = gains;
                    this.RealAxisFocus{ka} = {xfocus};
                    this.ImaginaryAxisFocus{ka} = {yfocus};
                end
            catch ME
                this.DataException = ME;
            end
        end
    end
end

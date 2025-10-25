classdef PZResponseDataSource < controllib.chart.internal.data.response.ModelResponseDataSource
    % controllib.chart.internal.data.response.PZResponseDataSource
    %   - base class for managing source and data objects for given pz response
    %   - inherited from controllib.chart.internal.data.response.ModelResponseDataSource
    %
    % h = PZResponseDataSource(model)
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
        function this = PZResponseDataSource(model)
            arguments
                model
            end
            this@controllib.chart.internal.data.response.ModelResponseDataSource(model);
            this.Type = "PZResponse";

            % Update (build)
            update(this);
        end
    end

    %% Public methods
    methods
        function [commonRealAxisFocus, commonImaginaryAxisFocus, timeUnit] = getCommonFocusForMultipleData(this,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.PZResponseDataSource
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            % Initialize variables
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

                        % If computing poles/zeros for all I/O together
                        % Real Axis
                        realAxisFocus = (1/cf)*this(k).RealAxisFocus{ka}{1};
                        commonRealAxisFocus{1}(1) = ...
                            min([commonRealAxisFocus{1}(1),realAxisFocus(1),minRealAxisValue]);
                        commonRealAxisFocus{1}(2) = ...
                            max([commonRealAxisFocus{1}(2),realAxisFocus(2),maxRealAxisValue]);

                        % Imaginary Axis
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
                this (1,1) controllib.chart.internal.data.response.PZResponseDataSource
            end
            TimeUnit = this.Model.TimeUnit;
        end
        % Ts
        function Ts = get.Ts(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.PZResponseDataSource
            end
            Ts = this.Model.Ts;
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,modelResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.PZResponseDataSource
                modelResponseOptionalInputs.Model = this.Model
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
            this.Poles = repmat({NaN},this.NResponses,1);
            this.Zeros = repmat({NaN},this.NResponses,1);
            this.RealAxisFocus = repmat({{[NaN NaN]}},this.NResponses,1);
            this.ImaginaryAxisFocus = repmat({{[NaN NaN]}},this.NResponses,1);
            if ~isempty(this.DataException)
                return;
            end
            try
                for ka = 1:this.NResponses
                    [p,z] = getPoleZeroData_(this.ModelValue,"pz",ka);
                    if this.NInputs == 1 && this.NOutputs == 1
                        % LTI array with a tf(NaN) returns a vector, so
                        % need to convert to a cell array
                        if ~iscell(p) && any(isnan(p))
                            p = {p};
                        end
                        this.Poles(ka) = p;

                        if ~iscell(z) && any(isnan(z))
                            z = {z};
                        end
                        this.Zeros(ka) = z;
                    else
                        this.Poles{ka} = p;
                        this.Zeros{ka} = z;
                    end
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
                this (1,1) controllib.chart.internal.data.response.PZResponseDataSource
            end
            realAxisFocus = cell(1,this.NResponses);
            imaginaryAxisFocus = cell(1,this.NResponses);
            for ka = 1:this.NResponses
                allPolesAndZeros = [this.Poles{ka}; this.Zeros{ka}];
                [realAxisFocus_,imagAxisFocus_] = this.computeFocusesFromPolesAndZeros(allPolesAndZeros);
                realAxisFocus{ka} = {realAxisFocus_};
                imaginaryAxisFocus{ka} = {imagAxisFocus_};
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

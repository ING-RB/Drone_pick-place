classdef BaseResponseDataSource < handle & matlab.mixin.SetGet & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
    % controllib.chart.internal.data.response.BaseResponseDataSource
    %   - base class for managing source and data objects for given base response
    %
    % h = BaseResponseDataSource()
    %
    % Read-only properties:
    %   Type                  type of response for subclass, string
    %   ArrayDim              array dimensions of response data, double
    %   NResponses            number of elements of response data, double
    %   CharacteristicTypes   types of Characteristics, string
    %   Characteristics       characteristics of response data, controllib.chart.internal.data.characteristics.BaseCharacteristicData
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

    % Copyright 2022-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        % "Type": string scalar
        % Type of response defined by subclass.
        Type (1,1) string = "BaseResponse"
    end
    
    properties (SetObservable, SetAccess = protected)
        % "ArrayDim": double array
        % Dimensions of the response data.
        ArrayDim (1,:) double {mustBeNonempty} = 1
        % "DataException": MException
        % Exception for invalid response data.
        DataException
    end

    properties (Dependent, SetAccess = private)
        % "NResponses": double scalar
        % Number of elements of the response data.
        NResponses
        % "CharacteristicTypes": string array
        % Types of the Characteristics.
        CharacteristicTypes
    end

    properties (GetAccess={?controllib.chart.internal.foundation.AbstractPlot,...
            ?controllib.chart.internal.view.axes.BaseAxesView,...
            ?controllib.chart.internal.view.wave.BaseResponseView,...
            ?controllib.chart.internal.view.characteristic.BaseCharacteristicViews},...
            SetAccess=private,NonCopyable)
        % "Characteristics":
        % controllib.chart.internal.data.characteristics.BaseCharacteristicData array
        % Assign in method "createCharacteristics_". Object that creates and
        % updates all characteristic data for the response.
        Characteristics (:,1) controllib.chart.internal.data.characteristics.BaseCharacteristicData
    end

    properties (Hidden)
        % "PlotInputIdx": double
        % Maps data input channels to plot input channels
        PlotInputIdx

        % "PlotOutputIdx": double
        % Maps data output channels to plot output channels
        PlotOutputIdx
    end

    %% Events
    events
        DataChanged
    end

    %% Constructor
    methods
        function this = BaseResponseDataSource()
        end
    end

    %% Public methods
    methods
        function characteristics = getCharacteristics(this,characteristicType)
            arguments
                this (1,1) controllib.chart.internal.data.response.BaseResponseDataSource
                characteristicType (:,1) string
            end
            characteristics = controllib.chart.internal.data.characteristics.BaseCharacteristicData.empty;
            for k = 1:length(characteristicType)
                idx = find(this.CharacteristicTypes == characteristicType(k));
                if ~isempty(idx)
                    characteristics = [characteristics; this.Characteristics(idx)]; %#ok<AGROW>
                end
            end
        end
    end

    %% Get/Set
    methods
        function NResponses = get.NResponses(this)
            NResponses = prod(this.ArrayDim);
        end
        function types = get.CharacteristicTypes(this)
            types = string.empty;
            if ~isempty(this.Characteristics)
                types = arrayfun(@(x) x.Type,this.Characteristics);
            end
        end
    end

    %% Sealed methods
    methods (Sealed)
        function update(this,varargin)
            arguments
                this (1,1) controllib.chart.internal.data.response.BaseResponseDataSource
            end
            arguments (Repeating)
                varargin
            end
            this.DataException = MException.empty;
            try
                updateData(this,varargin{:});
                createCharacteristics(this);
                for k = 1:length(this.CharacteristicTypes)
                    updateCharacteristicsData(this,this.CharacteristicTypes(k));
                end
            catch ME
                throw(ME);
            end
            notify(this,'DataChanged');
        end
    end

    %% Sealed protected methods
    methods (Sealed, Access = protected)
        function createCharacteristics(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.BaseResponseDataSource
            end
            c = createCharacteristics_(this);
            if isempty(c)
                types = string.empty;
            else
                types = arrayfun(@(x) x.Type,c);
            end
            newCharTypes = setdiff(types,this.CharacteristicTypes);
            if ~isempty(newCharTypes)
                for ii = 1:length(c)
                    if any(newCharTypes == c(ii).Type)
                        this.Characteristics = [this.Characteristics;c(ii)];
                    end
                end
            end
            removedCharTypes = setdiff(this.CharacteristicTypes,types);
            if ~isempty(removedCharTypes)
                for ii = 1:length(this.Characteristics)
                    if any(removedCharTypes == this.Characteristics(ii).Type)
                        delete(this.Characteristics(ii));
                    end
                end
                this.Characteristics = this.Characteristics(isvalid(this.Characteristics));
            end
        end

        function updateCharacteristicsData(this,characteristicType)
            arguments
                this (1,1) controllib.chart.internal.data.response.BaseResponseDataSource
                characteristicType (:,1) string
            end
            characteristics = getCharacteristics(this,characteristicType);
            for k = 1:length(characteristics)
                update(characteristics(k));
            end
        end
    end

    %% Protected methods (override in subclass)
    methods (Access = protected)
        function c = createCharacteristics_(this) %#ok<MANU>
            arguments
                this (1,1) controllib.chart.internal.data.response.BaseResponseDataSource
            end
            c = controllib.chart.internal.data.characteristics.BaseCharacteristicData.empty;
        end

        function updateData(this,varargin) %#ok<INUSD>
        end

        function thisCopy = copyElement(this)
            thisCopy = copyElement@matlab.mixin.Copyable(this);
            for ii = 1:length(this.Characteristics)
                thisCopy.Characteristics(ii) = copy(this.Characteristics(ii));
                thisCopy.Characteristics(ii).ResponseData = thisCopy;
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function characteristics = qeGetCharacteristics(this)
            arguments
                this (1,1) controllib.chart.internal.data.response.BaseResponseDataSource
            end
            characteristics = this.Characteristics;
        end

        function registerCharacteristic(this,characteristic)
            arguments
                this (1,1) controllib.chart.internal.data.response.BaseResponseDataSource
                characteristic (1,1) controllib.chart.internal.data.characteristics.BaseCharacteristicData
            end
            this.Characteristics = [this.Characteristics;characteristic];
        end
    end
end
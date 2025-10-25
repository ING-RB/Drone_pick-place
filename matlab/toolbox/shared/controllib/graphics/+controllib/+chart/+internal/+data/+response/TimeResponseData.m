classdef TimeResponseData < matlab.mixin.SetGet
    % controllib.chart.internal.data.response.TimeResponseData
    %   - base class for managing data objects for given time response
    %
    % h = TimeResponseData()
    %
    % h = TimeResponseData(_____,Name-Value)
    %   NData                 length of time data array, 1 (default)
    %   DataDimensions        dimensions of time data array, [1 1] (default)
    %   TimeUnit              time unit of data, 'seconds' (default)
    %
    % Read-only properties:
    %   TimeUnit              time unit of data, char
    %   Time                  time data of response, cell
    %   Amplitude             amplitude data of response, cell
    %   FinalValue            final value of respones, cell
    %   TimeFocus             time focus data of response, cell
    %   AmplitudeFocus        amplitude focus data of response, cell
    %   NData                 length of time data array, double
    %   DataDimensions        dimensions of time data array, double
    %
    % Public methods:
    %   getAmplitude(this,dataDimensionsIndex,seriesIndex)
    %       Get amplitude data at specified index.
    %   setAmplitude(this,amplitude,dataDimensionsIndex,seriesIndex)
    %       Set amplitude data at specified index.
    %   resetAmplitude(this)
    %       Reset amplitude data.
    %   getAmplitudeFocus(this,dataDimensionsIndex,arrayIndex)
    %       Get amplitude focus data at specified index.
    %   setAmplitudeFocus(this,amplitudeFocus,dataDimensionsIndex,arrayIndex)
    %       Set amplitude focus data at specified index.
    %   resetAmplitudeFocus(this)
    %       Reset amplitude focus data.
    %   getTime(this,dataDimensionsIndex,arrayIndex)
    %       Get time data at specified index.
    %   setTime(this,time,dataDimensionsIndex,arrayIndex)
    %       Set time data at specified index.
    %   resetTime(this)
    %       Reset time data.
    %   getTimeFocus(this,dataDimensionsIndex,arrayIndex)
    %       Get time focus data at specified index.
    %   setTimeFocus(this,timeFocus,dataDimensionsIndex,arrayIndex)
    %       Set time focus data at specified index.
    %   resetTimeFocus(this)
    %       Reset time focus data.
    %   getFinalValue(this,dataDimensionsIndex,arrayIndex)
    %       Get final value data at specified index.
    %   setFinalValue(this,finalValue,dataDimensionsIndex,arrayIndex)
    %       Set final value data at specified index.
    %   resetFinalValue(this)
    %       Reset final value data.
    %
    % Protected methods (to override in subclass):
    %   computeAmplitudeFocus(this)
    %       Compute the amplitude focus.
    %   getAllIndices(this)
    %       Get all indices from DataDimensions.       
    %   getAllIndexCombinations(this)
    %       Get all index combinations from DataDimensions and NData.
    
    % Copyright 2021-2024 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        TimeUnit
    end

    properties (Hidden, SetAccess = protected)
        Time
        TimeFocus

        Amplitude
        FinalValue
        InitialValue
        AmplitudeFocus

        ImaginaryAmplitude
        ImaginaryFinalValue
        ImaginaryInitialValue
        ImaginaryAmplitudeFocus

        MagnitudeFocus
    end

    properties (Dependent,SetAccess = protected)
        NData
        DataDimensions
    end

    properties (Access = private)
        NData_I
        DataDimensions_I
    end

    %% Constructor
    methods
        function this = TimeResponseData(optionalArguments)
            arguments
                optionalArguments.NData (1,1) double {mustBeInteger,mustBePositive} = 1;
                optionalArguments.DataDimensions (1,:) double {mustBeInteger,mustBePositive,mustBeNonempty} = [1 1];
                optionalArguments.TimeUnit (1,:) char = 'seconds'
            end
            this.NData_I = optionalArguments.NData;
            this.DataDimensions_I = optionalArguments.DataDimensions;
            this.TimeUnit = optionalArguments.TimeUnit;
            resetTime(this);
            resetAmplitude(this);
            resetFinalValue(this);
        end
    end

    %% Public methods
    methods
        % Amplitude
        function [realAmplitude,imaginaryAmplitude] = getAmplitude(this,dataDimensionsIndex,seriesIndex)
            % getAmplitude returns the amplitude data
            %
            % getAmplitude(data,dimensionIndex,seriesIndex) returns the
            % amplitude for the data series specified in seriesIndex along
            % the dimensions specified in dimensionIndex
            %
            %   Input Arguments:
            %       data            TimeResponseData object 
            %       dimensionIndex  Default is all dimensions.
            %       seriesIndex     Default is 1.
            %
            %   getAmplitude(data) returns amplitude for the 1st data series for all dimensions.  
            %
            %   getAmplitude(data,[n,m]) returns the amplitude for the 1st data series along the [n,m] dimensions.
            %       n,m are scalars
            %
            %   getAmplitude(data,{n,m}) returns the amplitude for the 1st data series along the [n,m] dimensions.
            %       n,m can be vectors
            %
            %   getAmplitude(data,{n,m},k) returns the amplitude for the k-th data series along the [n,m] dimensions.
            %       k can be vector

            arguments
                this
                dataDimensionsIndex = getAllIndices(this)
                seriesIndex double = 1
            end

            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end

            if isscalar(seriesIndex)
                realAmplitude = this.Amplitude{seriesIndex}(:,dataDimensionsIndex{:});
                imaginaryAmplitude = this.ImaginaryAmplitude{seriesIndex}(:,dataDimensionsIndex{:});
            else
                realAmplitude = cell(1,length(seriesIndex));
                imaginaryAmplitude = cell(1,length(seriesIndex));
                for k = 1:length(seriesIndex)
                    realAmplitude{k} = this.Amplitude{seriesIndex(k)}(:,dataDimensionsIndex{:});
                    imaginaryAmplitude{k} = this.ImaginaryAmplitude{seriesIndex(k)}(:,dataDimensionsIndex{:});
                end                
            end
        end

        function setAmplitude(this,amplitude,dataDimensionsIndex,seriesIndex)
            % setAmplitude sets the amplitude data
            %
            % setAmplitude(data,amplitude,dimensionIndex,seriesIndex) returns the
            % amplitude for the data series specified in seriesIndex along
            % the dimensions specified in dimensionIndex
            %
            %   Input Arguments:
            %       data            TimeResponseData object 
            %       amplitude       Amplitude data
            %       dimensionIndex  Default is all dimensions.
            %       seriesIndex     Default is 1.
            %
            %   setAmplitude(data,amplitude) sets amplitude for the 1st data series for all dimensions.  
            %
            %   setAmplitude(data,amplitude,[n,m]) sets the amplitude for the 1st data series along the [n,m] dimensions.
            %       n,m are scalars
            %
            %   setAmplitude(data,amplitude,{n,m}) sets the amplitude for the 1st data series along the [n,m] dimensions.
            %       n,m can be vectors
            %
            %   setAmplitude(data,amplitude,{n,m},k) sets the amplitude for the k-th data series along the [n,m] dimensions.
            %       k can be vector
            %
            %   setAmplitude(data,amplitude,"all",k) sets amplitude for the k-th data series for all dimensions. 

            arguments
                this
                amplitude double
                dataDimensionsIndex = getAllIndices(this)
                seriesIndex (1,1) double = 1
            end
            
            imaginaryAmplitude = imag(amplitude);
            realAamplitude = real(amplitude);
            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end
            
            if ~isempty(this.Amplitude{seriesIndex})
                currentLength = size(this.Amplitude{seriesIndex},1);
                inputLength = size(realAamplitude,1);
                if currentLength > inputLength
                    realAamplitude = [realAamplitude; NaN(currentLength-inputLength,size(realAamplitude,2))];
                    imaginaryAmplitude = [imaginaryAmplitude; ...
                            NaN(currentLength-inputLength,size(imaginaryAmplitude,2))];
                elseif currentLength < inputLength
                    sz = size(this.Amplitude{seriesIndex});
                    this.Amplitude{seriesIndex} = [this.Amplitude{seriesIndex}; ...
                        NaN([inputLength-currentLength,sz(2:end)])];
                    this.ImaginaryAmplitude{seriesIndex} = [this.ImaginaryAmplitude{seriesIndex}; ...
                        NaN([inputLength-currentLength,sz(2:end)])];
                end
            end
            this.Amplitude{seriesIndex}(:,dataDimensionsIndex{:}) = realAamplitude;
            this.ImaginaryAmplitude{seriesIndex}(:,dataDimensionsIndex{:}) = imaginaryAmplitude;
        end

        function resetAmplitude(this)
            this.Amplitude = repmat({NaN([1,this.DataDimensions])},1,this.NData);
            this.ImaginaryAmplitude = repmat({NaN([1,this.DataDimensions])},1,this.NData);
            resetAmplitudeFocus(this);
        end

        % AmplitudeFocus
        function [realAmplitudeFocus,imaginaryAmplitudeFocus] = getAmplitudeFocus(this,dataDimensionsIndex,arrayIndex)
            arguments
                this
                dataDimensionsIndex = getAllIndices(this)
                arrayIndex double = 1
            end

            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end

            realAmplitudeFocus = cell(1,length(arrayIndex));
            imaginaryAmplitudeFocus = cell(1,length(arrayIndex));
            for k = 1:length(arrayIndex)
                realAmplitudeFocus{k} = this.AmplitudeFocus{arrayIndex(k)}(dataDimensionsIndex{:});
                imaginaryAmplitudeFocus{k} = this.ImaginaryAmplitudeFocus{arrayIndex(k)}(dataDimensionsIndex{:});   
            end

            if isscalar(arrayIndex)
                realAmplitudeFocus = realAmplitudeFocus{1};
                imaginaryAmplitudeFocus = imaginaryAmplitudeFocus{1};
            end

            if isscalar(realAmplitudeFocus)
                realAmplitudeFocus = realAmplitudeFocus{1};
            end

            if isscalar(imaginaryAmplitudeFocus)
                imaginaryAmplitudeFocus = imaginaryAmplitudeFocus{1};
            end
        end

        function setAmplitudeFocus(this,realAmplitudeFocus,imaginaryAmplitudeFocus,dataDimensionsIndex,arrayIndex)
            arguments
                this
                realAmplitudeFocus cell
                imaginaryAmplitudeFocus cell
                dataDimensionsIndex = getAllIndices(this)
                arrayIndex (1,1) double = 1
            end

            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end

            this.AmplitudeFocus{arrayIndex}(dataDimensionsIndex{:}) = realAmplitudeFocus;
            if ~isempty(imaginaryAmplitudeFocus)
                this.ImaginaryAmplitudeFocus{arrayIndex}(dataDimensionsIndex{:}) = imaginaryAmplitudeFocus;
            end
        end

        function magnitudeFocus = getMagnitudeFocus(this,dataDimensionsIndex,arrayIndex)
            arguments
                this
                dataDimensionsIndex = getAllIndices(this)
                arrayIndex double = 1
            end

            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end

            magnitudeFocus = cell(1,length(arrayIndex));
            for k = 1:length(arrayIndex)
                magnitudeFocus{k} = this.MagnitudeFocus{arrayIndex(k)}(dataDimensionsIndex{:});
            end

            if isscalar(arrayIndex)
                magnitudeFocus = magnitudeFocus{1};
            end

            if isscalar(magnitudeFocus)
                magnitudeFocus = magnitudeFocus{1};
            end
        end

        function setMagnitudeFocus(this,magnitudeFocus,dataDimensionsIndex,arrayIndex)
            arguments
                this
                magnitudeFocus cell
                dataDimensionsIndex = getAllIndices(this)
                arrayIndex (1,1) double = 1
            end

            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end

            this.MagnitudeFocus{arrayIndex}(dataDimensionsIndex{:}) = magnitudeFocus;
        end


        function resetAmplitudeFocus(this)
            focus = {repmat({[NaN NaN]},this.DataDimensions)};
            this.AmplitudeFocus = repmat(focus,1,this.NData);
            this.ImaginaryAmplitudeFocus = repmat(focus,1,this.NData);
        end

        % Time
        function time = getTime(this,dataDimensionsIndex,arrayIndex)
            arguments
                this
                dataDimensionsIndex = getAllIndices(this)
                arrayIndex double = 1
            end

            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end

            if isscalar(arrayIndex)
                time = this.Time{arrayIndex}(:,dataDimensionsIndex{:});
            else
                time = cell(1,length(arrayIndex));
                for k = 1:length(arrayIndex)
                    time{k} = this.Time{arrayIndex(k)}(:,dataDimensionsIndex{:});
                end
            end
        end

        function setTime(this,time,dataDimensionsIndex,arrayIndex)
            arguments
                this
                time double
                dataDimensionsIndex = getAllIndices(this)
                arrayIndex (1,1) double = 1
            end

            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end
            
            if ~isempty(this.Time{arrayIndex})
                currentLength = size(this.Time{arrayIndex},1);
                inputLength = size(time,1);
                if currentLength > inputLength
                    time = [time; NaN(currentLength-inputLength,size(time,2))];
                elseif currentLength < inputLength
                    sz = size(this.Time{arrayIndex});
                    this.Time{arrayIndex} = [this.Time{arrayIndex}; ...
                        NaN([inputLength-currentLength,sz(2:end)])];
                end
            end

            this.Time{arrayIndex}(:,dataDimensionsIndex{:}) = time;
        end

        function resetTime(this)
            this.Time = repmat({NaN([1 this.DataDimensions])},1,this.NData);
            resetTimeFocus(this);
        end

        % TimeFocus
        function timeFocus = getTimeFocus(this,dataDimensionsIndex,arrayIndex)
            arguments
                this
                dataDimensionsIndex = getAllIndices(this)
                arrayIndex double = 1
            end

            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end

            timeFocus = cell(1,length(arrayIndex));
            for k = 1:length(arrayIndex)
                timeFocus{k} = this.TimeFocus{arrayIndex(k)}(dataDimensionsIndex{:});
            end

            if isscalar(arrayIndex)
                timeFocus = timeFocus{1};
            end

            if isscalar(timeFocus)
                timeFocus = timeFocus{1};
            end
        end

        function setTimeFocus(this,timeFocus,dataDimensionsIndex,arrayIndex)
            arguments
                this
                timeFocus cell
                dataDimensionsIndex = getAllIndices(this)
                arrayIndex (1,1) double = 1
            end

            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end

            this.TimeFocus{arrayIndex}(dataDimensionsIndex{:}) = timeFocus;
        end

        function resetTimeFocus(this)
            focus = {repmat({[NaN NaN]},this.DataDimensions)};
            this.TimeFocus = repmat(focus,1,this.NData);
        end

        % FinalValue
        function [realFinalValue,imaginaryFinalValue] = getFinalValue(this,dataDimensionsIndex,arrayIndex)
            arguments
                this
                dataDimensionsIndex = getAllIndices(this)
                arrayIndex double = 1
            end

            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end

            if isscalar(arrayIndex)
                % Real
                if isempty(this.FinalValue{arrayIndex})
                    realFinalValue = [];
                else
                    realFinalValue = this.FinalValue{arrayIndex}(dataDimensionsIndex{:});
                end

                % Imaginary
                if isempty(this.ImaginaryFinalValue{arrayIndex})
                    imaginaryFinalValue = [];
                else
                    imaginaryFinalValue = this.ImaginaryFinalValue{arrayIndex}(dataDimensionsIndex{:});
                end
            else
                realFinalValue = cell(1,length(arrayIndex));
                imaginaryFinalValue = cell(1,length(arrayIndex));
                for k = 1:length(arrayIndex)
                    % Real
                    if isempty(this.FinalValue{arrayIndex(k)})
                        realFinalValue{k} = [];
                    else
                        realFinalValue{k} = this.FinalValue{arrayIndex(k)}(dataDimensionsIndex{:});
                    end   
                    % Imaginary
                    if isempty(this.ImaginaryFinalValue{arrayIndex(k)})
                        imaginaryFinalValue{k} = [];
                    else
                        imaginaryFinalValue{k} = this.ImaginaryFinalValue{arrayIndex(k)}(dataDimensionsIndex{:});
                    end
                end
            end
        end

        function setFinalValue(this,finalValue,dataDimensionsIndex,arrayIndex)
            arguments
                this
                finalValue double
                dataDimensionsIndex = getAllIndices(this)
                arrayIndex (1,1) double = 1
            end
            
            realFinalValue = real(finalValue);
            imaginaryFinalValue = imag(finalValue);

            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end

            this.FinalValue{arrayIndex}(dataDimensionsIndex{:}) = realFinalValue;
            this.ImaginaryFinalValue{arrayIndex}(dataDimensionsIndex{:}) = imaginaryFinalValue;
        end

        function resetFinalValue(this)
            this.FinalValue = repmat({NaN(this.DataDimensions)},1,this.NData);
            this.ImaginaryFinalValue = repmat({NaN(this.DataDimensions)},1,this.NData);
        end

        % InitialValue
        function [realInitialValue,imaginaryInitialValue] = getInitialValue(this,dataDimensionsIndex,arrayIndex)
            arguments
                this
                dataDimensionsIndex = getAllIndices(this)
                arrayIndex double = 1
            end

            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end

            if isscalar(arrayIndex)
                % Real
                if isempty(this.InitialValue{arrayIndex})
                    realInitialValue = [];
                else
                    realInitialValue = this.InitialValue{arrayIndex}(dataDimensionsIndex{:});
                end
                % Imaginary
                if isempty(this.ImaginaryInitialValue{arrayIndex})
                    imaginaryInitialValue = [];
                else
                    imaginaryInitialValue = this.InitialValue{arrayIndex}(dataDimensionsIndex{:});
                end
            else
                realInitialValue = cell(1,length(arrayIndex));
                imaginaryInitialValue = cell(1,length(arrayIndex));
                for k = 1:length(arrayIndex)
                    % Real
                    if isempty(this.InitialValue{arrayIndex(k)})
                        realInitialValue{k} = [];
                    else
                        realInitialValue{k} = this.InitialValue{arrayIndex(k)}(dataDimensionsIndex{:});
                    end   
                    % Imaginary
                    if isempty(this.ImaginaryInitialValue{arrayIndex(k)})
                        imaginaryInitialValue{k} = [];
                    else
                        imaginaryInitialValue{k} = ...
                            this.ImaginaryInitialValue{arrayIndex(k)}(dataDimensionsIndex{:});
                    end
                end
            end
        end

        function setInitialValue(this,initialValue,dataDimensionsIndex,arrayIndex)
            arguments
                this
                initialValue
                dataDimensionsIndex = getAllIndices(this)
                arrayIndex (1,1) double = 1
            end
            
            realInitialValue = real(initialValue);
            imaginaryInitialValue = imag(initialValue);
            
            % Convert dataDimensionsIndex to cell if needed
            if isnumeric(dataDimensionsIndex)
                dataDimensionsIndex = num2cell(dataDimensionsIndex);
            elseif strcmp(dataDimensionsIndex,"all")
                dataDimensionsIndex = getAllIndices(this);
            end

            this.InitialValue{arrayIndex}(dataDimensionsIndex{:}) = realInitialValue;
            this.ImaginaryInitialValue{arrayIndex}(dataDimensionsIndex{:}) = imaginaryInitialValue;
        end

        function resetInitialValue(this)
            this.InitialValue = repmat({NaN(this.DataDimensions)},1,this.NData);
            this.ImaginaryInitialValue = repmat({NaN(this.DataDimensions)},1,this.NData);
        end
    end

    %% Get/Set
    methods
        % NData
        function NData = get.NData(this)
            NData = this.NData_I;
        end

        function set.NData(this,NData)
            arguments
                this (1,1) controllib.chart.internal.data.response.TimeResponseData
                NData (1,1) double {mustBeInteger,mustBePositive}
            end
            if NData < this.NData_I
                this.NData_I = NData;
                resetAmplitude(this);
                resetTime(this);
                resetFinalValue(this);
            else
                this.NData_I = NData;
            end
        end

        % DataDimensions
        function DataDimensions = get.DataDimensions(this)
            DataDimensions = this.DataDimensions_I;
        end

        function set.DataDimensions(this,DataDimensions)
            arguments
                this (1,1) controllib.chart.internal.data.response.TimeResponseData
                DataDimensions (1,:) double {mustBeInteger,mustBeNonempty}
            end
            this.DataDimensions_I = DataDimensions;
            resetAmplitude(this);
            resetTime(this);
        end
    end

    %% Protected methods
    methods (Access=protected)
        function computeAmplitudeFocus(this)
            for ka = 1:this.NData
                realAmplitudeFocus = repmat({[Inf, -Inf]},this.DataDimensions);
                imaginaryAmplitudeFocus = realAmplitudeFocus;
                magnitudeFocus = realAmplitudeFocus;
                allIndexCombinations = getAllIndexCombinations(this);

                for k = 1:size(allIndexCombinations,1)
                    dataDimensionsIdx = allIndexCombinations(k,:);
                    time = getTime(this,dataDimensionsIdx,ka);
                    timeFocus = getTimeFocus(this,dataDimensionsIdx,ka);

                    if all(isfinite(time))
                       idx1 = find(time >= timeFocus(1),1,'first');
                       idx2 = find(time <= timeFocus(2),1,'last');

                       if isempty(idx1) || isempty(idx2)
                          continue; % data lies outside focus
                       end
                    else
                       idx1 = zeros(1,0);
                       idx2 = zeros(1,0);
                    end

                    [realAllAmplitude,imaginaryAllAmplitude] = getAmplitude(this,dataDimensionsIdx,ka);

                    if idx1 >= idx2
                        % focus lies between two data points
                        realAmplitude = realAllAmplitude([idx1 idx2]);
                        imaginaryAmplitude = imaginaryAllAmplitude([idx1 idx2]);
                    else
                        realAmplitude = realAllAmplitude(idx1:idx2);
                        imaginaryAmplitude = imaginaryAllAmplitude(idx1:idx2);
                    end

                    realAmplitudeFocus = localUpdateAmplitudeFocus(realAmplitude,realAmplitudeFocus,dataDimensionsIdx);
                    imaginaryAmplitudeFocus = localUpdateAmplitudeFocus(imaginaryAmplitude,imaginaryAmplitudeFocus,dataDimensionsIdx);
                    
                    if any(imaginaryAmplitude)
                        magnitude = sqrt(realAmplitude.^2 + imaginaryAmplitude.^2);
                        magnitudeFocus = localUpdateAmplitudeFocus(magnitude,magnitudeFocus,dataDimensionsIdx);
                    else
                        magnitudeFocus = realAmplitudeFocus;
                    end
                end
                setAmplitudeFocus(this,realAmplitudeFocus,imaginaryAmplitudeFocus,getAllIndices(this),ka);
                setMagnitudeFocus(this,magnitudeFocus,getAllIndices(this),ka);
            end
        end

        function allIndex = getAllIndices(this)
            allIndex = arrayfun(@(x) 1:x,this.DataDimensions,UniformOutput=false);
        end

        function allIndexCombinations = getAllIndexCombinations(this)
            allIndex = getAllIndices(this);
            allIndexCombinations = table2cell(combinations(allIndex{:}));
        end
    end
end

function validateEqualAmplitudeSize(imaginaryAmplitude,amplitude)
controllib.chart.internal.utils.validators.mustBeSize(imaginaryAmplitude,size(amplitude));
end

function amplitudeFocus = localUpdateAmplitudeFocus(amplitude,amplitudeFocus,dataDimensionsIdx)

% Check if amplitude is NaN. If so, set focus to [0 1].
if isempty(amplitude) || all(isnan(amplitude))
    minRealAmplitude = 0;
    maxRealAmplitude = 1;
else
    minRealAmplitude = min(amplitude(:));
    maxRealAmplitude = max(amplitude(:));
end

amplitudeFocus{dataDimensionsIdx{:}} =  ...
    [min([minRealAmplitude; amplitudeFocus{dataDimensionsIdx{:}}(1)]),...
    max([maxRealAmplitude; amplitudeFocus{dataDimensionsIdx{:}}(2)])];

if amplitudeFocus{dataDimensionsIdx{:}}(1) == amplitudeFocus{dataDimensionsIdx{:}}(2)
    if amplitudeFocus{dataDimensionsIdx{:}}(1) == 0
        amplitudeFocus{dataDimensionsIdx{:}} = [-1 1];
    else
        amplitudeFocus{dataDimensionsIdx{:}}(1) = amplitudeFocus{dataDimensionsIdx{:}}(1) - ...
            0.1*abs(amplitudeFocus{dataDimensionsIdx{:}}(1));
        amplitudeFocus{dataDimensionsIdx{:}}(2) = amplitudeFocus{dataDimensionsIdx{:}}(2) + ...
            0.1*abs(amplitudeFocus{dataDimensionsIdx{:}}(2));
    end
end
end

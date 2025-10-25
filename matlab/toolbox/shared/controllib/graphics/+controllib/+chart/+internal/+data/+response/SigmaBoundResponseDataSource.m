classdef SigmaBoundResponseDataSource < controllib.chart.internal.data.response.FrequencyResponseDataSource
    % controllib.chart.internal.data.response.SigmaBoundResponseDataSource
    %   - manage source and data objects for given sigma bound response
    %   - inherited from controllib.chart.internal.data.response.FrequencyResponseDataSource
    %
    % h = SigmaBoundResponseDataSource(model)
    %   model           DynamicSystem
    %
    % h = SigmaBoundResponseDataSource(_____,Name-Value)
    %   Frequency               frequency specification used to generate data, [] (default) auto generates frequency specification
    %   SingularValueType       type of singular value response, 0 (default) plots the SV of H
    %   BoundType               type of bound, "upper" (default) plots above response data
    %   Focus                   focus of Tuning Goal, [0 Inf] (default)
    %   UseFrequencyFocus       contribute to XLimitFocus, true (default)
    %   UseMagnitudeFocus       contribute to YLimitFocus, true (default)
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
    %   SingularValueType           type of singular value response, double
    %   BoundType                   type of bound, string
    %   Focus                       focus of Tuning Goal, double
    %   UseFrequencyFocus           contribute to XLimitFocus, logical
    %   UseMagnitudeFocus           contribute to YLimitFocus, logical
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
    %   getCommonSingularValueFocus(this,commonFrequencyFocus,magnitudeScale,arrayVisible)
    %       Get singular value focus values for an array of response data.
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
    %   computeSingularValueFocus(this,frequencyFocus,magnitudeScale)
    %       Compute the singular value focus. Called in getCommonSingularValueFocus().
    %
    % See Also:
    %   <a href="matlab:help
    %   controllib.chart.internal.data.response.FrequencyResponseDataSource">controllib.chart.internal.data.response.FrequencyResponseDataSource</a>
    
    %% Properties
    properties (SetAccess = protected)
        % "SingularValue": cell vector
        % Singular values of response.
        SingularValue
        % "SingularValueType": double scalar
        % Type of singular value response.
        SingularValueType
        % "BoundType": string scalar
        % Type of response bound.
        BoundType
        % "Focus": 1x2 double
        % Frequency focus of Tuning Goal.
        Focus
        % "UseFrequencyFocus": logical scalar
        % Response contributes to XLimitFocus.
        UseFrequencyFocus
        % "UseMagnitudeFocus": logical scalar
        % Response contributes to YLimitFocus.
        UseMagnitudeFocus
    end
    
    %% Constructor
    methods
        function this = SigmaBoundResponseDataSource(model,sigmaBoundResponseOptionalInputs,frequencyResponseOptionalInputs)
            arguments
                model
                sigmaBoundResponseOptionalInputs.BoundType = "upper"
                sigmaBoundResponseOptionalInputs.Focus = [0 Inf]
                sigmaBoundResponseOptionalInputs.UseFrequencyFocus = true
                sigmaBoundResponseOptionalInputs.UseMagnitudeFocus = true
                sigmaBoundResponseOptionalInputs.SingularValueType = 0;
                frequencyResponseOptionalInputs.Frequency = []
            end
            frequencyResponseOptionalInputs = namedargs2cell(frequencyResponseOptionalInputs);
            this@controllib.chart.internal.data.response.FrequencyResponseDataSource(model,frequencyResponseOptionalInputs{:});
            
            this.Type = "SigmaBoundResponse";
            this.SingularValueType = sigmaBoundResponseOptionalInputs.SingularValueType;
            this.BoundType = sigmaBoundResponseOptionalInputs.BoundType;
            this.Focus = sigmaBoundResponseOptionalInputs.Focus;
            this.UseFrequencyFocus = sigmaBoundResponseOptionalInputs.UseFrequencyFocus;
            this.UseMagnitudeFocus = sigmaBoundResponseOptionalInputs.UseMagnitudeFocus;

            % Update response
            update(this);
        end
    end

    %% Public methods
    methods
        function [commonFrequencyFocus,frequencyUnit] = getCommonFrequencyFocus(this,frequencyScale,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.SigmaBoundResponseDataSource
                frequencyScale (1,1) string {mustBeMember(frequencyScale,["linear","log"])}
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            commonFrequencyFocus = {[NaN,NaN]};
            frequencyUnit = this(1).FrequencyUnit;
            for k = 1:length(this) % loop for number of data objects
                if this(k).UseFrequencyFocus
                    for ka = 1:this(k).NResponses % loop for system array
                        % Frequency Focus
                        if arrayVisible{k}(ka)
                            cf = funitconv(this(k).FrequencyUnit,frequencyUnit);
                            frequencyFocus = cf*this(k).FrequencyFocus{ka};
                            commonFrequencyFocus{1}(1) = ...
                                min(commonFrequencyFocus{1}(1),frequencyFocus(1));
                            commonFrequencyFocus{1}(2) = ...
                                max(commonFrequencyFocus{1}(2),frequencyFocus(2));
                        end
                    end
                end
            end
            if frequencyScale=="linear" && any(arrayfun(@(x) ~all(x.IsReal),this))
                commonFrequencyFocus{1}(1) = -commonFrequencyFocus{1}(2); %mirror focus
            end
        end

        function [commonSingularValueFocus,magnitudeUnit] = getCommonSingularValueFocus(this,commonFrequencyFocus,magnitudeScale,arrayVisible)
            arguments
                this (:,1) controllib.chart.internal.data.response.SigmaBoundResponseDataSource
                commonFrequencyFocus (1,1) cell
                magnitudeScale (1,1) string {mustBeMember(magnitudeScale,["linear","log"])}
                arrayVisible (:,1) cell = arrayfun(@(x) {true(x.NResponses,1)},this)
            end
            commonSingularValueFocus = {[NaN,NaN]};
            magnitudeUnit = 'abs';
            for k = 1:length(this) % loop for number of data objects
                if this(k).UseMagnitudeFocus
                    singularValueFocuses = computeSingularValueFocus(this(k),commonFrequencyFocus,magnitudeScale);
                    for ka = 1:this(k).NResponses % loop for system array
                        % Singular Value Focus
                        if arrayVisible{k}(ka)
                            singularValueFocus = singularValueFocuses{ka};
                            commonSingularValueFocus{1}(1) = ...
                                min(commonSingularValueFocus{1}(1),singularValueFocus(1));
                            commonSingularValueFocus{1}(2) = ...
                                max(commonSingularValueFocus{1}(2),singularValueFocus(2));
                        end
                    end
                end
            end
        end
    end

    %% Protected methods
    methods (Access = protected)
        function updateData(this,sigmaBoundResponseOptionalInputs,frequencyResponseOptionalInputs)
            arguments
                this (1,1) controllib.chart.internal.data.response.SigmaBoundResponseDataSource
                sigmaBoundResponseOptionalInputs.SingularValueType = this.SingularValueType
                sigmaBoundResponseOptionalInputs.BoundType = this.BoundType
                sigmaBoundResponseOptionalInputs.Focus = this.Focus
                sigmaBoundResponseOptionalInputs.UseFrequencyFocus = this.UseFrequencyFocus
                sigmaBoundResponseOptionalInputs.UseMagnitudeFocus = this.UseMagnitudeFocus
                frequencyResponseOptionalInputs.Model = this.Model
                frequencyResponseOptionalInputs.Frequency = this.FrequencyInput
            end
            try
                sysList.System = frequencyResponseOptionalInputs.Model;
                ParamList = {frequencyResponseOptionalInputs.Frequency};
                [sysList,w] = DynamicSystem.checkSigmaInputs(sysList,ParamList);
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
            this.SingularValueType = sigmaBoundResponseOptionalInputs.SingularValueType;
            this.BoundType = sigmaBoundResponseOptionalInputs.BoundType;
            this.Focus = sigmaBoundResponseOptionalInputs.Focus;
            this.UseFrequencyFocus = sigmaBoundResponseOptionalInputs.UseFrequencyFocus;
            this.UseMagnitudeFocus = sigmaBoundResponseOptionalInputs.UseMagnitudeFocus;
            this.SingularValue = repmat({NaN(min(this.NInputs,this.NOutputs),1)},this.NResponses,1);
            this.Frequency = repmat({NaN},this.NResponses,1);
            this.FrequencyFocus = repmat({[NaN NaN]},this.NResponses,1);
            if ~isempty(this.DataException)
                return;
            end
            try
                for ka = 1:this.NResponses
                    [sv,w,focus] = getSingularValueData_(this.ModelValue,this.FrequencyInput,...
                                        this.SingularValueType,ka);
                    if size(sv,1) == 0 %idnlmodel idpoly
                        sv = NaN(1,size(sv,2),size(sv,3));
                    end
                    this.SingularValue{ka} = sv;
                    this.Frequency{ka} = w;

                    if this.Focus(1)>w(1) || this.Focus(2)<w(end)
                        % Clip and interpolate to show true edges
                        if this.Focus(1)>w(1)
                            w = [this.Focus(1) ; w(w>this.Focus(1),:,:)];
                        end
                        if this.Focus(2)<w(end)
                            w = [w(w<this.Focus(2),:,:) ; this.Focus(2)];
                        end
                        % Note: Use log-log interpolation to preserve slope of gain asymptotes
                        this.SingularValue{ka} = exp(utInterp1(log(this.Frequency{ka}),log(this.SingularValue{ka}),log(w')));
                        this.Frequency{ka} = w;
                    end
                    DataFocus = focus.Focus;

                    % Remove NaNs from focus
                    if any(isnan(DataFocus))
                        % Check if focus contains NaN
                        DataFocus = [0.1 10];
                    end

                    if any(this.BoundType==["SBound" "TBound"])
                        DataFocus = updateDataForLoopShape(this,DataFocus);
                    end

                    w = this.Frequency{ka};
                    wMin = w(1);
                    wMax = w(end);
                    Span = min(DataFocus(2)/DataFocus(1),wMax/wMin);
                    if DataFocus(1)<wMin
                        DataFocus = [wMin wMin*Span];  % Slide right
                    elseif DataFocus(2)>wMax
                        DataFocus = [wMax/Span wMax];  % Slide left
                    end

                    % Round focus if frequency grid is automatically computed
                    roundedFocus = DataFocus;
                    if isempty(this.FrequencyInput)
                        roundedFocus(1) = 10^floor(log10(roundedFocus(1)));
                        roundedFocus(2) = 10^ceil(log10(roundedFocus(2)));
                    end
                    if roundedFocus(1) >= roundedFocus(2)
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

        function svFocus = computeSingularValueFocus(this,frequencyFocus,magnitudeScale)
            arguments
                this (1,1) controllib.chart.internal.data.response.SigmaBoundResponseDataSource
                frequencyFocus (1,1) cell
                magnitudeScale (1,1) string {mustBeMember(magnitudeScale,["linear","log"])}
            end
            svFocus = cell(1,this.NResponses);
            for ka = 1:this.NResponses
                svFocus{ka} = [NaN, NaN];

                % Get indices of frequencies within the focus (note
                % that these values are not necessarily equal to
                % focus values)
                w = this.Frequency{ka};
                sv = this.SingularValue{ka};
                sv = sv(:,~isnan(w));
                w = w(~isnan(w));
                idx1 = find(w >= frequencyFocus{1}(1),1,'first');
                idx2 = find(w <= frequencyFocus{1}(2),1,'last');

                if isempty(idx1) || isempty(idx2)
                    continue; % data lies outside focus
                end

                if idx1 >= idx2
                    % focus lies between two data points
                    sv_k = sv(:,[idx1 idx2]);
                    rowMinValues = min(sv_k,[],2);
                    rowMaxValues = max(sv_k,[],2);
                    svMin = min(rowMinValues);
                    svMax = max(rowMaxValues);
                else
                    % Get min and max of yData
                    yData_k = sv(:,idx1:idx2);

                    [rowMinValues, rowMinIdx] = min(yData_k,[],2);
                    [rowMaxValues, rowMaxIdx] = max(yData_k,[],2);

                    [svMin,rowIdxWithMinimumValue] = min(rowMinValues);
                    idxMin = rowMinIdx(rowIdxWithMinimumValue);

                    [svMax,rowIdxWithMaximumValue] = max(rowMaxValues);
                    idxMax = rowMaxIdx(rowIdxWithMaximumValue);

                    % Check if first data point is minimum
                    if idxMin == 1 && idx1~=1
                        % Interpolate to get yDataFocus(1) when f = frequencyFocus(1)
                        f = w(idx1-1:idx1);
                        y = sv(rowIdxWithMinimumValue,idx1-1:idx1);
                        svMin = interp1(f,y,frequencyFocus{1}(1));
                    end

                    % Check if last data point is maximum
                    if idxMax == length(yData_k) && idx2~=length(w)
                        % Interpolate to get yDataFocus(2) when f = frequencyFocus(2)
                        f = w(idx2:idx2+1);
                        y = sv(rowIdxWithMaximumValue,idx2:idx2+1);
                        svMax = interp1(f,y,frequencyFocus{1}(2));
                    end
                end

                % Check if value close to 0 (which results in error when
                % converting to dB and setting axis limits)
                if magnitudeScale == "log"
                    svMin = max([svMin, eps]);
                    svMax = max([svMax, eps]);
                end

                svFocus{ka} = [svMin,svMax];
                if (svFocus{ka}(1) == svFocus{ka}(2)) || any(isnan(svFocus{ka}))
                    value = svFocus{ka}(1);
                    if value == 0 || isnan(value)
                        svFocus{ka}(1) = 0.9;
                        svFocus{ka}(2) = 1.1;
                    else
                        absValue = abs(value);
                        svFocus{ka}(1) = value - 0.1*absValue;
                        svFocus{ka}(2) = value + 0.1*absValue;
                    end
                end
            end
        end
    end

    %% Private methods
    methods (Access=private)
        function focus = updateDataForLoopShape(this,focus)
            arguments
                this (1,1) controllib.chart.internal.data.response.SigmaBoundResponseDataSource
                focus (1,2) double
            end
            for ka = 1:prod(this.ArrayDim)
                Freq = this.Frequency{ka};
                switch this.BoundType
                    case 'SBound'
                        SV = this.SingularValue{ka};
                    case 'TBound'
                        SV = 1./this.SingularValue{ka};
                end
                % Compute 0dB crossovers
                nf = numel(Freq);
                logSV = log(SV);
                ic = find((logSV(1:nf-1)<=0 & logSV(2:nf)>=0) | (logSV(1:nf-1)>=0 & logSV(2:nf)<=0));
                wc = Freq(ic) .* exp(-logSV(ic)' .* log(Freq(ic+1)./Freq(ic))./(logSV(ic+1)'-logSV(ic)'));
                gc = ones(size(wc'));
                switch this.BoundType
                    case 'SBound'
                        if SV(1)>1
                            wc = [Freq(1) ; wc]; %#ok<AGROW>
                            gc = [SV(1) , gc]; %#ok<AGROW>
                        end
                        if SV(end)>1
                            wc = [wc ; Freq(end)]; %#ok<AGROW>
                            gc = [gc , SV(end)]; %#ok<AGROW>
                        end
                    case 'TBound'
                        if SV(1)<1
                            wc = [Freq(1) ; wc]; %#ok<AGROW>
                            gc = [SV(1) , gc]; %#ok<AGROW>
                        end
                        if SV(end)<1
                            wc = [wc ; Freq(end)]; %#ok<AGROW>
                            gc = [gc , SV(end)]; %#ok<AGROW>
                        end
                end
                if ~isempty(wc)
                    this.Frequency{ka} = [];
                    this.SingularValue{ka} = [];
                end
                for k=1:numel(wc)/2
                    wStart = wc(2*k-1);
                    wEnd = wc(2*k);
                    ix = find(Freq>wStart & Freq<wEnd);
                    x = [wStart ; Freq(ix) ; wEnd ; wEnd ; flipud(Freq(ix)) ; wStart ; wStart; NaN];
                    gStart = gc(2*k-1);
                    gEnd = gc(2*k);
                    switch this.BoundType
                        case 'SBound'
                            y = [gStart , SV(ix) , gEnd , 1/gEnd , fliplr(1./SV(ix)) , 1/gStart , gStart, NaN];
                        case 'TBound'
                            y = [gStart , SV(ix) , gEnd , 1 , ones(1,numel(ix)) , 1 , gStart, NaN];
                    end
                    this.Frequency{ka} = [this.Frequency{ka};x];
                    this.SingularValue{ka} = [this.SingularValue{ka},y];
                end
                focus(1) = min(min(this.Frequency{ka}),focus(1));
                focus(2) = max(max(this.Frequency{ka}),focus(2));
            end
        end
    end
end
